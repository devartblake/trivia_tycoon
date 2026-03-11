import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/bootstrap/app_init.dart';
import 'package:trivia_tycoon/core/bootstrap/app_launcher.dart';
import '/offline_fallback_screen.dart';
import 'package:trivia_tycoon/screens/splash_variants/main_splash.dart';
import 'package:trivia_tycoon/widgets/app_logo.dart';
import 'core/env.dart';
import 'core/manager/service_manager.dart';
import 'core/services/theme/theme_notifier.dart';
import 'game/providers/auth_providers.dart';
import 'game/providers/onboarding_providers.dart';
import 'game/providers/riverpod_providers.dart' hide themeNotifierProvider;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables before doing anything else
  await EnvConfig.load();

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
      await container.read(onboardingProgressProvider.notifier).markOnboardingCompleted(true);
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
  bool _recoveryChecked = false; // Track recovery check
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

    // Check for crash recovery after splash
    _checkForCrashRecovery();
  }

  // Check for crash recovery data
  Future<void> _checkForCrashRecovery() async {
    try {
      final persistenceService = AppInit.persistenceService;
      if (persistenceService == null) {
        setState(() => _recoveryChecked = true);
        return;
      }

      // Check if we have recoverable data
      final hasData = await persistenceService.hasRecoverableData();

      if (hasData && mounted) {
        // Get recovery summary
        final summary = await persistenceService.getRecoverySummary();

        // Show recovery dialog
        _showCrashRecoveryDialog(summary);
      } else {
        setState(() => _recoveryChecked = true);
      }
    } catch (e) {
      debugPrint('[Recovery] Check failed: $e');
      setState(() => _recoveryChecked = true);
    }
  }

  // Show crash recovery dialog
  void _showCrashRecoveryDialog(Map<String, dynamic> summary) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.info_outline, color: Theme.of(context).primaryColor),
            const SizedBox(width: 12),
            const Text('Welcome Back!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'We detected that the app closed unexpectedly. '
                  'Would you like to restore your previous session?',
              style: TextStyle(fontSize: 15),
            ),
            if (summary['has_game_state'] == true) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.videogame_asset, size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Recoverable Data:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Game progress saved',
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                    if (summary['pending_actions_count'] > 0)
                      Text(
                        '• ${summary['pending_actions_count']} pending actions',
                        style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                      ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              // Clear recovery data and start fresh
              await AppInit.persistenceService?.clearAll();
              setState(() => _recoveryChecked = true);
              Navigator.of(context).pop();
            },
            child: const Text('Start Fresh'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Restore data
              await _restoreCrashedSession(summary);
              setState(() => _recoveryChecked = true);
              Navigator.of(context).pop();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  // Restore crashed session
  Future<void> _restoreCrashedSession(Map<String, dynamic> summary) async {
    try {
      final persistenceService = AppInit.persistenceService;
      if (persistenceService == null) return;

      // Get saved states
      final gameState = await persistenceService.getGameState();
      final userSession = await persistenceService.getUserSession();
      final pendingActions = await persistenceService.getPendingActions();

      debugPrint('[Recovery] Restoring session...');
      debugPrint('[Recovery] Game state: ${gameState != null ? 'YES' : 'NO'}');
      debugPrint('[Recovery] User session: ${userSession != null ? 'YES' : 'NO'}');
      debugPrint('[Recovery] Pending actions: ${pendingActions.length}');

      // TODO: Actually restore the data to your app state
      // Example:
      // if (gameState != null) {
      //   ref.read(quizStateProvider.notifier).restore(gameState);
      // }
      // if (pendingActions.isNotEmpty) {
      //   ref.read(pendingActionsProvider.notifier).addAll(pendingActions);
      // }

      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Session restored successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      debugPrint('[Recovery] ✅ Session restored successfully');
    } catch (e) {
      debugPrint('[Recovery] ❌ Restore failed: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('⚠️ Could not restore session'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
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

    // Show splash screen first
    if (!_splashFinished) {
      return SimpleSplashScreen(
        onDone: _onSplashFinished,
      );
    }

    // Wait for recovery check to complete
    if (!_recoveryChecked) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLogo(size: 120, animate: true),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
              const SizedBox(height: 16),
              const Text(
                'Checking for saved progress...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    // Show loading while initializing
    if (!_initialized || _initialData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLogo(size: 120, animate: true),
              const SizedBox(height: 32),
              const CircularProgressIndicator(
                color: Color(0xFF6366F1),
              ),
            ],
          ),
        ),
      );
    }

    // Finally show the app
    return AppLauncher(initialData: _initialData!);
  }
}
