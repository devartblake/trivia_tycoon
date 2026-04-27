import '../../core/services/api_service.dart';
import '../../core/models/question_validation_models.dart';
import '../models/question_model.dart';
import 'question_loader_service.dart';
import 'question_response_contract.dart';
import 'quiz_category.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

enum QuestionDataSource {
  unknown,
  backend,
  localFallback,
}

class QuestionSourceSnapshot {
  final QuestionDataSource source;
  final String operation;
  final String? endpoint;
  final String? detail;
  final DateTime updatedAt;

  const QuestionSourceSnapshot({
    required this.source,
    required this.operation,
    required this.updatedAt,
    this.endpoint,
    this.detail,
  });

  QuestionSourceSnapshot.unknown()
      : source = QuestionDataSource.unknown,
        operation = 'idle',
        endpoint = null,
        detail = null,
        updatedAt = DateTime.fromMillisecondsSinceEpoch(0);

  bool get isBackend => source == QuestionDataSource.backend;
  bool get isFallback => source == QuestionDataSource.localFallback;
}

abstract class QuestionSourceReporter {
  void recordBackend({
    required String operation,
    required String endpoint,
    String? detail,
  });

  void recordFallback({
    required String operation,
    String? endpoint,
    String? detail,
  });
}

class QuestionHubService {
  QuestionHubService({
    required ApiService apiService,
    AdaptedQuestionLoaderService? localLoader,
    QuestionSourceReporter? reporter,
  })  : _apiService = apiService,
        _localLoader = localLoader ?? AdaptedQuestionLoaderService(),
        _reporter = reporter;

  final ApiService _apiService;
  final AdaptedQuestionLoaderService _localLoader;
  final QuestionSourceReporter? _reporter;

  Future<List<QuestionModel>> getQuestionsForCategory({
    required String category,
    int amount = 10,
    int? difficulty,
  }) async {
    try {
      final response = await _apiService.get(
        '/questions/set',
        queryParameters: {
          'category': category,
          'count': amount,
          if (difficulty != null) 'difficulty': difficulty,
        },
      );
      final questions = _parseQuestionListResponse(
        response,
        endpoint: '/questions/set',
      );
      if (questions.isNotEmpty) {
        _recordBackend(
          operation: 'category_questions',
          endpoint: '/questions/set',
          detail: 'Loaded ${questions.length} questions for $category',
        );
        return questions;
      }
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // fallback below
    } catch (_) {
      // fallback below
    }

    final localQuestions = await _localLoader.getQuestionsByCategory(category);
    final filtered = difficulty == null
        ? localQuestions
        : localQuestions.where((q) => q.difficulty == difficulty).toList();
    filtered.shuffle();

    _recordFallback(
      operation: 'category_questions',
      endpoint: '/questions/set',
      detail: 'Using local category questions for $category',
    );

    if (filtered.length <= amount) {
      return filtered;
    }

    return filtered.take(amount).toList();
  }

  Future<QuestionAnswerCheckResult> checkAnswer({
    required QuestionModel question,
    required String selectedAnswer,
  }) async {
    try {
      final response = await _apiService.post(
        '/questions/check',
        body: {
          'questionId': question.id,
          'selectedOptionId': selectedAnswer,
        },
      );
      return _parseAnswerCheckResult(
        response,
        question: question,
        selectedAnswer: selectedAnswer,
      );
    } on ApiRequestException {
      _recordFallback(
        operation: 'answer_check',
        endpoint: '/questions/check',
        detail: 'Falling back to local answer validation for ${question.id}',
      );
      return _fallbackAnswerCheck(question, selectedAnswer);
    } on QuestionContractException {
      _recordFallback(
        operation: 'answer_check',
        endpoint: '/questions/check',
        detail: 'Invalid answer-check contract for ${question.id}',
      );
      return _fallbackAnswerCheck(question, selectedAnswer);
    } catch (_) {
      _recordFallback(
        operation: 'answer_check',
        endpoint: '/questions/check',
        detail: 'Unexpected answer-check failure for ${question.id}',
      );
      return _fallbackAnswerCheck(question, selectedAnswer);
    }
  }

