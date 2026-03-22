import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/event_queue_service.dart';
import 'package:trivia_tycoon/core/services/settings/admin_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/audio_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/confetti_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/custom_theme_service.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/services/settings/onboarding_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/core/services/settings/prize_log_service.dart';
import 'package:trivia_tycoon/core/services/settings/purchase_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/qr_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/quiz_progress_service.dart';
import 'package:trivia_tycoon/core/services/settings/reward_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/spin_wheel_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/splash_settings_service.dart';
import 'package:trivia_tycoon/core/services/settings/theme_settings_service.dart';
import 'package:trivia_tycoon/core/services/storage/config_storage_service.dart';
import 'package:trivia_tycoon/core/services/theme/theme_notifier.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/services/auth_api_client.dart';
import 'package:trivia_tycoon/core/services/auth_service.dart' as core_auth;
import 'package:trivia_tycoon/core/services/auth_token_store.dart';
import 'package:trivia_tycoon/core/services/device_id_service.dart';
import 'package:trivia_tycoon/ui_components/login/providers/auth.dart';
import 'package:trivia_tycoon/ui_components/qr_code/services/qr_history_service.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';
import 'package:trivia_tycoon/core/services/question/question_service.dart';
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';
import 'package:trivia_tycoon/core/services/theme/swatch_service.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/encryption/encryption_service.dart';
import 'package:trivia_tycoon/core/services/encryption/fernet_service.dart';
import 'package:trivia_tycoon/core/services/leaderboard_data_service.dart';
import 'package:trivia_tycoon/core/services/store/store_service.dart';
import 'package:trivia_tycoon/game/analytics/services/analytics_service.dart';
import 'package:trivia_tycoon/game/controllers/settings_controller.dart';
import 'package:trivia_tycoon/game/services/achievement_service.dart';
import 'package:trivia_tycoon/game/services/mission_service.dart';
import 'package:trivia_tycoon/game/multiplayer/services/multiplayer_service.dart';
import '../../arcade/leaderboards/local_arcade_leaderboard_service.dart';
import '../../arcade/missions/arcade_mission_service.dart';
import '../../arcade/services/arcade_daily_bonus_service.dart';
import '../../arcade/services/arcade_personal_best_service.dart';
import '../../game/services/referral_api_service.dart';
import '../../game/services/referral_service.dart';
import '../../game/services/referral_storage_service.dart';
import '../env.dart';
import '../networking/http_client.dart';
import '../networking/signalr/match_hub.dart';
import '../services/auth_http_client.dart';
import '../networking/signalr/notification_hub.dart';
import '../networking/tycoon_api_client.dart';
import '../repositories/mission_repository.dart';

class ServiceManager {
  static late final ServiceManager instance;

  final ApiService apiService;
  final LocalAuthService authService;
  final AnalyticsService analyticsService;
  final EventQueueService eventQueueService;
  final AudioSettingsService audioSettingsService;
  final LeaderboardDataService leaderboardDataService;
  final StoreService storeService;
  final ConfigStorageService configStorageService;
  final EncryptionService encryptionService;
  final FernetService fernetService;
  final SwatchService swatchService;
  final AppCacheService appCacheService;
  final AchievementService achievementService;
  final ThemeNotifier themeNotifier;
  final SecureStorage secureStorage;
  final QrHistoryService historyService;
  final QuizProgressService quizProgressService;
  final CustomThemeService customThemeService;
  final MultiplayerService multiplayerService;
  final MissionService missionService;
  final QuestionService questionService;
  final SettingsController settingsController;
  final ConfettiSettingsService confettiSettingsService;
  final SpinWheelSettingsService spinWheelSettingsService;
  final PrizeLogService prizeLogService;
  final PurchaseSettingsService purchaseSettingsService;
  final RewardSettingsService rewardSettingsService;
  final SplashSettingsService splashSettingsService;
  final OnboardingSettingsService onboardingSettingsService;
  final ThemeSettingsService themeSettingsService;
  final AdminSettingsService adminSettingsService;
  final PlayerProfileService playerProfileService;
  final QrSettingsService qrSettingsService;
  final ReferralStorageService referralStorageService;
  final ReferralApiService referralApiService;
  final ReferralService referralService;
  final GeneralKeyValueStorageService generalKeyValueStorageService;
  final ArcadePersonalBestService arcadePersonalBestService;
  final ArcadeDailyBonusService arcadeDailyBonusService;
  final ArcadeMissionService arcadeMissionService;
  final LocalArcadeLeaderboardService localArcadeLeaderboardService;
  final TycoonApiClient tycoonApiClient;
  final NotificationHub notificationHub;
  final MatchHub matchHub;

