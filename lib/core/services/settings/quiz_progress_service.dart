import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

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
      debugPrint('[QuizProgress] Current progress saved for lifecycle event');
    } catch (e) {
      debugPrint('[QuizProgress] Error saving current progress: $e');
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
      debugPrint('[QuizProgress] Auto-save completed');
    } catch (e) {
      debugPrint('[QuizProgress] Auto-save failed: $e');
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

      debugPrint('[QuizProgress] Progress synced to server');
    } catch (e) {
      debugPrint('[QuizProgress] Sync failed: $e');
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
      debugPrint('[QuizProgress] Error restoring from auto-save: $e');
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
      debugPrint('[QuizProgress] Error getting last sync time: $e');
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
      debugPrint('[QuizProgress] Error updating quiz stats: $e');
    }
  }

  /// Clear all progress data
  Future<void> clearAllProgress() async {
    try {
      await _box.delete(_quizProgressKey);
      await _box.delete(_playerProgressKey);
      await _box.delete(_autoSaveKey);
      await _box.delete(_lastSyncKey);

      debugPrint('[QuizProgress] All progress data cleared');
    } catch (e) {
      debugPrint('[QuizProgress] Error clearing progress: $e');
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
}