  Future<List<QuestionAnswerCheckResult>> checkAnswerBatch({
    required List<QuestionAnswerSubmission> submissions,
  }) async {
    if (submissions.isEmpty) {
      return const <QuestionAnswerCheckResult>[];
    }

    try {
      final response = await _apiService.post(
        '/questions/check-batch',
        body: {
          'answers': submissions
              .map((submission) => {
                    'questionId': submission.question.id,
                    'selectedOptionId': submission.selectedAnswer,
                  })
              .toList(growable: false),
        },
      );

      final rawItems = response['items'] ??
          response['results'] ??
          response['answers'] ??
          response['data'] ??
          const <dynamic>[];

      if (rawItems is! List) {
        throw QuestionContractException(
          endpoint: '/questions/check-batch',
          reason: 'Invalid batch answer response payload',
        );
      }

      final submissionsById = {
        for (final submission in submissions)
          submission.question.id: submission,
      };

      final results = rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map((item) {
        final questionId =
            item['questionId']?.toString() ?? item['id']?.toString() ?? '';
        final submission = submissionsById[questionId];
        if (submission == null) {
          throw QuestionContractException(
            endpoint: '/questions/check-batch',
            reason: 'Unknown question id returned by backend: $questionId',
          );
        }
        return _parseAnswerCheckResult(
          item,
          question: submission.question,
          selectedAnswer: submission.selectedAnswer,
        );
      }).toList(growable: false);

      if (results.isNotEmpty) {
        _recordBackend(
          operation: 'answer_check_batch',
          endpoint: '/questions/check-batch',
          detail: 'Validated ${results.length} answers via backend',
        );
        return results;
      }
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // fallback below
    } catch (_) {
      // fallback below
    }

    _recordFallback(
      operation: 'answer_check_batch',
      endpoint: '/questions/check-batch',
      detail: 'Using local batch answer validation',
    );

    return submissions
        .map((submission) => _fallbackAnswerCheck(
              submission.question,
              submission.selectedAnswer,
            ))
        .toList(growable: false);
  }

  Future<List<QuizCategory>> getAvailableCategories() async {
    try {
      final response = await _apiService.get('/questions/categories');
      final envelope = QuestionResponseContract.parseCollection(
        response,
        endpoint: '/questions/categories',
        itemKeys: const ['items', 'categories', 'data'],
      );

      final categories = envelope.items
          .map(_parseCategory)
          .whereType<QuizCategory>()
          .toSet()
          .toList();
      if (categories.isNotEmpty) {
        _recordBackend(
          operation: 'categories',
          endpoint: '/questions/categories',
          detail: 'Loaded ${categories.length} categories from backend',
        );
        return categories;
      }
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // invalid contract, fallback below
    }

    _recordFallback(
      operation: 'categories',
      endpoint: '/questions/categories',
      detail: 'Using local category catalog',
    );
    return _localLoader.getAvailableQuizCategories();
  }

  Future<Map<String, dynamic>> getQuestionStats() async {
    try {
      final response = await _apiService.get('/questions/metadata');
      final envelope = QuestionResponseContract.parseObject(
        response,
        endpoint: '/questions/metadata',
        anyOfKeys: const ['totalQuestions', 'questionCount', 'total'],
      );
      _recordBackend(
        operation: 'question_stats',
        endpoint: '/questions/metadata',
        detail: 'Loaded question stats from backend',
      );
      return envelope.data;
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // fallback below
    }

    _recordFallback(
      operation: 'question_stats',
      detail: 'Using local dataset stats',
    );
    return _localLoader.getAllDatasetStats();
  }

  Future<Map<String, dynamic>> getCategoryStats(QuizCategory category) async {
    final categorySlug = category.name;
    try {
      final response = await _apiService.get(
        '/questions/categories/$categorySlug/stats',
      );
      final envelope = QuestionResponseContract.parseObject(
        response,
        endpoint: '/questions/categories/$categorySlug/stats',
        anyOfKeys: const ['questionCount', 'totalQuestions', 'total'],
      );
      _recordBackend(
        operation: 'category_stats',
        endpoint: '/questions/categories/$categorySlug/stats',
        detail: 'Loaded stats for ${category.name}',
      );
      return envelope.data;
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // fallback below
    }

    final questionCount =
        await _localLoader.getQuizCategoryQuestionCount(category);
    final difficulty = await _localLoader.getQuizCategoryDifficulty(category);

    _recordFallback(
      operation: 'category_stats',
      endpoint: '/questions/categories/${category.name}/stats',
      detail: 'Using local stats for ${category.name}',
    );
    return {
      'questionCount': questionCount,
      'difficulty': difficulty,
      'category': category.name,
      'source': 'local_fallback',
    };
  }

