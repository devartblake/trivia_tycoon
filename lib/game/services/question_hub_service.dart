import '../../core/services/api_service.dart';
import '../../core/models/question_validation_models.dart';
import '../models/question_model.dart';
import 'question_loader_service.dart';
import 'question_response_contract.dart';
import 'quiz_category.dart';

class QuestionHubService {
  QuestionHubService({
    required ApiService apiService,
    AdaptedQuestionLoaderService? localLoader,
  })  : _apiService = apiService,
        _localLoader = localLoader ?? AdaptedQuestionLoaderService();

  final ApiService _apiService;
  final AdaptedQuestionLoaderService _localLoader;

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
        return questions;
      }
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // fallback below
    } catch (_) {
      // fallback below
    }

    try {
      final response = await _apiService.fetchQuestions(
        amount: amount,
        category: category,
        difficulty: difficulty?.toString(),
      );
      final questions = response.map(QuestionModel.fromJson).toList();
      if (questions.isNotEmpty) {
        return questions;
      }
    } on ApiRequestException {
      // fallback below
    } catch (_) {
      // fallback below
    }

    final localQuestions = await _localLoader.getQuestionsByCategory(category);
    final filtered = difficulty == null
        ? localQuestions
        : localQuestions.where((q) => q.difficulty == difficulty).toList();

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
          'answer': selectedAnswer,
          'selectedAnswer': selectedAnswer,
        },
      );
      return _parseAnswerCheckResult(
        response,
        question: question,
        selectedAnswer: selectedAnswer,
      );
    } on ApiRequestException {
      return _fallbackAnswerCheck(question, selectedAnswer);
    } on QuestionContractException {
      return _fallbackAnswerCheck(question, selectedAnswer);
    } catch (_) {
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
                    'answer': submission.selectedAnswer,
                    'selectedAnswer': submission.selectedAnswer,
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
        for (final submission in submissions) submission.question.id: submission,
      };

      final results = rawItems
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .map((item) {
            final questionId = item['questionId']?.toString() ??
                item['id']?.toString() ??
                '';
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
          })
          .toList(growable: false);

      if (results.isNotEmpty) {
        return results;
      }
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // fallback below
    } catch (_) {
      // fallback below
    }

    return submissions
        .map((submission) => _fallbackAnswerCheck(
              submission.question,
              submission.selectedAnswer,
            ))
        .toList(growable: false);
  }

  Future<List<QuizCategory>> getAvailableCategories() async {
    try {
      final response = await _apiService.get('/quiz/categories');
      final envelope = QuestionResponseContract.parseCollection(
        response,
        endpoint: '/quiz/categories',
        itemKeys: const ['items', 'categories', 'data'],
      );

      final categories = envelope.items.map(_parseCategory).whereType<QuizCategory>().toSet().toList();
      if (categories.isNotEmpty) {
        return categories;
      }
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // invalid contract, fallback below
    }

    return _localLoader.getAvailableQuizCategories();
  }

  Future<Map<String, dynamic>> getQuestionStats() async {
    for (final endpoint in const ['/quiz/stats', '/questions/stats']) {
      try {
        final response = await _apiService.get(endpoint);
        final envelope = QuestionResponseContract.parseObject(
          response,
          endpoint: endpoint,
          anyOfKeys: const ['totalQuestions', 'questionCount', 'total'],
        );

        return envelope.data;
      } on ApiRequestException {
        // try next endpoint or fallback
      } on QuestionContractException {
        // invalid contract, try next endpoint or fallback
      }
    }

    return _localLoader.getAllDatasetStats();
  }

  Future<Map<String, dynamic>> getCategoryStats(QuizCategory category) async {
    final categorySlug = category.name;
    for (final endpoint in [
      '/quiz/categories/$categorySlug/stats',
      '/questions/categories/$categorySlug/stats',
    ]) {
      try {
        final response = await _apiService.get(endpoint);
        final envelope = QuestionResponseContract.parseObject(
          response,
          endpoint: endpoint,
          anyOfKeys: const ['questionCount', 'totalQuestions', 'total'],
        );

        return envelope.data;
      } on ApiRequestException {
        // try next endpoint or fallback
      } on QuestionContractException {
        // invalid contract, try next endpoint or fallback
      }
    }

    final questionCount = await _localLoader.getQuizCategoryQuestionCount(category);
    final difficulty = await _localLoader.getQuizCategoryDifficulty(category);

    return {
      'questionCount': questionCount,
      'difficulty': difficulty,
      'category': category.name,
      'source': 'local_fallback',
    };
  }

  Future<Map<String, dynamic>> getClassStats(String classId) async {
    for (final endpoint in [
      '/quiz/classes/$classId/stats',
      '/questions/classes/$classId/stats',
    ]) {
      try {
        final response = await _apiService.get(endpoint);
        if (response.isNotEmpty) {
          final envelope = QuestionResponseContract.parseCollection(
            response,
            endpoint: endpoint,
            itemKeys: const ['availableCategories', 'categories', 'items'],
          );
          final categories = envelope.items.map(_parseCategory).whereType<QuizCategory>().toList();

          return {
            'questionCount': (response['questionCount'] as num?)?.toInt() ?? 0,
            'subjectCount': (response['subjectCount'] as num?)?.toInt() ?? categories.length,
            'availableCategories': categories,
            'source': 'backend',
            'meta': envelope.meta,
          };
        }
      } on ApiRequestException {
        // try next endpoint or fallback
      } on QuestionContractException {
        // invalid contract, fallback below
      }
    }

    final questionCount = await _localLoader.getClassQuestionCount(classId);
    final subjectCount = await _localLoader.getClassSubjectCount(classId);
    final categories = QuizCategoryManager.getCategoriesForClass(classId);

    return {
      'questionCount': questionCount,
      'subjectCount': subjectCount,
      'availableCategories': categories,
      'source': 'local_fallback',
    };
  }

  Future<Map<String, dynamic>> getDatasetInfo() async {
    for (final endpoint in const ['/quiz/datasets/info', '/questions/datasets/info']) {
      try {
        final response = await _apiService.get(endpoint);
        final envelope = QuestionResponseContract.parseObject(
          response,
          endpoint: endpoint,
          anyOfKeys: const ['name', 'version', 'datasetName'],
        );

        return envelope.data;
      } on ApiRequestException {
        // try next endpoint or fallback
      } on QuestionContractException {
        // invalid contract, try next endpoint or fallback
      }
    }

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
          if (categories != null && categories.length == 1) 'category': categories.first,
          if (difficulties != null && difficulties.length == 1) 'difficulty': difficulties.first,
        },
      );
      final questions = _parseQuestionListResponse(
        response,
        endpoint: '/questions/set',
      );
      if (questions.isNotEmpty) {
        return questions;
      }
    } on ApiRequestException {
      // try legacy/fallback endpoints below
    } on QuestionContractException {
      // try legacy/fallback endpoints below
    }

    for (final endpoint in const ['/quiz/mixed', '/questions/mixed']) {
      try {
        final response = await _apiService.get(
          endpoint,
          queryParameters: {
            'count': questionCount,
            if (categories != null && categories.isNotEmpty) 'categories': categories.join(','),
            if (difficulties != null && difficulties.isNotEmpty) 'difficulties': difficulties.join(','),
            'balanceDifficulties': balanceDifficulties,
          },
        );

        final envelope = QuestionResponseContract.parseCollection(
          response,
          endpoint: endpoint,
          itemKeys: const ['items', 'questions', 'data'],
          requireMeta: true,
        );

        final questions = envelope.items
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .map(QuestionModel.fromJson)
            .toList();

        if (questions.isNotEmpty) {
          return questions;
        }
      } on ApiRequestException {
        // try next endpoint or fallback
      } on QuestionContractException {
        // invalid contract, fallback below
      }
    }

    final quizCategories = categories?.map(QuizCategoryManager.fromString).whereType<QuizCategory>().toList() ?? const <QuizCategory>[];

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
        return questions;
      }
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // fallback below
    }

    try {
      final response = await _apiService.get(
        '/quiz/daily',
        queryParameters: {'count': questionCount},
      );
      final envelope = QuestionResponseContract.parseCollection(
        response,
        endpoint: '/quiz/daily',
        itemKeys: const ['items', 'questions', 'data'],
        requireMeta: true,
      );

      final questions = envelope.items
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(QuestionModel.fromJson)
          .toList();

      if (questions.isNotEmpty) {
        return questions;
      }
    } on ApiRequestException {
      // fallback below
    } on QuestionContractException {
      // invalid contract, fallback below
    }

    return _localLoader.getDailyQuiz(questionCount: questionCount);
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

    final correctAnswer = response['correctAnswer']?.toString() ??
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
