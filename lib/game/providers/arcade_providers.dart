/// Arcade, seasonal, tier, mission, and flow-connect providers.
///
/// Depends on [core_providers.dart] and [game_providers.dart].
library;

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../arcade/leaderboards/local_arcade_leaderboard_service.dart';
import '../../arcade/leaderboards/arcade_leaderboard_api_service.dart';
import '../../arcade/missions/arcade_mission_service.dart';
import '../../arcade/services/arcade_mission_claim_service.dart';
import '../../core/env.dart';
import '../../core/manager/tier_manager.dart';
import '../../core/services/asset_resolver.dart';
import '../../core/services/tier_api_client.dart';
import '../../core/state/flow_connect_state_notifier.dart';
import '../../game/data/mission_data_loader.dart';
import '../../game/models/badge.dart';
import '../../game/models/champion_event.dart';
import '../../game/models/champion_prediction.dart';
import '../../game/models/season_tiebreaker.dart';
import '../../game/models/seasonal_competition_model.dart';
import '../../game/models/tier_model.dart';
import '../../game/services/flow_connect_level_generator.dart';
import '../../game/services/seasonal_competition_service.dart';
import '../../game/state/tier_progression_state.dart';
import '../../game/state/tier_update_result.dart';
import '../../core/services/arcade/spin_wheel_api_service.dart';
import '../../core/services/matches_api_client.dart';
import '../../features/reward_reactor/services/reward_reactor_service.dart';
import '../../ui_components/spin_wheel/controllers/spining_controller.dart';
import '../../ui_components/spin_wheel/services/segment_loader.dart';
import 'core_providers.dart';
import 'game_providers.dart';

// ---------------------------------------------------------------------------
// Spin Wheel
// ---------------------------------------------------------------------------

final spinWheelApiServiceProvider = Provider<SpinWheelApiService>((ref) {
  return SpinWheelApiService(
    ref.read(apiServiceProvider),
    encryptedClient: ref.read(encryptedApiClientProvider),
  );
});

final matchesApiClientProvider = Provider<MatchesApiClient>((ref) {
  return MatchesApiClient(ref.read(apiServiceProvider));
});

final rewardReactorServiceProvider = Provider<RewardReactorService>((ref) {
  return BackendRewardReactorService(
    ref.read(apiServiceProvider),
    ref.read(encryptedApiClientProvider),
  );
});

final segmentLoaderProvider = Provider<SegmentLoader>((ref) {
  final manager = ref.read(serviceManagerProvider);
  return SegmentLoader(
    appCache: manager.appCacheService,
    configStorage: manager.configStorageService,
    spinWheelService: manager.spinWheelSettingsService,
    generalKeyStorage: manager.generalKeyValueStorageService,
    source: SegmentSource.remote,
    apiService: ref.read(apiServiceProvider),
  );
});

final spinningControllerProvider =
    ChangeNotifierProvider<EnhancedSpinningController>((ref) {
  return EnhancedSpinningController(ref);
});

// ---------------------------------------------------------------------------
// Badges
// ---------------------------------------------------------------------------

final badgeProvider = FutureProvider<List<GameBadge>>((ref) async {
  final jsonString =
      await AssetResolver.instance.loadString('game-config/badge-icons');
  final List<dynamic> jsonData = json.decode(jsonString);
  return jsonData.map((e) => GameBadge.fromJson(e)).toList();
});

// ---------------------------------------------------------------------------
// Seasonal competition
// ---------------------------------------------------------------------------

final seasonalCompetitionServiceProvider =
    Provider<SeasonalCompetitionService>((ref) {
  final storage = ref.read(generalKeyValueStorageProvider);
  final apiService = ref.read(apiServiceProvider);
  return SeasonalCompetitionService(storage, apiService);
});

final seasonEndTimeProvider = FutureProvider<DateTime>((ref) async {
  final service = ref.read(seasonalCompetitionServiceProvider);
  return await service.getSeasonEndTime();
});

final timeRemainingProvider = StreamProvider<Duration>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (i) async {
    final service = ref.read(seasonalCompetitionServiceProvider);
    return await service.getTimeRemaining();
  }).asyncMap((future) => future);
});

final seasonLeaderboardProvider =
    FutureProvider<List<SeasonPlayer>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final seasonService = ref.read(seasonalCompetitionServiceProvider);
  final seasonId = await seasonService.getCurrentSeasonId();
  return await apiService.getSeasonLeaderboard(seasonId);
});