  Future<Map<String, dynamic>> getClassStats(String classId) async {
    try {
      final endpoint = '/questions/classes/$classId/stats';
      final response = await _apiService.get(endpoint);
      if (response.isNotEmpty) {
        final envelope = QuestionResponseContract.parseCollection(
          response,
          endpoint: endpoint,
          itemKeys: const ['availableCategories', 'categories', 'items'],
        );
        final categories = envelope.items
            .map(_parseCategory)
            .whereType<QuizCategory>()
            .toList();

        _recordBackend(
          operation: 'class_stats',
          endpoint: endpoint,
          detail: 'Loaded class stats for $classId',
        );
        return {
          'questionCount': (response['questionCount'] as num?)?.toInt() ?? 0,
          'subjectCount': (response['subjectCount'] as num?)?.toInt() ??
              categories.length,
          'availableCategories': categories,
          'source': 'backend',
          'meta': envelope.meta,
        };
      }
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // fallback below
    }

    final questionCount = await _localLoader.getClassQuestionCount(classId);
    final subjectCount = await _localLoader.getClassSubjectCount(classId);
    final categories = QuizCategoryManager.getCategoriesForClass(classId);

    _recordFallback(
      operation: 'class_stats',
      endpoint: '/questions/classes/$classId/stats',
      detail: 'Using local class stats for $classId',
    );
    return {
      'questionCount': questionCount,
      'subjectCount': subjectCount,
      'availableCategories': categories,
      'source': 'local_fallback',
    };
  }

  Future<Map<String, dynamic>> getDatasetInfo() async {
    try {
      final response = await _apiService.get('/questions/metadata');
      final envelope = QuestionResponseContract.parseObject(
        response,
        endpoint: '/questions/metadata',
        anyOfKeys: const ['name', 'version', 'datasetName', 'totalQuestions'],
      );
      _recordBackend(
        operation: 'dataset_info',
        endpoint: '/questions/metadata',
        detail: 'Loaded dataset info from backend',
      );
      return envelope.data;
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // fallback below
    }

    _recordFallback(
      operation: 'dataset_info',
      detail: 'Using local dataset info',
    );
    return _localLoader.getDatasetInfo();
  }

  Future<List<QuestionModel>> getMixedQuiz({
    int questionCount = 10,
    List<String>? categories,
    List<String>? difficulties,
    bool balanceDifficulties = false,
  }) async {
    try {
      final response = await _apiService.get(
        '/questions/set',
        queryParameters: {
          'count': questionCount,
          if (categories != null && categories.length == 1)
            'category': categories.first,
          if (difficulties != null && difficulties.length == 1)
            'difficulty': difficulties.first,
        },
      );
      final questions = _parseQuestionListResponse(
        response,
        endpoint: '/questions/set',
      );
      if (questions.isNotEmpty) {
        _recordBackend(
          operation: 'mixed_quiz',
          endpoint: '/questions/set',
          detail: 'Loaded ${questions.length} mixed questions',
        );
        return questions;
      }
    } on ApiRequestException {
      // try legacy/fallback endpoints below
    } on QuestionContractException {
      // try legacy/fallback endpoints below
    }

    final quizCategories = categories
            ?.map(QuizCategoryManager.fromString)
            .whereType<QuizCategory>()
            .toList() ??
        const <QuizCategory>[];

    _recordFallback(
      operation: 'mixed_quiz',
      endpoint: '/questions/mixed',
      detail: 'Using local mixed-quiz questions',
    );
    return _localLoader.getMixedQuizByCategories(
      questionCount: questionCount,
      categories: quizCategories.isEmpty ? null : quizCategories,
      difficulties: difficulties,
      balanceDifficulties: balanceDifficulties,
    );
  }

