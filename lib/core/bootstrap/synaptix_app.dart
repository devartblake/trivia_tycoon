import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_init.dart';
import 'app_launcher.dart';
import '../manager/log_manager.dart';
import '../manager/service_manager.dart';
import '../services/crash_recovery_service.dart';
import '../services/theme/theme_notifier.dart';
import '../../game/providers/riverpod_providers.dart'
    hide themeNotifierProvider;
import '../../widgets/app_logo.dart';
import '../../offline_fallback_screen.dart';
import '../../screens/splash_variants/main_splash.dart';
import '../../screens/widgets/custom_alert_dialog.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Root widget shared by all platform entry points (main.dart, main_mobile.dart,
/// main_web.dart). Manages the splash → crash-recovery → init → app sequence.
class SynaptixApp extends ConsumerStatefulWidget {
  final (ServiceManager, ThemeNotifier)? initialData;

  const SynaptixApp({super.key, this.initialData});

  @override
  ConsumerState<SynaptixApp> createState() => _SynaptixAppState();
}

class _SynaptixAppState extends ConsumerState<SynaptixApp> {
  (ServiceManager, ThemeNotifier)? _initialData;
  bool _initialized = false;
  bool _splashFinished = false;
  bool _recoveryChecked = false;
  bool _startupChecked = false;
  bool _forceUpdate = false;
  bool _backendUnreachable = false;
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loggedIn = ref.read(isLoggedInSyncProvider);
    if (loggedIn) ref.read(walletSyncProvider);
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
    _checkForCrashRecovery();
  }

  void _completeRecoveryPhase() {
    if (!mounted) return;

    if (!_recoveryChecked) {
      setState(() {
        _recoveryChecked = true;
      });
    }

    if (!_startupChecked) {
      _runStartupChecks();
    }
  }

  Future<void> _runStartupChecks() async {
    try {
      final apiClient = ref.read(serviceManagerProvider).synaptixApiClient;
      final isHealthy = await apiClient.healthCheck();
      if (!isHealthy) {
        if (mounted) {
          setState(() {
            _backendUnreachable = true;
            _startupChecked = true;
          });
        }
        return;
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _backendUnreachable = true;
          _startupChecked = true;
        });
      }
      return;
    }

    try {
      final config = await ref.read(appConfigProvider.future);
      if (config.minimumClientVersion != '0.0.0') {
        final info = await PackageInfo.fromPlatform();
        if (_isVersionBelow(info.version, config.minimumClientVersion)) {
          if (mounted) {
            setState(() {
              _forceUpdate = true;
              _startupChecked = true;
            });
          }
          return;
        }
      }
    } catch (_) {
      // Config unavailable — safe defaults, allow launch.
    }

    if (mounted) setState(() => _startupChecked = true);
  }

  bool _isVersionBelow(String current, String minimum) {
    final c = _parseSemver(current);
    final m = _parseSemver(minimum);
    for (var i = 0; i < 3; i++) {
      if (c[i] < m[i]) return true;
      if (c[i] > m[i]) return false;
    }
    return false;
  }

  List<int> _parseSemver(String v) {
    final parts = v.split('.').map((p) => int.tryParse(p) ?? 0).toList();
    while (parts.length < 3) {
      parts.add(0);
    }
    return parts;
  }

  Future<void> _checkForCrashRecovery() async {
    try {
      final persistenceService = AppInit.persistenceService;
      if (persistenceService == null) {
        _completeRecoveryPhase();
        return;
      }

      final hasData = await persistenceService.hasRecoverableData();

      if (hasData && mounted) {
        final summary = await persistenceService.getRecoverySummary();
        _showCrashRecoveryDialog(summary);
      } else {
        _completeRecoveryPhase();
      }
    } catch (e) {
      LogManager.error('[Recovery] Check failed: $e',
          source: '_SynaptixAppState');
      _completeRecoveryPhase();
    }
  }

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
            const Text('Welcome back to Synaptix'),
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
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.videogame_asset,
                            size: 16, color: Colors.blue),
                        SizedBox(width: 8),
                        Text(
                          'Recoverable Data:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 13),
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
              await AppInit.persistenceService?.clearAll();
              if (!context.mounted) return;
              _completeRecoveryPhase();
              Navigator.of(context).pop();
            },
            child: const Text('Start Fresh'),
          ),
          ElevatedButton(
            onPressed: () async {
              await _restoreCrashedSession(summary);
              if (!context.mounted) return;
              _completeRecoveryPhase();
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

  Future<void> _restoreCrashedSession(Map<String, dynamic> summary) async {
    try {
      final persistenceService = AppInit.persistenceService;
      if (persistenceService == null) return;

      final userSession = await persistenceService.getUserSession();

      LogManager.info('[Recovery] Restoring session...',
          source: '_SynaptixAppState');
      LogManager.debug(
          '[Recovery] User session: ${userSession != null ? 'YES' : 'NO'}',
          source: '_SynaptixAppState');

      final serviceManager = ref.read(serviceManagerProvider);
      final recoveryService = CrashRecoveryService(
        quizProgressService: serviceManager.quizProgressService,
        playerProfileService: serviceManager.playerProfileService,
      );
      final result = await recoveryService.restore(persistenceService);

      if (result.restoredAuthState) {
        ref.read(isLoggedInSyncProvider.notifier).state = true;
        ref.read(walletSyncProvider);
        LogManager.info('[Recovery] Auth state restored: logged in',
            source: '_SynaptixAppState');
      }

      if (result.pendingActionCount > 0) {
        LogManager.info(
          '[Recovery] ${result.pendingActionCount} pending action(s) queued for retry',
          source: '_SynaptixAppState',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Session restored successfully'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }

      LogManager.info('[Recovery] Session restored successfully',
          source: '_SynaptixAppState');
    } catch (e) {
      LogManager.error('[Recovery] Restore failed: $e',
          source: '_SynaptixAppState');

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

    if (!_splashFinished) {
      return SimpleSplashScreen(onDone: _onSplashFinished);
    }

    if (!_recoveryChecked) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLogo(size: 120, animate: true),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Color(0xFF6366F1)),
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

    if (!_startupChecked) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLogo(size: 120, animate: true),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Color(0xFF6366F1)),
              const SizedBox(height: 16),
              const Text(
                'Connecting to server...',
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    if (_backendUnreachable) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 64, color: Colors.grey),
              const SizedBox(height: 24),
              const Text(
                'Cannot reach the server',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please check your connection and try again.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _startupChecked = false;
                    _backendUnreachable = false;
                  });
                  _runStartupChecks();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_forceUpdate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showCustomAlertDialog(
          context: context,
          title: 'Update Required',
          message:
              'A new version of Synaptix is required to continue. Please update the app.',
          type: AlertType.warning,
          confirmText: 'Update Now',
          showCancelButton: false,
          onConfirm: () {},
        );
      });
    }

    if (!_initialized || _initialData == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7FA),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AppLogo(size: 120, animate: true),
              const SizedBox(height: 32),
              const CircularProgressIndicator(color: Color(0xFF6366F1)),
            ],
          ),
        ),
      );
    }

    return AppLauncher(initialData: _initialData!);
  }
}
