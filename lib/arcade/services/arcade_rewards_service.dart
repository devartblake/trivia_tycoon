import '../domain/arcade_difficulty.dart';
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

    final xp = (baseXp * diff * timeFactor).round().clamp(5, 1000);

    // Coins + Gems derived from XP (simple and tunable)
    final coins = (xp * 1.2).round().clamp(5, 2000);
    final gems = (xp / 120).floor().clamp(0, 25);

    return ArcadeRewards(xp: xp, coins: coins, gems: gems);
  }
}
