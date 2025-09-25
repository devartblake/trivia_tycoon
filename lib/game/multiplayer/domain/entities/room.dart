import 'package:trivia_tycoon/game/multiplayer/domain/entities/player_presence.dart';

/// A lobby/room where players gather before and during a match.
class Room {
  /// Unique room id (server-issued).
  final String id;

  /// Human-friendly room name (optional).
  final String? name;

  /// Max players allowed by server configuration.
  final int capacity;

  /// Current players in this room.
  final List<PlayerPresence> players;

  /// True if the **local** player is the host (authoritative).
  final bool isHost;

  const Room({
    required this.id,
    this.name,
    required this.capacity,
    this.players = const [],
    this.isHost = false,
  });

  int get playerCount => players.length;

  bool get isFull => playerCount >= capacity;

  PlayerPresence? get host =>
      players.cast<PlayerPresence?>().firstWhere((p) => p?.isHost == true, orElse: () => null);

  Room copyWith({
    String? id,
    String? name,
    int? capacity,
    List<PlayerPresence>? players,
    bool? isHost,
    bool clearName = false,
  }) {
    return Room(
      id: id ?? this.id,
      name: clearName ? null : (name ?? this.name),
      capacity: capacity ?? this.capacity,
      players: players ?? this.players,
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  String toString() =>
      'Room(id: $id, name: $name, capacity: $capacity, players: ${players.length}, isHost: $isHost)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Room &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              capacity == other.capacity &&
              _listEq(players, other.players) &&
              isHost == other.isHost;

  @override
  int get hashCode =>
      Object.hash(id, name, capacity, Object.hashAll(players), isHost);
}

bool _listEq<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
