import '../domain/arcade_game_id.dart';
import 'arcade_mission_models.dart';

class ArcadeMissionCatalog {
  /// Local default missions.
  /// These are used when no backend missions are cached/available.
  ///
  /// Conventions:
  /// - IDs are stable and encode tier + key intent + target where useful.
  /// - Season missions include seasonId in their IDs to avoid collisions.
  static List<ArcadeMission> allMissions({required String seasonId}) {
    return [
      ...dailyMissions(),
      ...weeklyMissions(),
      ...seasonMissions(seasonId: seasonId),
    ];
  }

  static List<ArcadeMission> dailyMissions() {
    return const [
      ArcadeMission(
        id: 'daily_play_runs_3',
        tier: ArcadeMissionTier.daily,
        type: ArcadeMissionType.playRuns,
        title: 'Arcade Warm-Up',
        subtitle: 'Play 3 arcade runs today.',
        target: 3,
        reward: ArcadeMissionReward(coins: 250, gems: 1),
      ),
      ArcadeMission(
        id: 'daily_quick_math_score_800',
        tier: ArcadeMissionTier.daily,
        type: ArcadeMissionType.scoreAtLeast,
        title: 'Quick Math Specialist',
        subtitle: 'Score 800+ in Quick Math Rush.',
        target: 800,
        gameId: ArcadeGameId.quickMathRush,
        reward: ArcadeMissionReward(coins: 350, gems: 2),
      ),
      ArcadeMission(
        id: 'daily_new_pb_1',
        tier: ArcadeMissionTier.daily,
        type: ArcadeMissionType.setNewPb,
        title: 'New Record',
        subtitle: 'Set 1 new personal best today.',
        target: 1,
        reward: ArcadeMissionReward(coins: 300, gems: 2),
      ),
    ];
  }

  static List<ArcadeMission> weeklyMissions() {
    return const [
      ArcadeMission(
        id: 'weekly_any_run_score_5000',
        tier: ArcadeMissionTier.weekly,
        type: ArcadeMissionType.scoreAtLeast,
        title: 'Big Week',
        subtitle: 'Score at least 5,000 in any run.',
        target: 5000,
        reward: ArcadeMissionReward(coins: 750, gems: 4),
      ),
      ArcadeMission(
        id: 'weekly_new_pb_2',
        tier: ArcadeMissionTier.weekly,
        type: ArcadeMissionType.setNewPb,
        title: 'Level Up',
        subtitle: 'Set 2 new personal bests this week.',
        target: 2,
        reward: ArcadeMissionReward(coins: 600, gems: 4),
      ),
      ArcadeMission(
        id: 'weekly_any_run_score_1000',
        tier: ArcadeMissionTier.weekly,
        type: ArcadeMissionType.scoreAtLeast,
        title: 'Weekly Milestone',
        subtitle: 'Score at least 1,000 points in a single run.',
        target: 1000,
        reward: ArcadeMissionReward(coins: 1000, gems: 5),
      ),
    ];
  }

  static List<ArcadeMission> seasonMissions({required String seasonId}) {
    return [
      ArcadeMission(
        id: 'season_${seasonId}_any_run_score_10000',
        tier: ArcadeMissionTier.season,
        type: ArcadeMissionType.scoreAtLeast,
        title: 'Season Milestone',
        subtitle: 'Score at least 10,000 points in a single run.',
        target: 10000,
        reward: const ArcadeMissionReward(coins: 1500, gems: 10),
        seasonId: seasonId,
      ),
      ArcadeMission(
        id: 'season_${seasonId}_new_pb_10',
        tier: ArcadeMissionTier.season,
        type: ArcadeMissionType.setNewPb,
        title: 'Season Grinder',
        subtitle: 'Set 10 new personal bests this season.',
        target: 10,
        reward: const ArcadeMissionReward(coins: 2500, gems: 10),
        seasonId: seasonId,
      ),
    ];
  }
}
