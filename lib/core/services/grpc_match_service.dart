import 'package:trivia_tycoon/core/networking/grpc/grpc_match_client.dart';
import 'package:trivia_tycoon/core/networking/grpc/generated/mobile.pb.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Business-logic façade over [GrpcMatchClient].
///
/// Responsibilities:
///   - Translates between proto types and app domain types where needed.
///   - Wraps gRPC errors into app-level exceptions with readable messages.
///   - Provides the primary interface consumed by game controllers / providers.
///
/// Integration strategy:
///   gRPC is *additive* — SignalR/WsClient remain for notifications, DMs, and
///   presence.  Use gRPC for match lifecycle and matchmaking queue streaming.
///
///   Feature gating: guard multiplayer RPCs behind the `realtimeMultiplayerEnabled`
///   flag from [AppConfigProvider] before calling [playMatch].
class GrpcMatchService {
  final GrpcMatchClient _client;

  const GrpcMatchService(this._client);

  // ── Match lifecycle ────────────────────────────────────────────────────────

  /// Start a new match. Returns the assigned [matchId] and server-side start
  /// timestamp in Unix epoch milliseconds.
  Future<({String matchId, int startedAtMs})> startMatch(
    String hostPlayerId,
    String mode,
  ) async {
    try {
      final res = await _client.startMatch(hostPlayerId, mode);
      return (matchId: res.matchId, startedAtMs: res.startedAt.toInt());
    } catch (e, st) {
      LogManager.error(
        '[GrpcMatchService] startMatch failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  /// Submit a completed match and retrieve XP/coin awards.
  Future<GrpcSubmitMatchResponse> submitMatch(
      GrpcSubmitMatchRequest req) async {
    try {
      return await _client.submitMatch(req);
    } catch (e, st) {
      LogManager.error(
        '[GrpcMatchService] submitMatch failed',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  // ── Live match session ─────────────────────────────────────────────────────

  /// Open a bidirectional match stream.
  ///
  /// [actionsOut] is the stream of [PlayerAction] messages the caller sends.
  /// Returns a stream of [MatchEvent] messages from the server
  /// (QuestionEvent, AnswerResultEvent, OpponentScoreEvent, TimerEvent,
  /// MatchEndEvent, ErrorEvent).
  Stream<MatchEvent> playMatch(Stream<PlayerAction> actionsOut) {
    return _client.playMatch(actionsOut).handleError((Object e) {
      LogManager.error('[GrpcMatchService] playMatch stream error', error: e);
    });
  }

  // ── Leaderboard stream ─────────────────────────────────────────────────────

  /// Subscribe to live rank-neighbourhood updates.
  /// Cancel the returned subscription to unsubscribe.
  Stream<LeaderboardUpdate> watchLeaderboard({
    required String playerId,
    String mode = '',
    int windowSize = 5,
  }) {
    return _client
        .watchLeaderboard(
      playerId: playerId,
      mode: mode,
      windowSize: windowSize,
    )
        .handleError((Object e) {
      LogManager.error(
        '[GrpcMatchService] watchLeaderboard stream error',
        error: e,
      );
    });
  }

  // ── Matchmaking ────────────────────────────────────────────────────────────

  /// Enter the matchmaking queue and stream status updates.
  ///
  /// Emits [MatchmakingStatusUpdate] with status values:
  ///   "Queued"    — ticket created; waiting for an opponent
  ///   "Matched"   — opponent found; check [opponentId] and start [playMatch]
  ///   "Cancelled" — queue cancelled (server-side or via [cancelMatchmaking])
  ///   "Error"     — unexpected server error
  ///
  /// Cancel the returned stream subscription to leave the queue silently.
  /// For an explicit cancel (show feedback to player), call [cancelMatchmaking].
  Stream<MatchmakingStatusUpdate> watchMatchmaking({
    required String playerId,
    String mode = 'ranked',
    int tierId = 0,
  }) {
    return _client
        .watchMatchmaking(
      playerId: playerId,
      mode: mode,
      tierId: tierId,
    )
        .handleError((Object e) {
      LogManager.error(
        '[GrpcMatchService] watchMatchmaking stream error',
        error: e,
      );
    });
  }

  /// Cleanly cancel an active matchmaking queue ticket.
  Future<bool> cancelMatchmaking(String playerId, String ticketId) async {
    try {
      final res = await _client.cancelMatchmaking(playerId, ticketId);
      return res.cancelled;
    } catch (e, st) {
      LogManager.error(
        '[GrpcMatchService] cancelMatchmaking failed',
        error: e,
        stackTrace: st,
      );
      return false;
    }
  }
}
