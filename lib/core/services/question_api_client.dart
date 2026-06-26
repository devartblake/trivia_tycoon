import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';

/// API client for fetching trivia questions from backend
class QuestionApiClient {
  final http.Client _httpClient;

  QuestionApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static const String _baseUrl = 'https://api.synaptixplay.com/api/v1';
  static const String _questionsPath = '/questions';

  /// Get questions for a specific category
  Future<List<QuestionModel>> getQuestionsByCategory(
    String categoryId, {
    int? count = 20,
    String? difficulty,
    String? mode,
  }) async {
    try {
      final params = {
        'category': categoryId,
        if (count != null) 'count': count.toString(),
        if (difficulty != null) 'difficulty': difficulty,
        if (mode != null) 'mode': mode,
      };

      final uri = Uri.parse(_baseUrl + _questionsPath).replace(
        queryParameters: params,
      );

      LogManager.debug('[QuestionApiClient] GET $uri');

      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final questions = _parseQuestionsFromResponse(data);
        LogManager.debug(
          '[QuestionApiClient] Loaded ${questions.length} questions for $categoryId',
        );
        return questions;
      } else if (response.statusCode == 404) {
        LogManager.warning(
          '[QuestionApiClient] Category not found: $categoryId',
        );
        return [];
      } else {
        throw QuestionApiException(
          message: 'Failed to fetch questions',
          statusCode: response.statusCode,
          category: categoryId,
        );
      }
    } catch (e) {
      LogManager.error(
        '[QuestionApiClient] Error fetching questions for $categoryId: $e',
        source: 'QuestionApiClient.getQuestionsByCategory',
        error: e,
      );
      rethrow;
    }
  }

  /// Get questions for multiple categories
  Future<Map<String, List<QuestionModel>>> getQuestionsForCategories(
    List<String> categoryIds, {
    int? countPerCategory = 10,
  }) async {
    try {
      final result = <String, List<QuestionModel>>{};

      for (final categoryId in categoryIds) {
        try {
          final questions = await getQuestionsByCategory(
            categoryId,
            count: countPerCategory,
          );
          result[categoryId] = questions;
        } catch (e) {
          LogManager.warning(
            '[QuestionApiClient] Failed to fetch $categoryId: $e',
          );
          result[categoryId] = [];
        }
      }

      return result;
    } catch (e) {
      LogManager.error(
        '[QuestionApiClient] Error fetching multiple categories: $e',
        source: 'QuestionApiClient.getQuestionsForCategories',
        error: e,
      );
      rethrow;
    }
  }

  /// Get questions for multiplayer matches
  Future<List<QuestionModel>> getMultiplayerQuestions(
    String matchId, {
    required int count,
    required List<String> categories,
  }) async {
    try {
      final params = {
        'matchId': matchId,
        'count': count.toString(),
        'categories': categories.join(','),
      };

      final uri = Uri.parse(_baseUrl + _questionsPath + '/multiplayer')
          .replace(queryParameters: params);

      LogManager.debug('[QuestionApiClient] GET $uri');

      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final questions = _parseQuestionsFromResponse(data);
        LogManager.debug(
          '[QuestionApiClient] Loaded ${questions.length} questions for match $matchId',
        );
        return questions;
      } else {
        throw QuestionApiException(
          message: 'Failed to fetch multiplayer questions',
          statusCode: response.statusCode,
          category: matchId,
        );
      }
    } catch (e) {
      LogManager.error(
        '[QuestionApiClient] Error fetching multiplayer questions: $e',
        source: 'QuestionApiClient.getMultiplayerQuestions',
        error: e,
      );
      rethrow;
    }
  }

  /// Parse questions from API response
  List<QuestionModel> _parseQuestionsFromResponse(dynamic data) {
    try {
      final List<dynamic> questionsList;

      // Handle different response formats
      if (data is List) {
        questionsList = data;
      } else if (data is Map && data.containsKey('data')) {
        questionsList = data['data'] as List;
      } else if (data is Map && data.containsKey('questions')) {
        questionsList = data['questions'] as List;
      } else {
        throw FormatException('Unexpected API response format');
      }

      return questionsList
          .map((json) => QuestionModel.fromJson(json as Map<String, dynamic>))
          .where((q) => q.question.isNotEmpty && q.options.isNotEmpty)
          .toList();
    } catch (e) {
      LogManager.error(
        '[QuestionApiClient] Error parsing questions: $e',
        source: 'QuestionApiClient._parseQuestionsFromResponse',
        error: e,
      );
      rethrow;
    }
  }

  /// Close the HTTP client
  void close() {
    _httpClient.close();
  }
}

/// Exception thrown by QuestionApiClient
class QuestionApiException implements Exception {
  final String message;
  final int statusCode;
  final String category;

  QuestionApiException({
    required this.message,
    required this.statusCode,
    required this.category,
  });

  @override
  String toString() =>
      'QuestionApiException: $message (status: $statusCode, category: $category)';
}
