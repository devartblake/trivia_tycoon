import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:trivia_tycoon/core/services/analytics/config_service.dart';
import 'package:trivia_tycoon/core/services/theme/theme_notifier.dart';
import 'package:trivia_tycoon/core/manager/service_manager.dart';
import '../services/settings/general_key_value_storage_service.dart';

/// AppInit handles bootstrapping critical services before runApp()
class AppInit {
  static Future<(ServiceManager, ThemeNotifier)> initialize() async {
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

    // ✅ Initialize theme notifier with required dependency
    final generalStorage = GeneralKeyValueStorageService();
    final themeNotifier = ThemeNotifier(generalStorage);
    await themeNotifier.initializationCompleted;

    // ✅ Preload user session (if needed)
    final isLoggedIn = await serviceManager.authService.isLoggedIn();
    final hasOnboarded = await serviceManager.onboardingSettingsService.hasCompletedOnboarding();
    debugPrint('Session: isLoggedIn=$isLoggedIn, hasOnboarded=$hasOnboarded');

    // ✅ Preload analytics and user session state
    try {
      await serviceManager.analyticsService.trackStartup();
    } catch (e) {
      debugPrint('[AppInit] Failed to preload analytics: ${e.toString()}');
    }

    return (serviceManager, themeNotifier);
  }
}