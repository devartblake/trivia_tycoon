import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../game/models/question_model.dart';

class QuestionApiService {
  static const String baseUrl = 'https://your-api-url.com/api/questions'; // Replace

  static Future<List<QuestionModel>> fetchQuestions() async {
    final response = await http.get(Uri.parse(baseUrl));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as List;
      return data.map((e) => QuestionModel.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load questions');
    }
  }

  static Future<void> uploadQuestions(List<QuestionModel> questions) async {
    final body = jsonEncode(questions.map((q) => q.toJson()).toList());
    final response = await http.post(
      Uri.parse('$baseUrl/bulk'),
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload questions');
    }
  }

  static Future<void> deleteQuestion(String id) async {
    final response = await http.delete(Uri.parse('$baseUrl/$id'));
    if (response.statusCode != 204) {
      throw Exception('Failed to delete question');
    }
  }
}
