import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/question_validation_models.dart';
import 'package:trivia_tycoon/core/repositories/question_repository.dart';
import 'package:trivia_tycoon/game/models/game_mode.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import 'package:trivia_tycoon/game/providers/question_providers.dart'
    as question_data;
import 'package:trivia_tycoon/game/providers/quiz_providers.dart';
import 'package:trivia_tycoon/game/services/quiz_category.dart';

class _FakeQuestionRepository implements QuestionRepository {
  @override
  Future<List<QuizCategory>> getAvailableCategories() async =>
      [QuizCategory.science, QuizCategory.mathematics];

  @override
  Future<Map<String, dynamic>> getCategoryStats(QuizCategory category) async {
    return {
      'totalQuestions': 12,
      'difficulty': 'hard',
      'source': 'backend',
      'category': category.name,
    };
  }

  @override
  Future<Map<String, dynamic>> getClassStats(String classId) async {
    return {
      'totalQuestions': '30',
      'categoryCount': 2,
      'availableCategories': [QuizCategory.history, 'ignored'],
      'source': 'backend',
    };
  }

  @override
  Future<List<QuestionModel>> getDailyQuestions({int count = 5}) async =>
      const [];

  @override
  Future<Map<String, dynamic>> getDatasetInfo() async {
    return {
      'datasetName': 'phase2_pack',
      'datasetVersion': 'v3',
      'totalQuestions': 90,
    };
  }

  @override
  Future<List<QuestionModel>> getMixedQuiz({
    int questionCount = 10,
    List<String>? categories,
    List<String>? difficulties,
    bool balanceDifficulties = false,
  }) async =>
      const [];

  @override
  Future<List<QuestionModel>> getMultiplayerQuestions({
    int amount = 10,
    String? category,
  }) async =>
      const [];

  @override
  Future<Map<String, dynamic>> getQuestionStats() async {
    return {
      'totalQuestions': 120,
      'totalCategories': 8,
    };
  }

  @override
  Future<List<QuestionModel>> getQuestionsForCategory({
    required String category,
    int amount = 10,
    int? difficulty,
  }) async =>
      const [];

  @override
  Future<List<QuestionModel>> getQuestionsForMode({
    required GameMode mode,
    int amount = 10,
    String? category,
    int? difficulty,
  }) async =>
      const [];

  @override
  Future<QuestionAnswerCheckResult> checkAnswer({
    required QuestionModel question,
    required String selectedAnswer,
  }) async {
    return QuestionAnswerCheckResult(
      questionId: question.id,
      selectedAnswer: selectedAnswer,
      isCorrect: question.correctAnswer == selectedAnswer,
      correctAnswer: question.correctAnswer,
      source: 'test',
    );
  }

  @override
  Future<List<QuestionAnswerCheckResult>> checkAnswerBatch({
    required List<QuestionAnswerSubmission> submissions,
  }) async {
    return submissions
        .map(
          (submission) => QuestionAnswerCheckResult(
            questionId: submission.question.id,
            selectedAnswer: submission.selectedAnswer,
            isCorrect:
                submission.question.correctAnswer == submission.selectedAnswer,
            correctAnswer: submission.question.correctAnswer,
            source: 'test',
          ),
        )
        .toList(growable: false);
  }
}

void main() {
  ProviderContainer _containerWithRepo(QuestionRepository repo) {
    return ProviderContainer(
      overrides: [
        question_data.questionRepositoryProvider.overrideWithValue(repo),
      ],
    );
  }

  test('question providers normalize repository outputs', () async {
    final container = _containerWithRepo(_FakeQuestionRepository());
    addTearDown(container.dispose);

    final questionStats =
        await container.read(question_data.questionStatsProvider.future);
    final datasetInfo =
        await container.read(question_data.datasetInfoProvider.future);
    final categoryStats = await container
        .read(question_data.categoryStatsProvider(QuizCategory.science).future);
    final classStats =
        await container.read(question_data.classStatsProvider('7').future);

    expect(questionStats['questionCount'], 120);
    expect(questionStats['categoryCount'], 8);

    expect(datasetInfo['name'], 'phase2_pack');
    expect(datasetInfo['version'], 'v3');
    expect(datasetInfo['questionCount'], 90);

    expect(categoryStats['category'], 'science');
    expect(categoryStats['questionCount'], 12);
    expect(categoryStats['difficulty'], 'hard');

    expect(classStats['questionCount'], 30);
    expect(classStats['subjectCount'], 2);
    expect(classStats['availableCategories'], [QuizCategory.history]);
  });

  test(
      'serviceStatusProvider returns normalized repository-backed status payload',
      () async {
    final container = _containerWithRepo(_FakeQuestionRepository());
    addTearDown(container.dispose);

    final status = await container.read(serviceStatusProvider.future);

    expect(status['isHealthy'], isTrue);
    expect(status['source'], 'repository');
    expect((status['questionStats'] as Map<String, dynamic>)['questionCount'],
        120);
    expect(
        (status['datasetInfo'] as Map<String, dynamic>)['name'], 'phase2_pack');
  });
}
