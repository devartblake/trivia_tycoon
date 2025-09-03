import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';

import '../settings/app_settings.dart';

typedef AppLifecycleStateNotifier = ValueNotifier<AppLifecycleState>;
typedef LifecycleCallback = void Function(AppLifecycleState state);

/// Riverpod stream controller for broadcasting lifecycle changes
final StreamController<AppLifecycleState> lifecycleStreamController = StreamController<AppLifecycleState>.broadcast();

/// Riverpod provider for lifecycle value
final appLifecycleProvider = Provider<AppLifecycleStateNotifier>((ref) {
  throw UnimplementedError('AppLifecycleObserver must be mounted before accessing the lifecycle provider.');
});

/// Broadcast controller for global access
final _lifecycleStreamController = StreamController<AppLifecycleState>.broadcast();

class AppLifecycleObserver extends StatefulWidget {
  final Widget child;
  final LifecycleCallback? onChanged;

  const AppLifecycleObserver({
    super.key,
    required this.child,
    this.onChanged,
  });

  @override
  State<AppLifecycleObserver> createState() => _AppLifecycleObserverState();
}

class _AppLifecycleObserverState extends State<AppLifecycleObserver> with WidgetsBindingObserver {
  static final _log = Logger('AppLifecycleObserver');
  final AppLifecycleStateNotifier _lifecycleNotifier = ValueNotifier<AppLifecycleState>(AppLifecycleState.inactive);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadLastLifecycleState();
    _lifecycleStreamController.close();
    _log.info('Subscribed to app lifecycle updates');
  }

  /// Load last state from HivePreferences
  Future<void> _loadLastLifecycleState() async {
    final lastState = await AppSettings.getString('last_lifecycle_state');
    if (lastState != null) {
      _log.info('Last saved lifecycle state: $lastState');
    }
  }

  /// Called on lifecycle change
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _log.info('App lLifecycle state changed to $state');
    _lifecycleNotifier.value = state;
    lifecycleStreamController.add(state);
    widget.onChanged?.call(state);
    AppSettings.setString('last_lifecycle_state', state.name);

    switch (state) {
      case AppLifecycleState.paused:
        _pauseGame();
        break;
      case AppLifecycleState.resumed:
        _resumeGame();
        break;
      case AppLifecycleState.inactive:
        _log.info('App became inactive');
        break;
      case AppLifecycleState.detached:
        _syncCloudData();
        break;
      case AppLifecycleState.hidden:  // Added for newer Flutter versions
        _log.info('App is hidden');
        break;
    }
  }

  void _pauseGame() {
    _log.info('Game paused - stopping audio, saving state');
    // Stop audio, save session, etc.
  }

  void _resumeGame() {
    _log.info('Game resumed - resuming timers/audio');
    // Resume audio, timers, etc.
  }

  void _syncCloudData() {
    _log.info('Detached - syncing cloud data...');
    // Backend sync, API push, etc.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lifecycleNotifier.dispose();
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
