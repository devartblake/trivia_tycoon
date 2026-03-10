import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:trivia_tycoon/core/repositories/question_repository.dart';
import 'package:trivia_tycoon/game/models/game_mode.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import 'package:trivia_tycoon/game/services/multiplayer_quiz_service.dart';
import 'package:trivia_tycoon/game/services/quiz_category.dart';

class _FakeQuestionRepository implements QuestionRepository {
  _FakeQuestionRepository({
    this.questionsForMode = const [],
    this.throwOnMode = false,
  });

  final List<QuestionModel> questionsForMode;
  final bool throwOnMode;
  int modeCallCount = 0;

  @override
  Future<List<QuestionModel>> getQuestionsForMode({
    required GameMode mode,
    int amount = 10,
    String? category,
    int? difficulty,
  }) async {
    modeCallCount++;
    if (throwOnMode) {
      throw Exception('repository unavailable');
    }
    return questionsForMode;
  }

  @override
  Future<List<QuestionModel>> getQuestionsForCategory({required String category, int amount = 10, int? difficulty}) async => const [];

  @override
  Future<List<QuestionModel>> getDailyQuestions({int count = 5}) async => const [];

  @override
  Future<List<QuizCategory>> getAvailableCategories() async => const [];

  @override
  Future<Map<String, dynamic>> getQuestionStats() async => const {};

  @override
  Future<Map<String, dynamic>> getDatasetInfo() async => const {};

  @override
  Future<Map<String, dynamic>> getCategoryStats(QuizCategory category) async => const {};

  @override
  Future<Map<String, dynamic>> getClassStats(String classId) async => const {};

  @override
  Future<List<QuestionModel>> getMixedQuiz({int questionCount = 10, List<String>? categories, List<String>? difficulties, bool balanceDifficulties = false}) async => const [];

  @override
  Future<List<QuestionModel>> getMultiplayerQuestions({int amount = 10, String? category}) async => const [];
}

Map<String, dynamic> _questionJson({required String id, required String category, int difficulty = 2}) {
  return {
    'id': id,
    'category': category,
    'question': 'Question $id',
    'answers': const [
      {'text': 'A', 'isCorrect': true},
      {'text': 'B', 'isCorrect': false},
    ],
    'correctAnswer': 'A',
    'type': 'multiple_choice',
    'difficulty': difficulty,
  };
}

void main() {
  test('uses repository-backed mode questions when available', () async {
    final repository = _FakeQuestionRepository(
      questionsForMode: [QuestionModel.fromJson(_questionJson(id: 'repo-1', category: 'science'))],
    );

    final service = MultiplayerQuizService(
      client: MockClient((_) async => http.Response('{}', 500)),
      questionRepository: repository,
    );

    final questions = await service.getQuestionsForGameMode('arena');

    expect(questions.length, 1);
    expect(questions.first.id, 'repo-1');
    expect(repository.modeCallCount, 1);
  });

  test('prefetched questions are reused by getQuestionsForGameMode', () async {
    final repository = _FakeQuestionRepository(
      questionsForMode: [QuestionModel.fromJson(_questionJson(id: 'prefetch-1', category: 'history'))],
    );

    final service = MultiplayerQuizService(
      client: MockClient((_) async => http.Response('{}', 500)),
      questionRepository: repository,
    );

    await service.prefetchQuestionsForGameMode('arena');
    final questions = await service.getQuestionsForGameMode('arena');

    expect(questions.first.id, 'prefetch-1');
    expect(repository.modeCallCount, 1);
  });

  test('falls back to HTTP when repository is unavailable', () async {
    final repository = _FakeQuestionRepository(throwOnMode: true);

    final service = MultiplayerQuizService(
      client: MockClient((request) async {
        if (request.url.path.endsWith('/api/questions')) {
          return http.Response(
            jsonEncode({
              'questions': [_questionJson(id: 'http-1', category: 'mixed')],
            }),
            200,
          );
        }
        return http.Response('{}', 404);
      }),
      questionRepository: repository,
    );

    final questions = await service.getQuestionsForGameMode('arena');

    expect(questions.length, 1);
    expect(questions.first.id, 'http-1');
    expect(repository.modeCallCount, 1);
  });
}
