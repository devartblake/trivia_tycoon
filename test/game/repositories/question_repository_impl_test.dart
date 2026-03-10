import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/game/models/game_mode.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import 'package:trivia_tycoon/game/repositories/question_repository_impl.dart';
import 'package:trivia_tycoon/game/services/question_hub_service.dart';
import 'package:trivia_tycoon/game/services/quiz_category.dart';

class _FakeQuestionHubService extends QuestionHubService {
  _FakeQuestionHubService()
      : super(
          apiService: ApiService(
            baseUrl: 'http://localhost',
            initializeCache: false,
          ),
        );

  String? lastCategory;
  int? lastAmount;
  int? lastDifficulty;

  @override
  Future<List<QuestionModel>> getQuestionsForCategory({
    required String category,
    int amount = 10,
    int? difficulty,
  }) async {
    lastCategory = category;
    lastAmount = amount;
    lastDifficulty = difficulty;
    return const [];
  }

  @override
  Future<List<QuestionModel>> getDailyQuiz({int questionCount = 5}) async => const [];

  @override
  Future<List<QuestionModel>> getMixedQuiz({
    int questionCount = 10,
    List<String>? categories,
    List<String>? difficulties,
    bool balanceDifficulties = false,
  }) async => const [];

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
}

void main() {
  test('topicExplorer mode routes to category questions through hub service', () async {
    final hub = _FakeQuestionHubService();
    final repo = QuestionRepositoryImpl(questionHubService: hub);

    await repo.getQuestionsForMode(
      mode: GameMode.topicExplorer,
      category: 'science',
      amount: 7,
      difficulty: 2,
    );

    expect(hub.lastCategory, 'science');
    expect(hub.lastAmount, 7);
    expect(hub.lastDifficulty, 2);
  });
}
