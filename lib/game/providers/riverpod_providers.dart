import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/services/settings/admin_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/onboarding_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/core/services/settings/prize_log_service.dart';
import 'package:trivia_tycoon/core/services/settings/purchase_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/splash_settings_service.dart';
import 'package:trivia_tycoon/game/controllers/settings_controller.dart';
import 'package:trivia_tycoon/game/models/pvp_challenge_models.dart';

// 🔧 Core Services & Config
import '../../admin/controllers/admin_filter_controller.dart';
import '../../admin/states/admin_filter_state.dart';
import '../../arcade/leaderboards/local_arcade_leaderboard_service.dart';
import '../../arcade/missions/arcade_mission_service.dart';
import '../../arcade/services/arcade_daily_bonus_service.dart';
import '../../arcade/services/arcade_mission_claim_service.dart';
import '../../arcade/services/arcade_personal_best_service.dart';
import '../../core/bootstrap/app_init.dart';
import '../../core/manager/login_manager.dart';
import '../../core/manager/tier_manager.dart';
import '../../core/repositories/message_repository.dart';
import '../../core/services/encryption/encryption_service.dart';
import '../../core/services/encryption/fernet_service.dart';
import '../../core/services/event_queue_service.dart';
import '../../core/services/settings/audio_settings_service.dart';
import '../../core/services/settings/confetti_settings_service.dart';
import '../../core/services/settings/custom_theme_service.dart';
import '../../core/services/settings/general_key_value_storage_service.dart';
import '../../core/services/settings/qr_settings_service.dart';
import '../../core/services/settings/quiz_progress_service.dart';
import '../../core/services/settings/reward_settings_service.dart';
import '../../core/services/settings/spin_wheel_settings_service.dart';
import '../../core/services/settings/theme_settings_service.dart';
import '../../core/services/social/challenge_coordination_service.dart';
import '../../core/state/flow_connect_state_notifier.dart';
import '../../ui_components/login/providers/auth.dart';
import '../../ui_components/qr_code/models/qr_settings_model.dart';
import '../../ui_components/qr_code/services/qr_history_service.dart';
import '../../core/manager/service_manager.dart';
import '../../core/navigation/app_router.dart';
import '../../core/services/api_service.dart';
import '../../core/services/analytics/config_service.dart';
import '../../core/services/leaderboard_data_service.dart';
import '../../core/services/question/question_service.dart';
import '../../core/services/storage/secure_storage.dart';
import '../../core/services/storage/app_cache_service.dart';
import '../../core/services/theme/swatch_service.dart';

// Core auth imports
import '../../core/services/auth_service.dart' as core_auth;
import '../../core/services/auth_http_client.dart';
import '../../core/services/auth_api_client.dart';
import '../../core/services/auth_token_store.dart';
import '../../core/services/device_id_service.dart';
import '../../core/networking/http_client.dart';
import '../../core/networking/ws_client.dart';
import '../../core/networking/tycoon_api_client.dart';
import '../../core/env.dart';

// 📦 Store & Inventory
import '../../core/services/theme/theme_notifier.dart';
import '../analytics/services/analytics_service.dart';
import '../controllers/coin_balance_notifier.dart';
import '../controllers/energy_lives_notifier.dart';
import '../controllers/fernet_controller.dart';
import '../controllers/power_up_controller.dart';
import '../controllers/splash_controller.dart';
import '../data/mission_data_loader.dart';
import '../data/referral_repository.dart';
import '../models/conversation_models.dart';
import '../models/leaderboard_entry.dart';
import '../models/power_up.dart';
import '../models/referral_models.dart';
import '../models/seasonal_competition_model.dart';
import '../models/store_item_model.dart';
import '../models/tier_model.dart';
import '../services/achievement_service.dart';
import '../services/flow_connect_level_generator.dart';
import '../services/matches_service.dart';
import '../services/referral_api_service.dart';
import '../services/referral_invite_api_service.dart';
import '../services/referral_invite_service.dart';
import '../services/referral_invite_storage_service.dart';
import '../services/referral_service.dart';
import '../services/referral_storage_service.dart';
import '../services/seasonal_competition_service.dart';
import '../services/store_data_service.dart';

