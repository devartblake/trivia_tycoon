import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:synaptix/core/manager/log_manager.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:synaptix/core/services/analytics/config_service.dart';
import 'package:synaptix/core/services/storage/secure_storage.dart';
import 'package:synaptix/core/services/theme/theme_notifier.dart';
import 'package:synaptix/core/manager/service_manager.dart';
import 'package:synaptix/game/analytics/services/spin_analytics_tracker.dart';
import 'package:synaptix/game/logic/referral_invite_adapter.dart';
import 'package:synaptix/game/providers/multi_profile_providers.dart';
import 'package:synaptix/game/providers/notification_history_store.dart';
import 'package:synaptix/game/providers/notification_template_store.dart';
import 'package:synaptix/game/services/referral_storage_service.dart';
import 'package:synaptix/core/env.dart';
import 'package:synaptix/core/networking/ws_client.dart';
import 'package:synaptix/core/services/app_lifecycle_manager.dart';
import 'package:synaptix/core/services/asset_resolver.dart';
import 'package:synaptix/core/services/guest_api_gate.dart';
import 'package:synaptix/core/services/auth_api_client.dart';
import 'package:synaptix/core/services/auth_service.dart';
import 'package:synaptix/core/services/auth_token_store.dart';
import 'package:synaptix/core/services/device_id_service.dart';
import 'package:synaptix/core/security/secure_session_store.dart';
import 'package:synaptix/core/services/notification_service.dart';
import 'package:synaptix/game/providers/auth_providers.dart';
import 'package:synaptix/core/helpers/educational_stats_initializer.dart';
import 'package:synaptix/core/services/presence/rich_presence_service.dart';
import 'package:synaptix/core/services/settings/profile_sync_service.dart';
import 'package:synaptix/core/services/settings/app_settings.dart';
import 'package:synaptix/core/services/settings/multi_profile_service.dart';
import 'package:synaptix/core/services/state_persistence_service.dart';
import 'package:synaptix/synaptix/mode/synaptix_mode_notifier.dart';
import 'package:synaptix/game/providers/riverpod_providers.dart';

/// App bootstrapper
class AppInit {
  static bool _backgroundServicesReady = false;
  static SpinAnalyticsTracker? _spinAnalyticsTracker;
  static SpinAnalyticsTracker? get spinAnalyticsTracker =>
      _spinAnalyticsTracker;

  static WsClient? _wsClient;
  static WsClient? get wsClient => _wsClient;
  static bool _wsConnected = false;

  static AuthTokenStore? _tokenStore;
  static AuthTokenStore? get tokenStore => _tokenStore;

  static AppLifecycleManager? _lifecycleManager;
  static AppLifecycleManager? get lifecycleManager => _lifecycleManager;

  static StatePersistenceService? _persistenceService;
  static StatePersistenceService? get persistenceService => _persistenceService;

  static ServiceManager? _serviceManager;

  static Future<(ServiceManager, ThemeNotifier)> initialize(
      {ProviderContainer? container}) async {
    await EnvConfig.load();
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(ReferralInviteHiveAdapter().typeId)) {
      Hive.registerAdapter(ReferralInviteHiveAdapter());
    }

    final authTokenBox = await Hive.openBox('auth_tokens');
    await Hive.openBox('settings');
    await Hive.openBox('secrets');

    _persistenceService = StatePersistenceService();
    await _persistenceService!.initialize();
    await NotificationTemplateStore.instance.loadAllFromSettings();
    await NotificationHistoryStore.instance.loadAllFromSettings();

    final secureStorage = SecureStorage();
    final deviceIdService = DeviceIdService(secureStorage);
    await deviceIdService.getOrCreate();

    final tokenStore = AuthTokenStore(authTokenBox);
    await tokenStore.initialize();
    _tokenStore = tokenStore;

    final httpClient = http.Client();
    final secureSessionStore = SecureSessionStore(secureStorage);
    final authApi = AuthApiClient(httpClient,
        apiBaseUrl: EnvConfig.apiV1BaseUrl,
        deviceId: deviceIdService,
        secureSessionStore: secureSessionStore);

    final authService = BackendAuthService(
      deviceId: deviceIdService,
      tokenStore: tokenStore,
      api: authApi,
    );

    await authService.ensureDeviceId();

    final serviceManager =
        await ServiceManager.initialize(authTokenStore: tokenStore);
    _serviceManager = serviceManager;

    _lifecycleManager = AppLifecycleManager(
      onAppPaused: () {},
      onAppResumed: () {},
      onAppDetached: () {},
      onAppInactive: () {},
      onSaveState: () async {
        await _saveAppState();
      },
      onClearTempData: () async {
        await _persistenceService?.clearTemporaryData();
      },
    );
    _lifecycleManager!.initialize();

