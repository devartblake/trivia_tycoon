import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/admin/questions/question_ingestion_service.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';

class _FakeApiService extends ApiService {
  _FakeApiService()
      : super(
          baseUrl: 'http://localhost',
          initializeCache: false,
        );

  String? lastPath;
  Map<String, dynamic>? lastBody;
  Map<String, dynamic> nextResponse = const {};

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    lastPath = path;
    return nextResponse;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    lastPath = path;
    lastBody = body;
    return nextResponse;
  }
}

QuestionModel _sampleQuestion() {
  return QuestionModel.fromJson({
    'id': 'q1',
    'category': 'science',
    'question': 'What is H2O?',
    'answers': const [
      {'text': 'Water', 'isCorrect': true},
      {'text': 'Oxygen', 'isCorrect': false},
    ],
    'correctAnswer': 'Water',
    'type': 'multiple_choice',
    'difficulty': 1,
  });
}

void main() {
  test(
      'validateBulkImport posts payload and returns normalized validation object',
      () async {
    final api = _FakeApiService()
      ..nextResponse = {
        'valid': true,
        'errors': [],
      };
    final service = QuestionIngestionService(apiService: api);

    final result = await service.validateBulkImport(
      questions: [_sampleQuestion()],
      datasetName: 'phase3_pack',
    );

    expect(api.lastPath, '/admin/questions/validate-bulk');
    expect(api.lastBody?['datasetName'], 'phase3_pack');
    expect((api.lastBody?['items'] as List).length, 1);
    expect(result['isValid'], true);
  });

  test('importBulkQuestions sends dataset and publish flag', () async {
    final api = _FakeApiService();
    final service = QuestionIngestionService(apiService: api);

    await service.importBulkQuestions(
      questions: [_sampleQuestion()],
      datasetName: 'phase3_pack',
      publishAfterImport: true,
    );

    expect(api.lastPath, '/admin/questions/import-bulk');
    expect(api.lastBody?['datasetName'], 'phase3_pack');
    expect(api.lastBody?['publishAfterImport'], true);
  });

  test('publish/unpublish use dataset-specific endpoints', () async {
    final api = _FakeApiService();
    final service = QuestionIngestionService(apiService: api);

    await service.publishDataset('phase3 pack/v1');
    expect(
        api.lastPath, '/admin/questions/datasets/phase3%20pack%2Fv1/publish');

    await service.unpublishDataset('phase3 pack/v1');
    expect(
        api.lastPath, '/admin/questions/datasets/phase3%20pack%2Fv1/unpublish');
  });

  test('getDatasetStatuses maps dataset list response', () async {
    final api = _FakeApiService()
      ..nextResponse = {
        'items': [
          {'name': 'pack_1', 'published': true, 'questionCount': 12},
        ],
      };
    final service = QuestionIngestionService(apiService: api);

    final datasets = await service.getDatasetStatuses();

    expect(api.lastPath, '/admin/questions/datasets');
    expect(datasets.length, 1);
    expect(datasets.first['name'], 'pack_1');
  });
}