// 🧠 Game State & Controllers
import '../controllers/question_controller.dart';
import '../controllers/leaderboard_controller.dart';
import '../controllers/profile_avatar_controller.dart';
import '../state/premium_profile_state.dart';
import '../state/qr_settings_state.dart';
import '../state/question_state.dart';

// 🎊 Visual/Confetti
import '../../ui_components/confetti/core/confetti_controller.dart';

// 🎡 Spin Wheel
import '../../ui_components/spin_wheel/controllers/spining_controller.dart';
import '../../ui_components/spin_wheel/services/segment_loader.dart';

// 💰 Currency
import '../../core/manager/currency_manager.dart';
import '../models/currency_type.dart';

// 🎖️ Badges
import '../models/badge.dart';
import '../state/tier_progression_state.dart';
import '../state/tier_update_result.dart';
import 'message_providers.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

// Infrastructure providers (auth chain, storage, networking, router).
// Re-exported so all existing imports of riverpod_providers.dart continue to work.
export 'core_providers.dart';

// --- 🧠 Game Logic ---
/// Provides the SettingsController for theme/audio/etc
final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(
    audioService: ref.watch(audioSettingsServiceProvider),
    profileService: ref.watch(playerProfileServiceProvider),
    purchaseService: ref.watch(purchaseSettingsServiceProvider),
  );
});

/// Provides the AudioSettingsService from ServiceManager
final audioSettingsServiceProvider = Provider<AudioSettingsService>((ref) {
  return ref.watch(serviceManagerProvider).audioSettingsService;
});

final quizProgressServiceProvider = Provider<QuizProgressService>((ref) {
  final manager = ref.watch(serviceManagerProvider);
  return manager.quizProgressService;
});

final spinWheelSettingsServiceProvider =
    Provider<SpinWheelSettingsService>((ref) {
  return ref.watch(serviceManagerProvider).spinWheelSettingsService;
});

final confettiSettingsServiceProvider =
    Provider<ConfettiSettingsService>((ref) {
  return ref.watch(serviceManagerProvider).confettiSettingsService;
});

final themeSettingsServiceProvider = Provider<ThemeSettingsService>((ref) {
  return ref.watch(serviceManagerProvider).themeSettingsService;
});

final rewardSettingsServiceProvider = Provider<RewardSettingsService>((ref) {
  return ref.watch(serviceManagerProvider).rewardSettingsService;
});

final customThemeServiceProvider = Provider<CustomThemeService>((ref) {
  final manager = ref.read(serviceManagerProvider);
  return manager.customThemeService;
});

final authServiceProvider = Provider<LocalAuthService>((ref) {
  final manager = ref.watch(serviceManagerProvider);
  return manager.authService;
});

/// Provides the Player Profile from ServiceManger
final playerProfileServiceProvider = Provider<PlayerProfileService>((ref) {
  return ref.read(serviceManagerProvider).playerProfileService;
});

/// Provides the PurchaseSettingsService from ServiceManager
final purchaseSettingsServiceProvider =
    Provider<PurchaseSettingsService>((ref) {
  final manager = ref.read(serviceManagerProvider);
  return manager.purchaseSettingsService;
});

/// Provides the PrizeLodService from ServiceManager
final prizeLogServiceProvider = Provider<PrizeLogService>((ref) {
  return ref.read(serviceManagerProvider).prizeLogService;
});

/// Provides the OnboardingServiceProvider from ServiceManager
final onboardingSettingsServiceProvider =
    Provider<OnboardingSettingsService>((ref) {
  return ref.read(serviceManagerProvider).onboardingSettingsService;
});

/// Provides the AdminSettingsServiceProvider from ServiceManager
final adminSettingsServiceProvider = Provider<AdminSettingsService>((ref) {
  return ref.read(serviceManagerProvider).adminSettingsService;
});

