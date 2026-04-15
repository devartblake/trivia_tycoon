import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/question_validation_models.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import 'package:trivia_tycoon/game/services/question_hub_service.dart';
import 'package:trivia_tycoon/game/services/question_loader_service.dart';
import 'package:trivia_tycoon/game/services/quiz_category.dart';

class _FakeApiService extends ApiService {
  _FakeApiService()
      : super(
          baseUrl: 'http://localhost',
          initializeCache: false,
        );

  List<Map<String, dynamic>> fetchQuestionsResult = const [];
  Object? fetchQuestionsError;
  final Map<String, Map<String, dynamic>> getResponses = {};
  final Map<String, Map<String, dynamic>> postResponses = {};
  Object? postError;

  @override
  Future<List<Map<String, dynamic>>> fetchQuestions({
    required int amount,
    String? category,
    String? difficulty,
  }) async {
    if (fetchQuestionsError != null) {
      throw fetchQuestionsError!;
    }
    return fetchQuestionsResult;
  }

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    return getResponses[path] ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    if (postError != null) {
      throw postError!;
    }
    return postResponses[path] ?? <String, dynamic>{};
  }
}

class _FakeLoaderService extends AdaptedQuestionLoaderService {
  List<QuestionModel> categoryQuestions = const [];
  List<QuestionModel> mixedQuizQuestions = const [];
  List<QuestionModel> dailyQuizQuestions = const [];
  int classQuestionCount = 0;
  int classSubjectCount = 0;

  @override
  Future<List<QuestionModel>> getQuestionsByCategory(String category) async {
    return categoryQuestions;
  }

  @override
  Future<List<QuestionModel>> getMixedQuizByCategories({
    int questionCount = 10,
    List<QuizCategory>? categories,
    List<dynamic>? difficulties,
    List<String>? types,
    List<String>? tags,
    List<String>? datasets,
    bool includeImages = true,
    bool includeVideos = true,
    bool includeAudio = true,
    bool balanceDifficulties = false,
    bool balanceCategories = false,
  }) async {
    return mixedQuizQuestions;
  }

  @override
  Future<List<QuestionModel>> getDailyQuiz({int questionCount = 5}) async {
    return dailyQuizQuestions;
  }

  @override
  Future<int> getQuizCategoryQuestionCount(QuizCategory category) async => categoryQuestions.length;

  @override
  Future<String> getQuizCategoryDifficulty(QuizCategory category) async => 'mixed';

  @override
  Future<int> getClassQuestionCount(String classId) async => classQuestionCount;

  @override
  Future<int> getClassSubjectCount(String classId) async => classSubjectCount;
}

Map<String, dynamic> _questionJson({required String id, required int difficulty}) {
  return {
    'id': id,
    'category': 'science',
    'question': 'Q$id',
    'type': 'multiple_choice',
    'difficulty': difficulty,
    'correctAnswer': 'A',
    'answers': const [
      {'text': 'A', 'isCorrect': true},
      {'text': 'B', 'isCorrect': false},
    ],
  };
}

