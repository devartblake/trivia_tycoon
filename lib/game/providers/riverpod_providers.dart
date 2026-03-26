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

/// Global WebSocket client provider
final globalWsClientProvider = Provider<WsClient?>((ref) {
  return AppInit.wsClient;
});

/// WebSocket connection status provider
final wsConnectionStatusProvider = StateProvider<bool>((ref) {
  return AppInit.isWebSocketConnected;
});

// --- 🔐 Core Auth Providers ---

/// Provides the Hive box for auth tokens
final authTokenBoxProvider = Provider<Box>((ref) {
  if (!Hive.isBoxOpen('auth_tokens')) {
    throw StateError('auth_tokens box must be opened in app_init.dart before creating providers');
  }
  return Hive.box('auth_tokens');
});

/// Provides the AuthTokenStore
final authTokenStoreProvider = Provider<AuthTokenStore>((ref) {
  final box = ref.watch(authTokenBoxProvider);
  return AuthTokenStore(box);
});

/// Provides the DeviceIdService
final deviceIdServiceProvider = Provider<DeviceIdService>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  return DeviceIdService(secureStorage);
});

/// Provides the AuthApiClient
final authApiClientProvider = Provider<AuthApiClient>((ref) {
  return AuthApiClient(
    http.Client(),
    apiBaseUrl: EnvConfig.apiBaseUrl, deviceId: ref.watch(deviceIdServiceProvider),
  );
});

/// Provides the core AuthService (backend token management)
final coreAuthServiceProvider = Provider<core_auth.BackendAuthService>((ref) {
  return core_auth.BackendAuthService(
    deviceId: ref.watch(deviceIdServiceProvider),
    tokenStore: ref.watch(authTokenStoreProvider),
    api: ref.watch(authApiClientProvider),
  );
});

/// Provides authenticated HTTP client with auto-refresh
final authHttpClientProvider = Provider<AuthHttpClient>((ref) {
  return AuthHttpClient(
    ref.watch(coreAuthServiceProvider),
    ref.watch(authTokenStoreProvider),
    autoRefresh: true,
    onTokenRefreshed: () {
      LogManager.debug('[Auth] ✅ Token auto-refreshed');
    },
    onRefreshFailed: (error) {
      LogManager.debug('[Auth] ❌ Refresh failed: $error');
      // Optional: Navigate to login or show notification
    },
  );
});

/// Provides HttpClient wrapper
final httpClientProvider = Provider<HttpClient>((ref) {
  return HttpClient(
    authClient: ref.watch(authHttpClientProvider),
    baseUrl: EnvConfig.apiBaseUrl,
  );
});

/// Provides TycoonApiClient
final tycoonApiClientProvider = Provider<TycoonApiClient>((ref) {
  return TycoonApiClient(
    httpClient: ref.watch(httpClientProvider),
  );
});

/// Provides WebSocket client
final wsClientProvider = Provider<WsClient>((ref) {
  return WsClient(
    url: EnvConfig.apiWsBaseUrl,
    onMessage: (message) {
      LogManager.debug('[WS] Message: ${message.op}');
    },
    onStateChange: (state) {
      LogManager.debug('[WS] State: $state');
    },
    onError: (error) {
      LogManager.debug('[WS] Error: $error');
    },
  );
});

/// Provides SecureStorage
final secureStorageProvider = Provider<SecureStorage>((ref) {
  return SecureStorage();
});

// --- 🔑 UPDATED: LoginManager Provider ---

/// Provides the LoginManager with all required dependencies
final loginManagerProvider = Provider<LoginManager>((ref) {
  final serviceManager = ref.read(serviceManagerProvider);

  return LoginManager(
    authService: ref.watch(coreAuthServiceProvider),      // ← UPDATED: Core auth service
    tokenStore: ref.watch(authTokenStoreProvider),        // ← NEW: Token store
    deviceIdService: ref.watch(deviceIdServiceProvider),  // ← NEW: Device ID service
    profileService: serviceManager.playerProfileService,
    onboardingService: serviceManager.onboardingSettingsService,
    secureStorage: ref.watch(secureStorageProvider),      // ← UPDATED: Use provider
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
  return ref.watch(serviceManagerProvider).generalKeyValueStorageService;
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
final appCacheServiceProvider = Provider<AppCacheService>((ref) {
  return ref.read(serviceManagerProvider).appCacheService;
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

// Power-ups
final equippedPowerUpProvider =
StateNotifierProvider<PowerUpController, PowerUp?>((ref) {
  return PowerUpController(ref);
});

// UI badge state
final unreadNotificationsProvider = StateProvider<int>((ref) => 0);
final dailyRewardsAvailableProvider = StateProvider<bool>((ref) => true);

// Premium status
final premiumStatusProvider = StateProvider<PremiumStatus>((ref) {
  return PremiumStatus(
    isPremium: false,
    discountPercent: 50,
    expiryDate: null,
  );
});

// Non-widget access container (legacy — prefer passing ProviderContainer via DI)
// ignore: prefer_const_constructors
final refContainer = ProviderContainer();
