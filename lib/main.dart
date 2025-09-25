import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/bootstrap/app_init.dart';
import 'package:trivia_tycoon/core/bootstrap/app_launcher.dart';
import 'package:trivia_tycoon/core/widgets/offline_fallback_screen.dart';
import 'package:trivia_tycoon/screens/splash_variants/main_splash.dart';
import 'package:trivia_tycoon/widgets/app_logo.dart';

import 'core/manager/service_manager.dart';
import 'core/services/theme/theme_notifier.dart';
import 'game/providers/riverpod_providers.dart' hide themeNotifierProvider;
import 'game/providers/auth_providers.dart';
import 'game/providers/onboarding_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize services first
    final (manager, theme) = await AppInit.initialize();

    // Initialize auth state from services
    await _initializeAuthState(manager);

    runApp(
      ProviderScope(
        overrides: [
          serviceManagerProvider.overrideWithValue(manager),
        ],
        child: TriviaTycoonApp(initialData: (manager, theme)),
      ),
    );
  } catch (e) {
    debugPrint('App initialization failed: $e');

    // Fallback - run app without pre-initialized state
    runApp(
      ProviderScope(
        child: const TriviaTycoonApp(),
      ),
    );
  }
}

/// Initialize auth state and sync with River-pod providers
Future<void> _initializeAuthState(ServiceManager serviceManager) async {
  try {
    // Create a temporary container to update providers
    final container = ProviderContainer(
      overrides: [
        serviceManagerProvider.overrideWithValue(serviceManager),
      ],
    );

    // Load auth state from services
    final isLoggedIn = await serviceManager.authService.isLoggedIn();
    final hasOnboarded = await serviceManager.onboardingSettingsService.hasCompletedOnboarding();

    debugPrint('Session loaded: isLoggedIn=$isLoggedIn, hasOnboarded=$hasOnboarded');

    // Sync with River-pod providers
    container.read(isLoggedInSyncProvider.notifier).state = isLoggedIn;

    // Update onboarding state based on completion status
    if (hasOnboarded) {
      container.read(hasSeenIntroProvider.notifier).state = true;
      container.read(hasCompletedProfileProvider.notifier).state = true;
    }

    // Dispose the temporary container
    container.dispose();

    debugPrint('River-pod providers synchronized with service state');
  } catch (e) {
    debugPrint('Auth state initialization failed: $e');
    // Continue with default state - app should still work
  }
}

class TriviaTycoonApp extends StatefulWidget {
  final (ServiceManager, ThemeNotifier)? initialData;

  const TriviaTycoonApp({super.key, this.initialData});

  @override
  State<TriviaTycoonApp> createState() => _TriviaTycoonAppState();
}

class _TriviaTycoonAppState extends State<TriviaTycoonApp> {
  (ServiceManager, ThemeNotifier)? _initialData;
  bool _initialized = false;
  bool _splashFinished = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _initialData = widget.initialData;
      _initialized = true;
    } else {
      _init();
    }
  }

  Future<void> _init() async {
    try {
      final data = await AppInit.initialize();
      setState(() {
        _initialData = data;
        _initialized = true;
      });
    } catch (e) {
      setState(() {
        _error = e;
      });
    }
  }

  void _onSplashFinished() {
    setState(() {
      _splashFinished = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 500),
        switchInCurve: Curves.easeIn,
        switchOutCurve: Curves.easeOut,
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_error != null) {
      return OfflineFallbackScreen(onRetry: _init);
    }

    if (!_splashFinished) {
      return SimpleSplashScreen(
        onDone: _onSplashFinished,
      );
    }

    if (!_initialized || _initialData == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return AppLauncher(initialData: _initialData!);
  }
}
