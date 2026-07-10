import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'tier_progression_service.dart';

/// Service for managing tier-based leaderboard scoring
/// Applies multipliers and bonuses based on player tier
class TierLeaderboardService {
  final TierProgressionService _tierProgressionService;

  // Tier score multipliers (higher tier = higher multiplier)
  static const Map<String, double> tierMultipliers = {
    'bronze-rookie': 1.0,
    'silver-scholar': 1.1,
    'gold-master': 1.25,
    'platinum-elite': 1.5,
    'diamond-legend': 1.75,
    'master-sage': 2.0,
    'grandmaster': 2.5,
    'ultimate-champion': 3.0,
  };

  TierLeaderboardService({
    required TierProgressionService tierProgressionService,
  }) : _tierProgressionService = tierProgressionService;

  /// Calculate score multiplier for a player based on tier
  Future<double> getScoreMultiplier(String userId) async {
    try {
      final progress =
          await _tierProgressionService.getPlayerTierProgress(userId);
      final tierId = progress.currentTier.id;
      final multiplier = tierMultipliers[tierId] ?? 1.0;

      LogManager.debug(
        '[TierLeaderboard] Score multiplier for ${progress.currentTier.name}: $multiplier',
      );

      return multiplier;
    } catch (e) {
      LogManager.error(
        '[TierLeaderboard] Error getting score multiplier: $e',
        error: e,
      );
      return 1.0; // Default multiplier on error
    }
  }

  /// Apply tier-based multiplier to a score
  Future<int> applyTierMultiplier(String userId, int baseScore) async {
    try {
      final multiplier = await getScoreMultiplier(userId);
      final finalScore = (baseScore * multiplier).round();

      LogManager.debug(
        '[TierLeaderboard] Applied multiplier: $baseScore × $multiplier = $finalScore',
      );

      return finalScore;
    } catch (e) {
      LogManager.error(
        '[TierLeaderboard] Error applying multiplier: $e',
        error: e,
      );
      return baseScore; // Return base score on error
    }
  }

  /// Get tier bonus points (flat bonus for reaching tier)
  Future<int> getTierBonus(String userId) async {
    try {
      final progress =
          await _tierProgressionService.getPlayerTierProgress(userId);
      final tierId = progress.currentTier.id;

      // Bonus points increase with tier level
      final bonusPoints = switch (tierId) {
        'bronze-rookie' => 0,
        'silver-scholar' => 50,
        'gold-master' => 100,
        'platinum-elite' => 200,
        'diamond-legend' => 350,
        'master-sage' => 550,
        'grandmaster' => 800,
        'ultimate-champion' => 1200,
        _ => 0,
      };

      LogManager.debug(
        '[TierLeaderboard] Tier bonus for ${progress.currentTier.name}: $bonusPoints',
      );

      return bonusPoints;
    } catch (e) {
      LogManager.error(
        '[TierLeaderboard] Error getting tier bonus: $e',
        error: e,
      );
      return 0;
    }
  }

  /// Calculate final leaderboard score with tier multiplier and bonus
  Future<int> calculateLeaderboardScore(String userId, int baseScore) async {
    try {
      final multipliedScore = await applyTierMultiplier(userId, baseScore);
      final bonus = await getTierBonus(userId);
      final finalScore = multipliedScore + bonus;

      LogManager.debug(
        '[TierLeaderboard] Final score: $baseScore → $multipliedScore + $bonus = $finalScore',
      );

      return finalScore;
    } catch (e) {
      LogManager.error(
        '[TierLeaderboard] Error calculating leaderboard score: $e',
        error: e,
      );
      return baseScore; // Return base score on error
    }
  }

  /// Get score breakdown for display
  Future<ScoreBreakdown> getScoreBreakdown(String userId, int baseScore) async {
    try {
      final progress =
          await _tierProgressionService.getPlayerTierProgress(userId);
      final multiplier = await getScoreMultiplier(userId);
      final bonus = await getTierBonus(userId);
      final multipliedScore = (baseScore * multiplier).round();
      final finalScore = multipliedScore + bonus;

      return ScoreBreakdown(
        baseScore: baseScore,
        tierName: progress.currentTier.name,
        multiplier: multiplier,
        multipliedScore: multipliedScore,
        bonusPoints: bonus,
        finalScore: finalScore,
      );
    } catch (e) {
      LogManager.error(
        '[TierLeaderboard] Error getting score breakdown: $e',
        error: e,
      );
      return ScoreBreakdown(
        baseScore: baseScore,
        tierName: 'Unknown',
        multiplier: 1.0,
        multipliedScore: baseScore,
        bonusPoints: 0,
        finalScore: baseScore,
      );
    }
  }

  /// Get tier multiplier information
  static double? getTierMultiplier(String tierId) {
    return tierMultipliers[tierId];
  }

  /// Get all tier multipliers sorted by tier level
  static List<TierMultiplierInfo> getAllTierMultipliers() {
    return [
      TierMultiplierInfo('bronze-rookie', 1.0),
      TierMultiplierInfo('silver-scholar', 1.1),
      TierMultiplierInfo('gold-master', 1.25),
      TierMultiplierInfo('platinum-elite', 1.5),
      TierMultiplierInfo('diamond-legend', 1.75),
      TierMultiplierInfo('master-sage', 2.0),
      TierMultiplierInfo('grandmaster', 2.5),
      TierMultiplierInfo('ultimate-champion', 3.0),
    ];
  }

  /// Estimate score increase from tier advancement
  static int estimateScoreIncrease(
      String currentTierId, String nextTierId, int baseScore) {
    final currentMultiplier = tierMultipliers[currentTierId] ?? 1.0;
    final nextMultiplier = tierMultipliers[nextTierId] ?? 1.0;

    final currentScore = (baseScore * currentMultiplier).round();
    final nextScore = (baseScore * nextMultiplier).round();

    return nextScore - currentScore;
  }
}

/// Score breakdown information for display
class ScoreBreakdown {
  final int baseScore;
  final String tierName;
  final double multiplier;
  final int multipliedScore;
  final int bonusPoints;
  final int finalScore;

  ScoreBreakdown({
    required this.baseScore,
    required this.tierName,
    required this.multiplier,
    required this.multipliedScore,
    required this.bonusPoints,
    required this.finalScore,
  });
}

/// Tier multiplier information
class TierMultiplierInfo {
  final String tierId;
  final double multiplier;

  TierMultiplierInfo(this.tierId, this.multiplier);
}
