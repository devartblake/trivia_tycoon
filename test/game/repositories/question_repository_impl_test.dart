import 'package:trivia_tycoon/core/models/question_validation_models.dart';
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
  int? lastDailyCount;
  int? lastMixedCount;
  List<String>? lastMixedCategories;
  bool? lastBalanceDifficulties;
  QuestionModel? lastCheckedQuestion;
  String? lastSelectedAnswer;
  List<QuestionAnswerSubmission>? lastBatchSubmissions;

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
  Future<List<QuestionModel>> getDailyQuiz({int questionCount = 5}) async {
    lastDailyCount = questionCount;
    return const [];
  }

  @override
  Future<List<QuestionModel>> getMixedQuiz({
    int questionCount = 10,
    List<String>? categories,
    List<String>? difficulties,
    bool balanceDifficulties = false,
  }) async {
    lastMixedCount = questionCount;
    lastMixedCategories = categories;
    lastBalanceDifficulties = balanceDifficulties;
    return const [];
  }

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
  Future<QuestionAnswerCheckResult> checkAnswer({
    required QuestionModel question,
    required String selectedAnswer,
  }) async {
    lastCheckedQuestion = question;
    lastSelectedAnswer = selectedAnswer;
    return QuestionAnswerCheckResult(
      questionId: question.id,
      selectedAnswer: selectedAnswer,
      isCorrect: true,
    );
  }

  @override
  Future<List<QuestionAnswerCheckResult>> checkAnswerBatch({
    required List<QuestionAnswerSubmission> submissions,
  }) async {
    lastBatchSubmissions = submissions;
    return submissions
        .map(
          (submission) => QuestionAnswerCheckResult(
            questionId: submission.question.id,
            selectedAnswer: submission.selectedAnswer,
            isCorrect: true,
          ),
        )
        .toList();
  }
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

  test('daily mode routes to daily hub loader with requested count', () async {
    final hub = _FakeQuestionHubService();
    final repo = QuestionRepositoryImpl(questionHubService: hub);

    await repo.getQuestionsForMode(mode: GameMode.daily, amount: 6);

    expect(hub.lastDailyCount, 6);
  });

  test('arena mode routes to mixed hub loader with multiplayer balance', () async {
    final hub = _FakeQuestionHubService();
    final repo = QuestionRepositoryImpl(questionHubService: hub);

    await repo.getQuestionsForMode(
      mode: GameMode.arena,
      category: 'history',
      amount: 8,
    );

    expect(hub.lastMixedCount, 8);
    expect(hub.lastMixedCategories, ['history']);
    expect(hub.lastBalanceDifficulties, isTrue);
  });

  test('checkAnswer delegates validation to hub service', () async {
    final hub = _FakeQuestionHubService();
    final repo = QuestionRepositoryImpl(questionHubService: hub);
    final question = QuestionModel.fromJson({
      'id': 'q-1',
      'category': 'science',
      'question': 'Q1',
      'type': 'multiple_choice',
      'difficulty': 1,
      'correctAnswer': 'A',
      'answers': const [
        {'text': 'A', 'isCorrect': true},
        {'text': 'B', 'isCorrect': false},
      ],
    });

    await repo.checkAnswer(question: question, selectedAnswer: 'A');

    expect(hub.lastCheckedQuestion?.id, 'q-1');
    expect(hub.lastSelectedAnswer, 'A');
  });
}
