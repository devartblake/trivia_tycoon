import '../domain/arcade_difficulty.dart';
import '../domain/arcade_game_id.dart';
import '../domain/arcade_result.dart';

class ArcadeRewardsService {
  const ArcadeRewardsService();

  ArcadeRewards computeRewards(ArcadeResult result) {
    // Base XP from score
    final baseXp = (result.score / 10).round().clamp(5, 500);

    // Time bonus (faster = more)
    final seconds = result.duration.inSeconds.clamp(1, 3600);
    final timeFactor = (120 / seconds).clamp(0.75, 1.35);

    // Difficulty multiplier
    final diff = result.difficulty.rewardMultiplier;

    // Raw XP (pre-tuning)
    final rawXp = (baseXp * diff * timeFactor).round().clamp(5, 1000);

    // Raw coins + gems (pre-tuning)
    final rawCoins = (rawXp * 1.2).round().clamp(5, 2000);
    final rawGems = (rawXp / 120).floor().clamp(0, 25);

    // ✅ Step 6C: apply per-game tuning knobs
    final tuning = kArcadeRewardTuning[result.gameId] ??
        const ArcadeRewardTuning(xpMult: 1.0, coinMult: 1.0, gemMult: 1.0);

    final xp = (rawXp * tuning.xpMult).round().clamp(5, 1500);
    final coins = (rawCoins * tuning.coinMult).round().clamp(5, 4000);
    final gems = (rawGems * tuning.gemMult).round().clamp(0, 50);

    return ArcadeRewards(xp: xp, coins: coins, gems: gems);
  }
}

class ArcadeRewardTuning {
  final double xpMult;
  final double coinMult;
  final double gemMult;

  const ArcadeRewardTuning({
    required this.xpMult,
    required this.coinMult,
    required this.gemMult,
  });
}

const Map<ArcadeGameId, ArcadeRewardTuning> kArcadeRewardTuning = {
  ArcadeGameId.patternSprint: ArcadeRewardTuning(xpMult: 1.0, coinMult: 1.0, gemMult: 1.0),
  ArcadeGameId.memoryFlip: ArcadeRewardTuning(xpMult: 1.05, coinMult: 1.0, gemMult: 1.0),
  ArcadeGameId.quickMathRush: ArcadeRewardTuning(xpMult: 1.0, coinMult: 1.05, gemMult: 1.0),
};