/// The authenticated player's pending end-of-season tie-breakers
/// (GET /seasons/tiebreakers/mine). Resolves to an empty list on any
/// failure — including an unreachable backend — so UI can simply hide
/// the banner.
final myTiebreakersProvider =
    FutureProvider<List<SeasonTiebreaker>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  try {
    final tiebreakers = await apiService.getMyTiebreakers();
    return tiebreakers.where((t) => t.isPending).toList();
  } catch (_) {
    return const [];
  }
});

/// The current weekly "Champion vs Tier" headline event, if one is
/// scheduled/open/live. Null when there's none or the backend is
/// unreachable, so the card simply hides.
final championEventProvider = FutureProvider<ChampionEvent?>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  try {
    final events = await apiService.getUpcomingGameEvents();
    final summary = events
        .where((e) => e.isChampionVsTier && e.status != 'Closed')
        .firstOrNull;
    if (summary == null) return null;
    // Fetch full status so the card can show jackpot/champion/alive count.
    try {
      return await apiService.getGameEventStatus(summary.id);
    } catch (_) {
      return summary; // fall back to the summary shape
    }
  } catch (_) {
    return null;
  }
});

/// The caller's no-loss prediction state for a champion event (null if none /
/// backend unreachable, so the panel simply hides).
final championPredictionProvider =
    FutureProvider.family<ChampionPrediction?, String>(
        (ref, gameEventId) async {
  final apiService = ref.read(apiServiceProvider);
  return apiService.getPrediction(gameEventId);
});

// ---------------------------------------------------------------------------
// Missions
// ---------------------------------------------------------------------------

final childrenMissionsProvider =
    StateNotifierProvider<LiveMissionsNotifier, List<Map<String, dynamic>>>(
        (ref) {
  return LiveMissionsNotifier(AgeGroup.children);
});

final adolescenceMissionsProvider =
    StateNotifierProvider<LiveMissionsNotifier, List<Map<String, dynamic>>>(
        (ref) {
  return LiveMissionsNotifier(AgeGroup.adolescence);
});

final adultsMissionsProvider =
    StateNotifierProvider<LiveMissionsNotifier, List<Map<String, dynamic>>>(
        (ref) {
  return LiveMissionsNotifier(AgeGroup.adults);
});

final currentUserAgeGroupProvider = Provider<AgeGroup>((ref) {
  return AgeGroup.adolescence;
});

final liveMissionsProvider =
    StateNotifierProvider<LiveMissionsNotifier, List<Map<String, dynamic>>>(
        (ref) {
  final ageGroup = ref.watch(currentUserAgeGroupProvider);
  switch (ageGroup) {
    case AgeGroup.children:
      return ref.watch(childrenMissionsProvider.notifier);
    case AgeGroup.adolescence:
      return ref.watch(adolescenceMissionsProvider.notifier);
    case AgeGroup.adults:
      return ref.watch(adultsMissionsProvider.notifier);
  }
});

final missionActionsProvider = Provider<MissionActions>((ref) {
  return MissionActions(ref);
});

// ---------------------------------------------------------------------------
// Arcade
// ---------------------------------------------------------------------------

final arcadeMissionServiceProvider = Provider<ArcadeMissionService>((ref) {
  return ref.read(serviceManagerProvider).arcadeMissionService;
});

final localArcadeLeaderboardServiceProvider =
    Provider<LocalArcadeLeaderboardService>((ref) {
  return ref.read(serviceManagerProvider).localArcadeLeaderboardService;
});

final localArcadeLeaderboardProvider =
    Provider<LocalArcadeLeaderboardService>((ref) {
  final cache = ref.read(appCacheServiceProvider);
  return LocalArcadeLeaderboardService(cache);
});

final arcadeMissionClaimServiceProvider =
    Provider<ArcadeMissionClaimService>((ref) {
  final cache = ref.read(appCacheServiceProvider);
  return ArcadeMissionClaimService(cache);
});

final arcadeLeaderboardApiServiceProvider =
    Provider<ArcadeLeaderboardApiService>((ref) {
  final apiClient = ref.read(synaptixApiClientProvider);
  return ArcadeLeaderboardApiService(apiClient);
});

// ---------------------------------------------------------------------------
// Tier system
// ---------------------------------------------------------------------------

