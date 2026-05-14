import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/state/energy_state.dart';
import 'package:trivia_tycoon/game/state/lives_state.dart';
import 'package:trivia_tycoon/game/state/premium_profile_state.dart';
import 'package:trivia_tycoon/game/state/tier_update_result.dart';
import 'package:trivia_tycoon/game/state/question_state.dart';
import 'package:trivia_tycoon/game/state/tier_progression_state.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import 'package:trivia_tycoon/game/models/answer.dart';

QuestionModel _q({
  String id = 'q1',
  String correct = 'A',
  List<String> options = const ['A', 'B', 'C', 'D'],
  int correctIndex = 0,
}) =>
    QuestionModel(
      id: id,
      category: 'test',
      question: 'What?',
      answers: const <Answer>[],
      correctAnswer: correct,
      type: 'text',
      difficulty: 1,
      options: options,
      correctIndex: correctIndex,
    );

void main() {
  // -------------------------------------------------------------------------
  // EnergyState
  // -------------------------------------------------------------------------

  group('EnergyState', () {
    test('stores current and max', () {
      final s = EnergyState(current: 3, max: 5);
      expect(s.current, 3);
      expect(s.max, 5);
    });

    test('lastRefill defaults to null', () {
      expect(EnergyState(current: 0, max: 5).lastRefill, isNull);
    });

    test('stores lastRefill when provided', () {
      final dt = DateTime(2026, 1, 1);
      expect(EnergyState(current: 5, max: 5, lastRefill: dt).lastRefill, dt);
    });
  });

  // -------------------------------------------------------------------------
  // LivesState
  // -------------------------------------------------------------------------

  group('LivesState', () {
    test('stores current and max', () {
      final s = LivesState(current: 2, max: 3);
      expect(s.current, 2);
      expect(s.max, 3);
    });

    test('lastRefill defaults to null', () {
      expect(LivesState(current: 0, max: 3).lastRefill, isNull);
    });

    test('stores lastRefill when provided', () {
      final dt = DateTime(2026, 6, 1);
      expect(LivesState(current: 1, max: 3, lastRefill: dt).lastRefill, dt);
    });
  });

  // -------------------------------------------------------------------------
  // PremiumStatus
  // -------------------------------------------------------------------------

  group('PremiumStatus', () {
    test('stores isPremium and discountPercent', () {
      final s = PremiumStatus(isPremium: true, discountPercent: 20);
      expect(s.isPremium, isTrue);
      expect(s.discountPercent, 20);
    });

    test('expiryDate defaults to null', () {
      final s = PremiumStatus(isPremium: false, discountPercent: 0);
      expect(s.expiryDate, isNull);
    });

    test('stores expiryDate when provided', () {
      final dt = DateTime(2026, 12, 31);
      final s = PremiumStatus(isPremium: true, discountPercent: 10, expiryDate: dt);
      expect(s.expiryDate, dt);
    });
  });

  // -------------------------------------------------------------------------
  // TierUpdateResult
  // -------------------------------------------------------------------------

  group('TierUpdateResult', () {
    test('stores oldTierId and newTierId', () {
      const r = TierUpdateResult(
        oldTierId: 1,
        newTierId: 2,
        tierChanged: true,
        newUnlocks: [],
      );
      expect(r.oldTierId, 1);
      expect(r.newTierId, 2);
    });

    test('tierChanged is stored correctly', () {
      const r = TierUpdateResult(
          oldTierId: 0, newTierId: 0, tierChanged: false, newUnlocks: []);
      expect(r.tierChanged, isFalse);
    });

    test('hasNewUnlocks is false for empty list', () {
      const r = TierUpdateResult(
          oldTierId: 0, newTierId: 1, tierChanged: true, newUnlocks: []);
      expect(r.hasNewUnlocks, isFalse);
    });

    test('same oldTierId and newTierId with tierChanged false is valid', () {
      const r = TierUpdateResult(
          oldTierId: 5, newTierId: 5, tierChanged: false, newUnlocks: []);
      expect(r.tierChanged, isFalse);
      expect(r.oldTierId, r.newTierId);
    });
  });

  // -------------------------------------------------------------------------
  // QuestionState
  // -------------------------------------------------------------------------

  group('QuestionState', () {
    test('default constructor has empty questions and zero score', () {
      const s = QuestionState();
      expect(s.questions, isEmpty);
      expect(s.score, 0);
      expect(s.currentIndex, 0);
    });

    test('QuestionState.initial() returns default state', () {
      final s = QuestionState.initial();
      expect(s.questions, isEmpty);
      expect(s.timeLeft, 30);
      expect(s.score, 0);
    });

    test('currentQuestion is null for empty questions', () {
      expect(const QuestionState().currentQuestion, isNull);
    });

    test('currentQuestion returns first question at index 0', () {
      final q = _q();
      final s = QuestionState(questions: [q]);
      expect(s.currentQuestion?.id, 'q1');
    });

    test('currentQuestion returns nth question', () {
      final q1 = _q(id: 'q1');
      final q2 = _q(id: 'q2');
      final s = QuestionState(questions: [q1, q2], currentIndex: 1);
      expect(s.currentQuestion?.id, 'q2');
    });

    test('currentQuestion is null when index is out of bounds', () {
      final s = QuestionState(questions: [_q()], currentIndex: 5);
      expect(s.currentQuestion, isNull);
    });

    test('isQuizOver is true when index >= questions.length', () {
      final s = QuestionState(questions: [_q()], currentIndex: 1);
      expect(s.isQuizOver, isTrue);
    });

    test('isQuizOver is false when index < questions.length', () {
      final s = QuestionState(questions: [_q()], currentIndex: 0);
      expect(s.isQuizOver, isFalse);
    });

    test('isQuizOver is true for empty questions list', () {
      expect(const QuestionState().isQuizOver, isTrue);
    });

    test('accuracy is 0.0 when totalAnswered is 0', () {
      expect(const QuestionState().accuracy, 0.0);
    });

    test('accuracy is 1.0 when all answered correctly', () {
      final s = QuestionState(correctCount: 5, totalAnswered: 5);
      expect(s.accuracy, 1.0);
    });

    test('accuracy is 0.5 when half answered correctly', () {
      final s = QuestionState(correctCount: 3, totalAnswered: 6);
      expect(s.accuracy, closeTo(0.5, 0.001));
    });

    test('copyWith updates score', () {
      final s = const QuestionState().copyWith(score: 100);
      expect(s.score, 100);
    });

    test('copyWith updates currentIndex', () {
      final s = const QuestionState().copyWith(currentIndex: 3);
      expect(s.currentIndex, 3);
    });

    test('copyWith updates selectedAnswer', () {
      final s = const QuestionState().copyWith(selectedAnswer: 'B');
      expect(s.selectedAnswer, 'B');
    });

    test('copyWith updates powerUpUsed', () {
      final s = const QuestionState().copyWith(powerUpUsed: true);
      expect(s.powerUpUsed, isTrue);
    });

    test('copyWith updates streakCount, correctCount, totalAnswered', () {
      final s = const QuestionState()
          .copyWith(streakCount: 3, correctCount: 5, totalAnswered: 7);
      expect(s.streakCount, 3);
      expect(s.correctCount, 5);
      expect(s.totalAnswered, 7);
    });

    test('copyWith preserves unchanged fields', () {
      final base = QuestionState(
          questions: [_q()], score: 50, diamonds: 10, money: 100);
      final updated = base.copyWith(score: 200);
      expect(updated.questions.length, 1);
      expect(updated.diamonds, 10);
      expect(updated.money, 100);
    });
  });

  // -------------------------------------------------------------------------
  // TierProgressionState
  // -------------------------------------------------------------------------

  group('TierProgressionState', () {
    test('default state has isUpdating=false, no lastUpdate, no error', () {
      const s = TierProgressionState();
      expect(s.isUpdating, isFalse);
      expect(s.lastUpdate, isNull);
      expect(s.error, isNull);
    });

    test('copyWith updates isUpdating', () {
      const s = TierProgressionState();
      final updated = s.copyWith(isUpdating: true);
      expect(updated.isUpdating, isTrue);
    });

    test('copyWith updates error', () {
      const s = TierProgressionState();
      final updated = s.copyWith(error: 'oops');
      expect(updated.error, 'oops');
    });

    test('copyWith preserves unchanged fields', () {
      const s = TierProgressionState(isUpdating: true, error: 'e');
      final updated = s.copyWith(isUpdating: false);
      expect(updated.error, 'e');
    });

    test('equality: two default states are equal', () {
      const s1 = TierProgressionState();
      const s2 = TierProgressionState();
      expect(s1, equals(s2));
    });

    test('equality: states with different isUpdating are not equal', () {
      const s1 = TierProgressionState(isUpdating: true);
      const s2 = TierProgressionState(isUpdating: false);
      expect(s1, isNot(equals(s2)));
    });

    test('equality: states with different errors are not equal', () {
      const s1 = TierProgressionState(error: 'err');
      const s2 = TierProgressionState(error: null);
      expect(s1, isNot(equals(s2)));
    });

    test('toString contains class name', () {
      expect(const TierProgressionState().toString(),
          contains('TierProgressionState'));
    });

    test('hashCode is consistent for equal states', () {
      const s1 = TierProgressionState();
      const s2 = TierProgressionState();
      expect(s1.hashCode, s2.hashCode);
    });
  });
}
