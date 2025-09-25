import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:trivia_tycoon/core/services/analytics/config_service.dart';
import 'package:trivia_tycoon/core/services/theme/theme_notifier.dart';
import 'package:trivia_tycoon/core/manager/service_manager.dart';
import '../../game/providers/auth_providers.dart';
import '../../game/providers/onboarding_providers.dart';
import '../helpers/educational_stats_initializer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/settings/general_key_value_storage_service.dart';
import '../services/notification_service.dart'; // Import your NotificationService

/// AppInit handles bootstrapping critical services before runApp()
class AppInit {
  static Future<(ServiceManager, ThemeNotifier)> initialize({ProviderContainer? container}) async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    // Initialize NotificationService EARLY - but don't request permissions yet
    await _initializeNotifications();

    // Initialize Hive boxes
    await Hive.initFlutter();
    await Hive.openBox('secrets');
    await Hive.openBox('settings');
    await Hive.openBox('cache');
    await Hive.openBox('question');

    try {
      await Hive.openBox('settings');
    } catch (e) {
      // Fallback or recreate
      await Hive.deleteBoxFromDisk('settings');
      await Hive.openBox('settings');
    }

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

    // Safe pre-fetch of splash type to avoid runtime crash later
    try {
      await serviceManager.splashSettingsService.getSplashType();
    } catch (e) {
      debugPrint('[AppInit] Failed to load SplashType: $e — fallback to default.');
    }

    // Get ThemeNotifier from ServiceManager (already initialized)
    final themeNotifier = serviceManager.themeNotifier;

    // Preload user session and sync with River-pod providers
    await _initializeUserSession(serviceManager, container);

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

  /// Initialize user session and sync with River-pod providers
  static Future<void> _initializeUserSession(ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      // Load auth state from services
      final isLoggedIn = await serviceManager.authService.isLoggedIn();
      final hasOnboarded = await serviceManager.onboardingSettingsService.hasCompletedOnboarding();

      debugPrint('Session loaded: isLoggedIn=$isLoggedIn, hasOnboarded=$hasOnboarded');

      // Sync with River-pod providers if container is provided
      if (container != null) {
        // Update auth state
        container.read(isLoggedInSyncProvider.notifier).state = isLoggedIn;

        // Update onboarding state based on completion status
        if (hasOnboarded) {
          container.read(hasSeenIntroProvider.notifier).state = true;
          container.read(hasCompletedProfileProvider.notifier).state = true;
        }

        debugPrint('River-pod providers synchronized with service state');
      }

      // Load additional user data if logged in
      if (isLoggedIn) {
        await _loadUserProfile(serviceManager, container);
      }
    } catch (e) {
      debugPrint('[AppInit] User session initialization failed: $e');
      // Continue with default state - app should still work
    }
  }

  /// Load user profile data for logged-in users
  static Future<void> _loadUserProfile(ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      // Load user profile data
      final playerName = await serviceManager.playerProfileService.getPlayerName();
      final userRole = await serviceManager.playerProfileService.getUserRole();
      final isPremium = await serviceManager.playerProfileService.isPremiumUser();

      debugPrint('User profile loaded: $playerName, role: $userRole, premium: $isPremium');

      // You can sync additional profile data with River-pod providers here if needed
      // Example:
      // if (container != null) {
      //   container.read(userProfileProvider.notifier).updateProfile(
      //     name: playerName,
      //     role: userRole,
      //     isPremium: isPremium,
      //   );
      // }

    } catch (e) {
      debugPrint('[AppInit] User profile loading failed: $e');
      // Continue - this is not critical for app functionality
    }
  }

  /// Method to reinitialize user session (useful after login/logout)
  static Future<void> reinitializeUserSession(ServiceManager serviceManager, ProviderContainer container) async {
    await _initializeUserSession(serviceManager, container);
  }
}