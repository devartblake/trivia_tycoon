import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:synaptix/core/manager/log_manager.dart';

/// Manages app lifecycle events and graceful shutdown
///
/// Handles:
/// - Normal app closure (user exits)
/// - App crashes (uncaught errors)
/// - Background/foreground transitions
/// - Auto-save during gameplay
/// - State restoration on restart
class AppLifecycleManager with WidgetsBindingObserver {
  final void Function()? onAppPaused;
  final void Function()? onAppResumed;
  final void Function()? onAppDetached;
  final void Function()? onAppInactive;
  final Future<void> Function()? onSaveState;
  final Future<void> Function()? onClearTempData;

  bool _isInitialized = false;
  DateTime? _lastSaveTime;
  Timer? _autoSaveTimer;

  // Debug flag: set to true to see lifecycle logs
  static const bool _debugLifecycleLogging = false;

  // Minimum time between auto-saves (prevent too frequent saves)
  static const Duration _minSaveInterval = Duration(seconds: 30);

  AppLifecycleManager({
    this.onAppPaused,
    this.onAppResumed,
    this.onAppDetached,
    this.onAppInactive,
    this.onSaveState,
    this.onClearTempData,
  });

  /// Log debug message if debugging is enabled
  void _logDebug(String message) {
    if (_debugLifecycleLogging && kDebugMode) {
      LogManager.debug(message);
    }
  }

  /// Initialize lifecycle management
  void initialize() {
    if (_isInitialized) return;

    WidgetsBinding.instance.addObserver(this);
    _setupCrashHandling();
    _startAutoSave();
    _isInitialized = true;

    _logDebug('[Lifecycle] Initialized - graceful shutdown enabled');
  }

  /// Dispose and cleanup
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _autoSaveTimer?.cancel();
    _isInitialized = false;

    _logDebug('[Lifecycle] Disposed');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _logDebug('[Lifecycle] State changed: $state');

    switch (state) {
      case AppLifecycleState.resumed:
        _handleAppResumed();
        break;

      case AppLifecycleState.inactive:
        _handleAppInactive();
        break;

      case AppLifecycleState.paused:
        _handleAppPaused();
        break;

      case AppLifecycleState.detached:
        _handleAppDetached();
        break;

      case AppLifecycleState.hidden:
        _handleAppHidden();
        break;
    }
  }

  /// App resumed (came back to foreground)
  void _handleAppResumed() async {
    _logDebug('[Lifecycle] App RESUMED - User returned');
    onAppResumed?.call();

    // Restart auto-save if it was stopped
    if (_autoSaveTimer?.isActive != true) {
      _startAutoSave();
    }
  }

  /// App inactive (transitioning, overlays, etc.)
  void _handleAppInactive() async {
    _logDebug('[Lifecycle] App INACTIVE - Quick save triggered');
    onAppInactive?.call();

    // Quick save on inactive (user might be closing app)
    await _performSave(reason: 'inactive');
  }

  /// App paused (went to background)
  void _handleAppPaused() async {
    _logDebug('[Lifecycle] App PAUSED - Saving state...');
    onAppPaused?.call();

    // Save everything when app goes to background
    await _performSave(reason: 'paused');

    // Stop auto-save timer to conserve resources
    _autoSaveTimer?.cancel();
  }

  /// App detached (app closing)
  void _handleAppDetached() async {
    LogManager.debug(
        '[Lifecycle] App DETACHED - Final save before shutdown...');
    onAppDetached?.call();

    // Final save before app closes
    await _performSave(reason: 'detached');

    // Clear temporary data
    await _clearTemporaryData();

    _logDebug('[Lifecycle] Graceful shutdown complete');
  }

  /// App hidden (another app in foreground)
  void _handleAppHidden() async {
    _logDebug('[Lifecycle] App HIDDEN - Quick save');
    await _performSave(reason: 'hidden');
  }

  /// Setup crash/error handling
  void _setupCrashHandling() {
    // Catch Flutter framework errors
    FlutterError.onError = (FlutterErrorDetails details) async {
      LogManager.debug(
          '[Lifecycle] Flutter Error Caught: ${details.exception}');

      // Save state before crash
      await _performSave(reason: 'crash');

      // Log the error (in production, send to analytics)
      _logCrash(details.exception, details.stack);

      // Show error in debug mode
      FlutterError.presentError(details);
    };

    // Catch async errors outside Flutter
    PlatformDispatcher.instance.onError = (error, stack) {
      _logDebug('[Lifecycle] Async Error Caught: $error');

      // Save state before crash
      _performSave(reason: 'async_crash');

      // Log the error
      _logCrash(error, stack);

      return true; // Handled
    };
  }

  /// Perform save with throttling
  Future<void> _performSave({required String reason}) async {
    // Throttle saves to prevent too frequent disk writes
    final now = DateTime.now();
    if (_lastSaveTime != null) {
      final timeSinceLastSave = now.difference(_lastSaveTime!);
      if (timeSinceLastSave < _minSaveInterval) {
        LogManager.debug(
            '[Lifecycle] Save throttled (too soon since last save)');
        return;
      }
    }

    // Stamp before the async save so the next periodic tick measures
    // from save-start, aligning with the 30s timer interval.
    _lastSaveTime = now;

    try {
      _logDebug('[Lifecycle] Saving state (reason: $reason)...');
      final startTime = DateTime.now();

      await onSaveState?.call();

      final duration = DateTime.now().difference(startTime);
      LogManager.debug(
          '[Lifecycle] Save complete in ${duration.inMilliseconds}ms');
    } catch (e, stack) {
      _lastSaveTime = null; // Allow immediate retry after a failed save
      _logDebug('[Lifecycle] Save failed: $e');
      _logDebug('[Lifecycle] Stack: $stack');
    }
  }

  /// Start auto-save timer (saves periodically during gameplay)
  void _startAutoSave() {
    _autoSaveTimer?.cancel();

    // Auto-save every 30 seconds during active gameplay
    _autoSaveTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _logDebug('[Lifecycle] Auto-save triggered');
      _performSave(reason: 'auto');
    });

    _logDebug('[Lifecycle] Auto-save started (every 30s)');
  }

  /// Clear temporary data on shutdown
  Future<void> _clearTemporaryData() async {
    try {
      _logDebug('[Lifecycle] Clearing temporary data...');
      await onClearTempData?.call();
      _logDebug('[Lifecycle] Temporary data cleared');
    } catch (e) {
      _logDebug('[Lifecycle] Failed to clear temp data: $e');
    }
  }

  /// Log crash for analytics/debugging
  void _logCrash(Object error, StackTrace? stack) {
    // In production, send to Firebase Crashlytics, Sentry, etc.
    _logDebug('[Lifecycle] CRASH LOGGED:');
    LogManager.debug('  Error: $error');
    LogManager.debug('  Stack: $stack');

    LogManager.error(
      '[Lifecycle] Crash recorded',
      source: 'AppLifecycleManager',
      error: error,
      stackTrace: stack,
    );
  }

  /// Force save (call this before critical operations)
  Future<void> forceSave() async {
    _logDebug('[Lifecycle] Force save requested');
    _lastSaveTime = null; // Reset throttle
    await _performSave(reason: 'manual');
  }

  /// Check if auto-save is active
  bool get isAutoSaveActive => _autoSaveTimer?.isActive ?? false;
}
