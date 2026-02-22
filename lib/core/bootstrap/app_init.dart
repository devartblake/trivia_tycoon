import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/services/analytics/config_service.dart';
import 'package:trivia_tycoon/core/services/storage/secure_storage.dart';
import 'package:trivia_tycoon/core/services/theme/theme_notifier.dart';
import 'package:trivia_tycoon/core/manager/service_manager.dart';
import 'package:trivia_tycoon/game/logic/referral_invite_adapter.dart';
import '../../game/analytics/services/spin_analytics_tracker.dart';
import '../../game/providers/multi_profile_providers.dart';
import '../../game/services/referral_storage_service.dart';
import '../env.dart';
import '../networking/ws_client.dart';
import '../networking/http_client.dart';
import '../networking/tycoon_api_client.dart';
import '../services/auth_http_client.dart';
import '../services/auth_api_client.dart';
import '../services/auth_service.dart';
import '../services/auth_token_store.dart';
import '../services/device_id_service.dart';
import '../services/notification_service.dart';
import '../../game/providers/auth_providers.dart';
import '../helpers/educational_stats_initializer.dart';
import '../services/settings/app_settings.dart';
import '../services/settings/multi_profile_service.dart';

/// App bootstrapper
/// - Loads env
/// - Initializes ServiceManager (API clients, local storage, etc.)
class AppInit {
  static bool _backgroundServicesReady = false;
  static SpinAnalyticsTracker? _spinAnalyticsTracker;
  static SpinAnalyticsTracker? get spinAnalyticsTracker => _spinAnalyticsTracker;

  // WebSocket management
  static WsClient? _wsClient;
  static WsClient? get wsClient => _wsClient;
  static bool _wsConnected = false;

  // ✅ Store tokenStore for WebSocket
  static AuthTokenStore? _tokenStore;
  static AuthTokenStore? get tokenStore => _tokenStore;

  // --- CRITICAL INITIALIZATION (Required for first frame) ---
  static Future<(ServiceManager, ThemeNotifier)> initialize({ProviderContainer? container}) async {
    await EnvConfig.load();
    // 1. Core Flutter & Storage Setup
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Initialize Hive BEFORE any services access it
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(ReferralInviteHiveAdapter().typeId)) {
      Hive.registerAdapter(ReferralInviteHiveAdapter());
    }

    // Open critical boxes required for theme/auth immediately
    final authTokenBox = await Hive.openBox('auth_tokens'); // ← NEW: Dedicated box for auth tokens
    final settingsBox = await Hive.openBox('settings');
    final secretsBox = await Hive.openBox('secrets');

    // 2. Network & Backend
    // Create SecureStorage instance (don't cast the box!)
    final secureStorage = SecureStorage(); // ← FIXED: Create proper instance

    // Create DeviceIdService with SecureStorage
    final deviceIdService = DeviceIdService(secureStorage); // ← FIXED: Pass SecureStorage, not Box
    final deviceId = await deviceIdService.getOrCreate();
    debugPrint('✅ DeviceId ready: $deviceId');

    // Create AuthTokenStore with dedicated auth tokens box
    final tokenStore = AuthTokenStore(authTokenBox);

    // Store for after use
    _tokenStore = tokenStore;

    final httpClient = http.Client();
    final authApi = AuthApiClient(httpClient, apiBaseUrl: EnvConfig.apiBaseUrl, deviceId: deviceIdService);

    final authService = AuthService(
      deviceId: deviceIdService,
      tokenStore: tokenStore,
      api: authApi,
    );

    // Force deviceId creation early (so login/refresh always has it)
    await authService.ensureDeviceId();

    // 3. Service Manager & Core Logic
    final serviceManager = await ServiceManager.initialize();

    // Check session & load profile using safe casting
    await _initializeUserSession(serviceManager, container);
    await _initializeMultiProfileSystem(serviceManager, container);

