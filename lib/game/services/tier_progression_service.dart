import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/tier_api_client.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/game/state/tier_update_result.dart';

/// Unified tier progression service
/// Source of truth: TierApiClient (backend)
/// Local caching: PlayerProfileService (Hive storage)
///
/// This service bridges the old TierManager system with the new backend-driven
/// TierApiClient system, ensuring consistent tier progression across the app.
class TierProgressionService {
  final TierApiClient _tierApiClient;
  final PlayerProfileService _profileService;

  // Cache for tier definitions (prevents repeated API calls)
  List<TierDefinition>? _cachedTiers;

  TierProgressionService({
    required TierApiClient tierApiClient,
    required PlayerProfileService profileService,
  })  : _tierApiClient = tierApiClient,
        _profileService = profileService;

  /// Get all tier definitions from cache or API
  Future<List<TierDefinition>> getTierDefinitions() async {
    if (_cachedTiers != null) {
      return _cachedTiers!;
    }

    try {
      final tiers = await _tierApiClient.getTierDefinitions();
      _cachedTiers = tiers;
      LogManager.debug('[TierProgressionService] Loaded ${tiers.length} tier definitions');
      return tiers;
    } catch (e) {
      LogManager.error(
        '[TierProgressionService] Failed to load tier definitions: $e',
        error: e,
      );
      // Return fallback default tiers on error
      return _getDefaultTiers();
    }
  }

  /// Get default tier definitions (fallback)
  List<TierDefinition> _getDefaultTiers() {
    return [
      TierDefinition(
        id: 'bronze-rookie',
        name: 'Bronze Rookie',
        level: 1,
        minXp: 0,
        maxXp: 500,
        iconName: 'bronze_rookie',
        rewards: TierReward(badge: 'welcome_badge', coinsBonus: 100, gemsBonus: 0),
      ),
      TierDefinition(
        id: 'silver-scholar',
        name: 'Silver Scholar',
        level: 5,
        minXp: 500,
        maxXp: 1200,
        iconName: 'silver_scholar',
        rewards: TierReward(badge: 'scholar_badge', coinsBonus: 250, gemsBonus: 5),
      ),
      TierDefinition(
        id: 'gold-master',
        name: 'Gold Master',
        level: 10,
        minXp: 1200,
        maxXp: 2500,
        iconName: 'gold_master',
        rewards: TierReward(badge: 'master_badge', coinsBonus: 500, gemsBonus: 15),
      ),
      TierDefinition(
        id: 'platinum-elite',
        name: 'Platinum Elite',
        level: 18,
        minXp: 2500,
        maxXp: 5000,
        iconName: 'platinum_elite',
        rewards: TierReward(badge: 'elite_badge', coinsBonus: 1000, gemsBonus: 30),
      ),
      TierDefinition(
        id: 'diamond-legend',
        name: 'Diamond Legend',
        level: 25,
        minXp: 5000,
        maxXp: 10000,
        iconName: 'diamond_legend',
        rewards: TierReward(badge: 'legend_badge', coinsBonus: 2000, gemsBonus: 50),
      ),
      TierDefinition(
        id: 'master-sage',
        name: 'Master Sage',
        level: 35,
        minXp: 10000,
        maxXp: 20000,
        iconName: 'master_sage',
        rewards: TierReward(badge: 'sage_badge', coinsBonus: 5000, gemsBonus: 100),
      ),
      TierDefinition(
        id: 'grandmaster',
        name: 'Grandmaster',
        level: 50,
        minXp: 20000,
        maxXp: 50000,
        iconName: 'grandmaster',
        rewards: TierReward(badge: 'grandmaster_badge', coinsBonus: 10000, gemsBonus: 200),
      ),
      TierDefinition(
        id: 'ultimate-champion',
        name: 'Ultimate Champion',
        level: 75,
        minXp: 50000,
        maxXp: 100000,
        iconName: 'ultimate_champion',
        rewards: TierReward(badge: 'champion_badge', coinsBonus: 20000, gemsBonus: 500),
      ),
    ];
  }

