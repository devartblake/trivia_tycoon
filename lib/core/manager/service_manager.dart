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

class ServiceManager {
  static late final ServiceManager instance;

  final ApiService apiService;
  final AuthService authService;
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
  final SecureStorage secureStorage;
  final QrHistoryService historyService;
  final QuizProgressService quizProgressService;
  final CustomThemeService customThemeService;
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
  final GeneralKeyValueStorageService generalKeyValueStorageService;

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
    required this.secureStorage,
    required this.historyService,
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
  });

  /// Initialize all core services and return a ready ServiceManager
  static Future<ServiceManager> initialize() async {
    final api = ApiService(baseUrl: 'https://api.url');
    final leaderboard = LeaderboardDataService(apiService: api);

    // Add async initialize methods
    final audio = await AudioSettingsService.initialize();
    final store = await StoreService.initialize(api);
    final configStorage = ConfigStorageService();
    final secureStorage = SecureStorage();
    final fernetService = await FernetService.initialize(secureStorage);
    final encryptService = await EncryptionService.initialize(secureStorage);
    final cache = await AppCacheService.initialize();
    final quizProgress = await QuizProgressService.initialize();
    final customTheme = await CustomThemeService.initialize();
    final swatch = SwatchService();
    final mission = MissionService();
    final eventQueueService = EventQueueService();
    final analytics = AnalyticsService(api, eventQueueService);
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
    final playerProfile = PlayerProfileService();
    final qrSettings = QrSettingsService();
    final settingsController = SettingsController(
      audioService: audio,
      profileService: playerProfile,
      purchaseService: purchaseService,
    );
    final generalKey = GeneralKeyValueStorageService();
    final auth = AuthService(secureStorage: secureStorage, generalKey: generalKey, playerProfileService: playerProfile);
    final history = QrHistoryService(cache: cache, settings: qrSettings);

    // Save it globally here
    return ServiceManager(
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
      secureStorage: secureStorage,
      historyService: history,
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
    );
  }
}
