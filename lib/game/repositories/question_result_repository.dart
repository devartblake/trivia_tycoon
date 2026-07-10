import 'package:hive/hive.dart';
import '../models/question_result_model.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Repository for persisting and retrieving question results for analytics
class QuestionResultRepository {
  static const _boxName = 'question_results';
  static const _maxResults = 1000;

  Box<Map<String, dynamic>>? _box;

  /// Initialize the repository and open Hive box
  Future<void> init() async {
    try {
      if (Hive.isBoxOpen(_boxName)) {
        _box = Hive.box(_boxName);
      } else {
        _box = await Hive.openBox(_boxName);
      }
      LogManager.debug('[QuestionResultRepository] Initialized successfully');
    } catch (e) {
      LogManager.error('[QuestionResultRepository] Init error: $e');
    }
  }

  /// Save a single question result
  Future<bool> saveResult(QuestionResultModel result) async {
    if (_box == null) return false;

    try {
      final key =
          '${DateTime.now().millisecondsSinceEpoch}_${result.questionId}';
      await _box!.put(key, result.toJson());

      // Cleanup old results if exceeding max
      if (_box!.length > _maxResults) {
        await _cleanupOldResults();
      }

      return true;
    } catch (e) {
      LogManager.error('[QuestionResultRepository] Save error: $e');
      return false;
    }
  }

  /// Batch save multiple results
  Future<bool> saveResults(List<QuestionResultModel> results) async {
    if (_box == null) return false;

    try {
      for (final result in results) {
        await saveResult(result);
      }
      return true;
    } catch (e) {
      LogManager.error('[QuestionResultRepository] Batch save error: $e');
      return false;
    }
  }

  /// Get all results
  List<QuestionResultModel> getAllResults() {
    if (_box == null) return [];

    try {
      return _box!.values
          .map((json) => QuestionResultModel.fromJson(json))
          .toList();
    } catch (e) {
      LogManager.error('[QuestionResultRepository] Get all error: $e');
      return [];
    }
  }

  /// Get results for a specific category
  List<QuestionResultModel> getResultsByCategory(String category) {
    if (_box == null) return [];

    try {
      return _box!.values
          .map((json) => QuestionResultModel.fromJson(json))
          .where((result) =>
              result.category.toLowerCase() == category.toLowerCase())
          .toList();
    } catch (e) {
      LogManager.error('[QuestionResultRepository] Get by category error: $e');
      return [];
    }
  }

  /// Get results from last N hours
  List<QuestionResultModel> getRecentResults({int hoursAgo = 24}) {
    if (_box == null) return [];

    try {
      final cutoffTime = DateTime.now().subtract(Duration(hours: hoursAgo));

      return _box!.values
          .map((json) => QuestionResultModel.fromJson(json))
          .where((result) => result.answeredAt.isAfter(cutoffTime))
          .toList();
    } catch (e) {
      LogManager.error('[QuestionResultRepository] Get recent error: $e');
      return [];
    }
  }

  /// Calculate statistics for all results
  QuestionAnalytics calculateAnalytics() {
    final results = getAllResults();
    if (results.isEmpty) {
      return QuestionAnalytics.empty();
    }

    final correctCount = results.where((r) => r.isCorrect).length;
    final totalXP = results.fold(0, (sum, r) => sum + r.xpEarned);
    final totalCoins = results.fold(0, (sum, r) => sum + r.coinsEarned);
    final avgTime = results.isEmpty
        ? 0
        : results.fold(0, (sum, r) => sum + r.timeTakenSeconds) ~/
            results.length;

    // Category breakdown
    final categoryStats = <String, CategoryStats>{};
    for (final result in results) {
      if (!categoryStats.containsKey(result.category)) {
        categoryStats[result.category] = CategoryStats(
          category: result.category,
          total: 0,
          correct: 0,
          totalXP: 0,
        );
      }

      final stats = categoryStats[result.category]!;
      categoryStats[result.category] = CategoryStats(
        category: stats.category,
        total: stats.total + 1,
        correct: stats.correct + (result.isCorrect ? 1 : 0),
        totalXP: stats.totalXP + result.xpEarned,
      );
    }

    return QuestionAnalytics(
      totalAnswered: results.length,
      correctAnswered: correctCount,
      accuracy: (correctCount / results.length * 100).toStringAsFixed(1),
      totalXPEarned: totalXP,
      totalCoinsEarned: totalCoins,
      averageTimeSeconds: avgTime,
      categoryStats: categoryStats.values.toList(),
      mostRecentResult: results.last,
      oldestResult: results.first,
    );
  }

