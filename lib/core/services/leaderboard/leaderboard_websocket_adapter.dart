import 'dart:async';
import '../../../core/networking/ws_protocol.dart';
import '../../../core/bootstrap/app_init.dart';
import '../../../game/models/leaderboard_entry.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Adapts WebSocket messages to Leaderboard updates
class LeaderboardWebSocketAdapter {
  StreamSubscription<WsEnvelope>? _messageSubscription;

  // Callbacks for leaderboard events
  final void Function(LeaderboardUpdate)? onRankChange;
  final void Function(List<LeaderboardEntry>)? onSnapshot;
  final void Function(String userId, int newRank, int oldRank)?
      onPlayerPassedYou;

  bool _isSubscribed = false;
  String? _currentSubscription; // 'global', 'friends', 'weekly', etc.

  LeaderboardWebSocketAdapter({
    this.onRankChange,
    this.onSnapshot,
    this.onPlayerPassedYou,
  });

  /// Initialize and start listening to WebSocket messages
  void initialize() {
    final wsClient = AppInit.wsClient;
    if (wsClient == null) {
      LogManager.debug('[LeaderboardWS] WebSocket not available');
      return;
    }

    // Listen to all WebSocket messages
    _messageSubscription = wsClient.messageStream.listen(_handleMessage);

    LogManager.debug('[LeaderboardWS] Initialized');
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(WsEnvelope envelope) {
    switch (envelope.op) {
      case 'leaderboard.update':
        _handleRankUpdate(envelope.data);
        break;
      case 'leaderboard.snapshot':
        _handleSnapshot(envelope.data);
        break;
      case 'leaderboard.player_passed':
        _handlePlayerPassed(envelope.data);
        break;
      default:
        // Ignore other message types
        break;
    }
  }

  /// Handle single rank/score update
  void _handleRankUpdate(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      final update = LeaderboardUpdate(
        userId: data['userId'] as String,
        username: data['username'] as String?,
        rank: data['rank'] as int,
        oldRank: data['oldRank'] as int?,
        score: data['score'] as int,
        scoreChange: data['change'] as int?,
        tier: data['tier'] as int?,
        timestamp: DateTime.now(),
      );

      // Call callback
      onRankChange?.call(update);

      LogManager.debug(
          '[LeaderboardWS] Rank update: ${update.username} → #${update.rank} (score: ${update.score})');
    } catch (e) {
      LogManager.debug('[LeaderboardWS] Error parsing rank update: $e');
    }
  }

  /// Handle full leaderboard snapshot (initial load)
  void _handleSnapshot(Map<String, dynamic>? data) {
    if (data == null || data['entries'] == null) return;

    try {
      final entries = (data['entries'] as List<dynamic>)
          .map((entry) => _parseLeaderboardEntry(entry as Map<String, dynamic>))
          .where((entry) => entry != null)
          .cast<LeaderboardEntry>()
          .toList();

      // Call callback
      onSnapshot?.call(entries);

      LogManager.debug(
          '[LeaderboardWS] Loaded ${entries.length} leaderboard entries');
    } catch (e) {
      LogManager.debug('[LeaderboardWS] Error parsing snapshot: $e');
    }
  }

  /// Handle "player passed you" notification
  void _handlePlayerPassed(Map<String, dynamic>? data) {
    if (data == null) return;

    try {
      final userId = data['userId'] as String;
      final username = data['username'] as String;
      final newRank = data['newRank'] as int;
      final yourRank = data['yourRank'] as int;

      // Call callback
      onPlayerPassedYou?.call(userId, newRank, yourRank);

      LogManager.debug(
          '[LeaderboardWS] Player passed you: $username (#$newRank)');
    } catch (e) {
      LogManager.debug('[LeaderboardWS] Error parsing player passed: $e');
    }
  }

  /// Subscribe to leaderboard updates
  /// 'global', 'friends', 'weekly', 'monthly'
  void subscribe({String type = 'global', int? tier, String? category}) {
    final wsClient = AppInit.wsClient;
    if (wsClient == null || !AppInit.isWebSocketConnected) {
      LogManager.debug('[LeaderboardWS] Not connected, cannot subscribe');
      return;
    }

    final data = <String, dynamic>{
      'type': type,
    };

    if (tier != null) {
      data['tier'] = tier;
    }
    if (category != null) {
      data['category'] = category;
    }

    wsClient.send(WsEnvelope(
      op: 'leaderboard.subscribe',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: data,
    ));

    _isSubscribed = true;
    _currentSubscription = type;
    LogManager.debug('[LeaderboardWS] Subscribed to $type leaderboard');
  }