  Future<List<QuestionModel>> getDailyQuiz({int questionCount = 5}) async {
    try {
      final response = await _apiService.get(
        '/questions/set',
        queryParameters: {'count': questionCount},
      );
      final questions = _parseQuestionListResponse(
        response,
        endpoint: '/questions/set',
      );
      if (questions.isNotEmpty) {
        _recordBackend(
          operation: 'daily_quiz',
          endpoint: '/questions/set',
          detail: 'Loaded ${questions.length} daily questions',
        );
        return questions;
      }
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // fallback below
    }

    _recordFallback(
      operation: 'daily_quiz',
      endpoint: '/questions/set',
      detail: 'Using local daily quiz questions',
    );
    return _localLoader.getDailyQuiz(questionCount: questionCount);
  }

  void _recordBackend({
    required String operation,
    required String endpoint,
    String? detail,
  }) {
    _reporter?.recordBackend(
      operation: operation,
      endpoint: endpoint,
      detail: detail,
    );
    LogManager.debug(
      '[QuestionHub] BACKEND op=$operation endpoint=$endpoint${detail == null ? '' : ' detail=$detail'}',
    );
  }

  void _recordFallback({
    required String operation,
    String? endpoint,
    String? detail,
  }) {
    _reporter?.recordFallback(
      operation: operation,
      endpoint: endpoint,
      detail: detail,
    );
    LogManager.warning(
      '[QuestionHub] LOCAL_FALLBACK op=$operation${endpoint == null ? '' : ' endpoint=$endpoint'}${detail == null ? '' : ' detail=$detail'}',
      source: 'QuestionHubService',
    );
  }

  QuizCategory? _parseCategory(dynamic value) {
    if (value is String) {
      return QuizCategoryManager.fromString(value);
    }

    if (value is Map) {
      final map = Map<String, dynamic>.from(value);
      final candidate = map['name'] ?? map['slug'] ?? map['category'];
      if (candidate is String) {
        return QuizCategoryManager.fromString(candidate);
      }
    }

    return null;
  }

  List<QuestionModel> _parseQuestionListResponse(
    Object? response, {
    required String endpoint,
  }) {
    final rawItems = response is List
        ? response
        : (response as Map<String, dynamic>)['items'] ??
            response['questions'] ??
            response['data'] ??
            const <dynamic>[];

    if (rawItems is! List) {
      throw QuestionContractException(
        endpoint: endpoint,
        reason: 'Invalid question collection payload',
      );
    }

    return rawItems
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(QuestionModel.fromJson)
        .toList(growable: false);
  }

  QuestionAnswerCheckResult _parseAnswerCheckResult(
    Map<String, dynamic> response, {
    required QuestionModel question,
    required String selectedAnswer,
  }) {
    final isCorrect = response['isCorrect'] ??
        response['correct'] ??
        response['is_valid'] ??
        response['valid'];

    if (isCorrect is! bool) {
      throw QuestionContractException(
        endpoint: '/questions/check',
        reason: 'Invalid answer check response for question ${question.id}',
      );
    }

    final correctAnswer = response['correctOptionId']?.toString() ??
        response['correctAnswer']?.toString() ??
        response['expectedAnswer']?.toString() ??
        question.correctAnswer;
    final questionId = response['questionId']?.toString() ??
        response['id']?.toString() ??
        question.id;
    final source = response['source']?.toString() ?? 'backend';

    return QuestionAnswerCheckResult(
      questionId: questionId,
      selectedAnswer: selectedAnswer,
      isCorrect: isCorrect,
      correctAnswer: correctAnswer,
      source: source,
      metadata: response,
    );
  }

  QuestionAnswerCheckResult _fallbackAnswerCheck(
    QuestionModel question,
    String selectedAnswer,
  ) {
    return QuestionAnswerCheckResult(
      questionId: question.id,
      selectedAnswer: selectedAnswer,
      isCorrect: question.isCorrectAnswer(selectedAnswer),
      correctAnswer: question.correctAnswer,
      source: 'local_fallback',
    );
  }
}
