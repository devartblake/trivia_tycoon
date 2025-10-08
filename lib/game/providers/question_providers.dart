import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/question_loader_service.dart';
import '../services/quiz_category.dart';

// Provider for the question loader service with QuizCategory support
final questionStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final loader = AdaptedQuestionLoaderService();
  return await loader.getAllDatasetStats();
});

// Provider for available QuizCategories
final quizCategoriesProvider = FutureProvider<List<QuizCategory>>((ref) async {
  final loader = AdaptedQuestionLoaderService();
  return await loader.getAvailableQuizCategories();
});

// Provider for dataset info with QuizCategory integration
final datasetInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final loader = AdaptedQuestionLoaderService();
  return loader.getDatasetInfo();
});

// Provider for category stats
final categoryStatsProvider = FutureProvider.family<Map<String, dynamic>, QuizCategory>((ref, category) async {
  final loader = AdaptedQuestionLoaderService();
  final questionCount = await loader.getQuizCategoryQuestionCount(category);
  final difficulty = await loader.getQuizCategoryDifficulty(category);

  return {
    'questionCount': questionCount,
    'difficulty': difficulty,
    'category': category,
  };
});