/// Provides the AchievementService from ServiceManager
final achievementServiceProvider = Provider<AchievementService>((ref) {
  return ref.read(serviceManagerProvider).achievementService;
});

final questionControllerProvider =
    StateNotifierProvider<QuestionController, QuestionState>((ref) {
  return QuestionController(ref: ref);
});

/// Provides the singleton QuestionService instance
final questionServiceProvider = Provider<QuestionService>((ref) {
  return ref.read(serviceManagerProvider).questionService;
});

final leaderboardControllerProvider =
    ChangeNotifierProvider<LeaderboardController>((ref) {
  final dataService = ref.read(leaderboardDataServiceProvider);
  final storage = ref.read(generalKeyValueStorageProvider);
  return LeaderboardController(
      dataService: dataService, storage: storage, ref: ref);
});

final leaderboardDataServiceProvider = Provider<LeaderboardDataService>((ref) {
  final api = ref.watch(apiServiceProvider);
  final cache = ref.watch(appCacheServiceProvider);
  assetLoader() => ref.watch(leaderboardAssetProvider.future);
  return LeaderboardDataService(
    apiService: api,
    appCache: cache,
    assetLoader: assetLoader,
  );
});

/// Loads leaderboard.json from assets/data
final leaderboardAssetProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  final jsonStr =
      await rootBundle.loadString('assets/data/leaderboard/leaderboard.json');
  final List<dynamic> decoded = json.decode(jsonStr);
  return decoded.map((e) => LeaderboardEntry.fromJson(e)).toList();
});

final profileAvatarControllerProvider = ChangeNotifierProvider<ProfileAvatarController>((ref) {
  final serviceManager = ref.read(serviceManagerProvider);
  return ProfileAvatarController(
      keyValueStorage: serviceManager.generalKeyValueStorageService,
      appCache: serviceManager.appCacheService
  );
});

// --- 🎨 Theme & Visual Settings ---
final userAgeGroupProvider = StateProvider<String>((ref) => 'teens');

final themeSettingsProvider = Provider<ThemeSettingsService>((ref) {
  return ref.read(serviceManagerProvider).themeSettingsService;
});

/// Provides the ThemeNotifier from ServiceManager
final themeNotifierProvider = Provider<ThemeNotifier>((ref) {
  return ref.read(serviceManagerProvider).themeNotifier;
});

final swatchServiceProvider = Provider<SwatchService>((ref) {
  return ref.read(serviceManagerProvider).swatchService;
});

final splashSettingsServiceProvider = Provider<SplashSettingsService>((ref) {
  return ref.read(serviceManagerProvider).splashSettingsService;
});

final splashControllerProvider = Provider<SplashController>((ref) {
  final serviceManager = ref.read(serviceManagerProvider);
  return SplashController(
    onboardingService: serviceManager.onboardingSettingsService,
    splashSettingsService: serviceManager.splashSettingsService,
    analyticsService: serviceManager.analyticsService,
    authService: serviceManager.authService,
  );
});

// --- 🎊 Confetti System ---
final confettiControllerProvider =
    ChangeNotifierProvider<ConfettiController>((ref) {
  return ConfettiController();
});

// --- 💽 Local Storage Services ---

final qrSettingsServiceProvider = Provider<QrSettingsService>((ref) {
  return QrSettingsService();
});

final qrHistoryServiceProvider = Provider<QrHistoryService>((ref) {
  final cache = ref.read(serviceManagerProvider).appCacheService;
  final qrSettings = ref.read(qrSettingsServiceProvider);
  return QrHistoryService(cache: cache, settings: qrSettings);
});

final qrSettingsProvider =
StateNotifierProvider<QrSettingsNotifier, QrSettingsModel>(
      (ref) => QrSettingsNotifier(),
);

// --- 🛍 Store & Inventory ---
final storeServiceProvider =
    Provider((ref) => ref.read(serviceManagerProvider).storeService);

