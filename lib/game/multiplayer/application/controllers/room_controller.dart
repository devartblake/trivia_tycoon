import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/multiplayer/application/state/room_state.dart';
import 'package:trivia_tycoon/game/multiplayer/services/multiplayer_service.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_event.dart';

/// Manages lobby/room lifecycle: create, join, leave, and reacts to room-level events.
class RoomController extends StateNotifier<RoomState> {
  final MultiplayerService _svc;

  StreamSubscription<GameEvent>? _eventSub;

  RoomController(this._svc) : super(const RoomState.idle()) {
    _eventSub = _svc.events.listen(_onEvent, onError: (err, st) {
      state = RoomState(error: '$err');
    });
  }

  Future<void> createRoom(String name) async {
    state = const RoomState.loading();
    final ok = await _svc.createRoom(name);
    if (!ok) {
      state = const RoomState(error: 'Failed to create room');
      return;
    }
    // We expect a JoinedRoom event back; but in case the server is optimistic:
    // Set a temporary roomId or wait until the event arrives.
    // state = RoomState(roomId: 'pending'); // optional
  }

  Future<void> joinRoom(String roomId) async {
    state = const RoomState.loading();
    final ok = await _svc.joinRoom(roomId);
    if (!ok) {
      state = const RoomState(error: 'Failed to join room');
      return;
    }
    // JoinedRoom event should confirm the actual room and players.
  }

  Future<void> leaveRoom() async {
    // If you add a leaveRoom API in MultiplayerService, call it here.
    // For now, we just reset state.
    state = const RoomState.idle();
  }

  void _onEvent(GameEvent e) {
    if (e is JoinedRoom) {
      state = RoomState(roomId: e.roomId);
      return;
    }
    // You can expand with player joined/left, host changed, etc.
    // if (e is PlayerJoined) { ... }
    // if (e is PlayerLeft)   { ... }
  }

  @override
  void dispose() {
    _eventSub?.cancel();
    _eventSub = null;
    super.dispose();
  }
}
