import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/reward_progress_models.dart';
import 'package:trivia_tycoon/game/models/reward_step_models.dart';

RewardStep _step(double points) => RewardStep(
      pointValue: points,
      icon: Icons.star,
      backgroundColor: Colors.amber,
    );

void main() {
  // -------------------------------------------------------------------------
  // currentStepIndex
  // -------------------------------------------------------------------------

  group('RewardProgress — currentStepIndex', () {
    final steps = [_step(100), _step(200), _step(300)];

    test('0 when points below first step', () {
      final rp = RewardProgress(currentPoints: 50, steps: steps);
      expect(rp.currentStepIndex, 0);
    });

    test('0 when points exactly equal first step', () {
      final rp = RewardProgress(currentPoints: 100, steps: steps);
      expect(rp.currentStepIndex, 0);
    });

    test('1 when points past first but below second', () {
      final rp = RewardProgress(currentPoints: 150, steps: steps);
      expect(rp.currentStepIndex, 1);
    });

    test('2 (last) when points exceed all steps', () {
      final rp = RewardProgress(currentPoints: 400, steps: steps);
      expect(rp.currentStepIndex, 2);
    });

    test('0 for single step regardless of points', () {
      final rp = RewardProgress(currentPoints: 999, steps: [_step(100)]);
      expect(rp.currentStepIndex, 0);
    });
  });

  // -------------------------------------------------------------------------
  // nextReward
  // -------------------------------------------------------------------------

  group('RewardProgress — nextReward', () {
    final steps = [_step(100), _step(200), _step(300)];

    test('returns first step when points = 0', () {
      final rp = RewardProgress(currentPoints: 0, steps: steps);
      expect(rp.nextReward, steps[0]);
    });

    test('returns second step when first is reached but not claimed', () {
      final rp = RewardProgress(currentPoints: 100, steps: steps);
      expect(rp.nextReward, steps[1]);
    });

    test('skips claimed steps', () {
      final rp = RewardProgress(
          currentPoints: 0,
          steps: steps,
          claimedRewards: [steps[0]]);
      expect(rp.nextReward, steps[1]);
    });

    test('null when all steps claimed', () {
      final rp = RewardProgress(
          currentPoints: 999,
          steps: steps,
          claimedRewards: steps);
      expect(rp.nextReward, isNull);
    });

    test('null when steps is empty', () {
      final rp = RewardProgress(currentPoints: 100, steps: const []);
      expect(rp.nextReward, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // pointsToNextReward
  // -------------------------------------------------------------------------

  group('RewardProgress — pointsToNextReward', () {
    final steps = [_step(100), _step(200)];

    test('100 when at 0 points and next is 100', () {
      final rp = RewardProgress(currentPoints: 0, steps: steps);
      expect(rp.pointsToNextReward, 100.0);
    });

    test('50 when at 50 points and next is 100', () {
      final rp = RewardProgress(currentPoints: 50, steps: steps);
      expect(rp.pointsToNextReward, 50.0);
    });

    test('null when no next reward', () {
      final rp = RewardProgress(
          currentPoints: 999,
          steps: steps,
          claimedRewards: steps);
      expect(rp.pointsToNextReward, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // overallProgress
  // -------------------------------------------------------------------------

  group('RewardProgress — overallProgress', () {
    final steps = [_step(100), _step(200), _step(400)];

    test('0.0 when steps is empty', () {
      final rp = RewardProgress(currentPoints: 100, steps: const []);
      expect(rp.overallProgress, 0.0);
    });

    test('0.0 when at 0 points', () {
      final rp = RewardProgress(currentPoints: 0, steps: steps);
      expect(rp.overallProgress, 0.0);
    });

    test('0.5 when at 200 of 400 max', () {
      final rp = RewardProgress(currentPoints: 200, steps: steps);
      expect(rp.overallProgress, 0.5);
    });

    test('1.0 when at max points', () {
      final rp = RewardProgress(currentPoints: 400, steps: steps);
      expect(rp.overallProgress, 1.0);
    });

    test('clamped to 1.0 when over max', () {
      final rp = RewardProgress(currentPoints: 600, steps: steps);
      expect(rp.overallProgress, 1.0);
    });
  });

  // -------------------------------------------------------------------------
  // availableRewards
  // -------------------------------------------------------------------------

  group('RewardProgress — availableRewards', () {
    final steps = [_step(100), _step(200), _step(300)];

    test('empty when below all thresholds', () {
      final rp = RewardProgress(currentPoints: 50, steps: steps);
      expect(rp.availableRewards, isEmpty);
    });

    test('returns step at threshold when not claimed', () {
      final rp = RewardProgress(currentPoints: 100, steps: steps);
      expect(rp.availableRewards, [steps[0]]);
    });

    test('excludes claimed steps', () {
      final rp = RewardProgress(
          currentPoints: 200,
          steps: steps,
          claimedRewards: [steps[0]]);
      expect(rp.availableRewards, [steps[1]]);
    });

    test('returns all unclaimed above threshold', () {
      final rp = RewardProgress(currentPoints: 300, steps: steps);
      expect(rp.availableRewards.length, 3);
    });
  });

  // -------------------------------------------------------------------------
  // canClaimReward
  // -------------------------------------------------------------------------

  group('RewardProgress — canClaimReward', () {
    final steps = [_step(100), _step(200)];

    test('true when points met and not claimed', () {
      final rp = RewardProgress(currentPoints: 100, steps: steps);
      expect(rp.canClaimReward(steps[0]), isTrue);
    });

    test('false when points below threshold', () {
      final rp = RewardProgress(currentPoints: 50, steps: steps);
      expect(rp.canClaimReward(steps[0]), isFalse);
    });

    test('false when already claimed', () {
      final rp = RewardProgress(
          currentPoints: 100,
          steps: steps,
          claimedRewards: [steps[0]]);
      expect(rp.canClaimReward(steps[0]), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // RewardProgress.copyWith
  // -------------------------------------------------------------------------

  group('RewardProgress.copyWith', () {
    final steps = [_step(100), _step(200)];
    late RewardProgress base;
    setUp(() => base = RewardProgress(currentPoints: 50, steps: steps));

    test('copies currentPoints', () {
      expect(base.copyWith(currentPoints: 150).currentPoints, 150.0);
    });

    test('copies steps', () {
      final newSteps = [_step(500)];
      expect(base.copyWith(steps: newSteps).steps, newSteps);
    });

    test('copies claimedRewards', () {
      final claimed = [steps[0]];
      expect(base.copyWith(claimedRewards: claimed).claimedRewards, claimed);
    });

    test('preserves unchanged fields', () {
      final updated = base.copyWith(currentPoints: 200);
      expect(updated.steps, base.steps);
      expect(updated.claimedRewards, base.claimedRewards);
    });
  });
}
