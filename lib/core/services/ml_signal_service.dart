import 'api_service.dart';

/// Sends ML signal payloads to the backend for churn prediction and match quality.
/// Both endpoints are fire-and-forget — failures are silently swallowed so
/// they never interrupt the player experience.
class MlSignalService {
  final ApiService _api;

  const MlSignalService(this._api);

  /// `POST /ml/churn-risk` — signal that a player may be at risk of churning.
  /// [playerId] is the authenticated user's UUID.
  /// [signals] is an arbitrary map of client-observed features
  /// (e.g. session_gap_days, last_score, streak_broken).
  Future<void> sendChurnRisk({
    required String playerId,
    Map<String, dynamic> signals = const {},
  }) async {
    try {
      await _api.post('/ml/churn-risk', body: {
        'playerId': playerId,
        ...signals,
      });
    } catch (_) {
      // Non-critical — never surface ML errors to the user.
    }
  }

  /// `POST /ml/match-quality` — signal observed match quality after a game.
  /// [matchId] is the game/session ID.
  /// [playerId] is the authenticated user's UUID.
  /// [signals] is an arbitrary map of quality indicators
  /// (e.g. disconnect_count, latency_ms, score_delta, opponent_rating_diff).
  Future<void> sendMatchQuality({
    required String matchId,
    required String playerId,
    Map<String, dynamic> signals = const {},
  }) async {
    try {
      await _api.post('/ml/match-quality', body: {
        'matchId': matchId,
        'playerId': playerId,
        ...signals,
      });
    } catch (_) {
      // Non-critical — never surface ML errors to the user.
    }
  }
}
