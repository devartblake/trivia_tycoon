import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/tier_progression_service.dart';
import '../services/tier_rewards_service.dart';
import '../../core/env.dart';
import '../../core/services/tier_api_client.dart';
import 'game_providers.dart';
import 'core_providers.dart'
    show authHttpClientProvider, generalKeyValueStorageProvider;

// Export types for convenience
export '../services/tier_progression_service.dart' show TierProgressionService;
export '../services/tier_rewards_service.dart' show TierRewardsService;
export '../../core/services/tier_api_client.dart'
    show TierDefinition, TierReward, PlayerTierProgress;

/// Unified tier progression service provider
/// Uses TierApiClient as source of truth with local caching
final tierProgressionServiceProvider = Provider<TierProgressionService>((ref) {
  final tierApiClient = TierApiClient(
    httpClient: ref.watch(authHttpClientProvider),
    baseUrl: EnvConfig.apiV1BaseUrl,
  );
  final profileService = ref.read(playerProfileServiceProvider);

  return TierProgressionService(
    tierApiClient: tierApiClient,
    profileService: profileService,
  );
});

/// Get player's current tier progress
/// Rebuilds when tier data changes
final playerTierProgressProvider =
    FutureProvider.family<PlayerTierProgress, String>((ref, userId) async {
  final tierService = ref.watch(tierProgressionServiceProvider);
  return await tierService.getPlayerTierProgress(userId);
});

/// Get all tier definitions
/// Cached after first load
final tierDefinitionsProvider =
    FutureProvider<List<TierDefinition>>((ref) async {
  final tierService = ref.watch(tierProgressionServiceProvider);
  return await tierService.getTierDefinitions();
});

/// Tier rewards service provider
/// Manages tier reward distribution and tracking
final tierRewardsServiceProvider = Provider<TierRewardsService>((ref) {
  final tierService = ref.read(tierProgressionServiceProvider);
  final storage = ref.read(generalKeyValueStorageProvider);

  return TierRewardsService(
    tierProgressionService: tierService,
    storage: storage,
    ref: ref,
  );
});

/// Claim pending tier rewards for a player
/// Returns list of newly claimed tier IDs
final claimPendingRewardsProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final rewardsService = ref.watch(tierRewardsServiceProvider);
  return await rewardsService.claimPendingRewards(userId);
});

/// Get unclaimed tier rewards for a player
final unclaimedTiersProvider =
    FutureProvider.family<List<String>, String>((ref, userId) async {
  final rewardsService = ref.watch(tierRewardsServiceProvider);
  return await rewardsService.getUnclaimedTiers(userId);
});

/// Track last tier ID to detect tier changes
final _lastTierIdProvider = StateProvider<String?>((ref) => null);

/// Detect tier changes and return the new tier if changed
final tierChangeDetectorProvider =
    FutureProvider.family<TierDefinition?, String>((ref, userId) async {
  final progress = await ref.watch(playerTierProgressProvider(userId).future);
  final lastTierId = ref.watch(_lastTierIdProvider);
  final currentTierId = progress.currentTier.id;

  // Update the last tier ID
  if (lastTierId != currentTierId) {
    ref.read(_lastTierIdProvider.notifier).state = currentTierId;
    // Return the new tier so the caller knows there was a change
    return lastTierId != null ? progress.currentTier : null;
  }

  return null;
});
