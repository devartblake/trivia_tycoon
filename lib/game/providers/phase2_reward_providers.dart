import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/daily_bonus_api_client.dart';
import '../../core/services/weekly_rewards_api_client.dart';
import '../../core/services/tier_api_client.dart';
import '../../core/manager/log_manager.dart';
import '../../core/env.dart';
import '../../ui_components/spin_wheel/services/tier_config_cache.dart';
import 'auth_providers.dart';
import 'core_providers.dart';

/// ============================================================================
/// Phase 2: Daily Bonus Providers
/// ============================================================================

/// Provides the DailyBonusApiClient instance
final dailyBonusApiClientProvider = Provider<DailyBonusApiClient>((ref) {
  LogManager.debug('[Phase2] Initializing DailyBonusApiClient');
  return DailyBonusApiClient(
    httpClient: ref.watch(authHttpClientProvider),
    baseUrl: EnvConfig.apiV1BaseUrl,
  );
});

/// Fetch daily bonus configuration (reward amount, type, display info)
final dailyBonusConfigProvider = FutureProvider<DailyRewardConfig>((ref) async {
  try {
    LogManager.debug('[Phase2] Fetching daily bonus config...');
    final client = ref.watch(dailyBonusApiClientProvider);
    final config = await client.getDailyConfig();
    LogManager.debug('[Phase2] Daily bonus config loaded');
    return config;
  } catch (e) {
    LogManager.error(
      '[Phase2] Error fetching daily bonus config: $e',
      source: 'dailyBonusConfigProvider',
      error: e,
    );
    rethrow;
  }
});

/// Fetch account reward status (has claimed today, streak, next claim time)
final dailyBonusStatusProvider =
    FutureProvider.autoDispose<AccountRewardStatus>((ref) async {
  final client = ref.watch(dailyBonusApiClientProvider);

  try {
    LogManager.debug('[Phase2] Fetching daily bonus status...');
    final hasSession = await _ensureAccountRewardSession(ref);
    if (!hasSession) {
      throw DailyBonusException(
        message:
            'Daily bonus account status requires a player session; device bootstrap did not return tokens',
        statusCode: 401,
      );
    }

    final status = await client.getAccountRewardStatus();
    LogManager.debug(
        '[Phase2] Daily bonus status: claimed=${status.claimedToday}');
    return status;
  } on DailyBonusException catch (e) {
    if (e.statusCode == 401 && !ref.read(authTokenStoreProvider).hasTokens()) {
      final recoveredSession = await _ensureAccountRewardSession(ref);
      if (recoveredSession) {
        LogManager.debug(
          '[Phase2] Retrying daily bonus status after player session bootstrap',
        );
        final status = await client.getAccountRewardStatus();
        LogManager.debug(
          '[Phase2] Daily bonus status: claimed=${status.claimedToday}',
        );
        return status;
      }
    }

    LogManager.error(
      '[Phase2] Error fetching daily bonus status: $e',
      source: 'dailyBonusStatusProvider',
      error: e,
    );
    rethrow;
  } catch (e) {
    LogManager.error(
      '[Phase2] Error fetching daily bonus status: $e',
      source: 'dailyBonusStatusProvider',
      error: e,
    );
    rethrow;
  }
});

Future<bool> _ensureAccountRewardSession(Ref ref) async {
  final tokenStore = ref.read(authTokenStoreProvider);
  if (tokenStore.hasTokens()) return true;

  LogManager.debug(
    '[Phase2] No player session for account rewards; bootstrapping identity',
  );
  await ref.read(playerIdentityProvider.notifier).initialize();
  return tokenStore.hasTokens();
}

/// Claim daily reward - returns the claimed amount and new totals
final dailyBonusClaimProvider =
    FutureProvider.autoDispose<RewardClaimResult>((ref) async {
  try {
    LogManager.debug('[Phase2] Claiming daily bonus...');
    final client = ref.watch(dailyBonusApiClientProvider);
    final result = await client.claimDailyReward();
    LogManager.debug(
        '[Phase2] Daily bonus claimed: ${result.coinsAwarded} coins');
    // Invalidate status to refresh after claim
    ref.invalidate(dailyBonusStatusProvider);
    return result;
  } catch (e) {
    LogManager.error(
      '[Phase2] Error claiming daily bonus: $e',
      source: 'dailyBonusClaimProvider',
      error: e,
    );
    rethrow;
  }
});

/// ============================================================================
/// Phase 2: Weekly Rewards Providers
/// ============================================================================

