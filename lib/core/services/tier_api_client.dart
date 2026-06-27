import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// API client for tier/progression system
/// NOTE: Currently uses MOCK data from Phase 1 definitions
/// When backend tier endpoints are ready, replace implementation with:
/// - GET /progression/tiers
/// - GET /progression/player/{userId}
/// - POST /progression/xp/award
class TierApiClient {
  /// MOCK: Hardcoded tier definitions from Phase 1
  /// TODO: Replace with real API when backend endpoints available
  static final List<TierDefinition> _mockTiers = [
    TierDefinition(
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
    ),
    TierDefinition(
      id: 'silver-scholar',
      name: 'Silver Scholar',
      level: 5,
      minXp: 500,
      maxXp: 1200,
      iconName: 'silver_scholar',
      rewards: TierReward(
        badge: 'scholar_badge',
        coinsBonus: 250,
        gemsBonus: 5,
      ),
    ),
    TierDefinition(
      id: 'gold-master',
      name: 'Gold Master',
      level: 10,
      minXp: 1200,
      maxXp: 2500,
      iconName: 'gold_master',
      rewards: TierReward(
        badge: 'master_badge',
        coinsBonus: 500,
        gemsBonus: 15,
      ),
    ),
    TierDefinition(
      id: 'platinum-elite',
      name: 'Platinum Elite',
      level: 18,
      minXp: 2500,
      maxXp: 5000,
      iconName: 'platinum_elite',
      rewards: TierReward(
        badge: 'elite_badge',
        coinsBonus: 1000,
        gemsBonus: 30,
      ),
    ),
    TierDefinition(
      id: 'diamond-legend',
      name: 'Diamond Legend',
      level: 25,
      minXp: 5000,
      maxXp: 10000,
      iconName: 'diamond_legend',
      rewards: TierReward(
        badge: 'legend_badge',
        coinsBonus: 2000,
        gemsBonus: 50,
      ),
    ),
    TierDefinition(
      id: 'master-sage',
      name: 'Master Sage',
      level: 35,
      minXp: 10000,
      maxXp: 20000,
      iconName: 'master_sage',
      rewards: TierReward(
        badge: 'sage_badge',
        coinsBonus: 5000,
        gemsBonus: 100,
      ),
    ),
    TierDefinition(
      id: 'grandmaster',
      name: 'Grandmaster',
      level: 50,
      minXp: 20000,
      maxXp: 50000,
      iconName: 'grandmaster',
      rewards: TierReward(
        badge: 'grandmaster_badge',
        coinsBonus: 10000,
        gemsBonus: 200,
      ),
    ),
  ];

  /// Get all tier definitions
  /// MOCK IMPLEMENTATION - Returns hardcoded tiers
  Future<List<TierDefinition>> getTierDefinitions() async {
    try {
      LogManager.debug('[TierApiClient] Fetching tier definitions (MOCK)');

      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 100));

      LogManager.debug(
        '[TierApiClient] Loaded ${_mockTiers.length} tier definitions (MOCK)',
      );
      return _mockTiers;
    } catch (e) {
      LogManager.error(
        '[TierApiClient] Error fetching tier definitions: $e',
        source: 'TierApiClient.getTierDefinitions',
        error: e,
      );
      rethrow;
    }
  }

  /// Get player's current tier based on XP
  /// MOCK IMPLEMENTATION - Calculates from XP value
  Future<PlayerTierProgress> getPlayerTierProgress(int currentXp) async {
    try {
      LogManager.debug(
        '[TierApiClient] Fetching player tier progress for XP=$currentXp (MOCK)',
      );

      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 100));

      // Find current tier based on XP
      TierDefinition? currentTier;
      for (final tier in _mockTiers) {
        if (currentXp >= tier.minXp && currentXp < tier.maxXp) {
          currentTier = tier;
          break;
        }
      }

      // If XP exceeds highest tier, return highest tier
      currentTier ??= _mockTiers.last;

      // Calculate next tier
      final currentTierIndex = _mockTiers.indexOf(currentTier);
      final nextTier = currentTierIndex < _mockTiers.length - 1
          ? _mockTiers[currentTierIndex + 1]
          : null;

      // Calculate progress within tier
      final xpInTier = currentXp - currentTier.minXp;
      final xpNeededForTier = currentTier.maxXp - currentTier.minXp;
      final progressPercentage = (xpInTier / xpNeededForTier * 100).clamp(0, 100).toInt();

      final progress = PlayerTierProgress(
        currentTier: currentTier,
        nextTier: nextTier,
        currentXp: currentXp,
        xpInCurrentTier: xpInTier,
        xpNeededForNextTier: nextTier != null ? nextTier.minXp - currentXp : 0,
        progressPercentage: progressPercentage,
      );

      LogManager.debug(
        '[TierApiClient] Player tier: ${currentTier.name}, Progress: $progressPercentage%',
      );
      return progress;
    } catch (e) {
      LogManager.error(
        '[TierApiClient] Error fetching player tier progress: $e',
        source: 'TierApiClient.getPlayerTierProgress',
        error: e,
      );
      rethrow;
    }
  }

  /// Award XP to player
  /// MOCK IMPLEMENTATION - Just logs the action
  Future<XpAwardResult> awardXp(int amount, String reason) async {
    try {
      LogManager.debug(
        '[TierApiClient] Awarding $amount XP (reason: $reason) (MOCK)',
      );

      // Simulate API call delay
      await Future.delayed(const Duration(milliseconds: 100));

      final result = XpAwardResult(
        xpAwarded: amount,
        totalXp: 0, // Would be fetched from backend
        newLevel: 0, // Would be calculated by backend
        tierUpgraded: false, // Would be determined by backend
      );

      LogManager.debug('[TierApiClient] XP awarded (MOCK)');
      return result;
    } catch (e) {
      LogManager.error(
        '[TierApiClient] Error awarding XP: $e',
        source: 'TierApiClient.awardXp',
        error: e,
      );
      rethrow;
    }
  }
}