    await _ensureSecureSessionForStoredAuth(serviceManager);
    await _initializeUserSession(serviceManager, container);
    await _initializeMultiProfileSystem(serviceManager, container);

    _preloadQuestions(serviceManager).ignore();

    return (serviceManager, serviceManager.themeNotifier);
  }

  static Future<void> _ensureSecureSessionForStoredAuth(
      ServiceManager serviceManager) async {
    try {
      final session = serviceManager.authTokenStore.load();
      if (!session.hasTokens || session.accessToken.isEmpty) return;

      final existing = await serviceManager.secureChannelService.loadSession();
      if (existing != null &&
          !existing.isExpired &&
          existing.sessionId.isNotEmpty) {
        return;
      }

      if (session.isExpired) {
        await serviceManager.secureChannelService.clearSession();
        await serviceManager.authTokenStore.clear();
        return;
      }

      await serviceManager.secureChannelService
          .startSession(accessToken: session.accessToken);
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('403')) {
        await serviceManager.authTokenStore.clear();
      }
    }
  }

  static Future<void> _saveAppState() async {
    if (_serviceManager == null || _persistenceService == null) return;
    try {
      final gameState = await _getCurrentGameState();
      final userSession = await _getCurrentUserSession();
      final wsState = await _getCurrentWebSocketState();
      final pendingActions = await _getPendingActions();

      await _persistenceService!.saveAll(
        gameState: gameState,
        userSession: userSession,
        wsState: wsState,
        pendingActions: pendingActions,
      );
    } catch (_) {}
  }

  static Future<Map<String, dynamic>?> _getCurrentGameState() async {
    try {
      if (_serviceManager == null) return null;
      final quizProgress = await _serviceManager!.quizProgressService.getQuizProgress();
      final playerProgress = await _serviceManager!.quizProgressService.getPlayerProgress();
      if (!quizProgress.containsKey('quiz_id')) return null;
      return {
        'quiz_progress': quizProgress,
        'player_progress': playerProgress,
        'snapshot_time': DateTime.now().toIso8601String(),
      };
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> _getCurrentUserSession() async {
    try {
      if (_serviceManager == null) return null;
      final isLoggedIn = await _serviceManager!.authService.isLoggedIn();
      if (!isLoggedIn) return null;
      final session = _tokenStore?.load();
      final profile = await _serviceManager!.playerProfileService.loadCompleteProfile();
      return {
        'is_logged_in': isLoggedIn,
        ...profile,
        'has_tokens': session?.hasTokens ?? false,
        'session_start': DateTime.now().toIso8601String(),
      };
    } catch (_) { return null; }
  }

  static Future<Map<String, dynamic>?> _getCurrentWebSocketState() async {
    if (_wsClient == null) return null;
    return {
      'connected': _wsConnected,
      'url': EnvConfig.apiWsBaseUrl,
      'last_connection': DateTime.now().toIso8601String(),
    };
  }

  static Future<List<Map<String, dynamic>>> _getPendingActions() async {
    if (_persistenceService == null) return [];
    return await _persistenceService!.getPendingActions();
  }

  static Future<void> initializeWebSocket() async {
    if (_tokenStore == null || _serviceManager == null) return;
    final session = _tokenStore!.load();
    if (!session.hasTokens) return;
    final playerId = await _serviceManager!.playerProfileService.getUserId();
    if (playerId == null || playerId.isEmpty) return;

    final baseWsUrl = Uri.parse(EnvConfig.apiWsBaseUrl);
    final wsUrl = baseWsUrl.replace(
      queryParameters: { ...baseWsUrl.queryParameters, 'playerId': playerId },
    ).toString();

    _wsClient = WsClient(
      url: wsUrl,
      onMessage: (_) {},
      onStateChange: (state) {
        _wsConnected = (state == WsState.connected);
        _saveAppState();
      },
      onError: (_) {},
    );
    await _wsClient!.connect();
  }

  static Future<void> disconnectWebSocket() async {
    if (_wsClient != null) {
      await _wsClient!.disconnect();
      _wsClient = null;
      _wsConnected = false;
      await _saveAppState();
    }
  }

  static Future<void> reconnectWebSocket() async {
    if (_wsClient != null && !_wsConnected) {
      await _wsClient!.reconnect();
    }
  }

  static bool get isWebSocketConnected => _wsConnected;

  static Future<void> initializeBackgroundServices(
      ServiceManager serviceManager, ProviderContainer? container) async {
    await Future.delayed(const Duration(seconds: 1));
    try {
      await Hive.openBox('cache');
      await Hive.openBox('question');
      await _configureRemoteAssetManifest(serviceManager);
      await AssetResolver.instance.syncInBackground();

      final profile = serviceManager.playerProfileService.getProfile();
      final ageGroup = profile['age_group']?.toString() ?? 'teens';
      final mode = SynaptixModeNotifier.mapAgeGroupToMode(ageGroup);
      
      await NotificationService().initialize(mode: mode);
      await _initializeReferralStorage();

      final configService = ConfigService.instance;
      configService.initServices(serviceManager);
      await configService.loadConfig();

      _spinAnalyticsTracker = SpinAnalyticsTracker(serviceManager.analyticsService);
      await serviceManager.analyticsService.trackStartup();

      if (container != null) {
        await EducationalStatsInitializer.initialize(container as dynamic);
      }

      _backgroundServicesReady = true;
    } catch (_) {}
  }

  static Future<void> trackAppLifecycle(
      ServiceManager serviceManager, String event) async {
    if (!_backgroundServicesReady) return;
    try {
      await serviceManager.analyticsService.trackLifecycleEvent(
        event,
        additionalData: { 'timestamp': DateTime.now().toIso8601String() },
      );
    } catch (_) {}
  }

  /// Get spin analytics summary for debugging (Safely)
  static Future<Map<String, dynamic>> getSpinAnalyticsSummary() async {
    if (!_backgroundServicesReady) {
      return {
        'today_count': 0,
        'daily_limit': 0,
        'weekly_count': 0,
        'total_spins': 0,
        'can_spin': false,
        'spins_remaining': 0,
        'reward_points': 0,
      };
    }

    try {
      return {
        'today_count': await AppSettings.getTodaySpinCount(),
        'daily_limit': await AppSettings.getDailySpinLimit(),
        'weekly_count': await AppSettings.getWeeklySpinCount(),
        'total_spins': await AppSettings.getTotalLifetimeSpins(),
        'can_spin': await AppSettings.canSpinToday(),
        'spins_remaining': await AppSettings.getRemainingSpinsToday(),
        'reward_points': await AppSettings.getSpinRewardPoints(),
      };
    } catch (e) {
      LogManager.debug('[AppInit] Error fetching spin summary: $e');
      return {};
    }
  }

  static Future<void> _initializeUserSession(
      ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      final isLoggedIn = await serviceManager.authService.isLoggedIn();
      if (isLoggedIn) {
        GuestApiGate.isGuestSession = false;
      }
      if (container != null) {
        container.read(isLoggedInSyncProvider.notifier).state = isLoggedIn;
      }
      if (isLoggedIn) {
        await _loadUserProfile(serviceManager, container);
        final profileSyncService = ProfileSyncService(
          apiService: serviceManager.apiService,
          trackEvent: serviceManager.analyticsService.trackEvent,
        );
        await profileSyncService.retryQueuedUpdates();
        await initializeWebSocket();
        RichPresenceService().initialize(useWebSocket: true);
      }
    } catch (_) {}
  }

  static Future<void> _loadUserProfile(
      ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      final profileSyncService = ProfileSyncService(
        apiService: serviceManager.apiService,
        trackEvent: serviceManager.analyticsService.trackEvent,
      );
      final remoteProfile = await profileSyncService.fetchRemoteProfile();
      if (remoteProfile != null && remoteProfile.isNotEmpty) {
        await serviceManager.playerProfileService.saveProfileBatch(remoteProfile);
        return;
      }
    } catch (_) {}
  }

  static Future<void> _preloadQuestions(ServiceManager serviceManager) async {
    await Future.delayed(const Duration(seconds: 1));
  }

  static Future<void> _initializeMultiProfileSystem(
      ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      final multiProfileService = MultiProfileService();
      await multiProfileService.initializeAndMigrate(serviceManager.playerProfileService);
      final activeProfile = await multiProfileService.getActiveProfile();
      if (container != null && activeProfile != null) {
        container.read(activeProfileStateProvider.notifier).state = activeProfile;
      }
    } catch (_) {}
  }

  static Future<void> _initializeReferralStorage() async {
    await ReferralStorageService().initialize();
  }

  static Future<void> _configureRemoteAssetManifest(
      ServiceManager serviceManager) async {
    try {
      final appConfig = await serviceManager.apiService.fetchAppConfig();
      final assets = appConfig['assets'];
      if (assets is! Map) return;
      final manifestUrl = assets['manifestUrl']?.toString();
      if (manifestUrl != null && manifestUrl.isNotEmpty) {
        AssetResolver.configure(AssetResolver.fromManifestUrl(manifestUrl));
      }
    } catch (_) {}
  }

  static Future<void> forceSave() async {
    if (_lifecycleManager != null) await _lifecycleManager!.forceSave();
  }

  static Future<void> dispose() async {
    try {
      await disconnectWebSocket();
      await _saveAppState();
      _lifecycleManager?.dispose();
    } catch (_) {}
  }
}
