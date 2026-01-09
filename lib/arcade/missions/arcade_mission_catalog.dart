import '../domain/arcade_game_id.dart';
import 'arcade_mission_models.dart';

class ArcadeMissionCatalog {
  static List<ArcadeMission> dailyMissions() {
    return const [
      ArcadeMission(
        id: 'daily_play_3',
        title: 'Arcade Warm-Up',
        subtitle: 'Play 3 arcade runs today.',
        type: ArcadeMissionType.playRuns,
        target: 3,
        reward: ArcadeMissionReward(coins: 250, gems: 1),
      ),
      ArcadeMission(
        id: 'daily_math_800',
        title: 'Quick Math Specialist',
        subtitle: 'Score 800+ in Quick Math Rush.',
        type: ArcadeMissionType.scoreAtLeast,
        gameId: ArcadeGameId.quickMathRush,
        target: 800,
        reward: ArcadeMissionReward(coins: 350, gems: 2),
      ),
      ArcadeMission(
        id: 'daily_new_pb',
        title: 'New Record',
        subtitle: 'Set 1 new personal best today.',
        type: ArcadeMissionType.setNewPb,
        target: 1,
        reward: ArcadeMissionReward(coins: 300, gems: 2),
      ),
    ];
  }
}
