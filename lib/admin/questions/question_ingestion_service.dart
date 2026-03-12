import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/api_service.dart';
import '../../game/models/question_model.dart';
import '../../game/providers/riverpod_providers.dart';

class QuestionIngestionService {
  const QuestionIngestionService({required ApiService apiService}) : _apiService = apiService;

  final ApiService _apiService;

  Future<Map<String, dynamic>> validateBulkImport({
    required List<QuestionModel> questions,
    String? datasetName,
  }) async {
    final response = await _apiService.post(
      '/admin/questions/validate-bulk',
      body: {
        if (datasetName != null && datasetName.trim().isNotEmpty) 'datasetName': datasetName.trim(),
        'items': questions.map((q) => q.toJson()).toList(),
      },
    );

    return {
      'isValid': response['isValid'] ?? response['valid'] ?? true,
      'errors': response['errors'] ?? const <dynamic>[],
      'warnings': response['warnings'] ?? const <dynamic>[],
      'meta': response['meta'] ?? const <String, dynamic>{},
      ...response,
    };
  }

  Future<Map<String, dynamic>> importBulkQuestions({
    required List<QuestionModel> questions,
    required String datasetName,
    bool publishAfterImport = false,
  }) async {
    return _apiService.post(
      '/admin/questions/import-bulk',
      body: {
        'datasetName': datasetName.trim(),
        'publishAfterImport': publishAfterImport,
        'items': questions.map((q) => q.toJson()).toList(),
      },
    );
  }

  Future<List<Map<String, dynamic>>> getDatasetStatuses() async {
    final response = await _apiService.get('/admin/questions/datasets');

    final rawItems = response['items'] ?? response['datasets'] ?? response['data'];
    if (rawItems is! List) {
      return const <Map<String, dynamic>>[];
    }

    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }

  Future<Map<String, dynamic>> publishDataset(String datasetName) {
    final encodedName = Uri.encodeComponent(datasetName.trim());
    return _apiService.post(
      '/admin/questions/datasets/$encodedName/publish',
      body: const {},
    );
  }

  Future<Map<String, dynamic>> unpublishDataset(String datasetName) {
    final encodedName = Uri.encodeComponent(datasetName.trim());
    return _apiService.post(
      '/admin/questions/datasets/$encodedName/unpublish',
      body: const {},
    );
  }
}

final questionIngestionServiceProvider = Provider<QuestionIngestionService>((ref) {
  final serviceManager = ref.watch(serviceManagerProvider);
  return QuestionIngestionService(apiService: serviceManager.apiService);
});