  ServiceManager({
    required this.apiService,
    required this.authService,
    required this.analyticsService,
    required this.eventQueueService,
    required this.audioSettingsService,
    required this.leaderboardDataService,
    required this.storeService,
    required this.configStorageService,
    required this.encryptionService,
    required this.fernetService,
    required this.swatchService,
    required this.appCacheService,
    required this.achievementService,
    required this.themeNotifier,
    required this.secureStorage,
    required this.historyService,
    required this.multiplayerService,
    required this.missionService,
    required this.questionService,
    required this.quizProgressService,
    required this.customThemeService,
    required this.settingsController,
    required this.confettiSettingsService,
    required this.spinWheelSettingsService,
    required this.prizeLogService,
    required this.purchaseSettingsService,
    required this.rewardSettingsService,
    required this.splashSettingsService,
    required this.onboardingSettingsService,
    required this.themeSettingsService,
    required this.adminSettingsService,
    required this.playerProfileService,
    required this.qrSettingsService,
    required this.generalKeyValueStorageService,
    required this.arcadePersonalBestService,
    required this.arcadeDailyBonusService,
    required this.arcadeMissionService,
    required this.localArcadeLeaderboardService,
    required this.referralStorageService,
    required this.referralApiService,
    required this.referralService,
    required this.tycoonApiClient,
    required this.notificationHub,
    required this.matchHub,
  });

  // ── Hub lifecycle helpers ────────────────────────────────────────────────

  /// Call after a successful login to connect the persistent notification hub.
  Future<void> connectHubs({
    required String accessToken,
    required String playerId,
  }) async {
    final notifyUrl =
        '${EnvConfig.notifyHubUrl}?playerId=$playerId&access_token=$accessToken';
    await notificationHub.start(url: notifyUrl, accessToken: accessToken);
  }

  /// Call on logout to tear down all hub connections.
  Future<void> disconnectHubs() async {
    await notificationHub.stop();
    await matchHub.stop();
  }

  /// Connect the match hub for a specific match session.
  Future<void> connectMatchHub({
    required String accessToken,
    required String playerId,
  }) async {
    final matchUrl =
        '${EnvConfig.matchHubUrl}?playerId=$playerId&access_token=$accessToken';
    await matchHub.start(url: matchUrl, accessToken: accessToken);
  }

  Future<void> disconnectMatchHub() => matchHub.stop();

  static EnvConfig? get envConfig => null;

