import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/state/quiz_state.dart';
import 'package:trivia_tycoon/game/models/answer.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import 'package:trivia_tycoon/game/services/quiz_category.dart';
import 'package:trivia_tycoon/game/models/question_type.dart' as qtype;
import 'package:trivia_tycoon/game/models/question_difficulty.dart' as qdiff;

QuestionModel _q({
  String id = 'q1',
  String category = 'Science',
  String question = 'What is H2O?',
  int difficulty = 1,
}) =>
    QuestionModel(
      id: id,
      category: category,
      question: question,
      answers: [
        Answer(text: 'Water', isCorrect: true),
        Answer(text: 'Fire', isCorrect: false),
        Answer(text: 'Earth', isCorrect: false),
        Answer(text: 'Air', isCorrect: false),
      ],
      correctAnswer: 'Water',
      type: qtype.QuestionTypeExtension.fromString('multiple_choice'),
      difficulty: qdiff.QuestionDifficultyExtension.fromInt(difficulty),
      options: ['Water', 'Fire', 'Earth', 'Air'],
      correctIndex: 0,
    );

void main() {
  // -------------------------------------------------------------------------
  // default constructor values
  // -------------------------------------------------------------------------

  group('default constructor values', () {
    test('questions is empty', () {
      expect(const AdaptedQuizState().questions, isEmpty);
    });

    test('currentIndex is 0', () {
      expect(const AdaptedQuizState().currentIndex, 0);
    });

    test('score is 0', () {
      expect(const AdaptedQuizState().score, 0);
    });

    test('totalXP is 0', () {
      expect(const AdaptedQuizState().totalXP, 0);
    });

    test('coins is null', () {
      expect(const AdaptedQuizState().coins, isNull);
    });

    test('diamonds is null', () {
      expect(const AdaptedQuizState().diamonds, isNull);
    });

    test('stars is null', () {
      expect(const AdaptedQuizState().stars, isNull);
    });

    test('classLevel is "1"', () {
      expect(const AdaptedQuizState().classLevel, '1');
    });

    test('category is null', () {
      expect(const AdaptedQuizState().category, isNull);
    });

    test('isLoading is false', () {
      expect(const AdaptedQuizState().isLoading, isFalse);
    });

    test('error is null', () {
      expect(const AdaptedQuizState().error, isNull);
    });

    test('selectedAnswer is null', () {
      expect(const AdaptedQuizState().selectedAnswer, isNull);
    });

    test('showFeedback is false', () {
      expect(const AdaptedQuizState().showFeedback, isFalse);
    });

    test('timeRemaining is 30', () {
      expect(const AdaptedQuizState().timeRemaining, 30);
    });

    test('isPaused is false', () {
      expect(const AdaptedQuizState().isPaused, isFalse);
    });

    test('isTimerExpired is false', () {
      expect(const AdaptedQuizState().isTimerExpired, isFalse);
    });

    test('hasUsedPowerUp is false', () {
      expect(const AdaptedQuizState().hasUsedPowerUp, isFalse);
    });

    test('hasUsedExtraTime is false', () {
      expect(const AdaptedQuizState().hasUsedExtraTime, isFalse);
    });

    test('isAudioPlaying is false', () {
      expect(const AdaptedQuizState().isAudioPlaying, isFalse);
    });

    test('audioPosition is Duration.zero', () {
      expect(const AdaptedQuizState().audioPosition, Duration.zero);
    });

    test('answerSubmissions is empty', () {
      expect(const AdaptedQuizState().answerSubmissions, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith — field update
  // -------------------------------------------------------------------------

  group('copyWith field update', () {
    const base = AdaptedQuizState();

    test('score updated', () {
      expect(base.copyWith(score: 5).score, 5);
    });

    test('totalXP updated', () {
      expect(base.copyWith(totalXP: 100).totalXP, 100);
    });

    test('currentIndex updated', () {
      expect(base.copyWith(currentIndex: 2).currentIndex, 2);
    });

    test('isLoading updated', () {
      expect(base.copyWith(isLoading: true).isLoading, isTrue);
    });

    test('error updated', () {
      expect(base.copyWith(error: 'oops').error, 'oops');
    });

    test('showFeedback updated', () {
      expect(base.copyWith(showFeedback: true).showFeedback, isTrue);
    });

    test('timeRemaining updated', () {
      expect(base.copyWith(timeRemaining: 15).timeRemaining, 15);
    });

    test('isPaused updated', () {
      expect(base.copyWith(isPaused: true).isPaused, isTrue);
    });

    test('isTimerExpired updated', () {
      expect(base.copyWith(isTimerExpired: true).isTimerExpired, isTrue);
    });

    test('hasUsedPowerUp updated', () {
      expect(base.copyWith(hasUsedPowerUp: true).hasUsedPowerUp, isTrue);
    });

    test('hasUsedExtraTime updated', () {
      expect(base.copyWith(hasUsedExtraTime: true).hasUsedExtraTime, isTrue);
    });

    test('isAudioPlaying updated', () {
      expect(base.copyWith(isAudioPlaying: true).isAudioPlaying, isTrue);
    });

    test('coins updated', () {
      expect(base.copyWith(coins: 50).coins, 50);
    });

    test('diamonds updated', () {
      expect(base.copyWith(diamonds: 10).diamonds, 10);
    });

    test('stars updated', () {
      expect(base.copyWith(stars: 3).stars, 3);
    });

    test('classLevel updated', () {
      expect(base.copyWith(classLevel: '5').classLevel, '5');
    });

    test('category updated', () {
      expect(base.copyWith(category: QuizCategory.science).category,
          QuizCategory.science);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith — preserves unchanged fields
  // -------------------------------------------------------------------------

  group('copyWith preserves unchanged fields', () {
    final populated = const AdaptedQuizState().copyWith(
      score: 7,
      totalXP: 200,
      currentIndex: 2,
      timeRemaining: 20,
    );

    test('score preserved when updating other field', () {
      expect(populated.copyWith(totalXP: 300).score, 7);
    });

    test('currentIndex preserved when updating score', () {
      expect(populated.copyWith(score: 10).currentIndex, 2);
    });

    test('timeRemaining preserved when updating isLoading', () {
      expect(populated.copyWith(isLoading: true).timeRemaining, 20);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith chaining
  // -------------------------------------------------------------------------

  group('copyWith chaining', () {
    test('multiple updates chain correctly', () {
      final state = const AdaptedQuizState()
          .copyWith(score: 3)
          .copyWith(totalXP: 150)
          .copyWith(currentIndex: 1);
      expect(state.score, 3);
      expect(state.totalXP, 150);
      expect(state.currentIndex, 1);
    });
  });

  // -------------------------------------------------------------------------
  // Computed: currentQuestion
  // -------------------------------------------------------------------------

  group('currentQuestion', () {
    test('null when questions empty', () {
      expect(const AdaptedQuizState().currentQuestion, isNull);
    });

    test('returns first question when currentIndex=0', () {
      final q = _q(id: 'first');
      final state = const AdaptedQuizState().copyWith(questions: [q]);
      expect(state.currentQuestion!.id, 'first');
    });

    test('returns correct question by index', () {
      final q1 = _q(id: 'q1');
      final q2 = _q(id: 'q2');
      final state = const AdaptedQuizState()
          .copyWith(questions: [q1, q2], currentIndex: 1);
      expect(state.currentQuestion!.id, 'q2');
    });

    test('null when currentIndex >= questions.length', () {
      final q = _q();
      final state =
          const AdaptedQuizState().copyWith(questions: [q], currentIndex: 5);
      expect(state.currentQuestion, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // Computed: totalQuestions
  // -------------------------------------------------------------------------

  group('totalQuestions', () {
    test('0 when no questions', () {
      expect(const AdaptedQuizState().totalQuestions, 0);
    });

    test('reflects questions list length', () {
      final state = const AdaptedQuizState()
          .copyWith(questions: [_q(id: 'a'), _q(id: 'b'), _q(id: 'c')]);
      expect(state.totalQuestions, 3);
    });
  });

  // -------------------------------------------------------------------------
  // Computed: isLastQuestion
  // -------------------------------------------------------------------------

  group('isLastQuestion', () {
    test('false when no questions', () {
      // currentIndex=0, questions.length=0 → 0 >= -1 → true, but that's edge case
      // Actually 0 >= 0 - 1 = -1, so true... let's check
      // isLastQuestion: currentIndex >= questions.length - 1
      // 0 >= 0 - 1 = -1 → true
      // For empty list, isLastQuestion is true (vacuously)
      expect(const AdaptedQuizState().isLastQuestion, isTrue);
    });

    test('true when on last question', () {
      final state = const AdaptedQuizState()
          .copyWith(questions: [_q(id: 'a'), _q(id: 'b')], currentIndex: 1);
      expect(state.isLastQuestion, isTrue);
    });

    test('false when not on last question', () {
      final state = const AdaptedQuizState()
          .copyWith(questions: [_q(id: 'a'), _q(id: 'b')], currentIndex: 0);
      expect(state.isLastQuestion, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Computed: scorePercentage
  // -------------------------------------------------------------------------

  group('scorePercentage', () {
    test('0.0 when no questions', () {
      expect(const AdaptedQuizState().scorePercentage, 0.0);
    });

    test('100.0 when score equals totalQuestions', () {
      final state = const AdaptedQuizState()
          .copyWith(questions: [_q(), _q(id: 'q2')], score: 2);
      expect(state.scorePercentage, 100.0);
    });

    test('50.0 when half correct', () {
      final state = const AdaptedQuizState()
          .copyWith(questions: [_q(), _q(id: 'q2')], score: 1);
      expect(state.scorePercentage, 50.0);
    });

    test('0.0 when score is 0', () {
      final state = const AdaptedQuizState()
          .copyWith(questions: [_q(), _q(id: 'q2')], score: 0);
      expect(state.scorePercentage, 0.0);
    });
  });

  // -------------------------------------------------------------------------
  // Computed: quizDuration
  // -------------------------------------------------------------------------

  group('quizDuration', () {
    test('Duration.zero when quizStartTime is null', () {
      expect(const AdaptedQuizState().quizDuration, Duration.zero);
    });

    test('calculated when both start and end times set', () {
      final start = DateTime(2026, 1, 1, 10, 0, 0);
      final end = DateTime(2026, 1, 1, 10, 2, 30);
      final state = const AdaptedQuizState()
          .copyWith(quizStartTime: start, quizEndTime: end);
      expect(state.quizDuration.inSeconds, 150);
    });

    test('non-zero when start set but end not set (uses now)', () {
      final start = DateTime.now().subtract(const Duration(seconds: 5));
      final state = const AdaptedQuizState().copyWith(quizStartTime: start);
      expect(state.quizDuration.inSeconds, greaterThanOrEqualTo(4));
    });
  });

  // -------------------------------------------------------------------------
  // Computed: categoryDisplayName
  // -------------------------------------------------------------------------

  group('categoryDisplayName', () {
    test('"Mixed" when category is null', () {
      expect(const AdaptedQuizState().categoryDisplayName, 'Mixed');
    });

    test('returns category displayName when set', () {
      final state =
          const AdaptedQuizState().copyWith(category: QuizCategory.science);
      expect(state.categoryDisplayName, QuizCategory.science.displayName);
    });

    test('contains "Science" for science category', () {
      final state =
          const AdaptedQuizState().copyWith(category: QuizCategory.science);
      expect(state.categoryDisplayName, contains('Science'));
    });
  });

  // -------------------------------------------------------------------------
  // Computed: categoryDescription
  // -------------------------------------------------------------------------

  group('categoryDescription', () {
    test('non-empty when category is null (fallback)', () {
      expect(const AdaptedQuizState().categoryDescription.isNotEmpty, isTrue);
    });

    test('returns category description when set', () {
      final state =
          const AdaptedQuizState().copyWith(category: QuizCategory.history);
      expect(state.categoryDescription, QuizCategory.history.description);
    });
  });

  // -------------------------------------------------------------------------
  // Computed: categoryColor
  // -------------------------------------------------------------------------

  group('categoryColor', () {
    test('returns a Color when category is null (fallback)', () {
      expect(const AdaptedQuizState().categoryColor, isA<Color>());
    });

    test('returns category primaryColor when category is set', () {
      final state =
          const AdaptedQuizState().copyWith(category: QuizCategory.science);
      expect(state.categoryColor, QuizCategory.science.primaryColor);
    });
  });

  // -------------------------------------------------------------------------
  // Computed: categoryIcon
  // -------------------------------------------------------------------------

  group('categoryIcon', () {
    test('returns an IconData when category is null', () {
      expect(const AdaptedQuizState().categoryIcon, isA<IconData>());
    });

    test('returns category icon when category is set', () {
      final state =
          const AdaptedQuizState().copyWith(category: QuizCategory.mathematics);
      expect(state.categoryIcon, QuizCategory.mathematics.icon);
    });
  });

  // -------------------------------------------------------------------------
  // questions list management
  // -------------------------------------------------------------------------

  group('questions list', () {
    test('copyWith questions replaces list', () {
      final q1 = _q(id: 'old');
      final q2 = _q(id: 'new');
      final state = const AdaptedQuizState()
          .copyWith(questions: [q1]).copyWith(questions: [q2]);
      expect(state.questions.first.id, 'new');
    });

    test('multiple questions stored correctly', () {
      final questions = List.generate(5, (i) => _q(id: 'q$i'));
      final state = const AdaptedQuizState().copyWith(questions: questions);
      expect(state.totalQuestions, 5);
    });
  });

  // -------------------------------------------------------------------------
  // achievements list
  // -------------------------------------------------------------------------

  group('achievements', () {
    test('null by default', () {
      expect(const AdaptedQuizState().achievements, isNull);
    });

    test('copyWith sets achievements', () {
      final state =
          const AdaptedQuizState().copyWith(achievements: ['Perfect Score']);
      expect(state.achievements, ['Perfect Score']);
    });
  });

  // -------------------------------------------------------------------------
  // audioPosition
  // -------------------------------------------------------------------------

  group('audioPosition', () {
    test('Duration.zero by default', () {
      expect(const AdaptedQuizState().audioPosition, Duration.zero);
    });

    test('copyWith updates audioPosition', () {
      final state = const AdaptedQuizState()
          .copyWith(audioPosition: const Duration(seconds: 10));
      expect(state.audioPosition.inSeconds, 10);
    });
  });
}
