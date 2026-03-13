import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
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
import '../services/app_lifecycle_manager.dart';
import '../services/auth_api_client.dart';
import '../services/auth_service.dart';
import '../services/auth_token_store.dart';
import '../services/device_id_service.dart';
import '../services/notification_service.dart';
import '../../game/providers/auth_providers.dart';
import '../helpers/educational_stats_initializer.dart';
import '../services/presence/rich_presence_service.dart';
import '../services/settings/app_settings.dart';
import '../services/settings/multi_profile_service.dart';
import '../services/state_persistence_service.dart';

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

  // Store tokenStore for WebSocket
  static AuthTokenStore? _tokenStore;
  static AuthTokenStore? get tokenStore => _tokenStore;

  // Graceful shutdown services
  static AppLifecycleManager? _lifecycleManager;
  static AppLifecycleManager? get lifecycleManager => _lifecycleManager;

  static StatePersistenceService? _persistenceService;
  static StatePersistenceService? get persistenceService => _persistenceService;

  // Store ServiceManager for lifecycle callbacks
  static ServiceManager? _serviceManager;

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

    // Initialize persistence service early
    _persistenceService = StatePersistenceService();
    await _persistenceService!.initialize();
    LogManager.debug(' StatePersistence ready');

    // 2. Network & Backend
    // Create SecureStorage instance (don't cast the box!)
    final secureStorage = SecureStorage(); // ← FIXED: Create proper instance

    // Create DeviceIdService with SecureStorage
    final deviceIdService = DeviceIdService(secureStorage); // ← FIXED: Pass SecureStorage, not Box
    final deviceId = await deviceIdService.getOrCreate();
    final deviceType = deviceIdService.getDeviceType();
    LogManager.debug('✅ Device identity ready: id=$deviceId, type=$deviceType');

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
    _serviceManager = serviceManager; // Store for lifecycle callbacks

    // ✅ NEW - Initialize lifecycle manager with save callbacks
    _lifecycleManager = AppLifecycleManager(
      onAppPaused: () {
        LogManager.debug('[Lifecycle] 📱 App PAUSED - saving state...');
      },
      onAppResumed: () {
        LogManager.debug('[Lifecycle] 📱 App RESUMED');
      },
      onAppDetached: () {
        LogManager.debug('[Lifecycle] 📱 App DETACHED - final save...');
      },
      onAppInactive: () {
        LogManager.debug('[Lifecycle] 📱 App INACTIVE - quick save...');
      },
      onSaveState: () async {
        await _saveAppState();
      },
      onClearTempData: () async {
        await _persistenceService?.clearTemporaryData();
      },
    );
    _lifecycleManager!.initialize();
    LogManager.debug('✅ AppLifecycleManager initialized');

    // Check session & load profile using safe casting
    await _initializeUserSession(serviceManager, container);
    await _initializeMultiProfileSystem(serviceManager, container);

    LogManager.debug('[AppInit] Critical initialization complete');
    return (serviceManager, serviceManager.themeNotifier);
  }

  // Save all app state
  static Future<void> _saveAppState() async {
    if (_serviceManager == null || _persistenceService == null) {
      LogManager.debug('[AppInit] ⚠️ Services not ready, skipping save');
      return;
    }

    try {
      // 1. Gather game state (if in active game)
      final gameState = await _getCurrentGameState();

      // 2. Gather user session
      final userSession = await _getCurrentUserSession();

      // 3. Gather WebSocket state
      final wsState = await _getCurrentWebSocketState();

      // 4. Gather pending actions
      final pendingActions = await _getPendingActions();

      // 5. Save everything
      await _persistenceService!.saveAll(
        gameState: gameState,
        userSession: userSession,
        wsState: wsState,
        pendingActions: pendingActions,
      );

      LogManager.debug('[AppInit] ✅ App state saved successfully');
    } catch (e, stack) {
      LogManager.debug('[AppInit] ❌ App state save failed: $e');
      LogManager.debug('[AppInit] Stack: $stack');
    }
  }

  // Get current game state
  static Future<Map<String, dynamic>?> _getCurrentGameState() async {
    try {
      // TODO: Get actual game state from your game providers/services
      // For now, return null if no active game

      // Example if you're in a quiz:
      // final quizBox = await Hive.openBox('current_quiz');
      // if (quizBox.isEmpty) return null;
      // return {
      //   'quiz_id': quizBox.get('quiz_id'),
      //   'current_question': quizBox.get('current_question'),
      //   'score': quizBox.get('score'),
      //   'lives': quizBox.get('lives'),
      //   'answers': quizBox.get('answers'),
      //   'time_started': DateTime.now().toIso8601String(),
      // };

      return null; // No active game state to save
    } catch (e) {
      LogManager.debug('[AppInit] ⚠️ Get game state error: $e');
      return null;
    }
  }

  // Get current user session
  static Future<Map<String, dynamic>?> _getCurrentUserSession() async {
    try {
      if (_serviceManager == null) return null;

      final isLoggedIn = await _serviceManager!.authService.isLoggedIn();
      if (!isLoggedIn) return null;

      // Get auth tokens
      final session = _tokenStore?.load();

      // Get user profile
      final rawProfile = await _serviceManager!.playerProfileService.getProfile();
      final profile = rawProfile != null ? Map<String, dynamic>.from(rawProfile as Map) : {};

      return {
        'is_logged_in': isLoggedIn,
        'user_id': profile['id'],
        'user_name': profile['name'],
        'has_tokens': session?.hasTokens ?? false,
        'session_start': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LogManager.debug('[AppInit] ⚠️ Get user session error: $e');
      return null;
    }
  }

  // Get WebSocket state
  static Future<Map<String, dynamic>?> _getCurrentWebSocketState() async {
    try {
      if (_wsClient == null) return null;

      return {
        'connected': _wsConnected,
        'url': EnvConfig.apiWsBaseUrl,
        'last_connection': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      LogManager.debug('[AppInit] ⚠️ Get WebSocket state error: $e');
      return null;
    }
  }

  // Get pending actions (failed requests)
  static Future<List<Map<String, dynamic>>> _getPendingActions() async {
    try {
      // TODO: Get from your queue/retry system
      // Example:
      // final pendingBox = await Hive.openBox('pending_requests');
      // return pendingBox.values.toList();

      return []; // No pending actions
    } catch (e) {
      LogManager.debug('[AppInit] ⚠️ Get pending actions error: $e');
      return [];
    }
  }

  /// Initialize WebSocket connection
  /// Should be called after user login
  static Future<void> initializeWebSocket() async {
    try {
      LogManager.debug('[AppInit] Initializing WebSocket...');

      // ✅ CHANGED - Use stored tokenStore
      if (_tokenStore == null) {
        LogManager.debug('[AppInit] TokenStore not initialized');
        return;
      }

      // Get auth token
      final session = _tokenStore!.load();
      if (!session.hasTokens) {
        LogManager.debug('[AppInit] No auth token, skipping WebSocket');
        return;
      }

      // Determine WebSocket URL based on environment
      final wsUrl = EnvConfig.apiWsBaseUrl;

      // Create WebSocket client
      _wsClient = WsClient(
        url: wsUrl,
        onMessage: (message) {
          LogManager.debug('[WS] ← ${message.op}');
        },
        onStateChange: (state) {
          LogManager.debug('[WS] State: $state');
          _wsConnected = (state == WsState.connected);

          // Save WebSocket state on connection change
          _saveAppState();
        },
        onError: (error) {
          LogManager.debug('[WS] Error: $error');
        },
      );

      // Connect
      await _wsClient!.connect();
      LogManager.debug('[AppInit] WebSocket initialized');

    } catch (e) {
      LogManager.debug('[AppInit] WebSocket initialization failed: $e');
    }
  }

  /// Disconnect WebSocket
  static Future<void> disconnectWebSocket() async {
    if (_wsClient != null) {
      LogManager.debug('[AppInit] Disconnecting WebSocket...');
      await _wsClient!.disconnect();
      _wsClient = null;
      _wsConnected = false;

      // Save state after disconnect
      await _saveAppState();
    }
  }

  /// Reconnect WebSocket (for app resume)
  static Future<void> reconnectWebSocket() async {
    if (_wsClient != null && !_wsConnected) {
      LogManager.debug('[AppInit] Reconnecting WebSocket...');
      await _wsClient!.reconnect();
    }
  }

  /// Check if WebSocket is connected
  static bool get isWebSocketConnected => _wsConnected;

  // --- BACKGROUND INITIALIZATION (Deferred for performance) ---
  static Future<void> initializeBackgroundServices(ServiceManager serviceManager, ProviderContainer? container) async {
    // Wait a short moment to let the UI finish rendering
    await Future.delayed(const Duration(seconds: 1));
    LogManager.debug('[AppInit] Starting deferred background services...');

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
      LogManager.debug('[AppInit] Background services ready');
    } catch (e) {
      LogManager.debug('[AppInit] Background initialization error: $e');
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
      LogManager.debug('[AppInit] Lifecycle track skipped: service not ready or error');
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
      LogManager.debug('[AppInit] Error fetching spin summary: $e');
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

        // No parameter needed now
        await initializeWebSocket();
        // Initialize presence service
        RichPresenceService().initialize(useWebSocket: true);
      }
    } catch (e) {
      LogManager.debug('[AppInit] Session check failed: $e');
    }
  }

  static Future<void> _loadUserProfile(ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      final rawProfile = await serviceManager.playerProfileService.getProfile();
      // FIX: Safe Map casting to prevent _Map<dynamic, dynamic> errors
      final profile = rawProfile != null ? Map<String, dynamic>.from(rawProfile as Map) : {};

      if (profile.isNotEmpty) {
        final rawUserId = profile['id'] ?? profile['user_id'];
        final parsedUserId = rawUserId?.toString();
        if (parsedUserId != null && parsedUserId.isNotEmpty) {
          await serviceManager.playerProfileService.saveUserId(parsedUserId);
        }

        final rawDisplayName = profile['name'] ?? profile['display_name'];
        final parsedDisplayName = rawDisplayName?.toString();
        if (parsedDisplayName != null && parsedDisplayName.isNotEmpty) {
          await serviceManager.playerProfileService.savePlayerName(parsedDisplayName);
        }

        final rawUsername = profile['username'] ?? profile['handle'];
        final parsedUsername = rawUsername?.toString().toLowerCase();
        if (parsedUsername != null && parsedUsername.isNotEmpty) {
          await serviceManager.playerProfileService.saveUsername(parsedUsername);
        }
        LogManager.debug('[AppInit] Profile loaded for: ${profile['name']}');
      }
    } catch (e) {
      LogManager.debug('[AppInit] Profile cast failed: $e');
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
      LogManager.debug('[AppInit] Multi-profile error: $e');
    }
  }

  static Future<void> _initializeReferralStorage() async {
    final referralStorage = ReferralStorageService();
    await referralStorage.initialize();
  }

  // Force save (call before critical operations)
  static Future<void> forceSave() async {
    if (_lifecycleManager != null) {
      await _lifecycleManager!.forceSave();
    }
  }

  // Cleanup on app shutdown
  static Future<void> dispose() async {
    try {
      LogManager.debug('[AppInit] 👋 Disposing services...');

      // Disconnect WebSocket
      await disconnectWebSocket();

      // Final save
      await _saveAppState();

      // Dispose lifecycle manager
      _lifecycleManager?.dispose();

      LogManager.debug('[AppInit] ✅ Cleanup complete');
    } catch (e) {
      LogManager.debug('[AppInit] ❌ Dispose error: $e');
    }
  }
}
