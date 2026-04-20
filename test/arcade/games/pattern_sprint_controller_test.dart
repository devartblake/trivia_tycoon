import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_difficulty.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_game_id.dart';
import 'package:trivia_tycoon/arcade/games/pattern_sprint/pattern_sprint_controller.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

PatternSprintController _ctrl({
  ArcadeDifficulty difficulty = ArcadeDifficulty.normal,
  int seed = 42,
}) =>
    PatternSprintController(difficulty: difficulty, rng: Random(seed));

/// Answer correctly [n] times, waiting 150 ms between each call so that
/// the 120 ms internal lock can reset.
Future<void> answerCorrectlyN(PatternSprintController ctrl, int n) async {
  for (int i = 0; i < n; i++) {
    ctrl.answer(ctrl.state.question.answer, (_) {});
    await Future<void>.delayed(const Duration(milliseconds: 150));
  }
}

/// Answer wrongly once (using a value guaranteed not to be the answer).
void answerWrong(PatternSprintController ctrl) {
  final wrong = ctrl.state.question.answer + 999;
  ctrl.answer(wrong, (_) {});
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // Initial state
  // -------------------------------------------------------------------------

  group('PatternSprintController initial state', () {
    test('score starts at 0', () {
      expect(_ctrl().state.score, 0);
    });

    test('streak and maxStreak start at 0', () {
      final c = _ctrl();
      expect(c.state.streak, 0);
      expect(c.state.maxStreak, 0);
    });

    test('correct and wrong start at 0', () {
      final c = _ctrl();
      expect(c.state.correct, 0);
      expect(c.state.wrong, 0);
    });

    test('questionsAnswered starts at 0', () {
      expect(_ctrl().state.questionsAnswered, 0);
    });

    test('isOver starts as false', () {
      expect(_ctrl().state.isOver, isFalse);
    });

    test('initial question has exactly 4 options', () {
      final c = _ctrl();
      expect(c.state.question.options.length, 4);
    });

    test('initial question answer is contained in options', () {
      final c = _ctrl();
      final q = c.state.question;
      expect(q.options.contains(q.answer), isTrue);
    });

    test('initial question sequence contains exactly one "?"', () {
      final c = _ctrl();
      final q = c.state.question;
      expect(q.sequence.where((s) => s == '?').length, 1);
    });

    test('"?" is at the missingIndex position', () {
      final c = _ctrl();
      final q = c.state.question;
      expect(q.sequence[q.missingIndex], '?');
    });

    test('initial question options have no duplicates', () {
      final c = _ctrl();
      final opts = c.state.question.options;
      expect(opts.toSet().length, opts.length);
    });
  });

  // -------------------------------------------------------------------------
  // answer() — correct answer
  // -------------------------------------------------------------------------

  group('PatternSprintController.answer() — correct', () {
    test('returns true for the correct answer', () {
      final c = _ctrl();
      final result = c.answer(c.state.question.answer, (_) {});
      expect(result, isTrue);
      c.dispose();
    });

    test('score increases after a correct answer', () {
      final c = _ctrl();
      c.answer(c.state.question.answer, (_) {});
      expect(c.state.score, greaterThan(0));
      c.dispose();
    });

    test('correct count increments', () {
      final c = _ctrl();
      c.answer(c.state.question.answer, (_) {});
      expect(c.state.correct, 1);
      c.dispose();
    });

    test('streak increments after correct answer', () {
      final c = _ctrl();
      c.answer(c.state.question.answer, (_) {});
      expect(c.state.streak, 1);
      c.dispose();
    });

    test('maxStreak increments after correct answer', () {
      final c = _ctrl();
      c.answer(c.state.question.answer, (_) {});
      expect(c.state.maxStreak, 1);
      c.dispose();
    });

    test('questionsAnswered increments', () {
      final c = _ctrl();
      c.answer(c.state.question.answer, (_) {});
      expect(c.state.questionsAnswered, 1);
      c.dispose();
    });

    test('a new question is generated after answering', () {
      final c = _ctrl();
      final oldAnswer = c.state.question.answer;
      final oldSequence = c.state.question.sequence;
      c.answer(c.state.question.answer, (_) {});
      // New question state is set even if question happens to have same answer
      // — the sequence reference changes
      expect(
        identical(c.state.question.sequence, oldSequence),
        isFalse,
        reason: 'A new question object should be generated',
      );
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // answer() — wrong answer
  // -------------------------------------------------------------------------

  group('PatternSprintController.answer() — wrong', () {
    test('returns false for a wrong answer', () {
      final c = _ctrl();
      final result = c.answer(c.state.question.answer + 999, (_) {});
      expect(result, isFalse);
      c.dispose();
    });

    test('wrong count increments', () {
      final c = _ctrl();
      answerWrong(c);
      expect(c.state.wrong, 1);
      c.dispose();
    });

    test('streak resets to 0 after a wrong answer', () async {
      final c = _ctrl();
      c.answer(c.state.question.answer, (_) {}); // correct → streak=1
      await Future<void>.delayed(const Duration(milliseconds: 150));
      answerWrong(c); // wrong → streak=0
      expect(c.state.streak, 0);
      c.dispose();
    });

    test('score never goes below 0 from a penalty (starting at 0)', () {
      final c = _ctrl();
      answerWrong(c);
      expect(c.state.score, greaterThanOrEqualTo(0));
      c.dispose();
    });

    test('questionsAnswered still increments on wrong answer', () {
      final c = _ctrl();
      answerWrong(c);
      expect(c.state.questionsAnswered, 1);
      c.dispose();
    });

    test('correct count does not increase on wrong answer', () {
      final c = _ctrl();
      answerWrong(c);
      expect(c.state.correct, 0);
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Streak multiplier
  // -------------------------------------------------------------------------

  group('PatternSprintController — streak multiplier', () {
    test('maxStreak tracks the highest consecutive correct count', () async {
      final c = _ctrl();
      await answerCorrectlyN(c, 3);
      expect(c.state.maxStreak, 3);
      c.dispose();
    });

    test('maxStreak is preserved after a wrong answer breaks the streak',
        () async {
      final c = _ctrl();
      await answerCorrectlyN(c, 3); // maxStreak = 3
      await Future<void>.delayed(const Duration(milliseconds: 150));
      answerWrong(c); // streak resets; maxStreak stays 3
      expect(c.state.maxStreak, 3);
      expect(c.state.streak, 0);
      c.dispose();
    });

    test('second correct answer scores at least as much as first', () async {
      final c = _ctrl();
      // First correct answer
      c.answer(c.state.question.answer, (_) {});
      final scoreAfterFirst = c.state.score;

      await Future<void>.delayed(const Duration(milliseconds: 150));

      // Second correct answer (higher streak multiplier)
      c.answer(c.state.question.answer, (_) {});
      final scoreGainedOnSecond = c.state.score - scoreAfterFirst;

      expect(scoreGainedOnSecond, greaterThanOrEqualTo(scoreAfterFirst),
          reason: 'Streak multiplier should make second answer score >= first');
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Lock behaviour
  // -------------------------------------------------------------------------

  group('PatternSprintController — answer lock', () {
    test('answer() returns false when called while locked', () {
      final c = _ctrl();
      c.answer(c.state.question.answer, (_) {}); // sets _locked=true
      // Immediately calling again while locked → should return false
      final result = c.answer(c.state.question.answer, (_) {});
      expect(result, isFalse);
      c.dispose();
    });

    test('answer() works again after 120 ms lock expires', () async {
      final c = _ctrl();
      c.answer(c.state.question.answer, (_) {});
      await Future<void>.delayed(const Duration(milliseconds: 150));
      final result = c.answer(c.state.question.answer, (_) {});
      expect(result, isTrue);
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // Question generation across difficulties
  // -------------------------------------------------------------------------

  group('PatternSprintController — question generation', () {
    for (final diff in ArcadeDifficulty.values) {
      test('$diff: answer is in options', () {
        final c = PatternSprintController(difficulty: diff, rng: Random(99));
        for (int i = 0; i < 10; i++) {
          final q = c.state.question;
          expect(q.options.contains(q.answer), isTrue,
              reason:
                  'Answer ${q.answer} not in options ${q.options} on $diff');
          c.answer(q.answer, (_) {});
        }
        c.dispose();
      });

      test('$diff: options have no duplicates', () {
        final c = PatternSprintController(difficulty: diff, rng: Random(7));
        for (int i = 0; i < 10; i++) {
          final opts = c.state.question.options;
          expect(opts.toSet().length, opts.length,
              reason: 'Duplicate options found on $diff: $opts');
          c.answer(c.state.question.answer, (_) {});
        }
        c.dispose();
      });

      test('$diff: sequence contains exactly one "?"', () {
        final c = PatternSprintController(difficulty: diff, rng: Random(3));
        final q = c.state.question;
        expect(q.sequence.where((s) => s == '?').length, 1);
        c.dispose();
      });
    }
  });

  // -------------------------------------------------------------------------
  // toResult()
  // -------------------------------------------------------------------------

  group('PatternSprintController.toResult()', () {
    test('gameId is ArcadeGameId.patternSprint', () {
      expect(_ctrl().toResult().gameId, ArcadeGameId.patternSprint);
    });

    test('difficulty matches the constructed difficulty', () {
      final c = PatternSprintController(
        difficulty: ArcadeDifficulty.hard,
        rng: Random(1),
      );
      expect(c.toResult().difficulty, ArcadeDifficulty.hard);
      c.dispose();
    });

    test('metadata contains required keys', () async {
      final c = _ctrl();
      c.answer(c.state.question.answer, (_) {});
      await Future<void>.delayed(const Duration(milliseconds: 150));
      answerWrong(c);
      final meta = c.toResult().metadata;
      expect(meta.containsKey('correct'), isTrue);
      expect(meta.containsKey('wrong'), isTrue);
      expect(meta.containsKey('questionsAnswered'), isTrue);
      expect(meta.containsKey('maxStreak'), isTrue);
      expect(meta.containsKey('accuracy'), isTrue);
      c.dispose();
    });

    test('accuracy is 0 when no questions answered', () {
      expect(_ctrl().toResult().metadata['accuracy'], 0.0);
    });

    test('accuracy is 1.0 after all correct answers', () async {
      final c = _ctrl();
      await answerCorrectlyN(c, 5);
      final accuracy = c.toResult().metadata['accuracy'] as double;
      expect(accuracy, closeTo(1.0, 0.001));
      c.dispose();
    });

    test('accuracy is 0.5 with equal correct and wrong', () async {
      final c = _ctrl();
      c.answer(c.state.question.answer, (_) {}); // correct
      await Future<void>.delayed(const Duration(milliseconds: 150));
      answerWrong(c); // wrong
      final accuracy = c.toResult().metadata['accuracy'] as double;
      expect(accuracy, closeTo(0.5, 0.001));
      c.dispose();
    });

    test('result score matches state score', () async {
      final c = _ctrl();
      await answerCorrectlyN(c, 3);
      expect(c.toResult().score, c.state.score);
      c.dispose();
    });
  });

  // -------------------------------------------------------------------------
  // dispose()
  // -------------------------------------------------------------------------

  group('PatternSprintController.dispose()', () {
    test('does not throw', () {
      expect(() => _ctrl().dispose(), returnsNormally);
    });

    test('can be called multiple times without throwing', () {
      final c = _ctrl();
      c.dispose();
      expect(() => c.dispose(), returnsNormally);
    });
  });
}
