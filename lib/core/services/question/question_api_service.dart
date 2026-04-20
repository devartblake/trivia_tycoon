import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../../../game/models/question_model.dart';

class QuestionApiService {
  static String get _baseUrl {
    final configuredBase = dotenv.env['API_BASE_URL']?.trim();
    if (configuredBase == null || configuredBase.isEmpty) {
      throw StateError(
        'API_BASE_URL is not configured. Add API_BASE_URL to your .env file.',
      );
    }
    return configuredBase.endsWith('/')
        ? '${configuredBase}questions'
        : '$configuredBase/questions';
  }

  static Future<List<QuestionModel>> fetchQuestions() async {
    final response = await http.get(Uri.parse(_baseUrl));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      final data = decoded is List
          ? decoded
          : (decoded is Map<String, dynamic>
              ? decoded['items'] as List? ?? const []
              : const []);
      return data.map((e) => QuestionModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load questions');
    }
  }

  static Future<void> uploadQuestions(List<QuestionModel> questions) async {
    final body = jsonEncode(questions.map((q) => q.toJson()).toList());
    final response = await http.post(
      Uri.parse('$_baseUrl/bulk'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload questions');
    }
  }

  static Future<void> deleteQuestion(String id) async {
    final response = await http.delete(Uri.parse('$_baseUrl/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete question');
    }
  }
}
