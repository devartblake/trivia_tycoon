import 'package:trivia_tycoon/game/multiplayer/domain/entities/player_presence.dart';
import 'package:trivia_tycoon/game/multiplayer/domain/entities/game_turn.dart';

/// A running or finalized match within a room.
class Match {
  /// Unique match id.
  final String id;

  /// The room this match belongs to.
  final String roomId;

  /// Players that participated / are participating.
  final List<PlayerPresence> players;

  /// The currently active turn (if any).
  final GameTurn? currentTurn;

  const Match({
    required this.id,
    required this.roomId,
    this.players = const [],
    this.currentTurn,
  });

  Match copyWith({
    String? id,
    String? roomId,
    List<PlayerPresence>? players,
    GameTurn? currentTurn, // pass explicit null to clear
    bool clearTurn = false,
  }) {
    return Match(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      players: players ?? this.players,
      currentTurn: clearTurn ? null : (currentTurn ?? this.currentTurn),
    );
  }

  @override
  String toString() =>
      'Match(id: $id, roomId: $roomId, players: ${players.length}, currentTurn: $currentTurn)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Match &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              roomId == other.roomId &&
              _listEq(players, other.players) &&
              currentTurn == other.currentTurn;

  @override
  int get hashCode =>
      Object.hash(id, roomId, Object.hashAll(players), currentTurn);
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