final storeItemsProvider = FutureProvider<List<StoreItemModel>>((ref) async {
  final jsonString =
      await rootBundle.loadString('assets/data/store_items.json');
  final List<dynamic> jsonData = jsonDecode(jsonString);
  return jsonData.map((e) => StoreItemModel.fromJson(e)).toList();
});

final powerUpInventoryProvider =
    FutureProvider<List<StoreItemModel>>((ref) async {
  final ids =
      await ref.read(purchaseSettingsServiceProvider).getAllPurchasedItems();
  final all = await StoreDataService.loadStoreItems();
  return all
      .where((item) => ids.contains(item.id) && item.category == 'power-up')
      .toList();
});

// --- 🔒 Encryption ---
final encryptionServiceProvider = FutureProvider<EncryptionService>((ref) async {
  final fernet = await ref.watch(fernetControllerProvider.future);
  return EncryptionService(fernetService: fernet);
});

/// Async provider to initialize and expose FernetService
final fernetServiceProvider = Provider<FernetService>((ref) {
  return ref.read(serviceManagerProvider).fernetService;
});

final fernetControllerProvider =
AsyncNotifierProvider<FernetController, FernetService>(() => FernetController());

// --- 💰 Currency ---
final currencyManagerProvider =
    Provider<CurrencyManager>((ref) => CurrencyManager(ref));

final coinBalanceProvider =
    StateNotifierProvider<CoinBalanceNotifier, int>((ref) {
  final storage = ref.read(generalKeyValueStorageProvider);
  return CoinBalanceNotifier(storage);
});

final diamondBalanceProvider = Provider<int>((ref) {
  return ref.watch(currencyManagerProvider).getBalance(CurrencyType.diamonds);
});

final coinNotifierProvider = Provider<CurrencyNotifier>((ref) {
  return ref.read(currencyManagerProvider).getNotifier(CurrencyType.coins);
});

final diamondNotifierProvider = Provider<CurrencyNotifier>((ref) {
  return ref.read(currencyManagerProvider).getNotifier(CurrencyType.diamonds);
});

// --- 📊 Energy System ---
final energyProvider = StateNotifierProvider<EnergyNotifier, EnergyState>((ref) {
  final storage = ref.read(generalKeyValueStorageProvider);
  return EnergyNotifier(storage);
});

// Lives System
final livesProvider = StateNotifierProvider<LivesNotifier, LivesState>((ref) {
  final storage = ref.read(generalKeyValueStorageProvider);
  return LivesNotifier(storage);
});

// Recent Quizzes Provider (for MainMenuScreen)
final recentQuizzesProvider = FutureProvider<List<Map<String, String>>>((ref) async {
  final quizService = ref.read(quizProgressServiceProvider);
  // Implement logic to get recent quizzes from your service
  return quizService.getRecentQuizzes();
});

// User Profile Data Provider (consolidated user info)
final userProfileProvider = Provider<Map<String, dynamic>>((ref) {
  final profileService = ref.watch(playerProfileServiceProvider);
  return profileService.getProfile();
});

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final services = ref.read(serviceManagerProvider);
  return ReferralRepository(
    api: services.apiService,
    cache: services.appCacheService,
  );
});

final referralStorageServiceProvider = Provider<ReferralStorageService>((ref) {
  // Reuse initialized singleton from ServiceManager to ensure Hive box is ready.
  return ref.watch(serviceManagerProvider).referralStorageService;
});

final referralApiServiceProvider = Provider<ReferralApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReferralApiService(apiService);
});

// Helper provider to get current user ID
final currentUserIdProvider = FutureProvider<String>((ref) async {
  final authService = ref.watch(authServiceProvider);
  final playerProfile = ref.watch(playerProfileServiceProvider);

  // Try to get email from secure storage
  final email = await authService.getStoredEmail();
  if (email != null && email.isNotEmpty) {
    return email.split('@').first; // Use email username as userId
  }

  // Fallback to player name
  final playerName = await playerProfile.getPlayerName();
  if (playerName != 'Player') {
    return playerName;
  }

  // Last resort
  return 'guest';
});

