import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:trivia_tycoon/core/services/analytics/config_service.dart';
import 'package:trivia_tycoon/core/services/theme/theme_notifier.dart';
import 'package:trivia_tycoon/core/manager/service_manager.dart';
import '../../game/providers/auth_providers.dart';
import '../../game/providers/onboarding_providers.dart';
import '../services/settings/general_key_value_storage_service.dart';

/// AppInit handles bootstrapping critical services before runApp()
class AppInit {
  static Future<(ServiceManager, ThemeNotifier)> initialize({ProviderContainer? container}) async {
    WidgetsFlutterBinding.ensureInitialized();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

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

    // Preload user session and sync with Riverpod providers
    await _initializeUserSession(serviceManager, container);

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

  /// Initialize user session and sync with Riverpod providers
  static Future<void> _initializeUserSession(ServiceManager serviceManager, ProviderContainer? container) async {
    try {
      // Load auth state from services
      final isLoggedIn = await serviceManager.authService.isLoggedIn();
      final hasOnboarded = await serviceManager.onboardingSettingsService.hasCompletedOnboarding();

      debugPrint('Session loaded: isLoggedIn=$isLoggedIn, hasOnboarded=$hasOnboarded');

      // Sync with Riverpod providers if container is provided
      if (container != null) {
        // Update auth state
        container.read(isLoggedInSyncProvider.notifier).state = isLoggedIn;

        // Update onboarding state based on completion status
        if (hasOnboarded) {
          container.read(hasSeenIntroProvider.notifier).state = true;
          container.read(hasCompletedProfileProvider.notifier).state = true;
        }

        debugPrint('Riverpod providers synchronized with service state');
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

      // You can sync additional profile data with Riverpod providers here if needed
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