void main() {
  test('getQuestionsForCategory returns backend questions when available', () async {
    final api = _FakeApiService()
      ..getResponses['/questions/set'] = {
        'items': [_questionJson(id: '1', difficulty: 1)],
      };
    final loader = _FakeLoaderService()
      ..categoryQuestions = [QuestionModel.fromJson(_questionJson(id: 'fallback', difficulty: 2))];

    final service = QuestionHubService(apiService: api, localLoader: loader);
    final result = await service.getQuestionsForCategory(category: 'science', amount: 1);

    expect(result.length, 1);
    expect(result.first.id, '1');
  });

  test('getQuestionsForCategory falls back to local and respects amount+difficulty', () async {
    final api = _FakeApiService()
      ..fetchQuestionsError = ApiRequestException('offline', path: '/quiz/play');
    final loader = _FakeLoaderService()
      ..categoryQuestions = [
        QuestionModel.fromJson(_questionJson(id: '1', difficulty: 1)),
        QuestionModel.fromJson(_questionJson(id: '2', difficulty: 2)),
        QuestionModel.fromJson(_questionJson(id: '3', difficulty: 2)),
      ];

    final service = QuestionHubService(apiService: api, localLoader: loader);
    final result = await service.getQuestionsForCategory(
      category: 'science',
      amount: 1,
      difficulty: 2,
    );

    expect(result.length, 1);
    expect(result.first.id, '2');
    expect(result.first.difficulty, 2);
  });

  test('getDailyQuiz falls back to local when backend contract is invalid', () async {
    final api = _FakeApiService()
      ..getResponses['/quiz/daily'] = {
        'items': [_questionJson(id: 'bad', difficulty: 1)],
      };
    final loader = _FakeLoaderService()
      ..dailyQuizQuestions = [QuestionModel.fromJson(_questionJson(id: 'fallback-daily', difficulty: 1))];

    final service = QuestionHubService(apiService: api, localLoader: loader);
    final result = await service.getDailyQuiz(questionCount: 1);

    expect(result.length, 1);
    expect(result.first.id, 'fallback-daily');
  });

  test('getMixedQuiz falls back to local when backend returns invalid envelope', () async {
    final api = _FakeApiService()
      ..getResponses['/quiz/mixed'] = {
        'questions': [_questionJson(id: 'bad-mixed', difficulty: 2)],
      };
    final loader = _FakeLoaderService()
      ..mixedQuizQuestions = [QuestionModel.fromJson(_questionJson(id: 'fallback-mixed', difficulty: 2))];

    final service = QuestionHubService(apiService: api, localLoader: loader);
    final result = await service.getMixedQuiz(questionCount: 1, categories: const ['science']);

    expect(result.length, 1);
    expect(result.first.id, 'fallback-mixed');
  });

  test('getClassStats falls back to local when backend class payload is invalid', () async {
    final api = _FakeApiService()
      ..getResponses['/quiz/classes/7/stats'] = {'questionCount': 10};
    final loader = _FakeLoaderService()
      ..classQuestionCount = 44
      ..classSubjectCount = 5;

    final service = QuestionHubService(apiService: api, localLoader: loader);
    final stats = await service.getClassStats('7');

    expect(stats['source'], 'local_fallback');
    expect(stats['questionCount'], 44);
    expect(stats['subjectCount'], 5);
  });

  test('getCategoryStats falls back when contract is invalid', () async {
    final api = _FakeApiService()
      ..getResponses['/quiz/categories/science/stats'] = {'unexpected': true};
    final loader = _FakeLoaderService()
      ..categoryQuestions = [
        QuestionModel.fromJson(_questionJson(id: '1', difficulty: 1)),
      ];

    final service = QuestionHubService(apiService: api, localLoader: loader);
    final stats = await service.getCategoryStats(QuizCategory.science);

    expect(stats['source'], 'local_fallback');
    expect(stats['questionCount'], 1);
    expect(stats['category'], 'science');
  });

  test('checkAnswer returns backend validation result when available', () async {
    final api = _FakeApiService()
      ..postResponses['/questions/check'] = {
        'questionId': '1',
        'isCorrect': true,
        'correctAnswer': 'A',
        'source': 'deployed-model',
      };
    final loader = _FakeLoaderService();
    final service = QuestionHubService(apiService: api, localLoader: loader);
    final question = QuestionModel.fromJson(_questionJson(id: '1', difficulty: 1));

    final result = await service.checkAnswer(
      question: question,
      selectedAnswer: 'A',
    );

    expect(result.isCorrect, isTrue);
    expect(result.correctAnswer, 'A');
    expect(result.source, 'deployed-model');
  });

  test('checkAnswer falls back to local validation when backend fails', () async {
    final api = _FakeApiService()
      ..postError = ApiRequestException('offline', path: '/questions/check');
    final service = QuestionHubService(
      apiService: api,
      localLoader: _FakeLoaderService(),
    );
    final question = QuestionModel.fromJson(_questionJson(id: '1', difficulty: 1));

    final result = await service.checkAnswer(
      question: question,
      selectedAnswer: 'B',
    );

    expect(result.isCorrect, isFalse);
    expect(result.source, 'local_fallback');
  });

  test('checkAnswerBatch falls back to local validation when payload is invalid', () async {
    final api = _FakeApiService()
      ..postResponses['/questions/check-batch'] = {
        'items': [
          {'unexpected': true},
        ],
      };
    final service = QuestionHubService(
      apiService: api,
      localLoader: _FakeLoaderService(),
    );
    final question = QuestionModel.fromJson(_questionJson(id: '1', difficulty: 1));

    final result = await service.checkAnswerBatch(
      submissions: [
        QuestionAnswerSubmission(question: question, selectedAnswer: 'A'),
      ],
    );

    expect(result, hasLength(1));
    expect(result.first.isCorrect, isTrue);
    expect(result.first.source, 'local_fallback');
  });
}