// --- 🎁 Referral Invite System Providers ---

/// Provides the ReferralService (synchronous with default userId)
/// Use asyncReferralServiceProvider for async operations
final referralServiceProvider = Provider<ReferralService>((ref) {
  final storage = ref.watch(referralStorageServiceProvider);
  final api = ref.watch(referralApiServiceProvider);

  // Use a default userId for now - will be replaced when async provider loads
  return ReferralService(
    storage: storage,
    api: api,
    userId: 'guest', // Temporary default
    baseUrl: 'https://www.trivia.app',
  );
});

/// Better approach: Async provider that waits for userId
final asyncReferralServiceProvider = FutureProvider<ReferralService>((ref) async {
  final storage = ref.watch(referralStorageServiceProvider);
  final api = ref.watch(referralApiServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);

  return ReferralService(
    storage: storage,
    api: api,
    userId: userId,
    baseUrl: 'https://www.trivia.app',
  );
});

/// Provides the user's referral code
final userReferralCodeProvider = FutureProvider<ReferralCode>((ref) async {
  final referralService = await ref.watch(asyncReferralServiceProvider.future);
  return await referralService.getOrCreateReferralCode();
});

/// Provides referral statistics
final referralStatsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final referralService = await ref.watch(asyncReferralServiceProvider.future);
  return await referralService.getStats();
});

/// Provides the ReferralInviteStorageService
final referralInviteStorageServiceProvider = FutureProvider<ReferralInviteStorageService>((ref) async {
  final storage = ReferralInviteStorageService();
  await storage.initialize();
  return storage;
});

/// Provides the ReferralInviteApiService
final referralInviteApiServiceProvider = Provider<ReferralInviteApiService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return ReferralInviteApiService(apiService);
});

/// Provides the ReferralInviteService (synchronous with default userId)
/// Use asyncReferralInviteServiceProvider for async operations
final referralInviteServiceProvider = Provider<ReferralInviteService>((ref) {
  final storageAsync = ref.watch(referralInviteStorageServiceProvider);
  final api = ref.watch(referralInviteApiServiceProvider);

  return storageAsync.maybeWhen(
    data: (storage) => ReferralInviteService(
      storage: storage,
    api: api,
      userId: 'guest', // Temporary default, use async version for actual userId
    ),
    orElse: () => throw StateError('ReferralInviteStorageService is not initialized yet.'),
  );
});

/// Async provider that waits for userId (RECOMMENDED for most use cases)
final asyncReferralInviteServiceProvider = FutureProvider<ReferralInviteService>((ref) async {
  final storage = await ref.watch(referralInviteStorageServiceProvider.future);
  final api = ref.watch(referralInviteApiServiceProvider);
  final userId = await ref.watch(currentUserIdProvider.future);

  return ReferralInviteService(
    storage: storage,
    api: api,
    userId: userId,
  );
});

/// Provides all invites for the current user
final userInvitesProvider = FutureProvider<List<ReferralInvite>>((ref) async {
  final service = await ref.watch(asyncReferralInviteServiceProvider.future);
  return service.getInvites();
});

/// Provides pending invites for the current user
final pendingInvitesCountProvider = FutureProvider<int>((ref) async {
  final service = await ref.watch(asyncReferralInviteServiceProvider.future);
  return service.getPendingInvites().length;
});

/// Provides invite statistics
final inviteStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = await ref.watch(asyncReferralInviteServiceProvider.future);
  return service.getStats();
});

/// Stream provider for real-time invite updates (updates every 5 seconds)
final liveInvitesProvider = StreamProvider.family<List<ReferralInvite>, String>((ref, userId) {
  return Stream.periodic(const Duration(seconds: 5), (_) async {
    final storage = await ref.read(referralInviteStorageServiceProvider.future);
    return storage.getUserInvites(userId);
  }).asyncMap((invites) async => invites);
});

