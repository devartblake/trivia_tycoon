import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:trivia_tycoon/core/networking/signalr/hub_client_base.dart';

/// Presence status for a single player.
class PlayerPresenceChangedDto {
  final String playerId;
  final String status; // "online" | "offline" | "away" | "inGame"
  final DateTime timestamp;

  const PlayerPresenceChangedDto({
    required this.playerId,
    required this.status,
    required this.timestamp,
  });

  factory PlayerPresenceChangedDto.fromJson(Map<String, dynamic> json) =>
      PlayerPresenceChangedDto(
        playerId: json['PlayerId'] as String,
        status: json['Status'] as String,
        timestamp: DateTime.tryParse(json['Timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}

/// Bulk snapshot of online friends.
class PlayerPresenceSnapshotDto {
  final List<({String playerId, String status})> onlinePlayers;
  final DateTime timestamp;

  const PlayerPresenceSnapshotDto({
    required this.onlinePlayers,
    required this.timestamp,
  });

  factory PlayerPresenceSnapshotDto.fromJson(Map<String, dynamic> json) {
    final raw = (json['OnlinePlayers'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    return PlayerPresenceSnapshotDto(
      onlinePlayers: raw
          .map((e) => (
                playerId: e['PlayerId'] as String,
                status: e['Status'] as String,
              ))
          .toList(),
      timestamp:
          DateTime.tryParse(json['Timestamp'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

/// SignalR hub client for `/ws/presence`.
///
/// Usage:
///   1. Call [start] after login.
///   2. Call [subscribeFriends] with a list of friend player IDs.
///   3. Listen to [presenceChanged] and [presenceSnapshot] streams.
///
/// The server pushes [presenceChanged] whenever a watched friend goes
/// online or offline, and an initial [presenceSnapshot] on subscribe.
class PresenceHub extends HubClientBase {
  final _presenceChanged =
      StreamController<PlayerPresenceChangedDto>.broadcast();
  final _presenceSnapshot =
      StreamController<PlayerPresenceSnapshotDto>.broadcast();

  Stream<PlayerPresenceChangedDto> get presenceChanged =>
      _presenceChanged.stream;
  Stream<PlayerPresenceSnapshotDto> get presenceSnapshot =>
      _presenceSnapshot.stream;

  @override
  void registerHandlers(HubConnection connection) {
    connection.on('PresenceChanged', (args) {
      if (args == null || args.isEmpty) return;
      final data = args[0] as Map<String, dynamic>;
      _presenceChanged.add(PlayerPresenceChangedDto.fromJson(data));
    });

    connection.on('PresenceSnapshot', (args) {
      if (args == null || args.isEmpty) return;
      final data = args[0] as Map<String, dynamic>;
      _presenceSnapshot.add(PlayerPresenceSnapshotDto.fromJson(data));
    });
  }

  /// Subscribe to presence events for a list of friend player IDs.
  /// The server responds immediately with a [presenceSnapshot] of who
  /// is currently online.
  Future<void> subscribeFriends(List<String> friendIds) =>
      invoke('SubscribeFriends', args: [friendIds]);

  Future<void> unsubscribeFriend(String friendId) =>
      invoke('UnsubscribeFriend', args: [friendId]);

  @override
  Future<void> stop() async {
    await _presenceChanged.close();
    await _presenceSnapshot.close();
    await super.stop();
  }
}
