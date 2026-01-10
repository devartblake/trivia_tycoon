import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/analytics/config_service.dart';
import 'package:trivia_tycoon/core/services/theme/theme_notifier.dart';
import 'package:trivia_tycoon/core/manager/service_manager.dart';
import 'package:trivia_tycoon/game/logic/referral_invite_adapter.dart';
import '../../game/analytics/services/spin_analytics_tracker.dart';
import '../../game/providers/multi_profile_providers.dart';
import '../../game/services/referral_storage_service.dart';
import '../services/notification_service.dart';
import '../../game/providers/auth_providers.dart';
import '../helpers/educational_stats_initializer.dart';
import '../../game/providers/onboarding_providers.dart';
import '../services/settings/app_settings.dart';
import '../services/settings/general_key_value_storage_service.dart';
import '../services/settings/multi_profile_service.dart';

/// AppInit handles bootstrapping critical services before runApp()
class AppInit {
  // Store tracker for later use
  static SpinAnalyticsTracker? _spinAnalyticsTracker;

  /// Get the spin analytics tracker instance
  static SpinAnalyticsTracker? get spinAnalyticsTracker => _spinAnalyticsTracker;

  static Future<void> _initializeMultiProfileSystem(ServiceManager serviceManager, ProviderContainer? container)
  async {
    try {
      // Initialize multi-profile system
      final multiProfileService = MultiProfileService();

      // Migrate existing single profile if needed
      await multiProfileService.initializeAndMigrate(serviceManager.playerProfileService);

      // Load active profile
      final activeProfile = await multiProfileService.getActiveProfile();

      if (container != null && activeProfile != null) {
        // Update the active profile state provider
        container.read(activeProfileStateProvider.notifier).state = activeProfile;

        debugPrint('[AppInit] Active profile loaded: ${activeProfile.name}');
      } else {
        debugPrint('[AppInit] No active profile found - user will need to select one');
      }

    } catch (e) {
      debugPrint('[AppInit] Multi-profile initialization failed: $e');
      // Continue with default state - app should still work
    }
  }

  static Future<(ServiceManager, ThemeNotifier)> initialize({ProviderContainer? container}) async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Initialize Hive boxes
    await Hive.initFlutter();
    await Hive.openBox('secrets');
    await Hive.openBox('settings');
    await Hive.openBox('cache');
    await Hive.openBox('question');
    Hive.registerAdapter(ReferralInviteHiveAdapter());

    // Initialize NotificationService EARLY - but don't request permissions yet
    await _initializeNotifications();

    try {
      await Hive.openBox('settings');
    } catch (e) {
      // Fallback or recreate
      await Hive.deleteBoxFromDisk('settings');
      await Hive.openBox('settings');
    }

    // Initialize referral storage
    await _initializeReferralStorage();

    // Initialize GeneralKeyValueStorageService early for mission data
    final generalKeyValueStorage = GeneralKeyValueStorageService();

    try {
      final storedAge = await generalKeyValueStorage.getString('user_age_group');
      debugPrint('[AppInit] User age group: ${storedAge ?? 'not set'}');
    } catch (e) {
      debugPrint('[AppInit] Failed to load user age group: $e');
    }

    // Initialize Supabase BEFORE ServiceManager
    try {
      await Supabase.initialize(
        url: 'your-supabase-url-here',
        anonKey: 'your-supabase-anon-key-here',
      );
      debugPrint('[AppInit] Supabase initialized successfully');
    } catch (e) {
      debugPrint('[AppInit] Supabase initialization failed: $e - continuing with local mode');
      // App continues without Supabase - will use JSON-only mission mode
    }

    // Load and initialize ServiceManager
    final serviceManager = await ServiceManager.initialize();

    // Inject dependencies into ConfigService
    final configService = ConfigService.instance;
    configService.initServices(serviceManager);