/// Provider to create a new invite
/// Usage: ref.read(createInviteProvider).call(...)
final createInviteProvider = Provider<Future<ReferralInvite> Function({
required String referralCode,
String? inviteeName,
String? inviteeEmail,
int expirationDays,
})>((ref) {
  return ({
    required String referralCode,
    String? inviteeName,
    String? inviteeEmail,
    int expirationDays = 7,
  }) async {
    final service = await ref.read(asyncReferralInviteServiceProvider.future);
    return await service.createInvite(
      referralCode: referralCode,
      inviteeName: inviteeName,
      inviteeEmail: inviteeEmail,
      expirationDays: expirationDays,
    );
  };
});

/// Provider to redeem an invite
final redeemInviteProvider = Provider<Future<bool> Function({
required String inviteId,
required String redeemedByUserId,
String? redeemerName,
})>((ref) {
  return ({
    required String inviteId,
    required String redeemedByUserId,
    String? redeemerName,
  }) async {
    final service = await ref.read(asyncReferralInviteServiceProvider.future);
    return await service.redeemInvite(
      inviteId: inviteId,
      redeemedByUserId: redeemedByUserId,
      redeemerName: redeemerName,
    );
  };
});

/// --- Messages ---

// Provider for the existing ChallengeCoordinationService
final challengeCoordinationServiceProvider = Provider<ChallengeCoordinationService>((ref) {
  final service = ChallengeCoordinationService();
  service.initialize();
  return service;
});

/// --- 🎡 Spin Wheel ---
final segmentLoaderProvider = Provider<SegmentLoader>((ref) {
  final manager = ref.read(serviceManagerProvider);

  return SegmentLoader(
    appCache: manager.appCacheService,
    configStorage: manager.configStorageService,
    spinWheelService: manager.spinWheelSettingsService,
    generalKeyStorage: manager.generalKeyValueStorageService,
    source: SegmentSource.remote,
    remoteUrl: 'https://example.com/api/segments',
  );
});

final spinningControllerProvider =
    ChangeNotifierProvider<EnhancedSpinningController>((ref) {
  return EnhancedSpinningController(ref);
});

/// --- 🎖 Badges ---
final badgeProvider = FutureProvider<List<GameBadge>>((ref) async {
  final jsonString =
      await rootBundle.loadString('assets/data/badges_icons.json');
  final List<dynamic> jsonData = json.decode(jsonString);
  return jsonData.map((e) => GameBadge.fromJson(e)).toList();
});

