import 'package:trivia_tycoon/game/multiplayer/domain/entities/player_presence.dart';

/// Room/lobby state observed by the lobby UI and room controller.
///
/// Keep this small and serializable; complex data (e.g., permissions) can live
/// on the entity models (Room/PlayerPresence) when needed.
class RoomState {
  /// The current room identifier if joined; null when idle.
  final String? roomId;

  /// Human-readable room name (optional).
  final String? roomName;

  /// Current players visible in the room (order may match server ordering).
  final List<PlayerPresence> players;

  /// True while creating/joining/syncing room info.
  final bool loading;

  /// Non-null if a user-facing error should be shown.
  final String? error;

  /// Whether the local player is the host (authoritative controls).
  final bool isHost;

  const RoomState({
    this.roomId,
    this.roomName,
    this.players = const [],
    this.loading = false,
    this.error,
    this.isHost = false,
  });

  const RoomState.idle()
      : roomId = null,
        roomName = null,
        players = const [],
        loading = false,
        error = null,
        isHost = false;

  const RoomState.loading()
      : roomId = null,
        roomName = null,
        players = const [],
        loading = true,
        error = null,
        isHost = false;

  RoomState copyWith({
    String? roomId,
    String? roomName,
    List<PlayerPresence>? players,
    bool? loading,
    String? error,     // pass explicit null to clear
    bool clearError = false,
    bool? isHost,
  }) {
    return RoomState(
      roomId: roomId ?? this.roomId,
      roomName: roomName ?? this.roomName,
      players: players ?? this.players,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  String toString() => 'RoomState(roomId: $roomId, roomName: $roomName, '
      'players: ${players.length}, loading: $loading, isHost: $isHost, error: $error)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is RoomState &&
              runtimeType == other.runtimeType &&
              roomId == other.roomId &&
              roomName == other.roomName &&
              _listEq(players, other.players) &&
              loading == other.loading &&
              error == other.error &&
              isHost == other.isHost;

  @override
  int get hashCode =>
      Object.hash(roomId, roomName, Object.hashAll(players), loading, error, isHost);
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