    // Load local + remote config
    await configService.loadConfig().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        debugPrint("[WARN] ConfigService timeout. Using default settings.");
      },
    );
    // Initialize multi-profile system
    await _initializeMultiProfileSystem(serviceManager, container);
    // Safe pre-fetch of splash type to avoid runtime crash later
    try {
      await serviceManager.splashSettingsService.getSplashType();
    } catch (e) {
      debugPrint('[AppInit] Failed to load SplashType: $e â€” fallback to default.');
    }

    // Get ThemeNotifier from ServiceManager (already initialized)
    final themeNotifier = serviceManager.themeNotifier;

    // Preload user session and sync with River-pod providers
    await _initializeUserSession(serviceManager, container);

    // ============ INITIALIZE SPIN ANALYTICS ============
    await _initializeSpinAnalytics(serviceManager);
    // ============ END SPIN ANALYTICS ============

    // Initialize educational statistics system
    if (container != null) {
      try {
        final tempContainer = ProviderContainer();
        await EducationalStatsInitializer.initialize(tempContainer.read as WidgetRef);
        tempContainer.dispose();
      } catch (e) {
        debugPrint('[AppInit] Educational stats initialization failed: $e');
      }
    }

    // Preload analytics and user session state
    try {
      await serviceManager.analyticsService.trackStartup().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          debugPrint('[AppInit] Analytics startup timeout - app continues normally');
        },
      );
    } catch (e) {
      debugPrint('[AppInit] Analytics startup failed: $e - app continues normally');
    }

    return (serviceManager, themeNotifier);
  }

  /// Initialize Spin Analytics Tracker
  static Future<void> _initializeSpinAnalytics(ServiceManager serviceManager) async {
    try {
      // Create spin analytics tracker
      _spinAnalyticsTracker = SpinAnalyticsTracker(serviceManager.analyticsService);

      // Load initial spin data
      final todayCount = await AppSettings.getTodaySpinCount();
      final weeklyCount = await AppSettings.getWeeklySpinCount();
      final totalSpins = await AppSettings.getTotalLifetimeSpins();
      final canSpin = await AppSettings.canSpinToday();
      final rewardPoints = await AppSettings.getSpinRewardPoints();

      // Track spin system initialized
      await serviceManager.analyticsService.trackEvent('spin_system_initialized', {
        'today_count': todayCount,
        'weekly_count': weeklyCount,
        'total_spins': totalSpins,
        'can_spin': canSpin,
        'reward_points': rewardPoints,
        'timestamp': DateTime.now().toIso8601String(),
      });

      debugPrint('[AppInit] Spin Analytics initialized');
      debugPrint('[AppInit] - Today: $todayCount spins');
      debugPrint('[AppInit] - Weekly: $weeklyCount spins');
      debugPrint('[AppInit] - Total: $totalSpins spins');
      debugPrint('[AppInit] - Can Spin: $canSpin');
      debugPrint('[AppInit] - Reward Points: $rewardPoints');
    } catch (e) {
      debugPrint('[AppInit] Spin Analytics initialization failed: $e');
      // Continue - analytics is not critical
    }
  }

  /// Initialize NotificationService (replaces the old _initializeNotifications method)
  static Future<void> _initializeNotifications() async {
    try {
      // Use the centralized NotificationService instead of direct AwesomeNotifications calls
      final success = await NotificationService().initialize();
      debugPrint('[AppInit] NotificationService initialized: $success');

      // Don't request permissions here - let the app request them contextually
      // This prevents the permission dialog from appearing immediately on app start

    } catch (e) {
      debugPrint('[AppInit] Failed to initialize NotificationService: $e');
      // App continues without notifications - this is not critical
    }
  }

  /// Initialize Referral Storage Service
  static Future<void> _initializeReferralStorage() async {
    try {
      final referralStorage = ReferralStorageService();
      await referralStorage.initialize();
      debugPrint('[AppInit] ReferralStorageService initialized');
    } catch (e) {
      debugPrint('[AppInit] Failed to initialize ReferralStorageService: $e');
      // Continue - referral system is not critical for app startup
    }
  }

  /// Optional: Request notification permissions (call this only when appropriate)
  /// You might want to call this from a settings screen or when user first interacts with notifications
  static Future<void> requestNotificationPermissions({BuildContext? context}) async {
    if (context != null) {
      await NotificationService().requestPermissionsWithDialog(context);
    } else {
      // Request without dialog (silent request)
      try {
        final isAllowed = await NotificationService().isNotificationEnabled();
        if (!isAllowed) {
          debugPrint('[AppInit] Notifications not enabled');
        } else {
          debugPrint('[AppInit] Notifications already enabled');
        }
      } catch (e) {
        debugPrint('[AppInit] Failed to check notification permissions: $e');
      }
    }
  }

  /// Initialize user session and sync with Riverpod providers
  static Future<void> _initializeUserSession(ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      final isLoggedIn = await serviceManager.authService.isLoggedIn();
      final hasOnboarded = await serviceManager.onboardingSettingsService.hasCompletedOnboarding();

      debugPrint('Session loaded: isLoggedIn=$isLoggedIn, hasOnboarded=$hasOnboarded');

      // Track session initialization
      await serviceManager.analyticsService.trackEvent('user_session_initialized', {
        'is_logged_in': isLoggedIn,
        'has_onboarded': hasOnboarded,
        'timestamp': DateTime.now().toIso8601String(),
      });

      if (container != null) {
        container.read(isLoggedInSyncProvider.notifier).state = isLoggedIn;

        if (hasOnboarded) {
          container.read(hasSeenIntroProvider.notifier).state = true;
          container.read(hasCompletedProfileProvider.notifier).state = true;
        }

        debugPrint('Riverpod providers synchronized with service state');
      }

      if (isLoggedIn) {
        await _loadUserProfile(serviceManager, container);
      }
    } catch (e) {
      debugPrint('[AppInit] User session initialization failed: $e');
    }
  }

  /// Load user profile data for logged-in users
  static Future<void> _loadUserProfile(ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      final playerName = await serviceManager.playerProfileService.getPlayerName();
      final userRole = await serviceManager.playerProfileService.getUserRole();
      final isPremium = await serviceManager.playerProfileService.isPremiumUser();

      debugPrint('User profile loaded: $playerName, role: $userRole, premium: $isPremium');

      await serviceManager.analyticsService.trackEvent('user_profile_loaded', {
        'player_name': playerName,
        'user_role': userRole,
        'is_premium': isPremium,
      });
    } catch (e) {
      debugPrint('[AppInit] User profile loading failed: $e');
    }
  }

  /// Method to reinitialize user session (useful after login/logout)
  static Future<void> reinitializeUserSession(ServiceManager serviceManager, ProviderContainer container) async {
    await _initializeUserSession(serviceManager, container);
  }

  /// Track app lifecycle events
  static Future<void> trackAppLifecycle(ServiceManager serviceManager, String event) async {
    try {
      await serviceManager.analyticsService.trackLifecycleEvent(
        event,
        additionalData: {
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('[AppInit] Failed to track lifecycle event: $e');
    }
  }

  /// Get spin analytics summary for debugging
  static Future<Map<String, dynamic>> getSpinAnalyticsSummary() async {
    try {
      return {
        'today_count': await AppSettings.getTodaySpinCount(),
        'weekly_count': await AppSettings.getWeeklySpinCount(),
        'total_spins': await AppSettings.getTotalLifetimeSpins(),
        'can_spin': await AppSettings.canSpinToday(),
        'spins_remaining': await AppSettings.getRemainingSpinsToday(),
        'reward_points': await AppSettings.getSpinRewardPoints(),
      };
    } catch (e) {
      debugPrint('[AppInit] Failed to get spin analytics summary: $e');
      return {};
    }
  }
}