/// --- ⏳ Live Countdown Timer ---
final seasonalCompetitionServiceProvider = Provider<SeasonalCompetitionService>((ref) {
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

final seasonLeaderboardProvider = FutureProvider<List<SeasonPlayer>>((ref) async {
  final apiService = ref.read(apiServiceProvider);
  final seasonService = ref.read(seasonalCompetitionServiceProvider);
  final seasonId = await seasonService.getCurrentSeasonId();
  return await apiService.getSeasonLeaderboard(seasonId);
});

/// --- 🏆 Missions ---

// Providers for different age groups
final childrenMissionsProvider = StateNotifierProvider<LiveMissionsNotifier, List<Map<String, dynamic>>>((ref) {
  return LiveMissionsNotifier(AgeGroup.children);
});

final adolescenceMissionsProvider = StateNotifierProvider<LiveMissionsNotifier, List<Map<String, dynamic>>>((ref) {
  return LiveMissionsNotifier(AgeGroup.adolescence);
});

final adultsMissionsProvider = StateNotifierProvider<LiveMissionsNotifier, List<Map<String, dynamic>>>((ref) {
  return LiveMissionsNotifier(AgeGroup.adults);
});

// Current user age provider (you'll need to implement this based on your user system)
final currentUserAgeGroupProvider = Provider<AgeGroup>((ref) {
  // Replace this with your actual user age logic
  // For now, returning adolescence as default
  return AgeGroup.adolescence;
});

// Dynamic mission provider that selects based on user age
final liveMissionsProvider = StateNotifierProvider<LiveMissionsNotifier, List<Map<String, dynamic>>>((ref) {
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

// Mission actions provider
final missionActionsProvider = Provider<MissionActions>((ref) {
  return MissionActions(ref);
});

/// --- 📈 Analytics ---
/// Access to AnalyticsService from the ServiceManager
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final api = ref.watch(apiServiceProvider);
  final queue = ref.watch(eventQueueServiceProvider);
  return AnalyticsService(api, queue);
});

final eventQueueServiceProvider = Provider<EventQueueService>((ref) {
  return EventQueueService();
});

/// --- Admin ---
final adminFilterProvider = StateNotifierProvider<AdminFilterController, AdminFilterState>(
  (ref) => AdminFilterController(ref),
);

/// -- PowerUps ---
final equippedPowerUpProvider = StateNotifierProvider<PowerUpController, PowerUp?>((ref) {
  return PowerUpController(ref);
});

// Notification and UI state providers
final unreadNotificationsProvider = StateProvider<int>((ref) => 0);
final pendingInvitesProvider = Provider<int>((ref) {
  final countAsync = ref.watch(pendingInvitesCountProvider);
  return countAsync.maybeWhen(data: (count) => count, orElse: () => 0);
});
final dailyRewardsAvailableProvider = StateProvider<bool>((ref) => true);

// Premium status provider
final premiumStatusProvider = StateProvider<PremiumStatus>((ref) {
  return PremiumStatus(
    isPremium: false,
    discountPercent: 50,
    expiryDate: null,
  );
});

// Matches providers
final matchesServiceProvider = Provider<MatchesService>((ref) {
  return MatchesService();
});

final activeMatchesProvider = StateNotifierProvider<ActiveMatchesNotifier, List<Map<String, dynamic>>>((ref) {
  return ActiveMatchesNotifier();
});

// Energy and Lives refill time providers
final energyRefillTimeProvider = StateProvider<Duration>((ref) {
  final energyState = ref.watch(energyProvider);
  if (energyState.current >= energyState.max) {
    return Duration.zero;
  }
  // Calculate time until next energy refill (assuming 1 energy per 20 minutes)
  final timePerEnergy = const Duration(minutes: 20);
  return timePerEnergy;
});

final livesRefillTimeProvider = StateProvider<Duration>((ref) {
  final livesState = ref.watch(livesProvider);
  if (livesState.current >= livesState.max) {
    return Duration.zero;
  }
  // Calculate time until next life refill (assuming 1 life per 30 minutes)
  final timePerLife = const Duration(minutes: 30);
  return timePerLife;

});

// --- 🎯 Tier System Providers ---

/// Provides the TierManager instance
final tierManagerProvider = Provider<TierManager>((ref) {
  final storage = ref.read(generalKeyValueStorageProvider);
  final profileService = ref.read(playerProfileServiceProvider);
  return TierManager(storage, profileService);
});

/// Provides the current tier model with full details
final currentTierProvider = FutureProvider<TierModel?>((ref) async {
  final tierManager = ref.read(tierManagerProvider);
  return await tierManager.getCurrentTier();
});

/// Provides all tiers with their unlock status
final allTiersProvider = FutureProvider<List<TierModel>>((ref) async {
  final tierManager = ref.read(tierManagerProvider);
  return await tierManager.getAllTiers();
});

/// Provides just the current tier ID (0-based index)
final currentTierIdProvider = FutureProvider<int>((ref) async {
  final tierManager = ref.read(tierManagerProvider);
  return await tierManager.getCurrentTierId();
});

/// Provides tier progression status for UI updates
final tierProgressionProvider = StateNotifierProvider<TierProgressionNotifier, TierProgressionState>((ref) {
  final tierManager = ref.read(tierManagerProvider);
  return TierProgressionNotifier(tierManager, ref);
});

// --- Arcade Settings ---
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

final arcadeMissionClaimServiceProvider = Provider<ArcadeMissionClaimService>((ref) {
  final cache = ref.read(appCacheServiceProvider); // or ServiceManager.instance.appCacheService
  return ArcadeMissionClaimService(cache);
});


// --- Flow Connect Settings ---

// A simple class to hold our settings state
@immutable
class FlowSettings {
  final int gridSize;
  final FlowConnectDifficulty difficulty;

  const FlowSettings({this.gridSize = 5, this.difficulty = FlowConnectDifficulty.easy});

  FlowSettings copyWith({int? gridSize, FlowConnectDifficulty? difficulty}) {
    return FlowSettings(
      gridSize: gridSize ?? this.gridSize,
      difficulty: difficulty ?? this.difficulty,
    );
  }
}

// A notifier to manage the settings state
class FlowSettingsNotifier extends StateNotifier<FlowSettings> {
  FlowSettingsNotifier() : super(const FlowSettings());

  void setGridSize(int size) {
    state = state.copyWith(gridSize: size);
  }

  void setDifficulty(FlowConnectDifficulty difficulty) {
    state = state.copyWith(difficulty: difficulty);
  }
}

// The provider that the UI will interact with
final flowSettingsProvider = StateNotifierProvider<FlowSettingsNotifier, FlowSettings>((ref) {
  return FlowSettingsNotifier();
});

/// Provider for the Flow Connect mini-game state
final flowConnectStateProvider = ChangeNotifierProvider.autoDispose<FlowConnectStateNotifier>((ref) {
  final settings = ref.watch(flowSettingsProvider);

  return FlowConnectStateNotifier(
    gridSize: settings.gridSize,
    difficulty: settings.difficulty,
    onPuzzleComplete: null, // Will be set from the UI
  );
});

// --- 🎯 Helper Providers for UI ---

/// Provides the next tier to unlock (useful for showing progression goals)
final nextTierProvider = FutureProvider<TierModel?>((ref) async {
  final currentTierId = await ref.watch(currentTierIdProvider.future);
  final allTiers = await ref.watch(allTiersProvider.future);

  if (currentTierId < allTiers.length - 1) {
    return allTiers[currentTierId + 1];
  }
  return null; // Already at max tier
});

/// Provides progress toward next tier (as percentage)
final tierProgressPercentageProvider = FutureProvider<double>((ref) async {
  final profileService = ref.read(playerProfileServiceProvider);
  final profile = profileService.getProfile();
  final currentXP = profile['currentXP'] ?? 0;

  final nextTier = await ref.watch(nextTierProvider.future);
  if (nextTier == null) return 100.0; // Max tier reached

  final currentTierId = await ref.watch(currentTierIdProvider.future);
  final tierManager = ref.read(tierManagerProvider);
  final currentTier = tierManager.getTierById(currentTierId);

  if (currentTier == null) return 0.0;

  final xpInCurrentTier = currentXP - currentTier.requiredXP;
  final xpNeededForNext = nextTier.requiredXP - currentTier.requiredXP;

  if (xpNeededForNext <= 0) return 100.0;

  return (xpInCurrentTier / xpNeededForNext * 100).clamp(0.0, 100.0);
});

// --- 🎯 Extension Helper for Easy Access ---

extension TierProviderExtensions on WidgetRef {
  /// Trigger tier progression check (call after quiz completion, XP gain, etc.)
  Future<TierUpdateResult> checkTierProgression() async {
    return await read(tierProgressionProvider.notifier).updateTierProgress();
  }

  /// Get current tier synchronously (if already loaded)
  TierModel? getCurrentTierSync() {
    final asyncValue = read(currentTierProvider);
    return asyncValue.value;
  }

  /// Get current tier ID synchronously (if already loaded)
  int? getCurrentTierIdSync() {
    final asyncValue = read(currentTierIdProvider);
    return asyncValue.value;
  }
}

// Optionally expose a container for non-widget access (like GameController)
final refContainer = ProviderContainer(); // or pass from your global app entry
