import 'package:grpc/service_api.dart';
import 'package:trivia_tycoon/core/networking/grpc/generated/mobile.pbgrpc.dart';

/// Thin typed wrapper around [MobileMatchServiceClient].
///
/// Auth is injected transparently via [GrpcAuthInterceptor] on the channel,
/// so no CallOptions need to be constructed at the call site.
class GrpcMatchClient {
  final MobileMatchServiceClient _stub;

  GrpcMatchClient(
    ClientChannel channel, {
    Iterable<ClientInterceptor> interceptors = const [],
  }) : _stub = MobileMatchServiceClient(
          channel,
          interceptors: interceptors,
        );

  // ── Unary ──────────────────────────────────────────────────────────────────

  Future<GrpcStartMatchResponse> startMatch(String hostPlayerId, String mode) =>
      _stub.startMatch(
        GrpcStartMatchRequest(hostPlayerId: hostPlayerId, mode: mode),
      );

  Future<GrpcSubmitMatchResponse> submitMatch(GrpcSubmitMatchRequest req) =>
      _stub.submitMatch(req);

  Future<CancelMatchmakingResponse> cancelMatchmaking(
    String playerId,
    String ticketId,
  ) =>
      _stub.cancelMatchmaking(
        CancelMatchmakingRequest(playerId: playerId, ticketId: ticketId),
      );

  // ── Streaming ──────────────────────────────────────────────────────────────

  ResponseStream<MatchEvent> playMatch(Stream<PlayerAction> actions) =>
      _stub.playMatch(actions);

  ResponseStream<LeaderboardUpdate> watchLeaderboard({
    required String playerId,
    String mode = '',
    int windowSize = 5,
  }) =>
      _stub.watchLeaderboard(
        LeaderboardWatchRequest(
          playerId: playerId,
          mode: mode,
          windowSize: windowSize,
        ),
      );

  ResponseStream<MatchmakingStatusUpdate> watchMatchmaking({
    required String playerId,
    String mode = 'ranked',
    int tierId = 0,
  }) =>
      _stub.watchMatchmaking(
        WatchMatchmakingRequest(
          playerId: playerId,
          mode: mode,
          tierId: tierId,
        ),
      );
}
