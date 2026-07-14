import '../models/question_result_model.dart';
import '../repositories/question_result_repository.dart';
import 'package:synaptix/core/manager/log_manager.dart';

/// Service for question analytics and reporting
class QuestionAnalyticsService {
  final QuestionResultRepository repository;

  QuestionAnalyticsService({required this.repository});

  /// Record a question result
  Future<bool> recordResult(QuestionResultModel result) async {
    try {
      final saved = await repository.saveResult(result);
      if (saved) {
        LogManager.debug(
          '[QuestionAnalyticsService] Recorded: ${result.category} - '
          '${result.isCorrect ? "✓" : "✗"} (${result.xpEarned} XP)',
        );
      }
      return saved;
    } catch (e) {
      LogManager.error('[QuestionAnalyticsService] Record error: $e');
      return false;
    }
  }

  /// Get performance summary
  PerformanceSummary getPerformanceSummary() {
    final analytics = repository.calculateAnalytics();

    return PerformanceSummary(
      totalQuestions: analytics.totalAnswered,
      correctQuestions: analytics.correctAnswered,
      accuracy: double.parse(analytics.accuracy),
      totalXP: analytics.totalXPEarned,
      totalCoins: analytics.totalCoinsEarned,
      averageTimeSeconds: analytics.averageTimeSeconds,
      lastUpdated: DateTime.now(),
    );
  }

  /// Get category performance
  CategoryPerformance getCategoryPerformance(String category) {
    final analytics = repository.calculateCategoryAnalytics(category);

    if (analytics.categoryStats.isEmpty) {
      return CategoryPerformance(
        category: category,
        totalQuestions: 0,
        correctQuestions: 0,
        accuracy: 0.0,
        totalXP: 0,
      );
    }

    final stats = analytics.categoryStats.first;
    return CategoryPerformance(
      category: category,
      totalQuestions: stats.total,
      correctQuestions: stats.correct,
      accuracy: stats.accuracy,
      totalXP: stats.totalXP,
    );
  }

  /// Get trending performance (last N hours)
  TrendingSummary getTrendingSummary({int hoursAgo = 24}) {
    final recentResults = repository.getRecentResults(hoursAgo: hoursAgo);

    if (recentResults.isEmpty) {
      return TrendingSummary(
        period: '${hoursAgo}h',
        questionsAnswered: 0,
        correctAnswered: 0,
        trending: 'neutral',
      );
    }

    final correctCount = recentResults.where((r) => r.isCorrect).length;
    final accuracy = correctCount / recentResults.length;

    // Determine trend
    String trending = 'neutral';
    if (accuracy > 0.8) {
      trending = 'up'; // Excellent performance
    } else if (accuracy < 0.5) {
      trending = 'down'; // Needs improvement
    }

    return TrendingSummary(
      period: '${hoursAgo}h',
      questionsAnswered: recentResults.length,
      correctAnswered: correctCount,
      trending: trending,
      accuracyPercent: (accuracy * 100).toStringAsFixed(1),
    );
  }

  /// Get weakest categories
  List<WeakCategory> getWeakCategories({int limit = 5}) {
    final allResults = repository.getAllResults();
    if (allResults.isEmpty) return [];

    final categoryMap = <String, (int, int)>{};

    for (final result in allResults) {
      if (!categoryMap.containsKey(result.category)) {
        categoryMap[result.category] = (0, 0);
      }

      final (total, correct) = categoryMap[result.category]!;
      categoryMap[result.category] = (
        total + 1,
        correct + (result.isCorrect ? 1 : 0),
      );
    }

    return categoryMap.entries
        .map((entry) {
          final (total, correct) = entry.value;
          return WeakCategory(
            category: entry.key,
            accuracy: (correct / total * 100).toStringAsFixed(1),
            questionCount: total,
          );
        })
        .where((cat) => double.parse(cat.accuracy) < 75.0)
        .toList()
      ..sort((a, b) =>
          double.parse(a.accuracy).compareTo(double.parse(b.accuracy)))
      ..take(limit);
  }

  /// Get strongest categories
  List<StrongCategory> getStrongCategories({int limit = 5}) {
    final allResults = repository.getAllResults();
    if (allResults.isEmpty) return [];

    final categoryMap = <String, (int, int, int)>{};

    for (final result in allResults) {
      if (!categoryMap.containsKey(result.category)) {
        categoryMap[result.category] = (0, 0, 0);
      }

      final (total, correct, xp) = categoryMap[result.category]!;
      categoryMap[result.category] = (
        total + 1,
        correct + (result.isCorrect ? 1 : 0),
        xp + result.xpEarned,
      );
    }

    return categoryMap.entries
        .map((entry) {
          final (total, correct, xp) = entry.value;
          return StrongCategory(
            category: entry.key,
            accuracy: (correct / total * 100).toStringAsFixed(1),
            questionCount: total,
            totalXP: xp,
          );
        })
        .where((cat) => double.parse(cat.accuracy) >= 75.0)
        .toList()
      ..sort((a, b) =>
          double.parse(b.accuracy).compareTo(double.parse(a.accuracy)))
      ..take(limit);
  }
}

/// Overall performance summary
class PerformanceSummary {
  final int totalQuestions;
  final int correctQuestions;
  final double accuracy;
  final int totalXP;
  final int totalCoins;
  final int averageTimeSeconds;
  final DateTime lastUpdated;

  PerformanceSummary({
    required this.totalQuestions,
    required this.correctQuestions,
    required this.accuracy,
    required this.totalXP,
    required this.totalCoins,
    required this.averageTimeSeconds,
    required this.lastUpdated,
  });

  int get incorrectQuestions => totalQuestions - correctQuestions;

  @override
  String toString() =>
      'PerformanceSummary(total: $totalQuestions, correct: $correctQuestions, accuracy: $accuracy%)';
}

/// Category-specific performance
class CategoryPerformance {
  final String category;
  final int totalQuestions;
  final int correctQuestions;
  final double accuracy;
  final int totalXP;

  CategoryPerformance({
    required this.category,
    required this.totalQuestions,
    required this.correctQuestions,
    required this.accuracy,
    required this.totalXP,
  });

  int get incorrectQuestions => totalQuestions - correctQuestions;

  @override
  String toString() =>
      'CategoryPerformance($category: $correctQuestions/$totalQuestions, ${accuracy.toStringAsFixed(1)}%)';
}

/// Trending performance over time period
class TrendingSummary {
  final String period;
  final int questionsAnswered;
  final int correctAnswered;
  final String? accuracyPercent;
  final String trending; // 'up', 'down', 'neutral'

  TrendingSummary({
    required this.period,
    required this.questionsAnswered,
    required this.correctAnswered,
    this.accuracyPercent,
    this.trending = 'neutral',
  });

  @override
  String toString() =>
      'TrendingSummary($period: $correctAnswered/$questionsAnswered, trending: $trending)';
}

/// Category with weak performance
class WeakCategory {
  final String category;
  final String accuracy;
  final int questionCount;

  WeakCategory({
    required this.category,
    required this.accuracy,
    required this.questionCount,
  });

  @override
  String toString() => '$category: $accuracy% ($questionCount Q)';
}

/// Category with strong performance
class StrongCategory {
  final String category;
  final String accuracy;
  final int questionCount;
  final int totalXP;

  StrongCategory({
    required this.category,
    required this.accuracy,
    required this.questionCount,
    required this.totalXP,
  });

  @override
  String toString() => '$category: $accuracy% ($questionCount Q, $totalXP XP)';
}
