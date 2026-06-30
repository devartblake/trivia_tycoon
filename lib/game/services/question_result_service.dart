import '../models/question_difficulty.dart';
import 'xp_service.dart';
import 'wallet_service.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Represents the result of answering a question
class QuestionResult {
  final String questionId;
  final String category;
  final QuestionDifficulty difficulty;
  final String selectedAnswer;
  final bool isCorrect;
  final Duration timeTaken;
  final int baseXPReward;
  final int baseCoinReward;
  final DateTime answeredAt;

  QuestionResult({
    required this.questionId,
    required this.category,
    required this.difficulty,
    required this.selectedAnswer,
    required this.isCorrect,
    required this.timeTaken,
    this.baseXPReward = 100,
    this.baseCoinReward = 50,
    DateTime? answeredAt,
  }) : answeredAt = answeredAt ?? DateTime.now();

  @override
  String toString() =>
      'QuestionResult(id: $questionId, correct: $isCorrect, difficulty: ${difficulty.displayName})';
}

/// Progression data after answering a question
class ProgressionData {
  final int xpEarned;
  final int coinsEarned;
  final int? streakCount;
  final bool streakBonusApplied;
  final double difficultyMultiplier;
  final double timeBonus;
  final String? milestone;

  ProgressionData({
    required this.xpEarned,
    required this.coinsEarned,
    this.streakCount,
    this.streakBonusApplied = false,
    this.difficultyMultiplier = 1.0,
    this.timeBonus = 1.0,
    this.milestone,
  });

  @override
  String toString() =>
      'ProgressionData(xp: $xpEarned, coins: $coinsEarned, streak: $streakCount)';
}

/// Service for processing question results and awarding progression
class QuestionResultService {
  final XPService xpService;
  final WalletService walletService;

  // Streak tracking
  int _currentStreak = 0;
  DateTime? _lastCorrectAnswerTime;
  static const _streakTimeoutMinutes = 30;

  QuestionResultService({
    required this.xpService,
    required this.walletService,
  });

  /// Process a question result and award progression
  Future<ProgressionData> processResult(QuestionResult result) async {
    if (!result.isCorrect) {
      _resetStreak();
      return ProgressionData(
        xpEarned: 0,
        coinsEarned: 0,
        streakCount: 0,
        difficultyMultiplier: 1.0,
      );
    }

    // Calculate rewards
    final difficultyMultiplier = result.difficulty.xpMultiplier;
    final coinMultiplier = result.difficulty.coinMultiplier;
    final timeBonus = _calculateTimeBonus(result.timeTaken, result.difficulty);

    // Update streak
    _updateStreak();
    final streakMultiplier = result.difficulty.streakMultiplier;
    final shouldApplyStreakBonus = _currentStreak > 1;

    // Calculate final rewards
    final xpEarned = (result.baseXPReward *
        difficultyMultiplier *
        (shouldApplyStreakBonus ? streakMultiplier : 1.0) *
        timeBonus).round();

    final coinsEarned = (result.baseCoinReward *
        coinMultiplier *
        (shouldApplyStreakBonus ? streakMultiplier : 1.0) *
        timeBonus).round();

    // Award to services
    xpService.addXP(xpEarned);
    walletService.addCoins(coinsEarned);

    // Check for milestones
    final milestone = _checkMilestone(xpService.playerXP);

    LogManager.debug(
      '[QuestionResultService] Result: ${result.questionId}, '
      'XP: $xpEarned, Coins: $coinsEarned, Streak: $_currentStreak',
    );

    return ProgressionData(
      xpEarned: xpEarned,
      coinsEarned: coinsEarned,
      streakCount: _currentStreak,
      streakBonusApplied: shouldApplyStreakBonus,
      difficultyMultiplier: difficultyMultiplier,
      timeBonus: timeBonus,
      milestone: milestone,
    );
  }

  /// Calculate time-based bonus (faster answers = higher bonus)
  double _calculateTimeBonus(Duration timeTaken, QuestionDifficulty difficulty) {
    final timeLimit = difficulty.timeLimitSeconds ?? 30;
    final secondsTaken = timeTaken.inSeconds;

    // Bonus for answering in first 50% of time
    if (secondsTaken <= timeLimit * 0.5) {
      return 1.5; // 50% bonus
    }

    // Regular reward for answering within time
    if (secondsTaken <= timeLimit) {
      return 1.0;
    }

    // Penalty for timeout (still award base, but no multiplier)
    return 0.5;
  }

  /// Update streak counter
  void _updateStreak() {
    final now = DateTime.now();

    if (_lastCorrectAnswerTime == null) {
      _currentStreak = 1;
    } else {
      final timeSinceLastAnswer =
          now.difference(_lastCorrectAnswerTime!).inMinutes;

      if (timeSinceLastAnswer <= _streakTimeoutMinutes) {
        _currentStreak++;
      } else {
        _currentStreak = 1;
      }
    }

    _lastCorrectAnswerTime = now;
  }

  /// Reset streak on wrong answer
  void _resetStreak() {
    _currentStreak = 0;
    _lastCorrectAnswerTime = null;
  }

  /// Check for achievement milestones
  String? _checkMilestone(int totalXP) {
    if (totalXP >= 10000 && totalXP < 10100) {
      return 'Reached 10,000 XP!';
    }
    if (totalXP >= 50000 && totalXP < 50100) {
      return 'Reached 50,000 XP!';
    }
    if (totalXP >= 100000 && totalXP < 100100) {
      return 'Reached 100,000 XP!';
    }

    if (_currentStreak == 5) {
      return '5 Question Streak!';
    }
    if (_currentStreak == 10) {
      return '10 Question Streak! 🔥';
    }
    if (_currentStreak == 25) {
      return '25 Question Streak! 🌟';
    }

    return null;
  }

  /// Get current streak count
  int get streak => _currentStreak;

  /// Get time since last correct answer
  Duration? get timeSinceLastAnswer {
    if (_lastCorrectAnswerTime == null) return null;
    return DateTime.now().difference(_lastCorrectAnswerTime!);
  }

  /// Check if streak is still active
  bool get isStreakActive {
    if (_lastCorrectAnswerTime == null) return false;
    final elapsed = DateTime.now().difference(_lastCorrectAnswerTime!).inMinutes;
    return elapsed <= _streakTimeoutMinutes;
  }

  /// Reset all progression (for testing or reset scenarios)
  void resetProgression() {
    _resetStreak();
    xpService.resetXP();
  }
}
