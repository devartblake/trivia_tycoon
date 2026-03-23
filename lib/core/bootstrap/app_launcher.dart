import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'package:trivia_tycoon/core/services/analytics/app_lifecycle.dart';
import 'package:trivia_tycoon/core/manager/service_manager.dart';
import 'package:trivia_tycoon/core/services/theme/theme_notifier.dart';
import 'package:trivia_tycoon/core/services/user_identity_resolver.dart';
import 'package:trivia_tycoon/game/analytics/models/spin_live_summary.dart';
import 'package:trivia_tycoon/game/analytics/providers/analytics_providers.dart';
import 'package:trivia_tycoon/game/providers/multi_profile_providers.dart';
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
  ProviderSubscription<AsyncValue<SpinLiveSummary>>? _spinSummarySubscription;
  String? _lastSpinSummaryDedupeKey;
  bool _printedInitialLocalSummary = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeAuthState();
    _initRouter();
    _trackAppLaunch();
    _listenToLiveSpinSummary();
    _retryQueuedProfileSyncUpdates();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    // Cleanup on dispose
    _spinSummarySubscription?.close();
    AppInit.dispose();

    super.dispose();
  }

  void _listenToLiveSpinSummary() {
    _spinSummarySubscription = ref.listenManual<AsyncValue<SpinLiveSummary>>(
      spinLiveSummaryProvider,
      (previous, next) {
        next.whenData((summary) {
          if (_lastSpinSummaryDedupeKey == summary.dedupeKey) return;
          _lastSpinSummaryDedupeKey = summary.dedupeKey;

          final isWebSocketSummary = summary.source.startsWith('websocket:');
          if (isWebSocketSummary || !_printedInitialLocalSummary) {
            _printSpinAnalyticsSummary(summary.toMap());
            if (!isWebSocketSummary) {
              _printedInitialLocalSummary = true;
            }
          }

          if (summary.source.startsWith('websocket:')) {
            _trackLiveSpinSummary(summary);
          }
        });
      },
    );
  }

  Future<void> _trackLiveSpinSummary(SpinLiveSummary summary) async {
    try {
      final serviceManager = widget.initialData.$1;
      await serviceManager.analyticsService.trackEvent('spin_summary_live_update', {
        ...summary.toMap(),
      });
    } catch (e) {
      LogManager.error('Failed to track live spin summary update', source: 'AppLauncher', error: e);
    }
  }

  Future<String> _resolveUserId() async {
    final serviceManager = widget.initialData.$1;
    return UserIdentityResolver.resolveUserId(serviceManager);
  }

  void _printSpinAnalyticsSummary(Map<String, dynamic> summary) {
    LogManager.info('╔════════════════════════════════════════════════╗', source: 'AppLauncher');
    LogManager.info('              SPIN ANALYTICS SUMMARY              ', source: 'AppLauncher');
    LogManager.info('╠════════════════════════════════════════════════╣', source: 'AppLauncher');
    LogManager.info(' User Name:     ${summary['user_name'] ?? 'Unknown'}', source: 'AppLauncher');
    LogManager.info(' User ID:       ${summary['user_id'] ?? 'unknown'}', source: 'AppLauncher');
    LogManager.info(' Snapshot At:   ${summary['snapshot_at'] ?? DateTime.now().toIso8601String()}', source: 'AppLauncher');
    LogManager.info(' Today:         ${summary['today_count'] ?? 0}/${summary['daily_limit'] ?? 0}', source: 'AppLauncher');
    LogManager.info(' Weekly:        ${summary['weekly_count'] ?? 0}', source: 'AppLauncher');
    LogManager.info(' Total:         ${summary['total_spins'] ?? 0}', source: 'AppLauncher');
    LogManager.info(' Can Spin:      ${summary['can_spin'] ?? false}', source: 'AppLauncher');
    LogManager.info(' Remaining:     ${summary['spins_remaining'] ?? 0}', source: 'AppLauncher');
    LogManager.info(' Reward Points: ${summary['reward_points'] ?? 0}', source: 'AppLauncher');
    LogManager.info(' Source:        ${summary['source'] ?? 'unknown'}', source: 'AppLauncher');
    LogManager.info('╚════════════════════════════════════════════════╝', source: 'AppLauncher');
  }

  // ============ LIFECYCLE TRACKING ============

  Future<void> _retryQueuedProfileSyncUpdates() async {
    try {
      final multiProfileService = ref.read(multiProfileServiceProvider);
      await multiProfileService.retryQueuedProfileSyncUpdates();
    } catch (e) {
      LogManager.error('Failed retrying queued profile sync updates', source: 'AppLauncher', error: e);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Use the existing initialData pattern to avoid breaking changes
    final serviceManager = widget.initialData.$1;

    switch (state) {
      case AppLifecycleState.resumed:
      // This is now safe because we made trackAppLifecycle robust in app_init.dart
        AppInit.trackAppLifecycle(serviceManager, 'app_resumed');
        _checkSpinStatusOnResume();
        _retryQueuedProfileSyncUpdates();

        // Reconnect WebSocket
        AppInit.reconnectWebSocket();
        break;

      case AppLifecycleState.paused:
        AppInit.trackAppLifecycle(serviceManager, 'app_paused');
        _flushAnalyticsOnPause(); // Added safety inside this method below

        // Disconnect WebSocket to save battery
        AppInit.disconnectWebSocket();

        // NOTE: AppLifecycleManager handles the save automatically
        // No need to call forceSave() here - it's triggered by the manager

        break;

      case AppLifecycleState.inactive:
        AppInit.trackAppLifecycle(serviceManager, 'app_inactive');

        // ✅ NOTE: AppLifecycleManager handles quick save automatically

        break;

      case AppLifecycleState.detached:
        AppInit.trackAppLifecycle(serviceManager, 'app_detached');

        // Cleanup on app close
        AppInit.disconnectWebSocket();

        // ✅ NOTE: AppLifecycleManager handles final save + cleanup automatically

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

        final enrichedSummary = {
          ...summary,
          'user_name': await UserIdentityResolver.resolveUserName(serviceManager),
          'user_id': await _resolveUserId(),
          'snapshot_at': DateTime.now().toIso8601String(),
          'source': 'app_launch',
        };

        _printSpinAnalyticsSummary(enrichedSummary);
      }
    } catch (e) {
      LogManager.error('Failed to track app launch', source: 'AppLauncher', error: e);
    }
  }

  /// Flush analytics when app pauses
  void _flushAnalyticsOnPause() {
    try {
      final serviceManager = widget.initialData.$1;
      serviceManager.analyticsService.flushEvents();
      LogManager.info('Analytics flushed on app pause', source: 'AppLauncher');
    } catch (e) {
      LogManager.error('Failed to flush analytics', source: 'AppLauncher', error: e);
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
        'user_name': await UserIdentityResolver.resolveUserName(serviceManager),
        'user_id': await _resolveUserId(),
        'snapshot_at': DateTime.now().toIso8601String(),
      });

      LogManager.info('Spin status checked on resume: ${summary['spins_remaining']} spins remaining', source: 'AppLauncher');
    } catch (e) {
      LogManager.error('Failed to check spin status', source: 'AppLauncher', error: e);
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
        await ref.read(onboardingProgressProvider.notifier).markOnboardingCompleted(true);
      }

      setState(() {
        _authStateInitialized = true;
      });

      LogManager.info('Auth state initialized: isLoggedIn=$isLoggedIn, hasOnboarded=$hasOnboarded', source: 'AppLauncher');
    } catch (e) {
      LogManager.error('Error initializing auth state', source: 'AppLauncher', error: e);
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
