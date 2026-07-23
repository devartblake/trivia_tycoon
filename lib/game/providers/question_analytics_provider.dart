import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/question_result_repository.dart';
import '../services/question_analytics_service.dart';
import '../models/question_result_model.dart';

/// Provides the question result repository
final questionResultRepositoryProvider = Provider((ref) {
  return QuestionResultRepository();
});

/// Provides the question analytics service
final questionAnalyticsServiceProvider = Provider((ref) {
  final repository = ref.watch(questionResultRepositoryProvider);
  return QuestionAnalyticsService(repository: repository);
});

/// Provides overall performance summary
final performanceSummaryProvider = Provider((ref) {
  final analyticsService = ref.watch(questionAnalyticsServiceProvider);
  return analyticsService.getPerformanceSummary();
});

/// Provides category-specific performance (requires category parameter)
final categoryPerformanceProvider =
    FutureProvider.family<dynamic, String>((ref, category) async {
  final analyticsService = ref.watch(questionAnalyticsServiceProvider);
  return analyticsService.getCategoryPerformance(category);
});

/// Provides all categories with their performance data
final allCategoriesPerformanceProvider =
    Provider<List<CategoryPerformance>>((ref) {
  final analyticsService = ref.watch(questionAnalyticsServiceProvider);
  // We'll use a representative list of categories to scan
  const categoriesToScan = [
    'Science',
    'History',
    'Geography',
    'Mathematics',
    'Arts',
    'Literature',
    'Sports',
    'Entertainment'
  ];

  return categoriesToScan
      .map((c) => analyticsService.getCategoryPerformance(c))
      .where((p) => p.totalQuestions > 0)
      .toList();
});

/// Provides trending performance for last 24 hours
final trendingPerformanceProvider = Provider((ref) {
  final analyticsService = ref.watch(questionAnalyticsServiceProvider);
  return analyticsService.getTrendingSummary(hoursAgo: 24);
});

/// Provides weak categories that need improvement
final weakCategoriesProvider = Provider((ref) {
  final analyticsService = ref.watch(questionAnalyticsServiceProvider);
  return analyticsService.getWeakCategories(limit: 5);
});

/// Provides strong categories for confidence building
final strongCategoriesProvider = Provider((ref) {
  final analyticsService = ref.watch(questionAnalyticsServiceProvider);
  return analyticsService.getStrongCategories(limit: 5);
});

/// Notifier for recording new question results
class ResultRecorderNotifier extends StateNotifier<bool> {
  final QuestionAnalyticsService analyticsService;

  ResultRecorderNotifier(this.analyticsService) : super(false);

  Future<void> recordResult(QuestionResultModel result) async {
    state = true;
    try {
      await analyticsService.recordResult(result);
    } finally {
      state = false;
    }
  }
}

/// Provides the result recorder for recording new results
final resultRecorderProvider =
    StateNotifierProvider<ResultRecorderNotifier, bool>((ref) {
  final analyticsService = ref.watch(questionAnalyticsServiceProvider);
  return ResultRecorderNotifier(analyticsService);
});