    debugPrint('[AppInit] Critical initialization complete');
    return (serviceManager, serviceManager.themeNotifier);
  }

  /// Initialize WebSocket connection
  /// Should be called after user login
  static Future<void> initializeWebSocket() async {
    try {
      debugPrint('[AppInit] Initializing WebSocket...');

      // ✅ CHANGED - Use stored tokenStore
      if (_tokenStore == null) {
        debugPrint('[AppInit] TokenStore not initialized');
        return;
      }

      // Get auth token
      final session = _tokenStore!.load();
      if (!session.hasTokens) {
        debugPrint('[AppInit] No auth token, skipping WebSocket');
        return;
      }

      // Determine WebSocket URL based on environment
      final wsUrl = EnvConfig.apiWsBaseUrl;

      // Create WebSocket client
      _wsClient = WsClient(
        url: wsUrl,
        onMessage: (message) {
          debugPrint('[WS] ← ${message.op}');
        },
        onStateChange: (state) {
          debugPrint('[WS] State: $state');
          _wsConnected = (state == WsState.connected);
        },
        onError: (error) {
          debugPrint('[WS] Error: $error');
        },
      );

      // Connect
      await _wsClient!.connect();
      debugPrint('[AppInit] WebSocket initialized');

    } catch (e) {
      debugPrint('[AppInit] WebSocket initialization failed: $e');
    }
  }

  /// Disconnect WebSocket
  static Future<void> disconnectWebSocket() async {
    if (_wsClient != null) {
      debugPrint('[AppInit] Disconnecting WebSocket...');
      await _wsClient!.disconnect();
      _wsClient = null;
      _wsConnected = false;
    }
  }

  /// Reconnect WebSocket (for app resume)
  static Future<void> reconnectWebSocket() async {
    if (_wsClient != null && !_wsConnected) {
      debugPrint('[AppInit] Reconnecting WebSocket...');
      await _wsClient!.reconnect();
    }
  }

  /// Check if WebSocket is connected
  static bool get isWebSocketConnected => _wsConnected;

  // --- BACKGROUND INITIALIZATION (Deferred for performance) ---
  static Future<void> initializeBackgroundServices(ServiceManager serviceManager, ProviderContainer? container) async {
    // Wait a short moment to let the UI finish rendering
    await Future.delayed(const Duration(seconds: 1));
    debugPrint('[AppInit] Starting deferred background services...');

    try {
      // 1. Open secondary storage
      await Hive.openBox('cache');
      await Hive.openBox('question');

      // 2. Notifications (Hive is ready now)
      await NotificationService().initialize();
      await _initializeReferralStorage();

      // 3. Analytics & Config (The "Noisy" Services)
      final configService = ConfigService.instance;
      configService.initServices(serviceManager);
      await configService.loadConfig();

      _spinAnalyticsTracker = SpinAnalyticsTracker(serviceManager.analyticsService);
      await serviceManager.analyticsService.trackStartup();

      if (container != null) {
        await EducationalStatsInitializer.initialize(container as dynamic);
      }

      _backgroundServicesReady = true;
      debugPrint('[AppInit] Background services ready');
    } catch (e) {
      debugPrint('[AppInit] Background initialization error: $e');
    }
  }

  /// Refactored to be safe even if called before analytics are ready
  static Future<void> trackAppLifecycle(ServiceManager serviceManager, String event) async {
    // If background services aren't ready, we skip tracking to avoid console noise/errors
    if (!_backgroundServicesReady) return;

    try {
      await serviceManager.analyticsService.trackLifecycleEvent(
        event,
        additionalData: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      // Use silent logging here to keep console clean
      debugPrint('[AppInit] Lifecycle track skipped: service not ready or error');
    }
  }

  // --- HELPERS WITH SAFE CASTING ---

  /// Get spin analytics summary for debugging (Safely)
  static Future<Map<String, dynamic>> getSpinAnalyticsSummary() async {
    // If background services (Hive boxes) aren't ready, return empty/safe defaults
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
      debugPrint('[AppInit] Error fetching spin summary: $e');
      return {};
    }
  }

  static Future<void> _initializeUserSession(ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      final isLoggedIn = await serviceManager.authService.isLoggedIn();
      if (container != null) {
        container.read(isLoggedInSyncProvider.notifier).state = isLoggedIn;
      }
      if (isLoggedIn) {
        await _loadUserProfile(serviceManager, container);

        // ✅ CHANGED - No parameter needed now
        await initializeWebSocket();
      }
    } catch (e) {
      debugPrint('[AppInit] Session check failed: $e');
    }
  }

  static Future<void> _loadUserProfile(ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      final rawProfile = await serviceManager.playerProfileService.getProfile();
      // FIX: Safe Map casting to prevent _Map<dynamic, dynamic> errors
      final profile = rawProfile != null ? Map<String, dynamic>.from(rawProfile as Map) : {};

      if (profile.isNotEmpty) {
        debugPrint('[AppInit] Profile loaded for: ${profile['name']}');
      }
    } catch (e) {
      debugPrint('[AppInit] Profile cast failed: $e');
    }
  }

  static Future<void> _initializeMultiProfileSystem(ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      final multiProfileService = MultiProfileService();
      await multiProfileService.initializeAndMigrate(serviceManager.playerProfileService);
      final activeProfile = await multiProfileService.getActiveProfile();
      if (container != null && activeProfile != null) {
        container.read(activeProfileStateProvider.notifier).state = activeProfile;
      }
    } catch (e) {
      debugPrint('[AppInit] Multi-profile error: $e');
    }
  }

  static Future<void> _initializeReferralStorage() async {
    final referralStorage = ReferralStorageService();
    await referralStorage.initialize();
  }
}