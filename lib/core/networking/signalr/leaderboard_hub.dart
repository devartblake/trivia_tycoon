import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:trivia_tycoon/core/networking/signalr/hub_client_base.dart';

class LeaderboardRankChangedDto {
  final String playerId;
  final int tierId;
  final int oldRank;
  final int newRank;
  final int newScore;
  final DateTime timestamp;

  const LeaderboardRankChangedDto({
    required this.playerId,
    required this.tierId,
    required this.oldRank,
    required this.newRank,
    required this.newScore,
    required this.timestamp,
  });

  factory LeaderboardRankChangedDto.fromJson(Map<String, dynamic> json) =>
      LeaderboardRankChangedDto(
        playerId: json['PlayerId'] as String,
        tierId: json['TierId'] as int,
        oldRank: json['OldRank'] as int,
        newRank: json['NewRank'] as int,
        newScore: json['NewScore'] as int,
        timestamp: DateTime.tryParse(json['Timestamp'] as String? ?? '') ??
            DateTime.now(),
      );
}

class LeaderboardSnapshotEntryDto {
  final String playerId;
  final String handle;
  final String countryCode;
  final int score;
  final int tierRank;
  final int globalRank;

  const LeaderboardSnapshotEntryDto({
    required this.playerId,
    required this.handle,
    required this.countryCode,
    required this.score,
    required this.tierRank,
    required this.globalRank,
  });

  factory LeaderboardSnapshotEntryDto.fromJson(Map<String, dynamic> json) =>
      LeaderboardSnapshotEntryDto(
        playerId: json['PlayerId'] as String,
        handle: json['Handle'] as String,
        countryCode: json['CountryCode'] as String? ?? '',
        score: json['Score'] as int,
        tierRank: json['TierRank'] as int,
        globalRank: json['GlobalRank'] as int,
      );
}

class LeaderboardSnapshotDto {
  final int tierId;
  final List<LeaderboardSnapshotEntryDto> entries;
  final DateTime snapshotAtUtc;

  const LeaderboardSnapshotDto({
    required this.tierId,
    required this.entries,
    required this.snapshotAtUtc,
  });

  factory LeaderboardSnapshotDto.fromJson(Map<String, dynamic> json) {
    final raw =
        (json['Entries'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    return LeaderboardSnapshotDto(
      tierId: json['TierId'] as int,
      entries: raw.map(LeaderboardSnapshotEntryDto.fromJson).toList(),
      snapshotAtUtc:
          DateTime.tryParse(json['SnapshotAtUtc'] as String? ?? '') ??
              DateTime.now(),
    );
  }
}

/// SignalR hub client for `/ws/leaderboard`.
///
/// Usage:
///   1. Call [start] after login.
///   2. Call [subscribeTier] or [subscribeGlobal].
///   3. Listen to [rankChanged] and [snapshot] streams.
///
/// The server immediately sends a [snapshot] on subscribe,
/// and pushes updates whenever the leaderboard is recalculated.
class LeaderboardHub extends HubClientBase {
  final _rankChanged = StreamController<LeaderboardRankChangedDto>.broadcast();
  final _snapshot = StreamController<LeaderboardSnapshotDto>.broadcast();

  Stream<LeaderboardRankChangedDto> get rankChanged => _rankChanged.stream;
  Stream<LeaderboardSnapshotDto> get snapshot => _snapshot.stream;

  @override
  void registerHandlers(HubConnection connection) {
    connection.on('RankChanged', (args) {
      if (args == null || args.isEmpty) return;
      _rankChanged.add(
          LeaderboardRankChangedDto.fromJson(args[0] as Map<String, dynamic>));
    });

    connection.on('LeaderboardSnapshot', (args) {
      if (args == null || args.isEmpty) return;
      _snapshot.add(
          LeaderboardSnapshotDto.fromJson(args[0] as Map<String, dynamic>));
    });
  }

  Future<void> subscribeTier(int tierId) =>
      invoke('SubscribeTier', args: [tierId]);

  Future<void> subscribeGlobal() => invoke('SubscribeGlobal');

  Future<void> unsubscribeTier(int tierId) =>
      invoke('UnsubscribeTier', args: [tierId]);

  @override
  Future<void> stop() async {
    await _rankChanged.close();
    await _snapshot.close();
    await super.stop();
  }
}
