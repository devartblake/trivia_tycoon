import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/core/manager/log_manager.dart';
import 'package:synaptix/core/services/settings/general_key_value_storage_service.dart';
import 'package:synaptix/core/services/tier_api_client.dart';
import 'tier_progression_service.dart';

/// Service for managing tier reward distribution
/// Tracks which tier rewards have been claimed and awards them to players
class TierRewardsService {
  final TierProgressionService _tierProgressionService;
  final GeneralKeyValueStorageService _storage;

  static const String _claimedTiersKey = 'claimed_tier_rewards';

  TierRewardsService({
    required TierProgressionService tierProgressionService,
    required GeneralKeyValueStorageService storage,
    required Ref ref,
  })  : _tierProgressionService = tierProgressionService,
        _storage = storage;

  /// Check for unclaimed tier rewards and award them
  /// Returns list of newly claimed tiers
  Future<List<String>> claimPendingRewards(String userId) async {
    try {
      final claimedTiers = await _getClaimedTiers();
      final progress =
          await _tierProgressionService.getPlayerTierProgress(userId);
      final currentTierId = progress.currentTier.id;

      // Check if current tier reward has been claimed
      if (claimedTiers.contains(currentTierId)) {
        return [];
      }

      // Award current tier rewards
      await _awardTierRewards(
        userId: userId,
        tier: progress.currentTier,
      );

      // Mark as claimed
      claimedTiers.add(currentTierId);
      await _saveClaimedTiers(claimedTiers);

      LogManager.debug(
        '[TierRewardsService] Claimed rewards for tier: ${progress.currentTier.name}',
      );

      return [currentTierId];
    } catch (e) {
      LogManager.error(
        '[TierRewardsService] Error claiming pending rewards: $e',
        error: e,
      );
      return [];
    }
  }

  /// Award rewards for reaching a tier
  Future<void> _awardTierRewards({
    required String userId,
    required TierDefinition tier,
  }) async {
    try {
      final reward = tier.rewards;

      // Award coins
      if (reward.coinsBonus > 0) {
        LogManager.debug(
          '[TierRewardsService] Awarding ${reward.coinsBonus} coins for tier: ${tier.name}',
        );
        // TODO: Call currency manager to award coins
        // await _currencyManager.earnFromAction(
        //   'tier_reward_${tier.id}',
        //   type: CurrencyType.coins,
        //   amount: reward.coinsBonus,
        // );
      }

      // Award gems
      if (reward.gemsBonus > 0) {
        LogManager.debug(
          '[TierRewardsService] Awarding ${reward.gemsBonus} gems for tier: ${tier.name}',
        );
        // TODO: Call currency manager to award gems
        // await _currencyManager.earnFromAction(
        //   'tier_reward_${tier.id}',
        //   type: CurrencyType.diamonds,
        //   amount: reward.gemsBonus,
        // );
      }

      // Award badge
      if (reward.badge.isNotEmpty) {
        LogManager.debug(
          '[TierRewardsService] Unlocking badge for tier: ${tier.name}',
        );
        // TODO: Call badge system to unlock badge
        // await _badgeService.unlockBadge(reward.badge);
      }
    } catch (e) {
      LogManager.error(
        '[TierRewardsService] Error awarding tier rewards: $e',
        error: e,
      );
    }
  }

  /// Get list of claimed tier reward IDs
  Future<List<String>> _getClaimedTiers() async {
    try {
      final stored = await _storage.getStringList(_claimedTiersKey);
      return stored ?? [];
    } catch (e) {
      LogManager.warning(
        '[TierRewardsService] Failed to load claimed tiers: $e',
      );
      return [];
    }
  }

  /// Save claimed tier reward IDs
  Future<void> _saveClaimedTiers(List<String> tierIds) async {
    try {
      await _storage.setStringList(_claimedTiersKey, tierIds);
    } catch (e) {
      LogManager.error(
        '[TierRewardsService] Failed to save claimed tiers: $e',
        error: e,
      );
    }
  }

  /// Reset claimed tier rewards (for testing or admin operations)
  Future<void> resetClaimedRewards() async {
    try {
      await _storage.remove(_claimedTiersKey);
      LogManager.debug('[TierRewardsService] Claimed tier rewards reset');
    } catch (e) {
      LogManager.error(
        '[TierRewardsService] Failed to reset claimed rewards: $e',
        error: e,
      );
    }
  }

  /// Check if a specific tier reward has been claimed
  Future<bool> hasTierRewardBeenClaimed(String tierId) async {
    final claimed = await _getClaimedTiers();
    return claimed.contains(tierId);
  }

  /// Get all unclaimed tier IDs for a player
  Future<List<String>> getUnclaimedTiers(String userId) async {
    try {
      final claimed = await _getClaimedTiers();
      final progress =
          await _tierProgressionService.getPlayerTierProgress(userId);

      // For now, just the current tier if not claimed
      final unclaimed = <String>[];
      if (!claimed.contains(progress.currentTier.id)) {
        unclaimed.add(progress.currentTier.id);
      }

      return unclaimed;
    } catch (e) {
      LogManager.error(
        '[TierRewardsService] Error getting unclaimed tiers: $e',
        error: e,
      );
      return [];
    }
  }
}
