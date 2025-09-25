import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/multiplayer/application/state/multiplayer_state.dart';
import 'package:trivia_tycoon/game/multiplayer/services/multiplayer_service.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_event.dart';

/// Handles connection lifecycle (connect / disconnect), basic presence,
/// and high-level errors. It also exposes latency updates if available.
class MultiplayerController extends StateNotifier<MultiplayerState> {
  final MultiplayerService _svc;

  StreamSubscription<GameEvent>? _eventSub;
  Timer? _latencyTimer;

  MultiplayerController(this._svc) : super(const MultiplayerState.disconnected());

  /// Connect to the multiplayer backend using an auth token.
  Future<void> connect({required String token}) async {
    if ((state.connected && state.error == null)) {
      // proceed
    }
    state = const MultiplayerState.connecting();

    final ok = await _svc.connect(token: token);
    if (!ok) {
      state = const MultiplayerState.error('Failed to connect');
      _teardownListeners();
      return;
    }

    // Start listening to events (even if this controller only tracks connectivity,
    // it’s useful to observe fatal errors or kicks).
    _eventSub?.cancel();
    _eventSub = _svc.events.listen(_onEvent, onError: (err, st) {
      state = MultiplayerState.error('$err');
    });

    // Optionally poll latency (if service updates RTT internally)
    _latencyTimer?.cancel();
    _latencyTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      if (state.connected) {
        state = MultiplayerState.connected(latencyMs: _svc.lastLatencyMs);
      }
    });

    state = MultiplayerState.connected(latencyMs: _svc.lastLatencyMs);
  }

  /// Disconnect and clear listeners.
  Future<void> disconnect() async {
    await _svc.disconnect();
    _teardownListeners();
    state = const MultiplayerState.disconnected();
  }

  void _onEvent(GameEvent e) {
    // Keep this minimal: only react to global/fatal events here.
    // Room/match-specific events are handled in their own controllers.
    // If your backend emits a "kicked" or "serverClosing" event, you can map it here.
    // Example:
    // if (e is ServerClosing) {
    //   state = const MultiplayerState.error('Server is restarting');
    // }
  }

  void _teardownListeners() {
    _eventSub?.cancel();
    _eventSub = null;
    _latencyTimer?.cancel();
    _latencyTimer = null;
  }

  @override
  void dispose() {
    _teardownListeners();
    super.dispose();
  }
}
