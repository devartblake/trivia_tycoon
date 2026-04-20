import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../game/models/pvp_challenge_models.dart';
import 'challenge_message_bridge.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class ChallengeCoordinationService extends ChangeNotifier {
  static final ChallengeCoordinationService _instance =
      ChallengeCoordinationService._internal();
  factory ChallengeCoordinationService() => _instance;
  ChallengeCoordinationService._internal();
  ChallengeMessageBridge? _messageBridge;

  // Storage
  final Map<String, PVPChallenge> _challenges = {};
  final Map<String, int> _userCoinBalances = {}; // userId -> coin balance

  // Streams
  final Map<String, StreamController<List<PVPChallenge>>>
      _userChallengeStreams = {};

  // Expiration timer
  Timer? _expirationTimer;

  // Settings
  Duration _challengeExpiration = const Duration(hours: 24);
  int _maxActiveChallenges = 10;
  int _minWager = 10;
  int _maxWager = 1000;

  void initialize() {
    _startExpirationTimer();
    _loadMockBalances();
    LogManager.debug('ChallengeCoordinationService initialized');
  }

  @override
  void dispose() {
    _expirationTimer?.cancel();
    for (final controller in _userChallengeStreams.values) {
      controller.close();
    }
    _userChallengeStreams.clear();
    super.dispose();
  }

  // ============ Challenge Creation ============

  Future<PVPChallenge?> createChallenge({
    required String challengerId,
    required String challengerName,
    required String opponentId,
    required String opponentName,
    required String category,
    required int questionCount,
    required String difficulty,
    int wager = 0,
  }) async {
    // Validation
    if (wager > 0) {
      final balance = getCoinBalance(challengerId);
      if (balance < wager) {
        LogManager.debug('Insufficient coins for wager');
        return null;
      }

      if (wager < _minWager || wager > _maxWager) {
        LogManager.debug('Invalid wager amount');
        return null;
      }
    }

    // Check active challenge limit
    final activeChallenges = getActiveChallenges(challengerId);
    if (activeChallenges.length >= _maxActiveChallenges) {
      LogManager.debug('Maximum active challenges reached');
      return null;
    }

    final challenge = PVPChallenge(
      id: _generateChallengeId(),
      challengerId: challengerId,
      challengerName: challengerName,
      opponentId: opponentId,
      opponentName: opponentName,
      category: category,
      questionCount: questionCount,
      difficulty: difficulty,
      wager: wager,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(_challengeExpiration),
    );

    _challenges[challenge.id] = challenge;

    // Lock wager coins
    if (wager > 0) {
      _deductCoins(challengerId, wager);
    }

    LogManager.debug('Challenge created: ${challenge.id}');
    _broadcastChallengeUpdate(challengerId);
    _broadcastChallengeUpdate(opponentId);
    notifyListeners();

    // Notify the message bridge
    if (_messageBridge != null) {
      await _messageBridge!.onChallengeCreated(challenge);
    }

    notifyListeners();
    return challenge;
  }

  // ============ Challenge Actions ============

  Future<bool> acceptChallenge(String challengeId, String userId) async {
    final challenge = _challenges[challengeId];
    if (challenge == null || challenge.opponentId != userId) {
      return false;
    }

    if (!challenge.status.isPending) {
      LogManager.debug('Challenge is not pending');
      return false;
    }

    if (challenge.isExpired) {
      await _expireChallenge(challengeId);
      return false;
    }

    // Check wager
    if (challenge.wager > 0) {
      final balance = getCoinBalance(userId);
      if (balance < challenge.wager) {
        LogManager.debug('Insufficient coins for wager');
        return false;
      }
      _deductCoins(userId, challenge.wager);
    }

    _challenges[challengeId] = challenge.copyWith(
      status: PVPChallengeStatus.accepted,
      acceptedAt: DateTime.now(),
    );

    LogManager.debug('Challenge accepted: $challengeId');
    _broadcastChallengeUpdate(challenge.challengerId);
    _broadcastChallengeUpdate(challenge.opponentId);
    notifyListeners();

    return true;
  }

  Future<bool> declineChallenge(String challengeId, String userId) async {
    final challenge = _challenges[challengeId];
    if (challenge == null || challenge.opponentId != userId) {
      return false;
    }

    if (!challenge.status.isPending) {
      return false;
    }

    _challenges[challengeId] = challenge.copyWith(
      status: PVPChallengeStatus.declined,
      completedAt: DateTime.now(),
    );

    // Refund wager to challenger
    if (challenge.wager > 0) {
      _addCoins(challenge.challengerId, challenge.wager);
    }

    LogManager.debug('Challenge declined: $challengeId');
    _broadcastChallengeUpdate(challenge.challengerId);
    _broadcastChallengeUpdate(challenge.opponentId);
    notifyListeners();

    return true;
  }

  Future<bool> cancelChallenge(String challengeId, String userId) async {
    final challenge = _challenges[challengeId];
    if (challenge == null || challenge.challengerId != userId) {
      return false;
    }

    if (!challenge.status.isPending) {
      LogManager.debug('Can only cancel pending challenges');
      return false;
    }

    _challenges[challengeId] = challenge.copyWith(
      status: PVPChallengeStatus.cancelled,
      completedAt: DateTime.now(),
    );

    // Refund wager
    if (challenge.wager > 0) {
      _addCoins(challenge.challengerId, challenge.wager);
    }

    LogManager.debug('Challenge cancelled: $challengeId');
    _broadcastChallengeUpdate(challenge.challengerId);
    _broadcastChallengeUpdate(challenge.opponentId);
    notifyListeners();

    return true;
  }

  // ============ Challenge Completion ============

  Future<PVPChallengeResult?> completeChallenge({
    required String challengeId,
    required int challengerScore,
    required int opponentScore,
  }) async {
    final challenge = _challenges[challengeId];
    if (challenge == null || !challenge.status.isActive) {
      return null;
    }

    // Determine winner
    String? winnerId;
    int coinsWon = 0;

    if (challengerScore > opponentScore) {
      winnerId = challenge.challengerId;
      coinsWon = challenge.wager * 2; // Winner takes all
    } else if (opponentScore > challengerScore) {
      winnerId = challenge.opponentId;
      coinsWon = challenge.wager * 2;
    } else {
      // Draw - refund wagers
      if (challenge.wager > 0) {
        _addCoins(challenge.challengerId, challenge.wager);
        _addCoins(challenge.opponentId, challenge.wager);
      }
    }

    // Award coins to winner
    if (winnerId != null && coinsWon > 0) {
      _addCoins(winnerId, coinsWon);
    }

    _challenges[challengeId] = challenge.copyWith(
      status: PVPChallengeStatus.completed,
      completedAt: DateTime.now(),
      challengerScore: challengerScore.toString(),
      opponentScore: opponentScore.toString(),
      winnerId: winnerId,
    );

    LogManager.debug('Challenge completed: $challengeId, Winner: $winnerId');
    _broadcastChallengeUpdate(challenge.challengerId);
    _broadcastChallengeUpdate(challenge.opponentId);
    notifyListeners();

    return PVPChallengeResult(
      challengeId: challengeId,
      winnerId: winnerId ?? '',
      winnerName: challenge.getWinnerName(),
      challengerScore: challengerScore,
      opponentScore: opponentScore,
      coinsWon: coinsWon,
      completedAt: DateTime.now(),
    );
  }

  Future<bool> submitScore({
    required String challengeId,
    required String userId,
    required int score,
  }) async {
    final challenge = _challenges[challengeId];
    if (challenge == null || !challenge.status.isActive) {
      return false;
    }

    if (userId == challenge.challengerId) {
      _challenges[challengeId] = challenge.copyWith(
        challengerScore: score.toString(),
      );
    } else if (userId == challenge.opponentId) {
      _challenges[challengeId] = challenge.copyWith(
        opponentScore: score.toString(),
      );
    } else {
      return false;
    }

    // Check if both scores are submitted
    final updatedChallenge = _challenges[challengeId]!;
    if (updatedChallenge.challengerScore != null &&
        updatedChallenge.opponentScore != null) {
      // Auto-complete the challenge
      await completeChallenge(
        challengeId: challengeId,
        challengerScore: int.parse(updatedChallenge.challengerScore!),
        opponentScore: int.parse(updatedChallenge.opponentScore!),
      );
    }

    notifyListeners();
    return true;
  }

  // ============ Coin Management ============

  int getCoinBalance(String userId) {
    return _userCoinBalances[userId] ?? 0;
  }

  void _addCoins(String userId, int amount) {
    _userCoinBalances[userId] = getCoinBalance(userId) + amount;
    LogManager.debug(
        'Added $amount coins to $userId. New balance: ${_userCoinBalances[userId]}');
  }

  void _deductCoins(String userId, int amount) {
    _userCoinBalances[userId] = getCoinBalance(userId) - amount;
    LogManager.debug(
        'Deducted $amount coins from $userId. New balance: ${_userCoinBalances[userId]}');
  }

  Future<bool> addCoins(String userId, int amount, {String? reason}) async {
    if (amount <= 0) return false;

    _addCoins(userId, amount);
    LogManager.debug(
        'Coins added: $amount to $userId. Reason: ${reason ?? "N/A"}');
    notifyListeners();
    return true;
  }

  // ============ Query Methods ============

  PVPChallenge? getChallenge(String challengeId) {
    return _challenges[challengeId];
  }

  List<PVPChallenge> getUserChallenges(String userId) {
    return _challenges.values
        .where((c) => c.challengerId == userId || c.opponentId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<PVPChallenge> getPendingChallenges(String userId) {
    return _challenges.values
        .where(
            (c) => c.opponentId == userId && c.status.isPending && !c.isExpired)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<PVPChallenge> getSentChallenges(String userId) {
    return _challenges.values
        .where((c) => c.challengerId == userId && c.status.isPending)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  List<PVPChallenge> getActiveChallenges(String userId) {
    return _challenges.values
        .where((c) =>
            (c.challengerId == userId || c.opponentId == userId) &&
            c.status.isActive)
        .toList()
      ..sort((a, b) => b.acceptedAt!.compareTo(a.acceptedAt!));
  }

  List<PVPChallenge> getCompletedChallenges(String userId) {
    return _challenges.values
        .where((c) =>
            (c.challengerId == userId || c.opponentId == userId) &&
            c.status == PVPChallengeStatus.completed)
        .toList()
      ..sort((a, b) => b.completedAt!.compareTo(a.completedAt!));
  }

  List<PVPChallenge> getChallengeHistory(String userId, {int limit = 50}) {
    return getUserChallenges(userId)
        .where((c) => c.status.isFinished)
        .take(limit)
        .toList();
  }

  // ============ Statistics ============

  Map<String, dynamic> getChallengeStats(String userId) {
    final allChallenges = getUserChallenges(userId);
    final completed =
        allChallenges.where((c) => c.status == PVPChallengeStatus.completed);

    final wins = completed.where((c) => c.winnerId == userId).length;
    final losses = completed
        .where((c) => c.winnerId != null && c.winnerId != userId)
        .length;
    final draws = completed.where((c) => c.winnerId == null).length;

    final totalWagered = completed.fold<int>(0, (sum, c) => sum + c.wager);
    final totalWon = completed
        .where((c) => c.winnerId == userId)
        .fold<int>(0, (sum, c) => sum + (c.wager * 2));

    return {
      'total': allChallenges.length,
      'pending': allChallenges.where((c) => c.status.isPending).length,
      'active': allChallenges.where((c) => c.status.isActive).length,
      'completed': completed.length,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'winRate': completed.isNotEmpty ? (wins / completed.length) * 100 : 0.0,
      'totalWagered': totalWagered,
      'totalWon': totalWon,
      'netProfit': totalWon - totalWagered,
      'coinBalance': getCoinBalance(userId),
    };
  }

  // ============ Expiration Management ============

  void _startExpirationTimer() {
    _expirationTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkExpiredChallenges();
    });
  }

  void _checkExpiredChallenges() {
    final now = DateTime.now();
    final expiredIds = <String>[];

    for (final entry in _challenges.entries) {
      final challenge = entry.value;
      if (challenge.status.isPending && now.isAfter(challenge.expiresAt)) {
        expiredIds.add(entry.key);
      }
    }

    for (final id in expiredIds) {
      _expireChallenge(id);
    }

    if (expiredIds.isNotEmpty) {
      LogManager.debug('Expired ${expiredIds.length} challenges');
      notifyListeners();
    }
  }

  Future<void> _expireChallenge(String challengeId) async {
    final challenge = _challenges[challengeId];
    if (challenge == null) return;

    _challenges[challengeId] = challenge.copyWith(
      status: PVPChallengeStatus.expired,
      completedAt: DateTime.now(),
    );

    // Refund wager
    if (challenge.wager > 0) {
      _addCoins(challenge.challengerId, challenge.wager);
    }

    LogManager.debug('Challenge expired: $challengeId');
    _broadcastChallengeUpdate(challenge.challengerId);
    _broadcastChallengeUpdate(challenge.opponentId);
  }

  // ============ Streams ============

  Stream<List<PVPChallenge>> watchUserChallenges(String userId) {
    _userChallengeStreams[userId] ??=
        StreamController<List<PVPChallenge>>.broadcast();

    // Send initial data
    Future.delayed(Duration.zero, () {
      _broadcastChallengeUpdate(userId);
    });

    return _userChallengeStreams[userId]!.stream;
  }

  void _broadcastChallengeUpdate(String userId) {
    final controller = _userChallengeStreams[userId];
    if (controller != null && !controller.isClosed) {
      controller.add(getUserChallenges(userId));
    }
  }

  // ============ Helper Methods ============

  String _generateChallengeId() {
    return 'challenge_${DateTime.now().millisecondsSinceEpoch}_${_challenges.length}';
  }

  void _loadMockBalances() {
    // Give some starting coins for testing
    _userCoinBalances['current_user'] = 1250;
    _userCoinBalances['user_1'] = 800;
    _userCoinBalances['user_2'] = 1500;
  }

  // ============ Settings ============

  void updateSettings({
    Duration? challengeExpiration,
    int? maxActiveChallenges,
    int? minWager,
    int? maxWager,
  }) {
    _challengeExpiration = challengeExpiration ?? _challengeExpiration;
    _maxActiveChallenges = maxActiveChallenges ?? _maxActiveChallenges;
    _minWager = minWager ?? _minWager;
    _maxWager = maxWager ?? _maxWager;

    LogManager.debug('Challenge settings updated');
    notifyListeners();
  }

  Map<String, dynamic> getSettings() {
    return {
      'challengeExpiration': _challengeExpiration.inHours,
      'maxActiveChallenges': _maxActiveChallenges,
      'minWager': _minWager,
      'maxWager': _maxWager,
    };
  }
}