  /// Get player's current tier progress
  /// Calculates based on current XP and tier definitions
  Future<PlayerTierProgress> getPlayerTierProgress(String userId) async {
    try {
      final tiers = await getTierDefinitions();
      if (tiers.isEmpty) {
        LogManager.warning('[TierProgressionService] No tier definitions available');
        return _getEmptyProgress();
      }

      final profile = _profileService.getProfile();
      final currentXp = profile['currentXP'] ?? 0;

      // Find current tier based on XP
      TierDefinition currentTier = tiers.first;
      TierDefinition? nextTier;

      for (int i = tiers.length - 1; i >= 0; i--) {
        if (currentXp >= tiers[i].minXp) {
          currentTier = tiers[i];
          // Next tier is the one after this
          if (i + 1 < tiers.length) {
            nextTier = tiers[i + 1];
          }
          break;
        }
      }

      // Calculate progress to next tier
      int xpInCurrentTier = 0;
      int xpNeededForNextTier = 0;
      int progressPercentage = 0;

      if (nextTier != null) {
        xpInCurrentTier = currentXp - currentTier.minXp;
        xpNeededForNextTier = nextTier.minXp - currentTier.minXp;
        progressPercentage = xpNeededForNextTier > 0
            ? ((xpInCurrentTier / xpNeededForNextTier) * 100).round()
            : 0;
        progressPercentage = progressPercentage.clamp(0, 100);
      } else {
        // At max tier
        progressPercentage = 100;
      }

      final progress = PlayerTierProgress(
        currentTier: currentTier,
        nextTier: nextTier,
        currentXp: currentXp,
        xpInCurrentTier: xpInCurrentTier,
        xpNeededForNextTier: xpNeededForNextTier,
        progressPercentage: progressPercentage,
      );

      LogManager.debug(
        '[TierProgressionService] Player progress: Tier=${currentTier.name}, '
        'XP=$currentXp, Progress=$progressPercentage%',
      );

      return progress;
    } catch (e) {
      LogManager.error(
        '[TierProgressionService] Failed to get player tier progress: $e',
        error: e,
      );
      return _getEmptyProgress();
    }
  }

  /// Award XP to player and check for tier progression
  /// Returns true if tier changed
  Future<bool> awardXP(String userId, int xpAmount, String reason) async {
    try {
      LogManager.debug(
        '[TierProgressionService] Awarding $xpAmount XP to $userId ($reason)',
      );

      // Get current tier before XP award
      final beforeProgress = await getPlayerTierProgress(userId);
      final beforeTierXp = beforeProgress.currentTier.minXp;

      // Award XP via API
      await _tierApiClient.awardXp(userId, xpAmount, reason);

      // Get new tier after XP award
      final afterProgress = await getPlayerTierProgress(userId);
      final afterTierXp = afterProgress.currentTier.minXp;

      final tierChanged = beforeTierXp != afterTierXp;

      if (tierChanged) {
        LogManager.debug(
          '[TierProgressionService] Tier progression detected: '
          '${beforeProgress.currentTier.name} -> ${afterProgress.currentTier.name}',
        );
      }

      return tierChanged;
    } catch (e) {
      LogManager.error(
        '[TierProgressionService] Failed to award XP: $e',
        error: e,
      );
      return false;
    }
  }

  /// Get specific tier by ID
  Future<TierDefinition?> getTierById(String tierId) async {
    final tiers = await getTierDefinitions();
    try {
      return tiers.firstWhere((tier) => tier.id == tierId);
    } catch (e) {
      return null;
    }
  }

  /// Clear tier cache (for testing or force refresh)
  void clearCache() {
    _cachedTiers = null;
    LogManager.debug('[TierProgressionService] Tier cache cleared');
  }

  /// Create empty progress (fallback)
  PlayerTierProgress _getEmptyProgress() {
    final firstTier = TierDefinition(
      id: 'bronze-rookie',
      name: 'Bronze Rookie',
      level: 1,
      minXp: 0,
      maxXp: 500,
      iconName: 'bronze_rookie',
      rewards: TierReward(
        badge: 'welcome_badge',
        coinsBonus: 100,
        gemsBonus: 0,
      ),
    );

    return PlayerTierProgress(
      currentTier: firstTier,
      nextTier: null,
      currentXp: 0,
      xpInCurrentTier: 0,
      xpNeededForNextTier: 500,
      progressPercentage: 0,
    );
  }
}
