/// Game-logic providers — settings, quiz, leaderboard, store, encryption.
///
/// Depends only on [core_providers.dart].
library;

import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/leaderboard_data_service.dart';
import '../../core/services/question/question_service.dart';
import '../../core/services/settings/admin_settings_service.dart';
import '../../core/services/settings/audio_settings_service.dart';
import '../../core/services/settings/confetti_settings_service.dart';
import '../../core/services/settings/custom_theme_service.dart';
import '../../core/services/settings/onboarding_settings_service.dart';
import '../../core/services/settings/player_profile_service.dart';
import '../../core/services/settings/prize_log_service.dart';
import '../../core/services/settings/purchase_settings_service.dart';
import '../../core/services/settings/qr_settings_service.dart';
import '../../core/services/settings/quiz_progress_service.dart';
import '../../core/services/settings/reward_settings_service.dart';
import '../../core/services/settings/spin_wheel_settings_service.dart';
import '../../core/services/settings/splash_settings_service.dart';
import '../../core/services/settings/theme_settings_service.dart';
import '../../ui_components/login/providers/auth.dart' show LocalAuthService;
import '../../core/services/encryption/encryption_service.dart';
import '../../core/services/encryption/fernet_service.dart';
import '../../core/services/theme/swatch_service.dart';
import '../../core/services/theme/theme_notifier.dart';
import '../../game/controllers/fernet_controller.dart';
import '../../game/controllers/leaderboard_controller.dart';
import '../../game/controllers/profile_avatar_controller.dart';
import '../../game/controllers/question_controller.dart';
import '../../game/controllers/settings_controller.dart';
import '../../game/controllers/splash_controller.dart';
import '../../game/models/leaderboard_entry.dart';
import '../../game/models/store_item_model.dart';
import '../../game/services/achievement_service.dart';
import '../../game/services/store_data_service.dart';
import '../../game/state/qr_settings_state.dart';
import '../../game/state/question_state.dart';
import '../../ui_components/confetti/core/confetti_controller.dart';
import '../../ui_components/qr_code/models/qr_settings_model.dart';
import '../../ui_components/qr_code/services/qr_history_service.dart';
import 'core_providers.dart';

// ---------------------------------------------------------------------------
// Settings
// ---------------------------------------------------------------------------

final settingsControllerProvider = Provider<SettingsController>((ref) {
  return SettingsController(
    audioService: ref.watch(audioSettingsServiceProvider),
    profileService: ref.watch(playerProfileServiceProvider),
    purchaseService: ref.watch(purchaseSettingsServiceProvider),
  );
});

final audioSettingsServiceProvider = Provider<AudioSettingsService>((ref) {
  return ref.watch(serviceManagerProvider).audioSettingsService;
});

final quizProgressServiceProvider = Provider<QuizProgressService>((ref) {
  return ref.watch(serviceManagerProvider).quizProgressService;
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
  return ref.read(serviceManagerProvider).customThemeService;
});

final authServiceProvider = Provider<LocalAuthService>((ref) {
  return ref.watch(serviceManagerProvider).authService;
});

final playerProfileServiceProvider = Provider<PlayerProfileService>((ref) {
  return ref.read(serviceManagerProvider).playerProfileService;
});

final purchaseSettingsServiceProvider =
    Provider<PurchaseSettingsService>((ref) {
  return ref.read(serviceManagerProvider).purchaseSettingsService;
});

final prizeLogServiceProvider = Provider<PrizeLogService>((ref) {
  return ref.read(serviceManagerProvider).prizeLogService;
});

final onboardingSettingsServiceProvider =
    Provider<OnboardingSettingsService>((ref) {
  return ref.read(serviceManagerProvider).onboardingSettingsService;
});

final adminSettingsServiceProvider = Provider<AdminSettingsService>((ref) {
  return ref.read(serviceManagerProvider).adminSettingsService;
});

final achievementServiceProvider = Provider<AchievementService>((ref) {
  return ref.read(serviceManagerProvider).achievementService;
});

// ---------------------------------------------------------------------------
// Quiz / Question
// ---------------------------------------------------------------------------

final questionControllerProvider =
    StateNotifierProvider<QuestionController, QuestionState>((ref) {
  return QuestionController(ref: ref);
});

final questionServiceProvider = Provider<QuestionService>((ref) {
  return ref.read(serviceManagerProvider).questionService;
});

// ---------------------------------------------------------------------------
// Leaderboard
// ---------------------------------------------------------------------------

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

final leaderboardAssetProvider =
    FutureProvider<List<LeaderboardEntry>>((ref) async {
  final jsonStr =
      await rootBundle.loadString('assets/data/leaderboard/leaderboard.json');
  final List<dynamic> decoded = json.decode(jsonStr);
  return decoded.map((e) => LeaderboardEntry.fromJson(e)).toList();
});

// ---------------------------------------------------------------------------
// Profile / Avatar
// ---------------------------------------------------------------------------

final profileAvatarControllerProvider =
    ChangeNotifierProvider<ProfileAvatarController>((ref) {
  final serviceManager = ref.read(serviceManagerProvider);
  return ProfileAvatarController(
    keyValueStorage: serviceManager.generalKeyValueStorageService,
    appCache: serviceManager.appCacheService,
  );
});

// ---------------------------------------------------------------------------
// Theme / Visual
// ---------------------------------------------------------------------------

final userAgeGroupProvider = StateProvider<String>((ref) => 'teens');

final themeSettingsProvider = Provider<ThemeSettingsService>((ref) {
  return ref.read(serviceManagerProvider).themeSettingsService;
});

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

final confettiControllerProvider =
    ChangeNotifierProvider<ConfettiController>((ref) {
  return ConfettiController();
});

// ---------------------------------------------------------------------------
// QR
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Store / Inventory
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Encryption
// ---------------------------------------------------------------------------

final encryptionServiceProvider =
    FutureProvider<EncryptionService>((ref) async {
  final fernet = await ref.watch(fernetControllerProvider.future);
  return EncryptionService(fernetService: fernet);
});

final fernetServiceProvider = Provider<FernetService>((ref) {
  return ref.read(serviceManagerProvider).fernetService;
});

final fernetControllerProvider =
    AsyncNotifierProvider<FernetController, FernetService>(
        () => FernetController());
