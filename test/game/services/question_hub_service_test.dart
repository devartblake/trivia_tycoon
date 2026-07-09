import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/question_validation_models.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/game/models/question_difficulty.dart';
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
  String? lastGetPath;
  Map<String, dynamic>? lastGetQueryParameters;
  String? lastPostPath;
  Map<String, dynamic>? lastPostBody;
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
    lastGetPath = path;
    lastGetQueryParameters = queryParameters;
    return getResponses[path] ?? <String, dynamic>{};
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    required Map<String, dynamic> body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
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
  Future<int> getQuizCategoryQuestionCount(QuizCategory category) async =>
      categoryQuestions.length;

  @override
  Future<String> getQuizCategoryDifficulty(QuizCategory category) async =>
      'mixed';

  @override
  Future<int> getClassQuestionCount(String classId) async => classQuestionCount;

  @override
  Future<int> getClassSubjectCount(String classId) async => classSubjectCount;
}

Map<String, dynamic> _questionJson(
    {required String id, required int difficulty}) {
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
  setUp(() {
    // The gate is shared across service instances; keep tests isolated.
    QuestionHubService.backendGate.recordSuccess();
  });

  test('parses backend GameplayQuestionDto without embedded correctness',
      () async {
    final api = _FakeApiService()
      ..postResponses['/questions/mixed'] = {
        'questions': [
          {
            'id': 'backend-1',
            'text': 'Which option is safe?',
            'category': 'Science',
            'difficulty': 'Expert',
            'mediaKey': 'media/questions/backend-1.png',
            'options': const [
              {'optionId': 'a', 'text': 'Alpha'},
              {'optionId': 'b', 'text': 'Beta'},
            ],
          }
        ],
      };

    final service = QuestionHubService(
      apiService: api,
      localLoader: _FakeLoaderService(),
    );
    final result = await service.getMixedQuiz(questionCount: 1);

    expect(result, hasLength(1));
    expect(result.first.id, 'backend-1');
    expect(result.first.question, 'Which option is safe?');
    expect(result.first.options, ['Alpha', 'Beta']);
    expect(
      result.first.answers.map((answer) => answer.isCorrect),
      [false, false],
    );
    expect(result.first.correctAnswer, isEmpty);
    expect(result.first.difficulty, QuestionDifficulty.expert);
    expect(result.first.imageUrl, 'media/questions/backend-1.png');
    expect(result.first.optionIdForAnswer('Beta'), 'b');
  });

  test('category questions send /questions/set gameplay query parameters',
      () async {
    final api = _FakeApiService()
      ..getResponses['/questions/set'] = {
        'items': [_questionJson(id: '1', difficulty: 1)],
      };

    final service = QuestionHubService(
      apiService: api,
      localLoader: _FakeLoaderService(),
    );

    await service.getQuestionsForCategory(
      category: 'Science',
      amount: 5,
      difficulty: 1,
      mode: 'practice',
      playerId: 'adaptive-player',
    );

    expect(api.lastGetPath, '/questions/set');
    expect(api.lastGetQueryParameters, {
      'category': 'Science',
      'count': 5,
      'mode': 'practice',
      'difficulty': 'Easy',
      'playerId': 'adaptive-player',
    });
  });

  test('mixed quiz posts MixedQuestionSetRequest to /questions/mixed',
      () async {
    final api = _FakeApiService()
      ..postResponses['/questions/mixed'] = {
        'items': [_questionJson(id: 'ranked', difficulty: 2)],
      };

    final service = QuestionHubService(
      apiService: api,
      localLoader: _FakeLoaderService(),
    );

    await service.getMixedQuiz(
      questionCount: 8,
      categories: const ['science', 'history'],
      difficulties: const ['medium'],
      balanceDifficulties: true,
      mode: 'ranked',
      playerId: null,
    );

    expect(api.lastPostPath, '/questions/mixed');
    expect(api.lastPostBody, {
      'count': 8,
      'categories': ['science', 'history'],
      'difficulties': ['Medium'],
      'balanceCategories': true,
      'balanceDifficulties': true,
    });
  });

  test('getQuestionsForCategory returns backend questions when available',
      () async {
    final api = _FakeApiService()
      ..getResponses['/questions/set'] = {
        'items': [_questionJson(id: '1', difficulty: 1)],
      };
    final loader = _FakeLoaderService()
      ..categoryQuestions = [
        QuestionModel.fromJson(_questionJson(id: 'fallback', difficulty: 2))
      ];

    final service = QuestionHubService(apiService: api, localLoader: loader);
    final result =
        await service.getQuestionsForCategory(category: 'science', amount: 1);

    expect(result.length, 1);
    expect(result.first.id, '1');
  });

  test(
      'getQuestionsForCategory falls back to local and respects amount+difficulty',
      () async {
    final api = _FakeApiService()
      ..fetchQuestionsError =
          ApiRequestException('offline', path: '/quiz/play');
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
    expect(result.first.difficulty, QuestionDifficulty.medium);
  });

  test('getDailyQuiz falls back to local when backend contract is invalid',
      () async {
    final api = _FakeApiService()
      ..getResponses['/quiz/daily'] = {
        'items': [_questionJson(id: 'bad', difficulty: 1)],
      };
    final loader = _FakeLoaderService()
      ..dailyQuizQuestions = [
        QuestionModel.fromJson(
            _questionJson(id: 'fallback-daily', difficulty: 1))
      ];

    final service = QuestionHubService(apiService: api, localLoader: loader);
    final result = await service.getDailyQuiz(questionCount: 1);

    expect(result.length, 1);
    expect(result.first.id, 'fallback-daily');
  });

  test('getMixedQuiz falls back to local when backend returns invalid envelope',
      () async {
    final api = _FakeApiService()
      ..getResponses['/quiz/mixed'] = {
        'questions': [_questionJson(id: 'bad-mixed', difficulty: 2)],
      };
    final loader = _FakeLoaderService()
      ..mixedQuizQuestions = [
        QuestionModel.fromJson(
            _questionJson(id: 'fallback-mixed', difficulty: 2))
      ];

    final service = QuestionHubService(apiService: api, localLoader: loader);
    final result = await service
        .getMixedQuiz(questionCount: 1, categories: const ['science']);

    expect(result.length, 1);
    expect(result.first.id, 'fallback-mixed');
  });

  test('getClassStats serves local stats (backend has no stats endpoints)',
      () async {
    final api = _FakeApiService();
    final loader = _FakeLoaderService()
      ..classQuestionCount = 44
      ..classSubjectCount = 5;

    final service = QuestionHubService(apiService: api, localLoader: loader);
    final stats = await service.getClassStats('7');

    // Stats endpoints are flag-gated off; local data is canonical and the
    // API must not be called at all.
    expect(api.lastGetPath, isNull);
    expect(stats['source'], 'local');
    expect(stats['questionCount'], 44);
    expect(stats['subjectCount'], 5);
  });

  test('getCategoryStats serves local stats (backend has no stats endpoints)',
      () async {
    final api = _FakeApiService();
    final loader = _FakeLoaderService()
      ..categoryQuestions = [
        QuestionModel.fromJson(_questionJson(id: '1', difficulty: 1)),
      ];

    final service = QuestionHubService(apiService: api, localLoader: loader);
    final stats = await service.getCategoryStats(QuizCategory.science);

    expect(api.lastGetPath, isNull);
    expect(stats['source'], 'local');
    expect(stats['questionCount'], 1);
    expect(stats['category'], 'science');
  });

  test('checkAnswer returns backend validation result when available',
      () async {
    final api = _FakeApiService()
      ..postResponses['/questions/check'] = {
        'questionId': '1',
        'isCorrect': true,
        'correctOptionId': 'A',
        'source': 'deployed-model',
      };
    final loader = _FakeLoaderService();
    final service = QuestionHubService(apiService: api, localLoader: loader);
    final question =
        QuestionModel.fromJson(_questionJson(id: '1', difficulty: 1));

    final result = await service.checkAnswer(
      question: question,
      selectedAnswer: 'A',
    );

    expect(result.isCorrect, isTrue);
    expect(result.correctAnswer, 'A');
    expect(result.source, 'deployed-model');
    expect(api.lastPostPath, '/questions/check');
    expect(api.lastPostBody, {
      'questionId': '1',
      'selectedOptionId': 'A',
    });
  });

  test('checkAnswer posts backend option ids and maps correctOptionId to text',
      () async {
    final api = _FakeApiService()
      ..postResponses['/questions/check'] = {
        'questionId': 'backend-1',
        'isCorrect': false,
        'correctOptionId': 'b',
      };
    final service = QuestionHubService(
      apiService: api,
      localLoader: _FakeLoaderService(),
    );
    final question = QuestionModel.fromGameplayDto({
      'id': 'backend-1',
      'text': 'Backend question',
      'category': 'Science',
      'difficulty': 'Easy',
      'options': const [
        {'optionId': 'a', 'text': 'Alpha'},
        {'optionId': 'b', 'text': 'Beta'},
      ],
    });

    final result = await service.checkAnswer(
      question: question,
      selectedAnswer: 'Alpha',
    );

    expect(api.lastPostBody, {
      'questionId': 'backend-1',
      'selectedOptionId': 'a',
    });
    expect(result.correctAnswer, 'Beta');
    expect(result.selectedAnswer, 'Alpha');
  });

  test('checkAnswer falls back to local validation when backend fails',
      () async {
    final api = _FakeApiService()
      ..postError = ApiRequestException('offline', path: '/questions/check');
    final service = QuestionHubService(
      apiService: api,
      localLoader: _FakeLoaderService(),
    );
    final question =
        QuestionModel.fromJson(_questionJson(id: '1', difficulty: 1));

    final result = await service.checkAnswer(
      question: question,
      selectedAnswer: 'B',
    );

    expect(result.isCorrect, isFalse);
    expect(result.source, 'local_fallback');
  });

  test(
      'checkAnswerBatch falls back to local validation when payload is invalid',
      () async {
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
    final question =
        QuestionModel.fromJson(_questionJson(id: '1', difficulty: 1));

    final result = await service.checkAnswerBatch(
      submissions: [
        QuestionAnswerSubmission(question: question, selectedAnswer: 'A'),
      ],
    );

    expect(result.results, hasLength(1));
    expect(result.results.first.isCorrect, isTrue);
    expect(result.results.first.source, 'local_fallback');
  });
}