  /// Calculate statistics for a specific category
  QuestionAnalytics calculateCategoryAnalytics(String category) {
    final results = getResultsByCategory(category);
    if (results.isEmpty) {
      return QuestionAnalytics.empty();
    }

    final correctCount = results.where((r) => r.isCorrect).length;
    final totalXP = results.fold(0, (sum, r) => sum + r.xpEarned);
    final totalCoins = results.fold(0, (sum, r) => sum + r.coinsEarned);
    final avgTime = results.isEmpty
        ? 0
        : results.fold(0, (sum, r) => sum + r.timeTakenSeconds) ~/
            results.length;

    return QuestionAnalytics(
      totalAnswered: results.length,
      correctAnswered: correctCount,
      accuracy: (correctCount / results.length * 100).toStringAsFixed(1),
      totalXPEarned: totalXP,
      totalCoinsEarned: totalCoins,
      averageTimeSeconds: avgTime,
      categoryStats: [
        CategoryStats(
          category: category,
          total: results.length,
          correct: correctCount,
          totalXP: totalXP,
        ),
      ],
      mostRecentResult: results.last,
      oldestResult: results.first,
    );
  }

  /// Cleanup old results, keeping only recent ones
  Future<void> _cleanupOldResults() async {
    if (_box == null) return;

    try {
      final allKeys = _box!.keys.toList();
      if (allKeys.length > _maxResults) {
        // Sort by timestamp (key format: timestamp_questionId)
        allKeys.sort();

        // Remove oldest entries, keeping _maxResults
        final keysToRemove =
            allKeys.take(allKeys.length - _maxResults).toList();
        await _box!.deleteAll(keysToRemove);

        LogManager.debug(
          '[QuestionResultRepository] Cleaned up ${keysToRemove.length} old results',
        );
      }
    } catch (e) {
      LogManager.error('[QuestionResultRepository] Cleanup error: $e');
    }
  }

  /// Clear all results (use with caution)
  Future<void> clearAllResults() async {
    if (_box == null) return;

    try {
      await _box!.clear();
      LogManager.debug('[QuestionResultRepository] All results cleared');
    } catch (e) {
      LogManager.error('[QuestionResultRepository] Clear error: $e');
    }
  }

  /// Close the box (call on app shutdown)
  Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
    }
  }
}

/// Analytics summary for questions
class QuestionAnalytics {
  final int totalAnswered;
  final int correctAnswered;
  final String accuracy; // Percentage as string
  final int totalXPEarned;
  final int totalCoinsEarned;
  final int averageTimeSeconds;
  final List<CategoryStats> categoryStats;
  final QuestionResultModel? mostRecentResult;
  final QuestionResultModel? oldestResult;

  QuestionAnalytics({
    required this.totalAnswered,
    required this.correctAnswered,
    required this.accuracy,
    required this.totalXPEarned,
    required this.totalCoinsEarned,
    required this.averageTimeSeconds,
    required this.categoryStats,
    this.mostRecentResult,
    this.oldestResult,
  });

  factory QuestionAnalytics.empty() {
    return QuestionAnalytics(
      totalAnswered: 0,
      correctAnswered: 0,
      accuracy: '0.0',
      totalXPEarned: 0,
      totalCoinsEarned: 0,
      averageTimeSeconds: 0,
      categoryStats: [],
      mostRecentResult: null,
      oldestResult: null,
    );
  }

  @override
  String toString() =>
      'QuestionAnalytics(total: $totalAnswered, correct: $correctAnswered, accuracy: $accuracy%)';
}

/// Statistics for a specific category
class CategoryStats {
  final String category;
  final int total;
  final int correct;
  final int totalXP;

  CategoryStats({
    required this.category,
    required this.total,
    required this.correct,
    required this.totalXP,
  });

  double get accuracy => total > 0 ? (correct / total * 100) : 0.0;

  @override
  String toString() =>
      'CategoryStats($category: $correct/$total, ${accuracy.toStringAsFixed(1)}%)';
}
