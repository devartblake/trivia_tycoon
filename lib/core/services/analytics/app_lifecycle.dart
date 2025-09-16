import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../settings/app_settings.dart';
import '../../manager/service_manager.dart';
import '../../../game/providers/riverpod_providers.dart';

typedef AppLifecycleStateNotifier = ValueNotifier<AppLifecycleState>;
typedef LifecycleCallback = void Function(AppLifecycleState state);

/// Riverpod stream controller for broadcasting lifecycle changes
final StreamController<AppLifecycleState> lifecycleStreamController = StreamController<AppLifecycleState>.broadcast();

/// Riverpod provider for lifecycle value
final appLifecycleProvider = Provider<AppLifecycleStateNotifier>((ref) {
  throw UnimplementedError('AppLifecycleObserver must be mounted before accessing the lifecycle provider.');
});

/// Stream provider for lifecycle changes
final lifecycleStreamProvider = StreamProvider<AppLifecycleState>((ref) {
  return lifecycleStreamController.stream;
});

/// Broadcast controller for global access
final _lifecycleStreamController = StreamController<AppLifecycleState>.broadcast();

class AppLifecycleObserver extends ConsumerStatefulWidget {
  final Widget child;
  final LifecycleCallback? onChanged;

  const AppLifecycleObserver({
    super.key,
    required this.child,
    this.onChanged,
  });

  @override
  ConsumerState<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends ConsumerState<AppLifecycleObserver> with WidgetsBindingObserver {
  static final _log = Logger('AppLifecycleObserver');
  final AppLifecycleStateNotifier _lifecycleNotifier = ValueNotifier<AppLifecycleState>(AppLifecycleState.inactive);

  Timer? _backgroundTimer;
  DateTime? _pausedAt;
  bool _isPaused = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLastLifecycleState();
    _log.info('Subscribed to app lifecycle updates');
  }

  /// Load last state from AppSettings
  Future<void> _loadLastLifecycleState() async {
    try {
      final lastState = await AppSettings.getString('last_lifecycle_state');
      final lastPausedTime = await AppSettings.getString('last_paused_time');

      if (lastState != null) {
        _log.info('Last saved lifecycle state: $lastState');
      }

      if (lastPausedTime != null) {
        _pausedAt = DateTime.tryParse(lastPausedTime);
        if (_pausedAt != null) {
          final timePaused = DateTime.now().difference(_pausedAt!);
          _log.info('App was paused for: ${timePaused.inMinutes} minutes');

          // If app was paused for more than 30 minutes, trigger data refresh
          if (timePaused.inMinutes > 30) {
            _triggerDataRefresh();
          }
        }
      }
    } catch (e) {
      _log.warning('Failed to load last lifecycle state: $e');
    }
  }

  /// Called on lifecycle change
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log.info('App lifecycle state changed to $state');
    _lifecycleNotifier.value = state;
    lifecycleStreamController.add(state);
    widget.onChanged?.call(state);

    // Save state persistently
    AppSettings.setString('last_lifecycle_state', state.name);

