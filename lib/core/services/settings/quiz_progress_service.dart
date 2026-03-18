import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Service to manage quiz session data, onboarding flags, and player metadata.
class QuizProgressService {
  static const String _settingsBox = 'settings';
  static const String _quizProgressKey = 'quizProgress';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _playerNameKey = 'playerName';
  static const String _playerProgressKey = 'playerProgress';
  static const String _autoSaveKey = 'autoSaveData';
  static const String _lastSyncKey = 'lastSyncTimestamp';

  late final Box _box;

  QuizProgressService._(this._box);

  /// Factory initializer for use in ServiceManager
  static Future<QuizProgressService> initialize() async {
    final box = await Hive.openBox(_settingsBox);
    return QuizProgressService._(box);
  }

  // ------------------------- EXISTING METHODS ----------------

  /// Saves progress data of an ongoing quiz session.
  Future<void> saveQuizProgress(Map<String, dynamic> progress) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put(_quizProgressKey, progress);
  }

  /// Retrieves the stored quiz progress data.
  Future<Map<String, dynamic>> getQuizProgress() async {
    final box = await Hive.openBox(_settingsBox);
    return Map<String, dynamic>.from(box.get(_quizProgressKey, defaultValue: {}));
  }

  /// Marks the onboarding screen as completed.
  Future<void> setOnboardingCompleted() async {
    final box = await Hive.openBox(_settingsBox);
    await box.put(_onboardingCompleteKey, true);
  }

  /// Returns whether onboarding is completed.
  Future<bool> getOnboardingStatus() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get(_onboardingCompleteKey, defaultValue: false);
  }

  /// Saves the player's display name.
  Future<void> savePlayerName(String name) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put(_playerNameKey, name);
  }

  /// Returns the saved player name or default.
  Future<String> getPlayerName() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get(_playerNameKey, defaultValue: 'Player');
  }

  /// Saves score and streak progress.
  Future<void> savePlayerProgress(Map<String, dynamic> progress) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put(_playerProgressKey, progress);
  }

  /// Loads score and streak progress.
  Future<Map<String, dynamic>> getPlayerProgress() async {
    final box = await Hive.openBox(_settingsBox);
    return Map<String, dynamic>.from(box.get(_playerProgressKey, defaultValue: {}));
  }

  // ------------------------- LIFECYCLE METHODS ---------------

  /// Save current progress (called by AppLifecycleObserver)
  Future<void> saveCurrentProgress() async {
    try {
      final currentData = await getQuizProgress();
      currentData['last_saved'] = DateTime.now().toIso8601String();
      currentData['save_reason'] = 'lifecycle_pause';

      await saveQuizProgress(currentData);
      LogManager.debug('[QuizProgress] Current progress saved for lifecycle event');
    } catch (e) {
      LogManager.debug('[QuizProgress] Error saving current progress: $e');
    }
  }

  /// Auto-save progress periodically
  Future<void> autoSave() async {
    try {
      final autoSaveData = {
        'timestamp': DateTime.now().toIso8601String(),
        'quiz_progress': await getQuizProgress(),
        'player_progress': await getPlayerProgress(),
      };

      await _box.put(_autoSaveKey, autoSaveData);
      LogManager.debug('[QuizProgress] Auto-save completed');
    } catch (e) {
      LogManager.debug('[QuizProgress] Auto-save failed: $e');
    }
  }

  /// Sync progress to server
  Future<void> syncProgress() async {
    try {
      final progressData = await getQuizProgress();
      final playerData = await getPlayerProgress();

      // In a real app, you'd send this to your backend
      // For now, we just update the last sync timestamp
      await _box.put(_lastSyncKey, DateTime.now().toIso8601String());

      LogManager.debug('[QuizProgress] Progress synced to server');
    } catch (e) {
      LogManager.debug('[QuizProgress] Sync failed: $e');
    }
  }

  /// Restore from auto-save if available
  Future<Map<String, dynamic>?> restoreFromAutoSave() async {
    try {
      final autoSaveData = _box.get(_autoSaveKey);
      if (autoSaveData != null) {
        return Map<String, dynamic>.from(autoSaveData);
      }
      return null;
    } catch (e) {
      LogManager.debug('[QuizProgress] Error restoring from auto-save: $e');
      return null;
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTime() async {
    try {
      final timestamp = _box.get(_lastSyncKey);
      if (timestamp != null) {
        return DateTime.parse(timestamp);
      }
      return null;
    } catch (e) {
      LogManager.debug('[QuizProgress] Error getting last sync time: $e');
      return null;
    }
  }

  /// Update quiz statistics
  Future<void> updateQuizStats({
    int? questionsAnswered,
    int? correctAnswers,
    int? currentStreak,
    int? bestStreak,
    double? averageTime,
  }) async {
    try {
      final currentProgress = await getPlayerProgress();

      if (questionsAnswered != null) {
        currentProgress['total_questions'] = (currentProgress['total_questions'] ?? 0) + questionsAnswered;
      }
      if (correctAnswers != null) {
        currentProgress['correct_answers'] = (currentProgress['correct_answers'] ?? 0) + correctAnswers;
      }
      if (currentStreak != null) {
        currentProgress['current_streak'] = currentStreak;
      }
      if (bestStreak != null) {
        final current = currentProgress['best_streak'] ?? 0;
        currentProgress['best_streak'] = bestStreak > current ? bestStreak : current;
      }
      if (averageTime != null) {
        currentProgress['average_time'] = averageTime;
      }

      currentProgress['last_updated'] = DateTime.now().toIso8601String();
      await savePlayerProgress(currentProgress);
    } catch (e) {
      LogManager.debug('[QuizProgress] Error updating quiz stats: $e');
    }
  }

  /// Clear all progress data
  Future<void> clearAllProgress() async {
    try {
      await _box.delete(_quizProgressKey);
      await _box.delete(_playerProgressKey);
      await _box.delete(_autoSaveKey);
      await _box.delete(_lastSyncKey);

      LogManager.debug('[QuizProgress] All progress data cleared');
    } catch (e) {
      LogManager.debug('[QuizProgress] Error clearing progress: $e');
    }
  }

  /// Get progress summary for debugging
  Map<String, dynamic> getProgressSummary() {
    try {
      final quiz = _box.get(_quizProgressKey, defaultValue: {});
      final player = _box.get(_playerProgressKey, defaultValue: {});
      final lastSync = _box.get(_lastSyncKey);

      return {
        'has_quiz_progress': quiz.isNotEmpty,
        'has_player_progress': player.isNotEmpty,
        'last_sync': lastSync,
        'total_questions': player['total_questions'] ?? 0,
        'correct_answers': player['correct_answers'] ?? 0,
        'current_streak': player['current_streak'] ?? 0,
        'best_streak': player['best_streak'] ?? 0,
      };
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  /// Get recent quizzes for UI display
  List<Map<String, String>> getRecentQuizzes() {
    try {
      if (!Hive.isBoxOpen(_settingsBox)) {
        return _getDefaultRecentQuizzes();
      }

      final box = Hive.box(_settingsBox);
      final recentQuizzes = box.get('recent_quizzes');

      if (recentQuizzes != null && recentQuizzes is List) {
        return List<Map<String, String>>.from(
            recentQuizzes.map((quiz) => Map<String, String>.from(quiz))
        );
      }

      return _getDefaultRecentQuizzes();
    } catch (e) {
      LogManager.debug('[QuizProgress] Error getting recent quizzes: $e');
      return _getDefaultRecentQuizzes();
    }
  }

  /// Get default recent quizzes when no data available
  List<Map<String, String>> _getDefaultRecentQuizzes() {
    return [
      {
        'title': 'Science Trivia',
        'score': '85%',
        'date': 'March 5',
        'image': 'assets/images/quiz/category/science.jpg'
      },
      {
        'title': 'History Quiz',
        'score': '90%',
        'date': 'March 4',
        'image': 'assets/images/quiz/category/cinema.jpg'
      },
      {
        'title': 'Pop Culture',
        'score': '75%',
        'date': 'March 3',
        'image': 'assets/images/quiz/category/pop_culture.jpg'
      },
      {
        'title': '1980 Movies',
        'score': '25%',
        'date': 'February 28',
        'image': 'assets/images/quiz/category/film-strip.jpg'
      },
    ];
  }

  /// Save a completed quiz to recent quizzes
  Future<void> saveCompletedQuiz({
    required String title,
    required String score,
    required String category,
    String? imagePath,
  }) async {
    try {
      final box = await Hive.openBox(_settingsBox);
      final recentQuizzes = getRecentQuizzes();

      final newQuiz = {
        'title': title,
        'score': score,
        'date': _formatDate(DateTime.now()),
        'image': imagePath ?? 'assets/images/quiz/category/default.jpg',
        'category': category,
      };

      // Add to beginning and limit to 10 recent quizzes
      recentQuizzes.insert(0, newQuiz);
      if (recentQuizzes.length > 10) {
        recentQuizzes.removeRange(10, recentQuizzes.length);
      }

      await box.put('recent_quizzes', recentQuizzes);
      LogManager.debug('[QuizProgress] Saved completed quiz: $title');
    } catch (e) {
      LogManager.debug('[QuizProgress] Error saving completed quiz: $e');
    }
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${months[date.month - 1]} ${date.day}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Daily quiz tracking (synchronous — settings box is always open at startup)
  // ─────────────────────────────────────────────────────────────────────────

  static const _dailyQuizLastDateKey = 'daily_quiz_last_date';
  static const _dailyQuizStreakKey = 'daily_quiz_streak';

  /// Returns the date the daily quiz was last completed, or null.
  DateTime? getDailyQuizLastCompletedDateSync() {
    try {
      final box = Hive.box(_settingsBox);
      final dateStr = box.get(_dailyQuizLastDateKey) as String?;
      if (dateStr == null) return null;
      return DateTime.tryParse(dateStr);
    } catch (_) {
      return null;
    }
  }

  /// Returns the current daily quiz completion streak.
  int getDailyQuizStreakSync() {
    try {
      final box = Hive.box(_settingsBox);
      return (box.get(_dailyQuizStreakKey, defaultValue: 0) as num).toInt();
    } catch (_) {
      return 0;
    }
  }

  /// Marks today's daily quiz as completed and updates the streak.
  Future<void> markDailyQuizCompleted() async {
    try {
      final box = Hive.box(_settingsBox);
      final now = DateTime.now();
      final lastCompleted = getDailyQuizLastCompletedDateSync();
      final yesterday = now.subtract(const Duration(days: 1));

      int newStreak;
      if (lastCompleted == null) {
        newStreak = 1;
      } else if (_isSameDayStatic(lastCompleted, yesterday)) {
        // Continued streak
        newStreak = getDailyQuizStreakSync() + 1;
      } else if (_isSameDayStatic(lastCompleted, now)) {
        // Already completed today — keep streak unchanged
        return;
      } else {
        // Streak broken
        newStreak = 1;
      }

      await box.put(_dailyQuizLastDateKey, now.toIso8601String());
      await box.put(_dailyQuizStreakKey, newStreak);
      LogManager.debug('[QuizProgress] Daily quiz completed — streak: $newStreak');
    } catch (e) {
      LogManager.debug('[QuizProgress] Error marking daily quiz completed: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Monthly quiz tracking
  // ─────────────────────────────────────────────────────────────────────────

  String _monthlyKey(int year, int month) =>
      'monthly_quiz_completed_${year}_$month';

  String _monthlyRateKey(int year, int month) =>
      'monthly_quiz_rate_${year}_$month';

  /// Returns whether the monthly quiz for [year]/[month] has been completed.
  bool getMonthlyQuizCompletedSync(int year, int month) {
    try {
      final box = Hive.box(_settingsBox);
      return box.get(_monthlyKey(year, month), defaultValue: false) as bool;
    } catch (_) {
      return false;
    }
  }

  /// Returns the completion rate (0.0–1.0) for the monthly quiz.
  double getMonthlyQuizCompletionRateSync(int year, int month) {
    try {
      final box = Hive.box(_settingsBox);
      return (box.get(_monthlyRateKey(year, month), defaultValue: 0.0) as num)
          .toDouble();
    } catch (_) {
      return 0.0;
    }
  }

  /// Records progress on the monthly quiz (questionsCompleted / totalQuestions).
  Future<void> markMonthlyQuizProgress({
    required int year,
    required int month,
    required int questionsCompleted,
    required int totalQuestions,
  }) async {
    try {
      final box = Hive.box(_settingsBox);
      final rate = totalQuestions > 0
          ? questionsCompleted / totalQuestions
          : 0.0;
      final completed = questionsCompleted >= totalQuestions;
      await box.put(_monthlyKey(year, month), completed);
      await box.put(_monthlyRateKey(year, month), rate);
      LogManager.debug(
        '[QuizProgress] Monthly quiz progress: $questionsCompleted/$totalQuestions',
      );
    } catch (e) {
      LogManager.debug('[QuizProgress] Error saving monthly quiz progress: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Featured challenge unlock
  // ─────────────────────────────────────────────────────────────────────────

  /// Returns true once the player has completed at least 3 quizzes,
  /// unlocking the featured challenge.
  bool isFeaturedChallengeUnlocked() {
    try {
      final box = Hive.box(_settingsBox);
      final progress =
          Map<String, dynamic>.from(box.get(_playerProgressKey, defaultValue: {}));
      final totalQuizzes = (progress['total_quizzes'] ?? 0 as num).toInt();
      return totalQuizzes >= 3;
    } catch (_) {
      return true; // Fail-open so new players aren't blocked
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────────────────

  static bool _isSameDayStatic(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// Get quiz performance statistics
  Map<String, dynamic> getQuizStats() {
    try {
      final box = Hive.box(_settingsBox);
      final playerProgress = box.get(_playerProgressKey, defaultValue: {});

      return {
        'totalQuizzes': playerProgress['total_quizzes'] ?? 0,
        'totalQuestions': playerProgress['total_questions'] ?? 0,
        'correctAnswers': playerProgress['correct_answers'] ?? 0,
        'currentStreak': playerProgress['current_streak'] ?? 0,
        'bestStreak': playerProgress['best_streak'] ?? 0,
        'averageScore': _calculateAverageScore(playerProgress),
        'accuracyPercentage': _calculateAccuracy(playerProgress),
      };
    } catch (e) {
      LogManager.debug('[QuizProgress] Error getting quiz stats: $e');
      return {};
    }
  }

  /// Calculate average score percentage
  double _calculateAverageScore(Map<String, dynamic> progress) {
    final totalQuestions = progress['total_questions'] ?? 0;
    final correctAnswers = progress['correct_answers'] ?? 0;

    if (totalQuestions == 0) return 0.0;
    return (correctAnswers / totalQuestions) * 100;
  }

  /// Calculate accuracy percentage
  double _calculateAccuracy(Map<String, dynamic> progress) {
    return _calculateAverageScore(progress);
  }

  /// Update quiz completion data
  Future<void> updateQuizCompletion({
    required int questionsTotal,
    required int questionsCorrect,
    required String category,
    required double completionTime,
  }) async {
    try {
      final currentProgress = await getPlayerProgress();

      // Update totals
      currentProgress['total_quizzes'] = (currentProgress['total_quizzes'] ?? 0) + 1;
      currentProgress['total_questions'] = (currentProgress['total_questions'] ?? 0) + questionsTotal;
      currentProgress['correct_answers'] = (currentProgress['correct_answers'] ?? 0) + questionsCorrect;

      // Update streaks
      if (questionsCorrect == questionsTotal) {
        currentProgress['current_streak'] = (currentProgress['current_streak'] ?? 0) + 1;
        final bestStreak = currentProgress['best_streak'] ?? 0;
        if (currentProgress['current_streak'] > bestStreak) {
          currentProgress['best_streak'] = currentProgress['current_streak'];
        }
      } else {
        currentProgress['current_streak'] = 0;
      }

      // Update category stats
      final categoryStats = currentProgress['category_stats'] ?? {};
      final categoryKey = category.toLowerCase();
      categoryStats[categoryKey] = {
        'total_quizzes': (categoryStats[categoryKey]?['total_quizzes'] ?? 0) + 1,
        'total_questions': (categoryStats[categoryKey]?['total_questions'] ?? 0) + questionsTotal,
        'correct_answers': (categoryStats[categoryKey]?['correct_answers'] ?? 0) + questionsCorrect,
        'best_time': categoryStats[categoryKey]?['best_time'] ?? completionTime,
      };

      if (completionTime < (categoryStats[categoryKey]['best_time'] ?? double.infinity)) {
        categoryStats[categoryKey]['best_time'] = completionTime;
      }

      currentProgress['category_stats'] = categoryStats;
      currentProgress['last_quiz_date'] = DateTime.now().toIso8601String();

      await savePlayerProgress(currentProgress);
      LogManager.debug('[QuizProgress] Updated quiz completion stats');
    } catch (e) {
      LogManager.debug('[QuizProgress] Error updating quiz completion: $e');
    }
  }
}