/// Tier definition
class TierDefinition {
  final String id; // Unique identifier
  final String name; // Display name
  final int level; // Player level for this tier
  final int minXp; // Minimum XP to reach this tier
  final int maxXp; // Maximum XP in this tier
  final String iconName; // Icon/image name
  final TierReward rewards; // Rewards for reaching this tier

  TierDefinition({
    required this.id,
    required this.name,
    required this.level,
    required this.minXp,
    required this.maxXp,
    required this.iconName,
    required this.rewards,
  });

  /// XP range for this tier
  int get xpRange => maxXp - minXp;

  /// Is this the final tier?
  bool get isFinalTier => maxXp == double.maxFinite.toInt();

  factory TierDefinition.fromJson(Map<String, dynamic> json) {
    return TierDefinition(
      id: json['id'] ?? '',
      name: json['name'] ?? 'Unknown Tier',
      level: json['level'] ?? 1,
      minXp: json['minXp'] ?? json['min_xp'] ?? 0,
      maxXp: json['maxXp'] ?? json['max_xp'] ?? 999999,
      iconName: json['iconName'] ?? json['icon_name'] ?? 'tier_icon',
      rewards: TierReward.fromJson(json['rewards'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'level': level,
    'minXp': minXp,
    'maxXp': maxXp,
    'iconName': iconName,
    'rewards': rewards.toJson(),
  };
}

/// Rewards for reaching a tier
class TierReward {
  final String badge; // Badge name/id
  final int coinsBonus; // Coins reward
  final int gemsBonus; // Gems reward

  TierReward({
    required this.badge,
    required this.coinsBonus,
    required this.gemsBonus,
  });

  factory TierReward.fromJson(Map<String, dynamic> json) {
    return TierReward(
      badge: json['badge'] ?? 'unknown_badge',
      coinsBonus: json['coinsBonus'] ?? json['coins_bonus'] ?? 0,
      gemsBonus: json['gemsBonus'] ?? json['gems_bonus'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'badge': badge,
    'coinsBonus': coinsBonus,
    'gemsBonus': gemsBonus,
  };
}

/// Player's current tier progress
class PlayerTierProgress {
  final TierDefinition currentTier;
  final TierDefinition? nextTier; // Null if at max tier
  final int currentXp;
  final int xpInCurrentTier;
  final int xpNeededForNextTier;
  final int progressPercentage; // 0-100

  PlayerTierProgress({
    required this.currentTier,
    this.nextTier,
    required this.currentXp,
    required this.xpInCurrentTier,
    required this.xpNeededForNextTier,
    required this.progressPercentage,
  });

  /// Is player at max tier?
  bool get isMaxTier => nextTier == null;

  factory PlayerTierProgress.fromJson(Map<String, dynamic> json) {
    return PlayerTierProgress(
      currentTier: TierDefinition.fromJson(json['currentTier'] ?? {}),
      nextTier: json['nextTier'] != null
          ? TierDefinition.fromJson(json['nextTier'])
          : null,
      currentXp: json['currentXp'] ?? json['current_xp'] ?? 0,
      xpInCurrentTier: json['xpInCurrentTier'] ?? json['xp_in_current_tier'] ?? 0,
      xpNeededForNextTier: json['xpNeededForNextTier'] ?? json['xp_needed_for_next_tier'] ?? 0,
      progressPercentage: json['progressPercentage'] ?? json['progress_percentage'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'currentTier': currentTier.toJson(),
    'nextTier': nextTier?.toJson(),
    'currentXp': currentXp,
    'xpInCurrentTier': xpInCurrentTier,
    'xpNeededForNextTier': xpNeededForNextTier,
    'progressPercentage': progressPercentage,
  };
}

/// Result of awarding XP
class XpAwardResult {
  final int xpAwarded;
  final int totalXp;
  final int newLevel;
  final bool tierUpgraded;

  XpAwardResult({
    required this.xpAwarded,
    required this.totalXp,
    required this.newLevel,
    required this.tierUpgraded,
  });

  factory XpAwardResult.fromJson(Map<String, dynamic> json) {
    return XpAwardResult(
      xpAwarded: json['xpAwarded'] ?? json['xp_awarded'] ?? 0,
      totalXp: json['totalXp'] ?? json['total_xp'] ?? 0,
      newLevel: json['newLevel'] ?? json['new_level'] ?? 1,
      tierUpgraded: json['tierUpgraded'] ?? json['tier_upgraded'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'xpAwarded': xpAwarded,
    'totalXp': totalXp,
    'newLevel': newLevel,
    'tierUpgraded': tierUpgraded,
  };
}