    switch (state) {
      case AppLifecycleState.paused:
        _pauseGame();
        break;
      case AppLifecycleState.resumed:
        _resumeGame();
        break;
      case AppLifecycleState.inactive:
        _handleInactive();
        break;
      case AppLifecycleState.detached:
        _syncCloudData();
        break;
      case AppLifecycleState.hidden:
        _handleHidden();
        break;
    }
  }

  /// Pause game functionality
  void _pauseGame() {
    if (_isPaused) return;

    _log.info('Game paused - stopping audio, saving state');
    _isPaused = true;
    _pausedAt = DateTime.now();

    try {
      final serviceManager = ref.read(serviceManagerProvider);

      // Save pause timestamp
      AppSettings.setString('last_paused_time', _pausedAt!.toIso8601String());

      // Pause audio/music
      final audioService = serviceManager.audioSettingsService;
      audioService.pauseAllAudio();

      // Save current game state
      _saveGameState();

      // Stop any running timers or animations
      _pauseTimers();

      // Save analytics event
      serviceManager.analyticsService.trackEvent('app_paused', {
        'timestamp': _pausedAt!.toIso8601String(),
        'duration_since_last_resume': _getTimeSinceLastResume(),
      });

      _log.info('Game successfully paused');
    } catch (e) {
      _log.severe('Error pausing game: $e');
    }
  }

  /// Resume game functionality
  void _resumeGame() {
    if (!_isPaused) return;

    _log.info('Game resumed - resuming timers/audio');

    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final resumedAt = DateTime.now();

      // Calculate pause duration
      Duration? pauseDuration;
      if (_pausedAt != null) {
        pauseDuration = resumedAt.difference(_pausedAt!);
        _log.info('App was paused for: ${pauseDuration.inMinutes} minutes');
      }

      // Resume audio if it was playing before
      final audioService = serviceManager.audioSettingsService;
      audioService.resumeAudio();

      // Resume timers and animations
      _resumeTimers();

      // Check if we need to refresh data (if paused for a long time)
      if (pauseDuration != null && pauseDuration.inMinutes > 15) {
        _triggerDataRefresh();
      }

      // Update coin/currency if there are time-based rewards
      _updateTimeBasedRewards(pauseDuration);

      // Clear pause state
      _isPaused = false;
      _pausedAt = null;
      AppSettings.setString('last_paused_time', '');

      // Save analytics event
      serviceManager.analyticsService.trackEvent('app_resumed', {
        'timestamp': resumedAt.toIso8601String(),
        'pause_duration_minutes': pauseDuration?.inMinutes ?? 0,
      });

      _log.info('Game successfully resumed');
    } catch (e) {
      _log.severe('Error resuming game: $e');
    }
  }

  /// Sync cloud data when app is detached
  void _syncCloudData() {
    _log.info('App detached - syncing cloud data...');

    try {
      final serviceManager = ref.read(serviceManagerProvider);

      // Save all critical data before app closes
      _saveAllGameData();

      // Push analytics events
      serviceManager.analyticsService.flushEvents();

      // Sync leaderboard data
      _syncLeaderboardData();

      // Save user progress
      _syncUserProgress();

      // Clean up temporary data
      _cleanupTempData();

      _log.info('Cloud sync completed successfully');
    } catch (e) {
      _log.severe('Error syncing cloud data: $e');
    }
  }

  /// Handle inactive state
  void _handleInactive() {
    _log.info('App became inactive');

    try {
      // Reduce performance-intensive operations
      _reduceBackgroundActivity();

      // Save current state as a precaution
      _saveGameState();

    } catch (e) {
      _log.warning('Error handling inactive state: $e');
    }
  }

  /// Handle hidden state (newer Flutter versions)
  void _handleHidden() {
    _log.info('App is hidden');

    try {
      // Similar to inactive but more aggressive resource reduction
      _reduceBackgroundActivity();
      _pauseNonCriticalServices();

    } catch (e) {
      _log.warning('Error handling hidden state: $e');
    }
  }

  /// Save current game state
  void _saveGameState() {
    try {
      final serviceManager = ref.read(serviceManagerProvider);

      // Save quiz progress
      serviceManager.quizProgressService.saveCurrentProgress();

      // Save user profile changes
      serviceManager.playerProfileService.saveCurrentSession();

      // Save purchase state
      serviceManager.purchaseSettingsService.saveState();

      // Save theme settings
      serviceManager.themeSettingsService.saveCurrentTheme();

      _log.info('Game state saved successfully');
    } catch (e) {
      _log.severe('Error saving game state: $e');
    }
  }

  /// Save all critical game data
  void _saveAllGameData() {
    try {
      _saveGameState();

      final serviceManager = ref.read(serviceManagerProvider);

      // Save additional critical data
      serviceManager.rewardSettingsService.saveRewardState();
      serviceManager.achievementService.saveAchievementData();

      // Ensure all Hive boxes are properly closed/synced
      _flushAllStorage();

    } catch (e) {
      _log.severe('Error saving all game data: $e');
    }
  }

  /// Pause all timers and animations
  void _pauseTimers() {
    try {
      // Cancel background timer if running
      _backgroundTimer?.cancel();

      // Pause confetti animations
      final confettiController = ref.read(confettiControllerProvider);
      confettiController.pause();

      // Pause spin wheel animations
      final spinController = ref.read(spinningControllerProvider);
      spinController.pause();

    } catch (e) {
      _log.warning('Error pausing timers: $e');
    }
  }

  /// Resume timers and animations
  void _resumeTimers() {
    try {
      // Resume confetti animations
      final confettiController = ref.read(confettiControllerProvider);
      confettiController.resume();

      // Resume spin wheel animations
      final spinController = ref.read(spinningControllerProvider);
      spinController.resume();

      // Restart background timer if needed
      _startBackgroundTimer();

    } catch (e) {
      _log.warning('Error resuming timers: $e');
    }
  }

  /// Trigger data refresh after long pause
  void _triggerDataRefresh() {
    try {
      final serviceManager = ref.read(serviceManagerProvider);

      // Refresh leaderboard data
      serviceManager.leaderboardDataService.refreshData();

      // Refresh store items
      serviceManager.storeService.refreshStoreData();

      // Check for new achievements
      serviceManager.achievementService.checkForNewAchievements();

      _log.info('Data refresh triggered');
    } catch (e) {
      _log.warning('Error triggering data refresh: $e');
    }
  }

  /// Update time-based rewards
  void _updateTimeBasedRewards(Duration? pauseDuration) {
    if (pauseDuration == null) return;

    try {
      // Calculate offline rewards (coins, etc.)
      final offlineMinutes = pauseDuration.inMinutes;
      if (offlineMinutes > 5) { // Only give rewards if away for 5+ minutes
        final coinReward = (offlineMinutes / 10).floor(); // 1 coin per 10 minutes

        if (coinReward > 0) {
          final coinNotifier = ref.read(coinNotifierProvider);
          coinNotifier.addCoins(coinReward);

          _log.info('Awarded $coinReward offline coins for $offlineMinutes minutes away');
        }
      }
    } catch (e) {
      _log.warning('Error updating time-based rewards: $e');
    }
  }

  /// Sync leaderboard data
  void _syncLeaderboardData() {
    try {
      final leaderboardController = ref.read(leaderboardControllerProvider);
      leaderboardController.loadLeaderboard();
    } catch (e) {
      _log.warning('Error syncing leaderboard: $e');
    }
  }

  /// Sync user progress
  void _syncUserProgress() {
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      serviceManager.quizProgressService.syncProgress();
    } catch (e) {
      _log.warning('Error syncing user progress: $e');
    }
  }

  /// Clean up temporary data
  void _cleanupTempData() {
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      serviceManager.appCacheService.clearTemporaryData();
    } catch (e) {
      _log.warning('Error cleaning temp data: $e');
    }
  }

  /// Reduce background activity for performance
  void _reduceBackgroundActivity() {
    try {
      // Reduce animation frame rates
      // Pause non-critical background processes
      _backgroundTimer?.cancel();
    } catch (e) {
      _log.warning('Error reducing background activity: $e');
    }
  }

  /// Pause non-critical services
  void _pauseNonCriticalServices() {
    try {
      // Pause analytics collection
      final serviceManager = ref.read(serviceManagerProvider);
      serviceManager.analyticsService.pauseCollection();
    } catch (e) {
      _log.warning('Error pausing non-critical services: $e');
    }
  }

  /// Start background timer for periodic tasks
  void _startBackgroundTimer() {
    _backgroundTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      try {
        // Periodic background tasks
        _performBackgroundMaintenance();
      } catch (e) {
        _log.warning('Error in background timer: $e');
      }
    });
  }

  /// Perform background maintenance tasks
  void _performBackgroundMaintenance() {
    try {
      final serviceManager = ref.read(serviceManagerProvider);

      // Flush pending analytics
      serviceManager.analyticsService.flushPendingEvents();

      // Clean old cache entries
      serviceManager.appCacheService.cleanOldEntries();

      // Auto-save progress
      serviceManager.quizProgressService.autoSave();

    } catch (e) {
      _log.warning('Error in background maintenance: $e');
    }
  }

  /// Flush all storage systems
  void _flushAllStorage() {
    try {
      // Flush Hive boxes
      // This ensures all data is written to disk
      // Implementation depends on your Hive setup
    } catch (e) {
      _log.warning('Error flushing storage: $e');
    }
  }

  /// Get time since last resume for analytics
  String _getTimeSinceLastResume() {
    try {
      // This would track when the app was last resumed
      // Implementation depends on your analytics needs
      return 'unknown';
    } catch (e) {
      return 'error';
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleNotifier.dispose();
    _backgroundTimer?.cancel();
    lifecycleStreamController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        appLifecycleProvider.overrideWithValue(_lifecycleNotifier),
      ],
      child: widget.child,
    );
  }
}
