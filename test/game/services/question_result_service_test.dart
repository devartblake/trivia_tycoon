import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/services/question_result_service.dart';
import 'package:trivia_tycoon/game/services/xp_service.dart';
import 'package:trivia_tycoon/game/services/wallet_service.dart';
import 'package:trivia_tycoon/game/models/question_difficulty.dart';

void main() {
  group('QuestionResultService', () {
    late QuestionResultService service;
    late XPService xpService;
    late WalletService walletService;

    setUp(() {
      xpService = XPService();
      walletService = WalletService();
      service = QuestionResultService(
        xpService: xpService,
        walletService: walletService,
      );
    });

    group('Incorrect answer handling', () {
      test('No rewards for wrong answer', () async {
        final result = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.easy,
          selectedAnswer: 'Wrong',
          isCorrect: false,
          timeTaken: const Duration(seconds: 10),
          baseXPReward: 100,
          baseCoinReward: 50,
        );

        final progression = await service.processResult(result);

        expect(progression.xpEarned, equals(0));
        expect(progression.coinsEarned, equals(0));
        expect(progression.streakCount, equals(0));
      });

      test('Resets streak on wrong answer', () async {
        // Build a streak first
        final correctResult = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.easy,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 10),
        );

        await service.processResult(correctResult);
        expect(service.streak, equals(1));

        // Wrong answer resets
        final wrongResult = QuestionResult(
          questionId: 'q2',
          category: 'Math',
          difficulty: QuestionDifficulty.easy,
          selectedAnswer: 'Wrong',
          isCorrect: false,
          timeTaken: const Duration(seconds: 10),
        );

        await service.processResult(wrongResult);
        expect(service.streak, equals(0));
      });
    });

    group('Difficulty multipliers', () {
      test('Easy difficulty applies 1.0x multiplier', () async {
        final result = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.easy,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 15),
          baseXPReward: 100,
          baseCoinReward: 50,
        );

        final progression = await service.processResult(result);

        expect(progression.xpEarned, equals(100)); // 100 * 1.0
        expect(progression.coinsEarned, equals(50)); // 50 * 1.0
      });

      test('Medium difficulty applies 1.5x XP multiplier', () async {
        final result = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.medium,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 15),
          baseXPReward: 100,
          baseCoinReward: 50,
        );

        final progression = await service.processResult(result);

        expect(progression.xpEarned, equals(150)); // 100 * 1.5
        expect(progression.coinsEarned, equals(62)); // 50 * 1.25
      });

      test('Hard difficulty applies 2.0x XP multiplier', () async {
        final result = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.hard,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 15),
          baseXPReward: 100,
          baseCoinReward: 50,
        );

        final progression = await service.processResult(result);

        expect(progression.xpEarned, equals(200)); // 100 * 2.0
        expect(progression.coinsEarned, equals(75)); // 50 * 1.5
      });

      test('Expert difficulty applies 3.0x XP multiplier', () async {
        final result = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.expert,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 15),
          baseXPReward: 100,
          baseCoinReward: 50,
        );

        final progression = await service.processResult(result);

        expect(progression.xpEarned, equals(300)); // 100 * 3.0
        expect(progression.coinsEarned, equals(100)); // 50 * 2.0
      });

      test('Boss difficulty applies 5.0x XP multiplier', () async {
        final result = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.boss,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 15),
          baseXPReward: 100,
          baseCoinReward: 50,
        );

        final progression = await service.processResult(result);

        expect(progression.xpEarned, equals(500)); // 100 * 5.0
        expect(progression.coinsEarned, equals(150)); // 50 * 3.0
      });
    });

    group('Time bonus calculation', () {
      test('Fast answer (≤50% time) gets 1.5x bonus', () async {
        const timeLimit = 30;
        final result = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.easy,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 15), // 50% of 30
          baseXPReward: 100,
          baseCoinReward: 50,
        );

        final progression = await service.processResult(result);

        expect(progression.timeBonus, equals(1.5));
        expect(progression.xpEarned, equals(150)); // 100 * 1.0 * 1.5
      });

      test('Normal speed (≤100% time) gets 1.0x bonus', () async {
        const timeLimit = 30;
        final result = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.easy,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 25), // 83% of 30
          baseXPReward: 100,
          baseCoinReward: 50,
        );

        final progression = await service.processResult(result);

        expect(progression.timeBonus, equals(1.0));
        expect(progression.xpEarned, equals(100));
      });

      test('Timeout (>100% time) gets 0.5x penalty', () async {
        const timeLimit = 30;
        final result = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.easy,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 35), // > 30
          baseXPReward: 100,
          baseCoinReward: 50,
        );

        final progression = await service.processResult(result);

        expect(progression.timeBonus, equals(0.5));
        expect(progression.xpEarned, equals(50)); // 100 * 1.0 * 0.5
      });
    });

    group('Streak tracking', () {
      test('First correct answer creates streak of 1', () async {
        final result = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.easy,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 10),
        );

        await service.processResult(result);

        expect(service.streak, equals(1));
        expect(service.isStreakActive, isTrue);
      });

      test('Multiple correct answers increment streak', () async {
        for (int i = 0; i < 5; i++) {
          final result = QuestionResult(
            questionId: 'q$i',
            category: 'Math',
            difficulty: QuestionDifficulty.easy,
            selectedAnswer: 'Correct',
            isCorrect: true,
            timeTaken: const Duration(seconds: 10),
          );

          await service.processResult(result);
        }

        expect(service.streak, equals(5));
      });

      test('Streak bonus applies after 1st correct answer', () async {
        // First answer
        final result1 = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.easy,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 10),
          baseXPReward: 100,
        );

        final prog1 = await service.processResult(result1);
        expect(prog1.streakBonusApplied, isFalse); // No bonus on first

        // Second answer
        final result2 = QuestionResult(
          questionId: 'q2',
          category: 'Math',
          difficulty: QuestionDifficulty.easy,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 10),
          baseXPReward: 100,
        );

        final prog2 = await service.processResult(result2);
        expect(prog2.streakBonusApplied, isTrue); // Bonus on second
        expect(prog2.xpEarned, greaterThan(prog1.xpEarned));
      });
    });

    group('Milestone detection', () {
      test('Detects 5 question streak', () async {
        for (int i = 0; i < 5; i++) {
          final result = QuestionResult(
            questionId: 'q$i',
            category: 'Math',
            difficulty: QuestionDifficulty.easy,
            selectedAnswer: 'Correct',
            isCorrect: true,
            timeTaken: const Duration(seconds: 10),
          );

          final prog = await service.processResult(result);

          if (i == 4) {
            expect(prog.milestone, isNotNull);
            expect(prog.milestone, contains('5'));
          }
        }
      });

      test('Detects 10 question streak', () async {
        for (int i = 0; i < 10; i++) {
          final result = QuestionResult(
            questionId: 'q$i',
            category: 'Math',
            difficulty: QuestionDifficulty.easy,
            selectedAnswer: 'Correct',
            isCorrect: true,
            timeTaken: const Duration(seconds: 10),
          );

          final prog = await service.processResult(result);

          if (i == 9) {
            expect(prog.milestone, isNotNull);
            expect(prog.milestone, contains('10'));
          }
        }
      });
    });

    group('Service integration', () {
      test('Updates XPService with earned XP', () async {
        final initialXP = xpService.playerXP;

        final result = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.hard,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 10),
          baseXPReward: 100,
        );

        await service.processResult(result);

        expect(xpService.playerXP, greaterThan(initialXP));
      });

      test('Updates WalletService with earned coins', () async {
        final initialCoins = walletService.coins;

        final result = QuestionResult(
          questionId: 'q1',
          category: 'Math',
          difficulty: QuestionDifficulty.medium,
          selectedAnswer: 'Correct',
          isCorrect: true,
          timeTaken: const Duration(seconds: 10),
          baseCoinReward: 50,
        );

        await service.processResult(result);

        expect(walletService.coins, greaterThan(initialCoins));
      });
    });
  });
}
