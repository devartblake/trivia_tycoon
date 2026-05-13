import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/question_validation_models.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import 'package:trivia_tycoon/game/state/quiz_state.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

QuestionModel _question({
  String id = 'q1',
  String category = 'science',
  String question = 'What is H2O?',
  String correctAnswer = 'Water',
  int correctIndex = 0,
}) {
  return QuestionModel(
    id: id,
    category: category,
    question: question,
    answers: const [],
    correctAnswer: correctAnswer,
    type: 'multiple_choice',
    difficulty: 1,
    options: const ['Water', 'Fire', 'Earth', 'Air'],
    correctIndex: correctIndex,
  );
}

void main() {
  // -------------------------------------------------------------------------
  // Default constructor
  // -------------------------------------------------------------------------

  group('AdaptedQuizState — default values', () {
    test('default state has expected values', () {
      const state = AdaptedQuizState();

      expect(state.questions, isEmpty);
      expect(state.currentIndex, 0);
      expect(state.score, 0);
      expect(state.totalXP, 0);
      expect(state.coins, isNull);
      expect(state.diamonds, isNull);
      expect(state.stars, isNull);
      expect(state.classLevel, '1');
      expect(state.category, isNull);
      expect(state.isLoading, isFalse);
      expect(state.error, isNull);
      expect(state.selectedAnswer, isNull);
      expect(state.showFeedback, isFalse);
      expect(state.timeRemaining, 30);
      expect(state.isPaused, isFalse);
      expect(state.isTimerExpired, isFalse);
      expect(state.hasUsedPowerUp, isFalse);
      expect(state.hasUsedExtraTime, isFalse);
      expect(state.isAudioPlaying, isFalse);
      expect(state.audioPosition, Duration.zero);
      expect(state.audioDuration, isNull);
      expect(state.categoryScores, isNull);
      expect(state.achievements, isNull);
      expect(state.quizStartTime, isNull);
      expect(state.quizEndTime, isNull);
      expect(state.stopwatch, isNull);
      expect(state.answerSubmissions, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith — each field individually
  // -------------------------------------------------------------------------

  group('AdaptedQuizState.copyWith — numeric fields', () {
    test('copies score', () {
      const s = AdaptedQuizState(score: 0);
      expect(s.copyWith(score: 5).score, 5);
    });

    test('copies totalXP', () {
      const s = AdaptedQuizState();
      expect(s.copyWith(totalXP: 100).totalXP, 100);
    });

    test('copies currentIndex', () {
      const s = AdaptedQuizState();
      expect(s.copyWith(currentIndex: 3).currentIndex, 3);
    });

    test('copies timeRemaining', () {
      const s = AdaptedQuizState();
      expect(s.copyWith(timeRemaining: 15).timeRemaining, 15);
    });

    test('copies coins', () {
      expect(const AdaptedQuizState().copyWith(coins: 50).coins, 50);
    });

    test('copies diamonds', () {
      expect(const AdaptedQuizState().copyWith(diamonds: 3).diamonds, 3);
    });

    test('copies stars', () {
      expect(const AdaptedQuizState().copyWith(stars: 2).stars, 2);
    });
  });

  group('AdaptedQuizState.copyWith — bool fields', () {
    test('copies isLoading', () {
      expect(
          const AdaptedQuizState().copyWith(isLoading: true).isLoading, isTrue);
    });

    test('copies showFeedback', () {
      expect(
          const AdaptedQuizState().copyWith(showFeedback: true).showFeedback,
          isTrue);
    });

    test('copies isPaused', () {
      expect(const AdaptedQuizState().copyWith(isPaused: true).isPaused,
          isTrue);
    });

    test('copies isTimerExpired', () {
      expect(
          const AdaptedQuizState()
              .copyWith(isTimerExpired: true)
              .isTimerExpired,
          isTrue);
    });

    test('copies hasUsedPowerUp', () {
      expect(
          const AdaptedQuizState()
              .copyWith(hasUsedPowerUp: true)
              .hasUsedPowerUp,
          isTrue);
    });

    test('copies hasUsedExtraTime', () {
      expect(
          const AdaptedQuizState()
              .copyWith(hasUsedExtraTime: true)
              .hasUsedExtraTime,
          isTrue);
    });

    test('copies isAudioPlaying', () {
      expect(
          const AdaptedQuizState()
              .copyWith(isAudioPlaying: true)
              .isAudioPlaying,
          isTrue);
    });
  });

  group('AdaptedQuizState.copyWith — string fields', () {
    test('copies classLevel', () {
      expect(
          const AdaptedQuizState().copyWith(classLevel: '3').classLevel, '3');
    });

    test('copies error', () {
      expect(const AdaptedQuizState().copyWith(error: 'oops').error, 'oops');
    });

    test('copies selectedAnswer', () {
      expect(
          const AdaptedQuizState()
              .copyWith(selectedAnswer: 'B')
              .selectedAnswer,
          'B');
    });
  });

  group('AdaptedQuizState.copyWith — collection fields', () {
    test('copies questions list', () {
      final q = _question();
      final updated = const AdaptedQuizState().copyWith(questions: [q]);
      expect(updated.questions.length, 1);
      expect(updated.questions.first.id, 'q1');
    });

    test('copies answerSubmissions', () {
      final q = _question();
      final submission = QuestionAnswerSubmission(
        question: q,
        selectedAnswer: 'Water',
      );
      final updated =
          const AdaptedQuizState().copyWith(answerSubmissions: [submission]);
      expect(updated.answerSubmissions.length, 1);
      expect(updated.answerSubmissions.first.selectedAnswer, 'Water');
    });

    test('copies categoryScores', () {
      final updated = const AdaptedQuizState()
          .copyWith(categoryScores: {'science': 3, 'math': 1});
      expect(updated.categoryScores!['science'], 3);
    });

    test('copies achievements', () {
      final updated = const AdaptedQuizState()
          .copyWith(achievements: ['first_win', 'streak_5']);
      expect(updated.achievements, ['first_win', 'streak_5']);
    });
  });

  group('AdaptedQuizState.copyWith — DateTime / Duration fields', () {
    test('copies quizStartTime', () {
      final ts = DateTime(2025, 5, 1);
      final updated = const AdaptedQuizState().copyWith(quizStartTime: ts);
      expect(updated.quizStartTime, ts);
    });

    test('copies quizEndTime', () {
      final ts = DateTime(2025, 5, 1, 1);
      final updated = const AdaptedQuizState().copyWith(quizEndTime: ts);
      expect(updated.quizEndTime, ts);
    });

    test('copies audioPosition', () {
      const pos = Duration(seconds: 15);
      final updated =
          const AdaptedQuizState().copyWith(audioPosition: pos);
      expect(updated.audioPosition, pos);
    });

    test('copies audioDuration', () {
      const dur = Duration(minutes: 2);
      final updated =
          const AdaptedQuizState().copyWith(audioDuration: dur);
      expect(updated.audioDuration, dur);
    });
  });

  group('AdaptedQuizState.copyWith — preserves unchanged fields', () {
    test('non-copied fields retain original values', () {
      const original = AdaptedQuizState(
        score: 10,
        totalXP: 50,
        classLevel: '5',
        isLoading: false,
      );
      final updated = original.copyWith(score: 20);

      expect(updated.totalXP, 50);
      expect(updated.classLevel, '5');
      expect(updated.isLoading, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // Computed properties
  // -------------------------------------------------------------------------

  group('AdaptedQuizState — currentQuestion', () {
    test('returns null when questions list is empty', () {
      expect(const AdaptedQuizState().currentQuestion, isNull);
    });

    test('returns first question at index 0', () {
      final q = _question(id: 'q1');
      final state = AdaptedQuizState(questions: [q], currentIndex: 0);
      expect(state.currentQuestion?.id, 'q1');
    });

    test('returns correct question at non-zero index', () {
      final q0 = _question(id: 'q0');
      final q1 = _question(id: 'q1');
      final state = AdaptedQuizState(questions: [q0, q1], currentIndex: 1);
      expect(state.currentQuestion?.id, 'q1');
    });

    test('returns null when index equals questions length', () {
      final q = _question();
      final state = AdaptedQuizState(questions: [q], currentIndex: 1);
      expect(state.currentQuestion, isNull);
    });
  });

  group('AdaptedQuizState — totalQuestions', () {
    test('returns 0 for empty state', () {
      expect(const AdaptedQuizState().totalQuestions, 0);
    });

    test('returns length of questions list', () {
      final state = AdaptedQuizState(
          questions: [_question(id: 'a'), _question(id: 'b')]);
      expect(state.totalQuestions, 2);
    });
  });

  group('AdaptedQuizState — isLastQuestion', () {
    test('true for empty list (index 0 >= length 0 - 1 = -1)', () {
      // 0 >= 0 - 1 = -1 → true
      expect(const AdaptedQuizState().isLastQuestion, isTrue);
    });

    test('true when on the last question', () {
      final state = AdaptedQuizState(
        questions: [_question(id: 'a'), _question(id: 'b')],
        currentIndex: 1,
      );
      expect(state.isLastQuestion, isTrue);
    });

    test('false when not on last question', () {
      final state = AdaptedQuizState(
        questions: [_question(id: 'a'), _question(id: 'b')],
        currentIndex: 0,
      );
      expect(state.isLastQuestion, isFalse);
    });
  });

  group('AdaptedQuizState — scorePercentage', () {
    test('returns 0.0 when totalQuestions is 0', () {
      expect(const AdaptedQuizState().scorePercentage, 0.0);
    });

    test('returns 100.0 when score equals totalQuestions', () {
      final state = AdaptedQuizState(
        questions: [_question(id: 'a'), _question(id: 'b')],
        score: 2,
      );
      expect(state.scorePercentage, 100.0);
    });

    test('returns 50.0 for half correct', () {
      final state = AdaptedQuizState(
        questions: [_question(id: 'a'), _question(id: 'b')],
        score: 1,
      );
      expect(state.scorePercentage, 50.0);
    });

    test('returns 0.0 when score is 0', () {
      final state = AdaptedQuizState(
        questions: [_question()],
        score: 0,
      );
      expect(state.scorePercentage, 0.0);
    });
  });

  group('AdaptedQuizState — quizDuration', () {
    test('returns Duration.zero when quizStartTime is null', () {
      expect(const AdaptedQuizState().quizDuration, Duration.zero);
    });

    test('returns difference between start and end times', () {
      final start = DateTime(2025, 1, 1, 10, 0);
      final end = DateTime(2025, 1, 1, 10, 5); // 5 minutes later
      final state = AdaptedQuizState(
        quizStartTime: start,
        quizEndTime: end,
      );
      expect(state.quizDuration.inMinutes, 5);
    });

    test('uses DateTime.now() when quizEndTime is null', () {
      final start = DateTime.now().subtract(const Duration(seconds: 10));
      final state = AdaptedQuizState(quizStartTime: start);
      expect(state.quizDuration.inSeconds, greaterThanOrEqualTo(9));
    });
  });

  group('AdaptedQuizState — categoryDisplayName', () {
    test('returns "Mixed" when category is null', () {
      expect(const AdaptedQuizState().categoryDisplayName, 'Mixed');
    });
  });
}
