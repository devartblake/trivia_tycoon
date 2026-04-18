import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/question_repository.dart';
import '../repositories/question_repository_impl.dart';
import '../services/question_hub_service.dart';
import 'question_provider_contracts.dart';
import '../services/quiz_category.dart';
import 'core_providers.dart';

class QuestionSourceStatusNotifier extends StateNotifier<QuestionSourceSnapshot>
    implements QuestionSourceReporter {
  QuestionSourceStatusNotifier() : super(QuestionSourceSnapshot.unknown());

  @override
  void recordBackend({
    required String operation,
    required String endpoint,
    String? detail,
  }) {
    state = QuestionSourceSnapshot(
      source: QuestionDataSource.backend,
      operation: operation,
      endpoint: endpoint,
      detail: detail,
      updatedAt: DateTime.now(),
    );
  }

  @override
  void recordFallback({
    required String operation,
    String? endpoint,
    String? detail,
  }) {
    state = QuestionSourceSnapshot(
      source: QuestionDataSource.localFallback,
      operation: operation,
      endpoint: endpoint,
      detail: detail,
      updatedAt: DateTime.now(),
    );
  }
}

final questionSourceStatusProvider =
    StateNotifierProvider<QuestionSourceStatusNotifier, QuestionSourceSnapshot>(
  (ref) => QuestionSourceStatusNotifier(),
);

final questionHubServiceProvider = Provider<QuestionHubService>((ref) {
  final serviceManager = ref.watch(serviceManagerProvider);
  final reporter = ref.read(questionSourceStatusProvider.notifier);
  return QuestionHubService(
    apiService: serviceManager.apiService,
    reporter: reporter,
  );
});


final questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  final hubService = ref.watch(questionHubServiceProvider);

  return QuestionRepositoryImpl(
    questionHubService: hubService,
  );
});

// Provider for the question loader service with QuizCategory support
final questionStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(questionRepositoryProvider);
  final raw = await repository.getQuestionStats();
  return normalizeQuestionStats(raw);
});

// Provider for available QuizCategories
final quizCategoriesProvider = FutureProvider<List<QuizCategory>>((ref) async {
  final repository = ref.watch(questionRepositoryProvider);
  return repository.getAvailableCategories();
});

// Provider for dataset info with QuizCategory integration
final datasetInfoProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(questionRepositoryProvider);
  final raw = await repository.getDatasetInfo();
  return normalizeDatasetInfo(raw);
});

// Provider for category stats
final categoryStatsProvider = FutureProvider.family<Map<String, dynamic>, QuizCategory>((ref, category) async {
  final repository = ref.watch(questionRepositoryProvider);
  final raw = await repository.getCategoryStats(category);
  return normalizeCategoryStats(raw, category);
});

const _defaultClassIds = [
  'kindergarten', '1', '2', '3', '4', '5', '6', '7', '8', '9', '10', '11', '12',
];

final classStatsProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, classId) async {
  final repository = ref.watch(questionRepositoryProvider);
  final raw = await repository.getClassStats(classId);
  return normalizeClassStats(raw);
});

final allClassesStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final repository = ref.watch(questionRepositoryProvider);
  final stats = <String, Map<String, dynamic>>{};

  for (final classId in _defaultClassIds) {
    final raw = await repository.getClassStats(classId);
    stats[classId] = normalizeClassStats(raw);
  }

  return {'classStats': stats};
});

final serviceStatusProvider = Provider<Map<String, dynamic>>((ref) {
  final sourceSnapshot = ref.watch(questionSourceStatusProvider);

  return {
    'isHealthy': sourceSnapshot.source != QuestionDataSource.localFallback,
    'source': sourceSnapshot.source.name,
    'operation': sourceSnapshot.operation,
    'endpoint': sourceSnapshot.endpoint,
    'detail': sourceSnapshot.detail,
    'updatedAt': sourceSnapshot.updatedAt.toIso8601String(),
  };
});
