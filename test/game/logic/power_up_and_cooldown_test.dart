import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/logic/power_up_effect_applier.dart';
import 'package:trivia_tycoon/game/logic/skill_cooldown_handler.dart';
import 'package:trivia_tycoon/game/models/power_up.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';
import 'package:trivia_tycoon/game/models/answer.dart';
import 'package:trivia_tycoon/game/models/question_type.dart' as qtype;
import 'package:trivia_tycoon/game/models/question_difficulty.dart' as qdiff;

QuestionModel _baseQuestion({List<String>? options}) => QuestionModel(
      id: 'q1',
      category: 'test',
      question: 'Which is correct?',
      answers: const <Answer>[],
      correctAnswer: 'A',
      type: qtype.QuestionTypeExtension.fromString('text'),
      difficulty: qdiff.QuestionDifficultyExtension.fromInt(1),
      options: options ?? const ['A', 'B', 'C', 'D'],
      correctIndex: 0,
    );

PowerUp _powerUp(String type) => PowerUp(
      id: 'pu_$type',
      name: type,
      description: '',
      iconPath: '',
      duration: 60,
      price: 10,
      currency: 'coins',
      type: type,
    );

void main() {
  // -------------------------------------------------------------------------
  // PowerUpEffectApplier
  // -------------------------------------------------------------------------

  group('PowerUpEffectApplier', () {
    test('null powerUp returns question unchanged', () {
      final q = _baseQuestion();
      final result = PowerUpEffectApplier.apply(null, q);
      expect(identical(result, q), isTrue);
    });

    test('powerUp with id="none" returns question unchanged', () {
      final q = _baseQuestion();
      final result = PowerUpEffectApplier.apply(PowerUp.none(), q);
      expect(identical(result, q), isTrue);
    });

    test('type "hint" sets showHint to true', () {
      final q = _baseQuestion();
      final result = PowerUpEffectApplier.apply(_powerUp('hint'), q);
      expect(result.showHint, isTrue);
    });

    test('type "hint" does not change other fields', () {
      final q = _baseQuestion();
      final result = PowerUpEffectApplier.apply(_powerUp('hint'), q);
      expect(result.id, q.id);
      expect(result.options, q.options);
      expect(result.multiplier, isNull);
    });

    test('type "xp" sets multiplier to 2', () {
      final q = _baseQuestion();
      final result = PowerUpEffectApplier.apply(_powerUp('xp'), q);
      expect(result.multiplier, 2);
    });

    test('type "boost" sets isBoostedTime to true', () {
      final q = _baseQuestion();
      final result = PowerUpEffectApplier.apply(_powerUp('boost'), q);
      expect(result.isBoostedTime, isTrue);
    });

    test('type "shield" sets isShielded to true', () {
      final q = _baseQuestion();
      final result = PowerUpEffectApplier.apply(_powerUp('shield'), q);
      expect(result.isShielded, isTrue);
    });

    test('type "eliminate" reduces options and keeps correct answer', () {
      final q = _baseQuestion(); // options: ['A','B','C','D'], correct: 'A'
      final result = PowerUpEffectApplier.apply(_powerUp('eliminate'), q);
      expect(result.reducedOptions, isNotNull);
      expect(result.reducedOptions!.length, 2);
      expect(result.reducedOptions!, contains('A'));
    });

    test('type "eliminate" with only correct answer returns question unchanged',
        () {
      final q = _baseQuestion(options: const ['A']); // only correct answer
      final result = PowerUpEffectApplier.apply(_powerUp('eliminate'), q);
      expect(identical(result, q), isTrue);
    });

    test('type uppercase "HINT" is lowercased and applies hint', () {
      final q = _baseQuestion();
      final result = PowerUpEffectApplier.apply(_powerUp('HINT'), q);
      expect(result.showHint, isTrue);
    });

    test('unknown type returns question unchanged', () {
      final q = _baseQuestion();
      final result = PowerUpEffectApplier.apply(_powerUp('unknown_type'), q);
      expect(identical(result, q), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // SkillCooldownHandler
  // -------------------------------------------------------------------------

  group('SkillCooldownHandler', () {
    late SkillCooldownHandler handler;

    setUp(() {
      handler = SkillCooldownHandler();
    });

    test('isOnCooldown returns false before any cooldown is set', () {
      expect(handler.isOnCooldown('skill_x'), isFalse);
    });

    test('remaining returns null before cooldown is set', () {
      expect(handler.remaining('skill_x'), isNull);
    });

    test('isOnCooldown returns true after setCooldown', () {
      handler.setCooldown('skill_x', const Duration(minutes: 1));
      expect(handler.isOnCooldown('skill_x'), isTrue);
    });

    test('remaining returns positive Duration after setCooldown', () {
      handler.setCooldown('skill_x', const Duration(minutes: 1));
      final rem = handler.remaining('skill_x');
      expect(rem, isNotNull);
      expect(rem!.inSeconds, isPositive);
    });

    test('clearCooldown removes the cooldown', () {
      handler.setCooldown('skill_x', const Duration(minutes: 1));
      handler.clearCooldown('skill_x');
      expect(handler.isOnCooldown('skill_x'), isFalse);
    });

    test('clearCooldown on unknown skill does not throw', () {
      expect(() => handler.clearCooldown('nonexistent'), returnsNormally);
    });

    test('resetAll clears all cooldowns', () {
      handler.setCooldown('skill_a', const Duration(minutes: 1));
      handler.setCooldown('skill_b', const Duration(minutes: 2));
      handler.resetAll();
      expect(handler.isOnCooldown('skill_a'), isFalse);
      expect(handler.isOnCooldown('skill_b'), isFalse);
    });

    test('multiple skills are tracked independently', () {
      handler.setCooldown('skill_a', const Duration(minutes: 5));
      expect(handler.isOnCooldown('skill_a'), isTrue);
      expect(handler.isOnCooldown('skill_b'), isFalse);
    });

    test('clearCooldown for one skill does not affect others', () {
      handler.setCooldown('skill_a', const Duration(minutes: 1));
      handler.setCooldown('skill_b', const Duration(minutes: 1));
      handler.clearCooldown('skill_a');
      expect(handler.isOnCooldown('skill_a'), isFalse);
      expect(handler.isOnCooldown('skill_b'), isTrue);
    });
  });
}
