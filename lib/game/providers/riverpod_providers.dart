import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/services/settings/admin_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/onboarding_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/core/services/settings/prize_log_service.dart';
import 'package:trivia_tycoon/core/services/settings/purchase_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/splash_settings_service.dart';
import 'package:trivia_tycoon/game/controllers/settings_controller.dart';

// 🔧 Core Services & Config
import '../../admin/controllers/admin_filter_controller.dart';
import '../../admin/states/admin_filter_state.dart';
import '../../core/manager/login_manager.dart';
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

// 📦 Store & Inventory
import '../../core/services/theme/theme_notifier.dart';
import '../analytics/services/analytics_service.dart';
import '../controllers/coin_balance_notifier.dart';
import '../controllers/fernet_controller.dart';
import '../controllers/power_up_controller.dart';
import '../controllers/splash_controller.dart';
import '../models/leaderboard_entry.dart';
import '../models/power_up.dart';
import '../models/store_item_model.dart';
import '../services/achievement_service.dart';
import '../services/store_data_service.dart';

// 🧠 Game State & Controllers
import '../controllers/question_controller.dart';
import '../controllers/leaderboard_controller.dart';
import '../controllers/profile_avatar_controller.dart';
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

// --- 🌍 Global Services ---
final configServiceProvider =
    Provider<ConfigService>((ref) => ConfigService.instance);

/// Holds the [ServiceManager] after initialization
///
/// Must be overridden in `AppLauncher` after [AppInit] completes.
final serviceManagerProvider = Provider<ServiceManager>((ref) {
  throw UnimplementedError(
    "serviceManagerProvider must be overridden in ProviderScope in AppLauncher",
  );
});

/// Provides the GoRouter instance reactively
final routerProvider = FutureProvider<GoRouter>((ref) async {
  return await AppRouter.router();
});

final apiServiceProvider = Provider<ApiService>((ref) {
  final config = ref.watch(configServiceProvider);
  return ApiService(baseUrl: config.apiBaseUrl);
});

final loginManagerProvider = Provider<LoginManager>((ref) {
  final serviceManager = ref.read(serviceManagerProvider);
  return LoginManager(
    authService: serviceManager.authService,
    profileService: serviceManager.playerProfileService,
    onboardingService: serviceManager.onboardingSettingsService,
    secureStorage: serviceManager.secureStorage,
  );
});

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

final generalKeyValueStorageProvider =
    Provider<GeneralKeyValueStorageService>((ref) {
  return GeneralKeyValueStorageService();
});

final authServiceProvider = Provider<AuthService>((ref) {
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
  assetLoader() => ref.watch(leaderboardAssetProvider.future);
  return LeaderboardDataService(apiService: api, assetLoader: assetLoader);
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
final appCacheServiceProvider = Provider<AppCacheService>((ref) {
  return ref.read(serviceManagerProvider).appCacheService;
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return ref.read(serviceManagerProvider).secureStorage;
});

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

// --- 🎡 Spin Wheel ---
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
    ChangeNotifierProvider<SpinningController>((ref) {
  return SpinningController(ref);
});

// --- 🎖 Badges ---
final badgeProvider = FutureProvider<List<GameBadge>>((ref) async {
  final jsonString =
      await rootBundle.loadString('assets/data/badges_icons.json');
  final List<dynamic> jsonData = json.decode(jsonString);
  return jsonData.map((e) => GameBadge.fromJson(e)).toList();
});

// --- Analytics ---
/// Access to AnalyticsService from the ServiceManager
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  final api = ref.watch(apiServiceProvider);
  final queue = ref.watch(eventQueueServiceProvider);
  return AnalyticsService(api, queue);
});

final eventQueueServiceProvider = Provider<EventQueueService>((ref) {
  return EventQueueService();
});

// --- Admin ---
final adminFilterProvider = StateNotifierProvider<AdminFilterController, AdminFilterState>(
  (ref) => AdminFilterController(ref),
);

// -- PowerUps ---
final equippedPowerUpProvider = StateNotifierProvider<PowerUpController, PowerUp?>((ref) {
  return PowerUpController(ref);
});

// Optionally expose a container for non-widget access (like GameController)
final refContainer = ProviderContainer(); // or pass from your global app entry
