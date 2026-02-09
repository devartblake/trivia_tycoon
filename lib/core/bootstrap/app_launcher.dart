import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/analytics/app_lifecycle.dart';
import 'package:trivia_tycoon/core/manager/service_manager.dart';
import 'package:trivia_tycoon/core/services/theme/theme_notifier.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart' as providers;
import 'package:go_router/go_router.dart';
import '../../game/providers/auth_providers.dart';
import '../../game/providers/onboarding_providers.dart';
import '../../ui_components/power_ups/power_up_hud_overlay.dart';
import '../../widgets/app_logo.dart';
import '../navigation/app_router.dart';
import '../theme/app_scroll_behavior.dart';
import '../theme/themes.dart';
import '../services/theme/seasonal_theme_service.dart';
import 'app_init.dart';

/// AppLauncher handles config + service initialization and launches the app
class AppLauncher extends ConsumerStatefulWidget {
  final (ServiceManager, ThemeNotifier) initialData;
  const AppLauncher({super.key, required this.initialData});

  @override
  ConsumerState<AppLauncher> createState() => _AppLauncherState();
}

class _AppLauncherState extends ConsumerState<AppLauncher> with WidgetsBindingObserver {
  GoRouter? _router;
  bool _authStateInitialized = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAuthState();
    _initRouter();
    _trackAppLaunch();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ============ LIFECYCLE TRACKING ============

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Use the existing initialData pattern to avoid breaking changes
    final serviceManager = widget.initialData.$1;

    switch (state) {
      case AppLifecycleState.resumed:
      // This is now safe because we made trackAppLifecycle robust in app_init.dart
        AppInit.trackAppLifecycle(serviceManager, 'app_resumed');
        _checkSpinStatusOnResume();
        break;
      case AppLifecycleState.paused:
        AppInit.trackAppLifecycle(serviceManager, 'app_paused');
        _flushAnalyticsOnPause(); // Added safety inside this method below
        break;
      case AppLifecycleState.inactive:
        AppInit.trackAppLifecycle(serviceManager, 'app_inactive');
        break;
      case AppLifecycleState.detached:
        AppInit.trackAppLifecycle(serviceManager, 'app_detached');
        break;
      case AppLifecycleState.hidden:
        AppInit.trackAppLifecycle(serviceManager, 'app_hidden');
        break;
    }
  }

  /// Track initial app launch
  Future<void> _trackAppLaunch() async {
    try {
      final serviceManager = widget.initialData.$1;

      // 1. Track the launch (This is safe/silent if analytics aren't ready)
      await AppInit.trackAppLifecycle(serviceManager, 'app_launched');

      // 2. Show debug info
      if (!const bool.fromEnvironment('dart.vm.product')) {
        // Small delay to ensure Hive boxes are opened by the background loader
        await Future.delayed(const Duration(milliseconds: 500));

        final summary = await AppInit.getSpinAnalyticsSummary();

        // Use null-aware operators ?? 0 to prevent crashes if a key is missing
        debugPrint('╔════════════════════════════════════════════════╗');
        debugPrint('              SPIN ANALYTICS SUMMARY              ');
        debugPrint('╠════════════════════════════════════════════════╣');
        debugPrint(' Today:         ${summary['today_count'] ?? 0}/${summary['daily_limit'] ?? 0}');
        debugPrint(' Weekly:        ${summary['weekly_count'] ?? 0}');
        debugPrint(' Total:         ${summary['total_spins'] ?? 0}');
        debugPrint(' Can Spin:      ${summary['can_spin'] ?? false}');
        debugPrint(' Remaining:     ${summary['spins_remaining'] ?? 0}');
        debugPrint(' Reward Points: ${summary['reward_points'] ?? 0}');
        debugPrint('╚════════════════════════════════════════════════╝');
      }
    } catch (e) {
      debugPrint('[AppLauncher] Failed to track app launch: $e');
    }
  }

  /// Flush analytics when app pauses
  void _flushAnalyticsOnPause() {
    try {
      final serviceManager = widget.initialData.$1;
      serviceManager.analyticsService.flushEvents();
      debugPrint('[AppLauncher] Analytics flushed on app pause');
    } catch (e) {
      debugPrint('[AppLauncher] Failed to flush analytics: $e');
    }
  }

  /// Check spin status when app resumes
  Future<void> _checkSpinStatusOnResume() async {
    try {
      final summary = await AppInit.getSpinAnalyticsSummary();
      final serviceManager = widget.initialData.$1;

      await serviceManager.analyticsService.trackEvent('app_resumed_spin_check', {
        'spins_remaining': summary['spins_remaining'],
        'can_spin': summary['can_spin'],
        'reward_points': summary['reward_points'],
      });

      debugPrint('[AppLauncher] Spin status checked on resume: ${summary['spins_remaining']} spins remaining');
    } catch (e) {
      debugPrint('[AppLauncher] Failed to check spin status: $e');
    }
  }

  // ============ END LIFECYCLE TRACKING ============

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
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const AppLogo(size: 100, animate: true),
              const SizedBox(height: 32),
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Initializing app...'),
            ],
          ),
        ),
      );
    }

    // Get active theme with AsyncValue support
    final activeThemeAsync = ref.watch(activeThemeTypeProvider);

    return activeThemeAsync.when(
      data: (activeThemeType) => _buildApp(activeThemeType),
      loading: () => _buildApp(AppTheme.defaultTheme),
      error: (_, __) => _buildApp(AppTheme.defaultTheme),
    );
  }

  Widget _buildApp(ThemeType themeType) {
    final themeNotifier = ref.watch(providers.themeNotifierProvider);
    final appTheme = AppTheme.fromType(themeType, ThemeMode.light);

    return AppLifecycleObserver(
      child: MaterialApp.router(
        title: 'Trivia Tycoon',
        showPerformanceOverlay: false,
        debugShowCheckedModeBanner: false,
        scrollBehavior: AppScrollBehavior(),

        // Use active theme instead of hardcoded allStar
        theme: appTheme.themeData,
        darkTheme: AppTheme.fromType(themeType, ThemeMode.dark).themeData,
        themeMode: themeNotifier.themeMode,

        // Use the new provider-based router
        routerConfig: _router!,

        // PowerUpHUDOverlay now conditionally rendered
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
                  // Only render PowerUpHUDOverlay, let it handle visibility
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