/// Provides the WeeklyRewardsApiClient instance
final weeklyRewardsApiClientProvider = Provider<WeeklyRewardsApiClient>((ref) {
  LogManager.debug('[Phase2] Initializing WeeklyRewardsApiClient');
  return WeeklyRewardsApiClient(
    httpClient: ref.watch(authHttpClientProvider),
    baseUrl: EnvConfig.apiV1BaseUrl,
  );
});

/// Fetch weekly reward schedule (7-day progression)
final weeklyScheduleProvider =
    FutureProvider<List<WeeklyRewardDay>>((ref) async {
  try {
    LogManager.debug('[Phase2] Fetching weekly reward schedule...');
    final client = ref.watch(weeklyRewardsApiClientProvider);
    final schedule = await client.getWeeklySchedule();
    LogManager.debug(
        '[Phase2] Weekly schedule loaded: ${schedule.length} days');
    return schedule;
  } catch (e) {
    LogManager.error(
      '[Phase2] Error fetching weekly schedule: $e',
      source: 'weeklyScheduleProvider',
      error: e,
    );
    rethrow;
  }
});

/// Fetch player's weekly streak status (current day, days claimed, reset date)
final weeklyStreakProvider =
    FutureProvider.autoDispose<WeeklyStreakStatus>((ref) async {
  try {
    LogManager.debug('[Phase2] Fetching weekly streak status...');
    final client = ref.watch(weeklyRewardsApiClientProvider);
    final userId = ref.watch(currentUserIdProvider);
    final streak = await client.getWeeklyStreak(userId);
    LogManager.debug(
      '[Phase2] Weekly streak: day ${streak.currentDay}/7, claimed ${streak.daysClaimedCount}',
    );
    return streak;
  } catch (e) {
    LogManager.error(
      '[Phase2] Error fetching weekly streak: $e',
      source: 'weeklyStreakProvider',
      error: e,
    );
    rethrow;
  }
});

/// Claim weekly reward for current day
final weeklyClaimProvider =
    FutureProvider.autoDispose<WeeklyRewardClaimResult>((ref) async {
  try {
    LogManager.debug('[Phase2] Claiming weekly reward...');
    final client = ref.watch(weeklyRewardsApiClientProvider);
    final userId = ref.watch(currentUserIdProvider);
    final streak = await client.getWeeklyStreak(userId);
    final result = await client.claimWeeklyReward(day: streak.currentDay);
    LogManager.debug('[Phase2] Weekly reward claimed: Day ${result.dayNumber}');
    // Invalidate streak to refresh after claim
    ref.invalidate(weeklyStreakProvider);
    return result;
  } catch (e) {
    LogManager.error(
      '[Phase2] Error claiming weekly reward: $e',
      source: 'weeklyClaimProvider',
      error: e,
    );
    rethrow;
  }
});

/// ============================================================================
/// Phase 2: Tier System Providers (MOCK - will be replaced with real API)
/// ============================================================================

/// Current user ID for tier progression - uses "current-user" as fallback
final currentUserIdProvider = Provider<String>((ref) {
  final userId = ref.watch(authTokenStoreProvider).load().userId;
  if (userId == null || userId.isEmpty) {
    LogManager.debug('[Phase2] No authenticated user ID for tier progression');
    return '';
  }

  return userId;
});

/// Provides the TierApiClient instance
/// Now supports real API with mock fallback
final tierApiClientProvider = Provider<TierApiClient>((ref) {
  LogManager.debug('[Phase2] Initializing TierApiClient with real API support');
  return TierApiClient(
    httpClient: ref.watch(authHttpClientProvider),
    baseUrl: EnvConfig.apiV1BaseUrl,
  );
});

final tierConfigCacheProvider = Provider<TierConfigCache>((ref) {
  return TierConfigCache(apiClient: ref.watch(tierApiClientProvider));
});

/// Fetch all tier definitions (7-tier progression system)
final tierDefinitionsProvider =
    FutureProvider<List<TierDefinition>>((ref) async {
  try {
    LogManager.debug('[Phase2] Fetching tier definitions...');
    final cache = ref.watch(tierConfigCacheProvider);
    final tiers = await cache.getTierDefinitions();
    LogManager.debug('[Phase2] Tier definitions loaded: ${tiers.length} tiers');
    return tiers;
  } catch (e) {
    LogManager.error(
      '[Phase2] Error fetching tier definitions: $e',
      source: 'tierDefinitionsProvider',
      error: e,
    );
    rethrow;
  }
});

