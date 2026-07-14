import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/question_difficulty.dart';

void main() {
  group('QuestionDifficulty', () {
    test('Enum values are correctly defined', () {
      expect(QuestionDifficulty.easy, isNotNull);
      expect(QuestionDifficulty.medium, isNotNull);
      expect(QuestionDifficulty.hard, isNotNull);
      expect(QuestionDifficulty.expert, isNotNull);
      expect(QuestionDifficulty.boss, isNotNull);
    });

    group('value getter', () {
      test('Returns correct numeric values', () {
        expect(QuestionDifficulty.easy.value, equals(1));
        expect(QuestionDifficulty.medium.value, equals(2));
        expect(QuestionDifficulty.hard.value, equals(3));
        expect(QuestionDifficulty.expert.value, equals(4));
        expect(QuestionDifficulty.boss.value, equals(5));
      });
    });

    group('displayName getter', () {
      test('Returns user-friendly display names', () {
        expect(QuestionDifficulty.easy.displayName, equals('Easy'));
        expect(QuestionDifficulty.medium.displayName, equals('Medium'));
        expect(QuestionDifficulty.hard.displayName, equals('Hard'));
        expect(QuestionDifficulty.expert.displayName, equals('Expert'));
        expect(QuestionDifficulty.boss.displayName, equals('Boss'));
      });
    });

    group('xpMultiplier getter', () {
      test('Returns correct XP multipliers', () {
        expect(QuestionDifficulty.easy.xpMultiplier, equals(1.0));
        expect(QuestionDifficulty.medium.xpMultiplier, equals(1.5));
        expect(QuestionDifficulty.hard.xpMultiplier, equals(2.0));
        expect(QuestionDifficulty.expert.xpMultiplier, equals(3.0));
        expect(QuestionDifficulty.boss.xpMultiplier, equals(5.0));
      });

      test('Multipliers scale progressively', () {
        expect(
          QuestionDifficulty.medium.xpMultiplier >
              QuestionDifficulty.easy.xpMultiplier,
          isTrue,
        );
        expect(
          QuestionDifficulty.boss.xpMultiplier >
              QuestionDifficulty.expert.xpMultiplier,
          isTrue,
        );
      });
    });

    group('coinMultiplier getter', () {
      test('Returns correct coin multipliers', () {
        expect(QuestionDifficulty.easy.coinMultiplier, equals(1.0));
        expect(QuestionDifficulty.medium.coinMultiplier, equals(1.25));
        expect(QuestionDifficulty.hard.coinMultiplier, equals(1.5));
        expect(QuestionDifficulty.expert.coinMultiplier, equals(2.0));
        expect(QuestionDifficulty.boss.coinMultiplier, equals(3.0));
      });
    });

    group('streakMultiplier getter', () {
      test('Returns correct streak multipliers', () {
        expect(QuestionDifficulty.easy.streakMultiplier, equals(1.0));
        expect(QuestionDifficulty.medium.streakMultiplier, equals(1.1));
        expect(QuestionDifficulty.hard.streakMultiplier, equals(1.25));
        expect(QuestionDifficulty.expert.streakMultiplier, equals(1.5));
        expect(QuestionDifficulty.boss.streakMultiplier, equals(2.0));
      });
    });

    group('timeLimitSeconds getter', () {
      test('Returns correct time limits', () {
        expect(QuestionDifficulty.easy.timeLimitSeconds, equals(30));
        expect(QuestionDifficulty.medium.timeLimitSeconds, equals(25));
        expect(QuestionDifficulty.hard.timeLimitSeconds, equals(20));
        expect(QuestionDifficulty.expert.timeLimitSeconds, equals(15));
        expect(QuestionDifficulty.boss.timeLimitSeconds, equals(10));
      });

      test('Time limits decrease with difficulty', () {
        expect(
          QuestionDifficulty.easy.timeLimitSeconds! >
              QuestionDifficulty.medium.timeLimitSeconds!,
          isTrue,
        );
        expect(
          QuestionDifficulty.boss.timeLimitSeconds! <
              QuestionDifficulty.easy.timeLimitSeconds!,
          isTrue,
        );
      });
    });

    group('fromInt parsing', () {
      test('Parses integer values correctly', () {
        expect(QuestionDifficultyExtension.fromInt(1),
            equals(QuestionDifficulty.easy));
        expect(QuestionDifficultyExtension.fromInt(2),
            equals(QuestionDifficulty.medium));
        expect(QuestionDifficultyExtension.fromInt(3),
            equals(QuestionDifficulty.hard));
        expect(QuestionDifficultyExtension.fromInt(4),
            equals(QuestionDifficulty.expert));
        expect(QuestionDifficultyExtension.fromInt(5),
            equals(QuestionDifficulty.boss));
      });

      test('Returns easy for invalid integers', () {
        expect(QuestionDifficultyExtension.fromInt(0),
            equals(QuestionDifficulty.easy));
        expect(QuestionDifficultyExtension.fromInt(99),
            equals(QuestionDifficulty.easy));
        expect(QuestionDifficultyExtension.fromInt(-1),
            equals(QuestionDifficulty.easy));
      });
    });

    group('fromString parsing', () {
      test('Parses string values case-insensitively', () {
        expect(
          QuestionDifficultyExtension.fromString('easy'),
          equals(QuestionDifficulty.easy),
        );
        expect(
          QuestionDifficultyExtension.fromString('MEDIUM'),
          equals(QuestionDifficulty.medium),
        );
        expect(
          QuestionDifficultyExtension.fromString('Hard'),
          equals(QuestionDifficulty.hard),
        );
      });

      test('Parses numeric strings', () {
        expect(
          QuestionDifficultyExtension.fromString('1'),
          equals(QuestionDifficulty.easy),
        );
        expect(
          QuestionDifficultyExtension.fromString('5'),
          equals(QuestionDifficulty.boss),
        );
      });

      test('Returns easy for invalid strings', () {
        expect(
          QuestionDifficultyExtension.fromString('invalid'),
          equals(QuestionDifficulty.easy),
        );
        expect(
          QuestionDifficultyExtension.fromString(''),
          equals(QuestionDifficulty.easy),
        );
        expect(
          QuestionDifficultyExtension.fromString(null),
          equals(QuestionDifficulty.easy),
        );
      });
    });

    group('parse universal parser', () {
      test('Parses int values', () {
        expect(
          QuestionDifficultyExtension.parse(3),
          equals(QuestionDifficulty.hard),
        );
      });

      test('Parses String values', () {
        expect(
          QuestionDifficultyExtension.parse('expert'),
          equals(QuestionDifficulty.expert),
        );
      });

      test('Parses num values', () {
        expect(
          QuestionDifficultyExtension.parse(4.7),
          equals(QuestionDifficulty.expert),
        );
      });

      test('Defaults to easy for unknown types', () {
        expect(
          QuestionDifficultyExtension.parse({}),
          equals(QuestionDifficulty.easy),
        );
      });
    });
  });
}
