import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/models/question_validation_models.dart';
import 'package:synaptix/core/repositories/question_repository.dart';
import 'package:synaptix/game/models/game_mode.dart';
import 'package:synaptix/game/models/question_difficulty.dart';
import 'package:synaptix/game/models/question_model.dart';
import 'package:synaptix/game/services/quiz_category.dart';
import 'package:synaptix/game/state/quiz_state.dart';

QuestionModel _question({
  required String id,
  int difficulty = 1,
  String type = 'multiple_choice',
  String question = 'What is 2 + 2?',
  String correctAnswer = '4',
}) {
  return QuestionModel.fromJson({
    'id': id,
    'category': 'math',
    'question': question,
    'options': ['4', '5'],
    'correctAnswer': correctAnswer,
    'difficulty': difficulty,
    'type': type,
  });
}

class _FakeRepo implements QuestionRepository {
  @override
  Future<List<QuestionModel>> getQuestionsForCategory({
    required String category,
    int amount = 10,
    int? difficulty,
    String mode = 'practice',
    String? playerId,
  }) async =>
      [];

  @override
  Future<List<QuestionModel>> getDailyQuestions({int count = 5}) async => [];

  @override
  Future<List<QuizCategory>> getAvailableCategories() async => [];

  @override
  Future<Map<String, dynamic>> getQuestionStats() async => {};

  @override
  Future<Map<String, dynamic>> getDatasetInfo() async => {};

  @override
  Future<Map<String, dynamic>> getCategoryStats(QuizCategory category) async =>
      {};

  @override
  Future<Map<String, dynamic>> getClassStats(String classId) async => {};

  @override
  Future<List<QuestionModel>> getMixedQuiz({
    int questionCount = 10,
    List<String>? categories,
    List<String>? difficulties,
    bool balanceDifficulties = false,
    String mode = 'practice',
    String? playerId,
  }) async =>
      [];

  @override
  Future<List<QuestionModel>> getQuestionsForMode({
    required GameMode mode,
    int amount = 10,
    String? category,
    int? difficulty,
    String? playerId,
  }) async =>
      [];

  @override
  Future<List<QuestionModel>> getMultiplayerQuestions({
    int amount = 10,
    String? category,
    int? difficulty,
  }) async =>
      [];

  @override
  Future<QuestionAnswerCheckResult> checkAnswer({
    required QuestionModel question,
    required String selectedAnswer,
  }) async =>
      QuestionAnswerCheckResult(
        questionId: question.id,
        selectedAnswer: selectedAnswer,
        isCorrect: question.isCorrectAnswer(selectedAnswer),
        correctAnswer: question.correctAnswer,
      );

  @override
  Future<QuestionBatchCheckOutcome> checkAnswerBatch({
    required List<QuestionAnswerSubmission> submissions,
    String? quizSessionId,
    String? mode,
  }) async =>
      const QuestionBatchCheckOutcome(results: []);
}

void main() {
  group('free-text answer normalization', () {
    test('free-text comparison ignores case and extra whitespace', () {
      final q = _question(
        id: 'ft-1',
        type: 'free_text',
        correctAnswer: 'George Washington',
      );
      expect(q.isCorrectAnswer('george washington'), isTrue);
      expect(q.isCorrectAnswer('  GEORGE   WASHINGTON  '), isTrue);
      expect(q.isCorrectAnswer('John Adams'), isFalse);
    });

    test('non-free-text types still require an exact match', () {
      final q = _question(id: 'mc-1', correctAnswer: '4');
      expect(q.isCorrectAnswer('4'), isTrue);
      expect(q.isCorrectAnswer(' 4 '), isFalse);
    });
  });

  group('per-question time limits', () {
    test('classic mode uses the class-level limit for normal questions',
        () async {
      final notifier = AdaptedQuizNotifier(repository: _FakeRepo());
      await notifier.startQuizWithQuestions(
        questions: [_question(id: '1', difficulty: 2)],
        classLevel: '9',
      );

      // Class 9 → 25s regardless of the question's medium difficulty.
      expect(notifier.state.questionTimeLimit, 25);
      expect(notifier.state.timeRemaining, 25);
      notifier.dispose();
    });

    test('timed challenge uses the difficulty limit per question', () async {
      final notifier = AdaptedQuizNotifier(repository: _FakeRepo());
      await notifier.startQuizWithQuestions(
        questions: [
          _question(id: '1', difficulty: 1), // easy → 30s
          _question(id: '2', difficulty: 4), // expert → 15s
        ],
        classLevel: '9',
        timedChallenge: true,
      );

      expect(notifier.state.timedChallenge, isTrue);
      expect(notifier.state.questionTimeLimit, 30);

      notifier.nextQuestion();
      expect(notifier.state.questionTimeLimit, 15);
      expect(notifier.state.timeRemaining, 15);
      notifier.dispose();
    });

    test('boss questions always use the 10s boss limit, even in classic mode',
        () async {
      final notifier = AdaptedQuizNotifier(repository: _FakeRepo());
      await notifier.startQuizWithQuestions(
        questions: [
          _question(id: '1', difficulty: 1),
          _question(id: 'boss', difficulty: 5),
        ],
        classLevel: '1',
      );

      // Class 1 → 45s for the normal opener.
      expect(notifier.state.questionTimeLimit, 45);

      notifier.nextQuestion();
      expect(notifier.state.questions[1].difficulty, QuestionDifficulty.boss);
      expect(notifier.state.questionTimeLimit, 10);
      expect(notifier.state.timeRemaining, 10);
      notifier.dispose();
    });
  });
}