/// Fetch player's current tier progress (current tier, progress %, next tier)
/// Takes userId as a parameter to fetch player-specific data from API
final playerTierProgressProvider = FutureProvider.autoDispose
    .family<PlayerTierProgress, String>((ref, userId) async {
  try {
    LogManager.debug(
        '[Phase2] Fetching player tier progress for userId=$userId...');
    final cache = ref.watch(tierConfigCacheProvider);
    final progress = await cache.getPlayerTierProgress(userId);
    LogManager.debug(
      '[Phase2] Player tier: ${progress.currentTier.name}, Progress: ${progress.progressPercentage}%',
    );
    return progress;
  } catch (e) {
    LogManager.error(
      '[Phase2] Error fetching player tier progress: $e',
      source: 'playerTierProgressProvider',
      error: e,
    );
    rethrow;
  }
});

/// Award XP to player via API with real backend support
/// Parameters: (userId, amount, reason)
final awardXpProvider = FutureProvider.family<XpAwardResult,
    (String userId, int amount, String reason)>((
  ref,
  params,
) async {
  try {
    final (userId, amount, reason) = params;
    LogManager.debug(
        '[Phase2] Awarding $amount XP to user=$userId: $reason...');
    final cache = ref.watch(tierConfigCacheProvider);
    final result = await cache.awardXp(userId, amount, reason);
    LogManager.debug('[Phase2] XP awarded successfully');
    // Invalidate player progress to refresh
    ref.invalidate(playerTierProgressProvider(userId));
    return result;
  } catch (e) {
    LogManager.error(
      '[Phase2] Error awarding XP: $e',
      source: 'awardXpProvider',
      error: e,
    );
    rethrow;
  }
});

/// ============================================================================
/// Phase 2: Combined Reward Status Provider
/// ============================================================================

/// Combined reward status including daily, weekly, and tier info
/// Useful for dashboard or rewards home screen
/// Takes userId as parameter to fetch player-specific tier data
final combinedRewardStatusProvider =
    FutureProvider.autoDispose.family<CombinedRewardStatus, String>((
  ref,
  userId,
) async {
  try {
    LogManager.debug(
        '[Phase2] Fetching combined reward status for user=$userId...');

    // Get API clients
    final dailyClient = ref.watch(dailyBonusApiClientProvider);
    final weeklyClient = ref.watch(weeklyRewardsApiClientProvider);
    final tierCache = ref.watch(tierConfigCacheProvider);

    // Fetch all reward data in parallel
    final results = await Future.wait([
      dailyClient.getDailyConfig(),
      dailyClient.getAccountRewardStatus(),
      weeklyClient.getWeeklySchedule(),
      weeklyClient.getWeeklyStreak(userId),
      tierCache.getPlayerTierProgress(userId),
    ]);

    final status = CombinedRewardStatus(
      dailyConfig: results[0] as DailyRewardConfig,
      dailyStatus: results[1] as AccountRewardStatus,
      weeklySchedule: results[2] as List<WeeklyRewardDay>,
      weeklyStreak: results[3] as WeeklyStreakStatus,
      tierProgress: results[4] as PlayerTierProgress,
    );

    LogManager.debug('[Phase2] Combined reward status loaded');
    return status;
  } catch (e) {
    LogManager.error(
      '[Phase2] Error fetching combined reward status: $e',
      source: 'combinedRewardStatusProvider',
      error: e,
    );
    rethrow;
  }
});

/// ============================================================================
/// Model Classes for Combined Status
/// ============================================================================

class CombinedRewardStatus {
  final DailyRewardConfig dailyConfig;
  final AccountRewardStatus dailyStatus;
  final List<WeeklyRewardDay> weeklySchedule;
  final WeeklyStreakStatus weeklyStreak;
  final PlayerTierProgress tierProgress;

  CombinedRewardStatus({
    required this.dailyConfig,
    required this.dailyStatus,
    required this.weeklySchedule,
    required this.weeklyStreak,
    required this.tierProgress,
  });

  /// Check if player can claim daily reward
  bool get canClaimDaily => !dailyStatus.claimedToday;

  /// Check if player can claim weekly reward
  bool get canClaimWeekly =>
      weeklyStreak.currentDay <= weeklySchedule.length &&
      !weeklySchedule[weeklyStreak.currentDay - 1].claimed! &&
      weeklyStreak.daysClaimedCount < weeklySchedule.length;

  /// Get next unclaimed day in weekly schedule
  int? get nextUnclaimedWeeklyDay {
    for (int i = 0; i < weeklySchedule.length; i++) {
      if (weeklySchedule[i].claimed != true) {
        return i + 1;
      }
    }
    return null;
  }

  /// Check if player is at max tier
  bool get isMaxTier => tierProgress.isMaxTier;

  /// Get progress percentage for current tier
  int get tierProgressPercentage => tierProgress.progressPercentage;
}
