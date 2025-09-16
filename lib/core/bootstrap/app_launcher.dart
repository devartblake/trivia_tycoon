import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/analytics/app_lifecycle.dart';
import 'package:trivia_tycoon/core/manager/service_manager.dart';
import 'package:trivia_tycoon/core/services/theme/theme_notifier.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart' as providers;
import 'package:go_router/go_router.dart';

// Updated import to use new router
import '../../game/providers/auth_providers.dart';
import '../../game/providers/onboarding_providers.dart';
import '../../ui_components/power_ups/power_up_HUD_Overlay.dart';
import '../navigation/app_router.dart';
import '../theme/app_scroll_behavior.dart';

/// AppLauncher handles config + service initialization and launches the app
class AppLauncher extends ConsumerStatefulWidget {
  final (ServiceManager, ThemeNotifier) initialData;
  const AppLauncher({super.key, required this.initialData});

  @override
  ConsumerState<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends ConsumerState<AppLauncher> {
  GoRouter? _router;
  bool _authStateInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializeAuthState();
    _initRouter();
  }

  /// Initialize authentication state from your existing services
  Future<void> _initializeAuthState() async {
    try {
      final serviceManager = widget.initialData.$1;

      // Check existing auth state and update providers accordingly
      final isLoggedIn = await serviceManager.authService.isLoggedIn();
      final hasOnboarded = await serviceManager.onboardingSettingsService.hasCompletedOnboarding();

      // Update the provider state to match service state
      if (isLoggedIn) {
        ref.read(isLoggedInSyncProvider.notifier).state = true;
      }

      if (isLoggedIn && hasOnboarded) {
        // User is returning and has completed onboarding
        ref.read(hasSeenIntroProvider.notifier).state = true;
        ref.read(hasCompletedProfileProvider.notifier).state = true;
      }

      setState(() {
        _authStateInitialized = true;
      });

      debugPrint('Auth state initialized: isLoggedIn=$isLoggedIn, hasOnboarded=$hasOnboarded');
    } catch (e) {
      debugPrint('Error initializing auth state: $e');
      setState(() {
        _authStateInitialized = true; // Continue anyway
      });
    }
  }

  Future<void> _initRouter() async {
    // Wait for auth state to be initialized before creating router
    while (!_authStateInitialized) {
      await Future.delayed(const Duration(milliseconds: 50));
    }

    // Use the provider-based router
    final router = ref.read(goRouterProvider);
    setState(() => _router = router);
  }

  @override
  Widget build(BuildContext context) {
    if (!_authStateInitialized || _router == null) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Initializing app...'),
            ],
          ),
        ),
      );
    }

    // Get theme from your system
    final themeNotifier = ref.watch(providers.themeNotifierProvider);

    return AppLifecycleObserver(
      child: MaterialApp.router(
        title: 'Trivia Tycoon',
        debugShowCheckedModeBanner: false,
        scrollBehavior: AppScrollBehavior(),

        // Use your existing theme system - ThemeNotifier provides themeData and themeMode
        theme: themeNotifier.themeData,
        themeMode: themeNotifier.themeMode,

        // Use the new provider-based router
        routerConfig: _router!,

        // Add the PowerUpHUDOverlay and other features from your AppShell
        builder: (context, child) {
          return MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaleFactor: MediaQuery.of(context).textScaleFactor.clamp(0.8, 1.4),
            ),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              child: Stack(
                children: [
                  if (child != null) child,
                  const PowerUpHUDOverlay(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