  /// Initialize all core services and return a ready ServiceManager
  static Future<ServiceManager> initialize() async {
    final String baseUrl = EnvConfig.apiBaseUrl;
    final api = ApiService(baseUrl: '$baseUrl/api/v1');

    // Add async initialize methods
    final audio = await AudioSettingsService.initialize();
    final store = await StoreService.initialize(api);
    final configStorage = ConfigStorageService();
    final secureStorage = SecureStorage();
    final fernetService = await FernetService.initialize(secureStorage);
    final encryptService = await EncryptionService.initialize(secureStorage);
    final cache = await AppCacheService.initialize();
    final leaderboard = LeaderboardDataService(apiService: api, appCache: cache);
    final arcadePB = ArcadePersonalBestService(cache);
    final arcadeDaily = ArcadeDailyBonusService(cache);
    final arcadeMissions = ArcadeMissionService(cache);
    final localArcadeLeaderboards = LocalArcadeLeaderboardService(cache);
    final quizProgress = await QuizProgressService.initialize();
    final customTheme = await CustomThemeService.initialize();
    final swatch = SwatchService();
    final eventQueueService = EventQueueService();

    final analytics = AnalyticsService(api, eventQueueService);
    await analytics.initialize();
    await analytics.trackStartup();

    final achievements = AchievementService(apiService: api);
    final confetti = ConfettiSettingsService();
    final questions = QuestionService(apiService: api, quizProgressService: quizProgress);
    final spinWheel = SpinWheelSettingsService();
    final prizeLog = PrizeLogService();
    final purchaseService = PurchaseSettingsService();
    final reward = RewardSettingsService();
    final splash = SplashSettingsService();
    final onboard = OnboardingSettingsService();
    final theme = ThemeSettingsService();
    final admin = AdminSettingsService();
    final multiplayer = MultiplayerService(
      // inject: settings, http client, analytics, cache, etc.
    );
    final missionRepository = ApiMissionRepository(baseUrl: baseUrl, accessTokenProvider: null);
    final mission = MissionService(
      missionRepository,
      apiBaseUrl: api.baseUrl,
      apiKey: 'your-api-key-here',
    );

    // Initialize PlayerProfileService with Hive box
    final playerProfile = PlayerProfileService();

    // Initialize Referral Services
    final referralStorage = ReferralStorageService();
    await referralStorage.initialize();

    final referralApi = ReferralApiService(api);

    // Note: We need to get userId after auth is created, so we'll update this later
    // For now, use a placeholder
    final referralServiceTemp = ReferralService(
      storage: referralStorage,
      api: referralApi,
      userId: 'guest', // Will be updated after login
    );

    // Initialize QrHistoryService
    final qrSettings = QrSettingsService();
    final generalKey = GeneralKeyValueStorageService();

    // Initialize ThemeNotifier here instead of in AppInit
    final themeNotifier = ThemeNotifier(generalKey);
    await themeNotifier.initializationCompleted;

    final settingsController = SettingsController(
      audioService: audio,
      profileService: playerProfile,
      purchaseService: purchaseService,
    );
    final auth = LocalAuthService(secureStorage: secureStorage, generalKey: generalKey, playerProfileService: playerProfile);
    final history = QrHistoryService(cache: cache, settings: qrSettings);

    // Core auth service (token-based) used exclusively by AuthHttpClient
    final deviceId = DeviceIdService(secureStorage);
    final authTokenBox = Hive.box('auth_tokens');
    final tokenStore = AuthTokenStore(authTokenBox);
    final authApi = AuthApiClient(http.Client(), apiBaseUrl: EnvConfig.apiBaseUrl, deviceId: deviceId);
    final coreAuth = core_auth.AuthService(deviceId: deviceId, tokenStore: tokenStore, api: authApi);

    final authHttpClient = AuthHttpClient(coreAuth, tokenStore);
    final httpClient = HttpClient(
      authClient: authHttpClient,
      baseUrl: '$baseUrl/api/v1',
    );
    final tycoonApi = TycoonApiClient(httpClient: httpClient);
    final notifyHub = NotificationHub();
    final mHub = MatchHub();

    // Save it globally here
    final manager = ServiceManager(
      apiService: api,
      authService: auth,
      analyticsService: analytics,
      eventQueueService:  eventQueueService,
      audioSettingsService: audio,
      leaderboardDataService: leaderboard,
      storeService: store,
      configStorageService: configStorage,
      encryptionService: encryptService,
      fernetService: fernetService,
      swatchService: swatch,
      appCacheService: cache,
      // arcade services
      arcadePersonalBestService: arcadePB,
      arcadeDailyBonusService: arcadeDaily,
      arcadeMissionService: arcadeMissions,
      localArcadeLeaderboardService: localArcadeLeaderboards,
      themeNotifier: themeNotifier,
      secureStorage: secureStorage,
      historyService: history,
      multiplayerService: multiplayer,
      missionService: mission,
      achievementService: achievements,
      confettiSettingsService: confetti,
      questionService: questions,
      quizProgressService: quizProgress,
      customThemeService: customTheme,
      prizeLogService: prizeLog,
      purchaseSettingsService: purchaseService,
      rewardSettingsService: reward,
      splashSettingsService: splash,
      onboardingSettingsService: onboard,
      themeSettingsService: theme,
      adminSettingsService: admin,
      playerProfileService: playerProfile,
      qrSettingsService: qrSettings,
      settingsController: settingsController,
      spinWheelSettingsService: spinWheel,
      generalKeyValueStorageService: generalKey,
      referralStorageService: referralStorage,
      referralApiService: referralApi,
      referralService: referralServiceTemp,
      tycoonApiClient: tycoonApi,
      notificationHub: notifyHub,
      matchHub: mHub,
    );

    instance = manager;
    return manager;
  }
}
