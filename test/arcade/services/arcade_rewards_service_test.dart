import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_difficulty.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_game_id.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_result.dart';
import 'package:trivia_tycoon/arcade/services/arcade_rewards_service.dart';

ArcadeResult _result({
  ArcadeGameId gameId = ArcadeGameId.quickMathRush,
  ArcadeDifficulty difficulty = ArcadeDifficulty.normal,
  int score = 1000,
  Duration duration = const Duration(seconds: 90),
}) =>
    ArcadeResult(
      gameId: gameId,
      difficulty: difficulty,
      score: score,
      duration: duration,
    );

void main() {
  const service = ArcadeRewardsService();

  // ---------------------------------------------------------------------------
  // Basic output ranges
  // ---------------------------------------------------------------------------

  group('ArcadeRewardsService output ranges', () {
    test('XP is always at least 5', () {
      final rewards = service.computeRewards(_result(score: 1));
      expect(rewards.xp, greaterThanOrEqualTo(5));
    });

    test('XP never exceeds 1500', () {
      final rewards = service.computeRewards(
        _result(score: 999999, difficulty: ArcadeDifficulty.insane),
      );
      expect(rewards.xp, lessThanOrEqualTo(1500));
    });

    test('coins are always at least 5', () {
      final rewards = service.computeRewards(_result(score: 1));
      expect(rewards.coins, greaterThanOrEqualTo(5));
    });

    test('coins never exceed 4000', () {
      final rewards = service.computeRewards(
        _result(score: 999999, difficulty: ArcadeDifficulty.insane),
      );
      expect(rewards.coins, lessThanOrEqualTo(4000));
    });

    test('gems are non-negative', () {
      final rewards = service.computeRewards(_result(score: 1));
      expect(rewards.gems, greaterThanOrEqualTo(0));
    });

    test('gems never exceed 50', () {
      final rewards = service.computeRewards(
        _result(score: 999999, difficulty: ArcadeDifficulty.insane),
      );
      expect(rewards.gems, lessThanOrEqualTo(50));
    });
  });

  // ---------------------------------------------------------------------------
  // Difficulty scaling
  // ---------------------------------------------------------------------------

  group('ArcadeRewardsService difficulty scaling', () {
    ArcadeRewards _rewardsFor(ArcadeDifficulty diff) => service.computeRewards(
          _result(score: 500, difficulty: diff),
        );

    test('insane yields more XP than easy', () {
      final insane = _rewardsFor(ArcadeDifficulty.insane);
      final easy = _rewardsFor(ArcadeDifficulty.easy);
      expect(insane.xp, greaterThan(easy.xp));
    });

    test('hard yields more XP than normal', () {
      final hard = _rewardsFor(ArcadeDifficulty.hard);
      final normal = _rewardsFor(ArcadeDifficulty.normal);
      expect(hard.xp, greaterThan(normal.xp));
    });

    test('difficulty order is easy < normal < hard < insane for XP', () {
      final xps =
          ArcadeDifficulty.values.map((d) => _rewardsFor(d).xp).toList();
      for (int i = 1; i < xps.length; i++) {
        expect(xps[i], greaterThanOrEqualTo(xps[i - 1]));
      }
    });
  });

  // ---------------------------------------------------------------------------
  // Time bonus
  // ---------------------------------------------------------------------------

  group('ArcadeRewardsService time bonus', () {
    test('faster completion gives at least as much XP as slower', () {
      final fast = service
          .computeRewards(_result(duration: const Duration(seconds: 30)));
      final slow = service
          .computeRewards(_result(duration: const Duration(seconds: 3600)));
      expect(fast.xp, greaterThanOrEqualTo(slow.xp));
    });

    test('very short duration does not push XP beyond 1500', () {
      final rewards = service.computeRewards(
        _result(score: 10000, duration: const Duration(seconds: 1)),
      );
      expect(rewards.xp, lessThanOrEqualTo(1500));
    });
  });

  // ---------------------------------------------------------------------------
  // Per-game tuning knobs
  // ---------------------------------------------------------------------------

  group('ArcadeRewardsService per-game tuning', () {
    // memoryFlip has xpMult=1.05 vs patternSprint xpMult=1.0
    test('memoryFlip yields slightly more XP than patternSprint at same score',
        () {
      final memory = service.computeRewards(
        _result(gameId: ArcadeGameId.memoryFlip, score: 1000),
      );
      final pattern = service.computeRewards(
        _result(gameId: ArcadeGameId.patternSprint, score: 1000),
      );
      expect(memory.xp, greaterThanOrEqualTo(pattern.xp));
    });

    // quickMathRush has coinMult=1.05 vs patternSprint coinMult=1.0
    test(
        'quickMathRush yields slightly more coins than patternSprint at same score',
        () {
      final math = service.computeRewards(
        _result(gameId: ArcadeGameId.quickMathRush, score: 1000),
      );
      final pattern = service.computeRewards(
        _result(gameId: ArcadeGameId.patternSprint, score: 1000),
      );
      expect(math.coins, greaterThanOrEqualTo(pattern.coins));
    });
  });

  // ---------------------------------------------------------------------------
  // Coins ~ XP * 1.2
  // ---------------------------------------------------------------------------

  group('ArcadeRewardsService coins proportional to XP', () {
    test('coins are at least as large as XP for normal score', () {
      final rewards = service.computeRewards(_result(score: 300));
      expect(rewards.coins, greaterThanOrEqualTo(rewards.xp));
    });
  });

  // ---------------------------------------------------------------------------
  // ArcadeRewards model
  // ---------------------------------------------------------------------------

  group('ArcadeRewards model', () {
    test('has correct fields', () {
      final r = const ArcadeRewards(xp: 100, coins: 120, gems: 1);
      expect(r.xp, 100);
      expect(r.coins, 120);
      expect(r.gems, 1);
    });
  });
}
