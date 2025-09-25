/// Lightweight snapshot of a player currently known to the session/room.
class PlayerPresence {
  /// Stable server-issued identifier for a player (not the display name).
  final String id;

  /// The display name to show in UI.
  final String name;

  /// Optional avatar/image URL.
  final String? avatarUrl;

  /// True if this player currently holds host permissions in the room.
  final bool isHost;

  const PlayerPresence({
    required this.id,
    required this.name,
    this.avatarUrl,
    this.isHost = false,
  });

  PlayerPresence copyWith({
    String? id,
    String? name,
    String? avatarUrl, // pass explicit null to clear
    bool? isHost,
    bool clearAvatar = false,
  }) {
    return PlayerPresence(
      id: id ?? this.id,
      name: name ?? this.name,
      avatarUrl: clearAvatar ? null : (avatarUrl ?? this.avatarUrl),
      isHost: isHost ?? this.isHost,
    );
  }

  @override
  String toString() =>
      'PlayerPresence(id: $id, name: $name, isHost: $isHost, avatarUrl: ${avatarUrl != null})';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is PlayerPresence &&
              runtimeType == other.runtimeType &&
              id == other.id &&
              name == other.name &&
              avatarUrl == other.avatarUrl &&
              isHost == other.isHost;

  @override
  int get hashCode => Object.hash(id, name, avatarUrl, isHost);
}