final tierManagerProvider = Provider<TierManager>((ref) {
  final storage = ref.read(generalKeyValueStorageProvider);
  final profileService = ref.read(playerProfileServiceProvider);
  final tierApiClient = TierApiClient(
    httpClient: ref.watch(authHttpClientProvider),
    baseUrl: EnvConfig.apiV1BaseUrl,
  );

  return TierManager(
    storage,
    profileService,
    tierApiClient: tierApiClient,
  );
});

final currentTierProvider = FutureProvider<TierModel?>((ref) async {
  final tierManager = ref.read(tierManagerProvider);
  return await tierManager.getCurrentTier();
});

final allTiersProvider = FutureProvider<List<TierModel>>((ref) async {
  final tierManager = ref.read(tierManagerProvider);
  return await tierManager.getAllTiers();
});

final currentTierIdProvider = FutureProvider<int>((ref) async {
  final tierManager = ref.read(tierManagerProvider);
  return await tierManager.getCurrentTierId();
});

final tierProgressionProvider =
    StateNotifierProvider<TierProgressionNotifier, TierProgressionState>((ref) {
  final tierManager = ref.read(tierManagerProvider);
  return TierProgressionNotifier(tierManager, ref);
});

final nextTierProvider = FutureProvider<TierModel?>((ref) async {
  final currentTierId = await ref.watch(currentTierIdProvider.future);
  final allTiers = await ref.watch(allTiersProvider.future);
  if (currentTierId < allTiers.length - 1) {
    return allTiers[currentTierId + 1];
  }
  return null;
});

final tierProgressPercentageProvider = FutureProvider<double>((ref) async {
  final profileService = ref.read(playerProfileServiceProvider);
  final profile = profileService.getProfile();
  final currentXP = profile['currentXP'] ?? 0;

  final nextTier = await ref.watch(nextTierProvider.future);
  if (nextTier == null) return 100.0;

  final currentTierId = await ref.watch(currentTierIdProvider.future);
  final tierManager = ref.read(tierManagerProvider);
  final currentTier = tierManager.getTierById(currentTierId);

  if (currentTier == null) return 0.0;

  final xpInCurrentTier = currentXP - currentTier.requiredXP;
  final xpNeededForNext = nextTier.requiredXP - currentTier.requiredXP;

  if (xpNeededForNext <= 0) return 100.0;
  return (xpInCurrentTier / xpNeededForNext * 100).clamp(0.0, 100.0);
});

// ---------------------------------------------------------------------------
// Tier extension helpers (for WidgetRef)
// ---------------------------------------------------------------------------

extension TierProviderExtensions on WidgetRef {
  Future<TierUpdateResult> checkTierProgression() async {
    return await read(tierProgressionProvider.notifier).updateTierProgress();
  }

  TierModel? getCurrentTierSync() {
    return read(currentTierProvider).value;
  }

  int? getCurrentTierIdSync() {
    return read(currentTierIdProvider).value;
  }
}

// ---------------------------------------------------------------------------
// Flow Connect mini-game
// ---------------------------------------------------------------------------

@immutable
class FlowSettings {
  final int gridSize;
  final FlowConnectDifficulty difficulty;

  const FlowSettings(
      {this.gridSize = 5, this.difficulty = FlowConnectDifficulty.easy});

  FlowSettings copyWith({int? gridSize, FlowConnectDifficulty? difficulty}) {
    return FlowSettings(
      gridSize: gridSize ?? this.gridSize,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

class FlowSettingsNotifier extends StateNotifier<FlowSettings> {
  FlowSettingsNotifier() : super(const FlowSettings());

  void setGridSize(int size) {
    state = state.copyWith(gridSize: size);
  }

  void setDifficulty(FlowConnectDifficulty difficulty) {
    state = state.copyWith(difficulty: difficulty);
  }
}

final flowSettingsProvider =
    StateNotifierProvider<FlowSettingsNotifier, FlowSettings>((ref) {
  return FlowSettingsNotifier();
});

final flowConnectStateProvider =
    ChangeNotifierProvider.autoDispose<FlowConnectStateNotifier>((ref) {
  final settings = ref.watch(flowSettingsProvider);
  return FlowConnectStateNotifier(
    gridSize: settings.gridSize,
    difficulty: settings.difficulty,
    onPuzzleComplete: null,
  );
});
