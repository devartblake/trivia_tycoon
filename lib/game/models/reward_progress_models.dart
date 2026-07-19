import 'package:synaptix/game/models/reward_step_models.dart';

/// Progress tracker for reward steps
class RewardProgress {
  final double currentPoints;
  final List<RewardStep> steps;
  final List<RewardStep> claimedRewards;

  const RewardProgress({
    required this.currentPoints,
    required this.steps,
    this.claimedRewards = const [],
  });

  /// Get the current step index based on points. The index advances only once
  /// a step's threshold is strictly exceeded, so sitting exactly on a step's
  /// value keeps you on that step (e.g. 100 pts with a 100-pt step → index 0),
  /// while going past it moves to the next (150 pts → index 1).
  int get currentStepIndex {
    if (steps.isEmpty) return 0;
    for (int i = 0; i < steps.length; i++) {
      if (currentPoints <= steps[i].pointValue) {
        return i;
      }
    }
    return steps.length - 1;
  }

  /// Get the next reward step
  RewardStep? get nextReward {
    for (var step in steps) {
      if (currentPoints < step.pointValue && !claimedRewards.contains(step)) {
        return step;
      }
    }
    return null;
  }

  /// Get points needed for next reward
  double? get pointsToNextReward {
    final next = nextReward;
    return next != null ? next.pointValue - currentPoints : null;
  }

  /// Get overall progress percentage
  double get overallProgress {
    if (steps.isEmpty) return 0.0;
    final maxPoints = steps.last.pointValue;
    return (currentPoints / maxPoints).clamp(0.0, 1.0);
  }

  /// Get available rewards to claim
  List<RewardStep> get availableRewards {
    return steps
        .where((step) =>
            currentPoints >= step.pointValue && !claimedRewards.contains(step))
        .toList();
  }

  /// Check if a specific reward is claimable
  bool canClaimReward(RewardStep reward) {
    return currentPoints >= reward.pointValue &&
        !claimedRewards.contains(reward);
  }

  RewardProgress copyWith({
    double? currentPoints,
    List<RewardStep>? steps,
    List<RewardStep>? claimedRewards,
  }) {
    return RewardProgress(
      currentPoints: currentPoints ?? this.currentPoints,
      steps: steps ?? this.steps,
      claimedRewards: claimedRewards ?? this.claimedRewards,
    );
  }
}
