import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/question_repository.dart';
import '../repositories/question_repository_impl.dart';
import '../services/question_hub_service.dart';
import '../services/quiz_category.dart';
import 'riverpod_providers.dart';

final questionHubServiceProvider = Provider<QuestionHubService>((ref) {
  final serviceManager = ref.watch(serviceManagerProvider);
  return QuestionHubService(
    apiService: serviceManager.apiService,
  );
});

final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  final serviceManager = ref.watch(serviceManagerProvider);
  final hubService = ref.watch(questionHubServiceProvider);

  return QuestionRepositoryImpl(
    questionService: serviceManager.questionService,
    questionHubService: hubService,
  );
});

// Provider for the question loader service with QuizCategory support
final questionStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.getQuestionStats();
});

// Provider for available QuizCategories
final quizCategoriesProvider = FutureProvider<List<QuizCategory>>((ref) async {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.getAvailableCategories();
});

// Provider for dataset info with QuizCategory integration
final datasetInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.getDatasetInfo();
});

// Provider for category stats
final categoryStatsProvider = FutureProvider.family<Map<String, dynamic>, QuizCategory>((ref, category) async {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.getCategoryStats(category);
});