  /// Unsubscribe from current leaderboard
  void unsubscribe() {
    if (!_isSubscribed) return;

    final wsClient = AppInit.wsClient;
    if (wsClient == null) return;

    wsClient.send(WsEnvelope(
      op: 'leaderboard.unsubscribe',
      ts: DateTime.now().millisecondsSinceEpoch,
      data: {
        'type': _currentSubscription,
      },
    ));

    _isSubscribed = false;
    _currentSubscription = null;
    LogManager.debug('[LeaderboardWS] Unsubscribed from leaderboard');
  }

  /// Helper: Parse leaderboard entry from WebSocket data
  LeaderboardEntry? _parseLeaderboardEntry(Map<String, dynamic> data) {
    try {
      return LeaderboardEntry(
        userId: data['userId'] as int? ?? 0,
        playerName: data['username'] as String? ?? 'Unknown',
        score: data['score'] as int? ?? 0,
        rank: data['rank'] as int? ?? 0,
        tier: data['tier'] as int? ?? 1,
        tierRank: data['tierRank'] as int? ?? 0,
        isPromotionEligible: data['isPromotionEligible'] as bool? ?? false,
        isRewardEligible: data['isRewardEligible'] as bool? ?? false,
        wins: data['wins'] as int? ?? 0,
        country: data['country'] as String? ?? '',
        state: data['state'] as String? ?? '',
        countryCode: data['countryCode'] as String? ?? '',
        level: data['level'] as int? ?? 1,
        badges: data['badges'] as String? ?? '',
        xpProgress: (data['xpProgress'] as num?)?.toDouble() ?? 0.0,
        timeframe: data['timeframe'] as String? ?? 'global',
        avatar: data['avatar'] as String? ?? '',
        lastActive: DateTime.tryParse(data['lastActive'] as String? ?? '') ??
            DateTime.now(),
        timestamp: DateTime.now(),
        gender: data['gender'] as String? ?? '',
        ageGroup: data['ageGroup'] as String? ?? '',
        joinedDate: DateTime.tryParse(data['joinedDate'] as String? ?? '') ??
            DateTime.now(),
        streak: data['streak'] as int?,
        accuracy: (data['accuracy'] as num?)?.toDouble() ?? 0.0,
        favoriteCategory: data['favoriteCategory'] as String? ?? '',
        title: data['title'] as String? ?? '',
        status: data['status'] as String? ?? '',
        device: data['device'] as String? ?? '',
        language: data['language'] as String? ?? '',
        sessionLength: (data['sessionLength'] as num?)?.toDouble() ?? 0.0,
        lastQuestionCategory: data['lastQuestionCategory'] as String? ?? '',
        interests: (data['interests'] as List?)?.cast<String>() ?? [],
        emailVerified: data['emailVerified'] as bool? ?? false,
        accountStatus: data['accountStatus'] as String? ?? 'active',
        timezone: data['timezone'] as String? ?? 'UTC',
        powerUps: (data['powerUps'] as List?)?.cast<String>(),
        lastDeviceType: data['lastDeviceType'] as String? ?? '',
        preferredNotificationMethod:
            data['preferredNotificationMethod'] as String? ?? 'push',
        subscriptionStatus: data['subscriptionStatus'] as String? ?? 'free',
        averageAnswerTime:
            (data['averageAnswerTime'] as num?)?.toDouble() ?? 0.0,
        isBot: data['isBot'] as bool? ?? false,
        accountAgeDays: (data['accountAgeDays'] as num?)?.toDouble() ?? 0.0,
        engagementScore: (data['engagementScore'] as num?)?.toDouble() ?? 0.0,
      );
    } catch (e) {
      LogManager.debug('[LeaderboardWS] Error parsing entry: $e');
      return null;
    }
  }

  /// Cleanup
  void dispose() {
    _messageSubscription?.cancel();
    if (_isSubscribed) {
      unsubscribe();
    }
    LogManager.debug('[LeaderboardWS] Disposed');
  }
}

/// Model for leaderboard rank/score updates
class LeaderboardUpdate {
  final String userId;
  final String? username;
  final int rank;
  final int? oldRank;
  final int score;
  final int? scoreChange;
  final int? tier;
  final DateTime timestamp;

  LeaderboardUpdate({
    required this.userId,
    this.username,
    required this.rank,
    this.oldRank,
    required this.score,
    this.scoreChange,
    this.tier,
    required this.timestamp,
  });

  bool get rankImproved => oldRank != null && rank < oldRank!;
  bool get rankDeclined => oldRank != null && rank > oldRank!;
  int get rankChange => oldRank != null ? oldRank! - rank : 0;
}
