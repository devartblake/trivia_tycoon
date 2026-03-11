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
  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
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
  test('validateBulkImport posts payload and returns normalized validation object', () async {
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

    await service.publishDataset('phase3_pack');
    expect(api.lastPath, '/admin/questions/datasets/phase3_pack/publish');

    await service.unpublishDataset('phase3_pack');
    expect(api.lastPath, '/admin/questions/datasets/phase3_pack/unpublish');
  });
}
