import '../../core/services/api_service.dart';
import '../models/question_model.dart';
import 'question_loader_service.dart';
import 'quiz_category.dart';

class QuestionHubService {
  QuestionHubService({
    required ApiService apiService,
    AdaptedQuestionLoaderService? localLoader,
  })  : _apiService = apiService,
        _localLoader = localLoader ?? AdaptedQuestionLoaderService();

  final ApiService _apiService;
  final AdaptedQuestionLoaderService _localLoader;

  Future<List<QuizCategory>> getAvailableCategories() async {
    try {
      final response = await _apiService.get('/quiz/categories');
      final raw = _extractList(response, keys: const ['items', 'categories', 'data']);
      final categories = raw
          .map(_parseCategory)
          .whereType<QuizCategory>()
          .toSet()
          .toList();
      if (categories.isNotEmpty) {
        return categories;
      }
    } on ApiRequestException {
      // fallback below
    }

    return _localLoader.getAvailableQuizCategories();
  }

  Future<Map<String, dynamic>> getQuestionStats() async {
    for (final endpoint in const ['/quiz/stats', '/questions/stats']) {
      try {
        final response = await _apiService.get(endpoint);
        if (response.isNotEmpty) {
          return response;
        }
      } on ApiRequestException {
        // try next endpoint or fallback
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
        if (response.isNotEmpty) {
          return response;
        }
      } on ApiRequestException {
        // try next endpoint or fallback
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

  Future<Map<String, dynamic>> getDatasetInfo() async {
    for (final endpoint in const ['/quiz/datasets/info', '/questions/datasets/info']) {
      try {
        final response = await _apiService.get(endpoint);
        if (response.isNotEmpty) {
          return response;
        }
      } on ApiRequestException {
        // try next endpoint or fallback
      }
    }

    return _localLoader.getDatasetInfo();
  }

  Future<List<QuestionModel>> getDailyQuiz({int questionCount = 5}) async {
    try {
      final response = await _apiService.get(
        '/quiz/daily',
        queryParameters: {'count': questionCount},
      );
      final raw = _extractList(response, keys: const ['items', 'questions', 'data']);
      final questions = raw
          .whereType<Map>()
          .map((e) => Map<String, dynamic>.from(e))
          .map(QuestionModel.fromJson)
          .toList();

      if (questions.isNotEmpty) {
        return questions;
      }
    } on ApiRequestException {
      // fallback below
    }

    return _localLoader.getDailyQuiz(questionCount: questionCount);
  }

  List<dynamic> _extractList(
      Map<String, dynamic> response, {
        required List<String> keys,
      }) {
    for (final key in keys) {
      final value = response[key];
      if (value is List) {
        return value;
      }
    }
    return const [];
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
}
