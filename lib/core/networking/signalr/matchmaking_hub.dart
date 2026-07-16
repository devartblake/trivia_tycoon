import 'dart:async';
import 'package:signalr_netcore/signalr_client.dart';
import 'package:synaptix/core/networking/signalr/hub_client_base.dart';

class MatchmakingQueuedDto {
  final String ticketId;
  final String mode;
  final int tier;
  final DateTime queuedAtUtc;

  const MatchmakingQueuedDto({
    required this.ticketId,
    required this.mode,
    required this.tier,
    required this.queuedAtUtc,
  });

  factory MatchmakingQueuedDto.fromJson(Map<String, dynamic> json) =>
      MatchmakingQueuedDto(
        ticketId: json['TicketId'] as String,
        mode: json['Mode'] as String,
        tier: json['Tier'] as int,
        queuedAtUtc: DateTime.tryParse(json['QueuedAtUtc'] as String? ?? '') ??
            DateTime.now(),
      );
}

class MatchmakingMatchedDto {
  final String ticketId;
  final String opponentId;
  final String mode;
  final int tier;
  final DateTime matchedAtUtc;

  const MatchmakingMatchedDto({
    required this.ticketId,
    required this.opponentId,
    required this.mode,
    required this.tier,
    required this.matchedAtUtc,
  });

  factory MatchmakingMatchedDto.fromJson(Map<String, dynamic> json) =>
      MatchmakingMatchedDto(
        ticketId: json['TicketId'] as String,
        opponentId: json['OpponentId'] as String,
        mode: json['Mode'] as String,
        tier: json['Tier'] as int,
        matchedAtUtc:
            DateTime.tryParse(json['MatchedAtUtc'] as String? ?? '') ??
                DateTime.now(),
      );
}

class MatchmakingCancelledDto {
  final String ticketId;
  final String reason;
  final DateTime cancelledAtUtc;

  const MatchmakingCancelledDto({
    required this.ticketId,
    required this.reason,
    required this.cancelledAtUtc,
  });

  factory MatchmakingCancelledDto.fromJson(Map<String, dynamic> json) =>
      MatchmakingCancelledDto(
        ticketId: json['TicketId'] as String,
        reason: json['Reason'] as String,
        cancelledAtUtc:
            DateTime.tryParse(json['CancelledAtUtc'] as String? ?? '') ??
                DateTime.now(),
      );
}

/// SignalR hub client for `/ws/matchmaking`.
///
/// SignalR alternative to the gRPC [WatchMatchmaking] stream — targets
/// browser clients and any environment where gRPC is not available.
///
/// Usage:
///   1. Call [start] after login.
///   2. Call [joinQueue] with the desired mode.
///   3. Listen to [queued], [matched], and [cancelled] streams.
///   4. When [matched] fires, start the gRPC [PlayMatch] stream.
///   5. Call [cancelQueue] to withdraw.
class MatchmakingHub extends HubClientBase {
  final _queued = StreamController<MatchmakingQueuedDto>.broadcast();
  final _matched = StreamController<MatchmakingMatchedDto>.broadcast();
  final _cancelled = StreamController<MatchmakingCancelledDto>.broadcast();

  Stream<MatchmakingQueuedDto> get queued => _queued.stream;
  Stream<MatchmakingMatchedDto> get matched => _matched.stream;
  Stream<MatchmakingCancelledDto> get cancelled => _cancelled.stream;

  @override
  void registerHandlers(HubConnection connection) {
    connection.on('Queued', (args) {
      if (args == null || args.isEmpty) return;
      _queued
          .add(MatchmakingQueuedDto.fromJson(args[0] as Map<String, dynamic>));
    });

    connection.on('Matched', (args) {
      if (args == null || args.isEmpty) return;
      _matched
          .add(MatchmakingMatchedDto.fromJson(args[0] as Map<String, dynamic>));
    });

    connection.on('Cancelled', (args) {
      if (args == null || args.isEmpty) return;
      _cancelled.add(
          MatchmakingCancelledDto.fromJson(args[0] as Map<String, dynamic>));
    });
  }

  /// Enter the matchmaking queue for [mode] (e.g. "ranked", "duel").
  /// Server responds with [queued] event; [matched] fires when an opponent is found.
  Future<void> joinQueue(String mode, {int tier = 1}) =>
      invoke('JoinQueue', args: [mode, tier]);

  /// Withdraw from the queue. Server responds with [cancelled] event.
  Future<void> cancelQueue() => invoke('CancelQueue');

  @override
  Future<void> stop() async {
    await _queued.close();
    await _matched.close();
    await _cancelled.close();
    await super.stop();
  }
}
