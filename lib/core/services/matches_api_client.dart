import 'package:logging/logging.dart';
import 'api_service.dart';

/// Data Transfer Objects for Match API
class MatchStartRequest {
  final String? opponentId;
  final String? gameMode;

  MatchStartRequest({this.opponentId, this.gameMode});

  Map<String, dynamic> toJson() => {
        if (opponentId != null) 'opponentId': opponentId,
        if (gameMode != null) 'gameMode': gameMode,
      };
}

class MatchStartResponse {
  final String matchId;
  final String playerId;
  final String? opponentId;
  final String gameMode;
  final String status;
  final DateTime createdAtUtc;

  const MatchStartResponse({
    required this.matchId,
    required this.playerId,
    this.opponentId,
    required this.gameMode,
    required this.status,
    required this.createdAtUtc,
  });

  factory MatchStartResponse.fromJson(Map<String, dynamic> json) {
    return MatchStartResponse(
      matchId: json['matchId']?.toString() ?? '',
      playerId: json['playerId']?.toString() ?? '',
      opponentId: json['opponentId'] as String?,
      gameMode: json['gameMode']?.toString() ?? 'quiz',
      status: json['status']?.toString() ?? 'started',
      createdAtUtc:
          DateTime.tryParse(json['createdAtUtc']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
    );
  }
}

class MatchSubmitRequest {
  final int playerScore;
  final int? opponentScore;
  final List<String> answeredQuestionIds;
  final DateTime? completedAtUtc;

  MatchSubmitRequest({
    required this.playerScore,
    this.opponentScore,
    required this.answeredQuestionIds,
    this.completedAtUtc,
  });

  Map<String, dynamic> toJson() => {
        'playerScore': playerScore,
        if (opponentScore != null) 'opponentScore': opponentScore,
        'answeredQuestionIds': answeredQuestionIds,
        if (completedAtUtc != null)
          'completedAtUtc': completedAtUtc?.toIso8601String(),
      };
}

class MatchSubmitResponse {
  final String matchId;
  final int playerScore;
  final int? opponentScore;
  final String result; // 'won', 'lost', 'tied', 'ongoing'
  final String status; // 'completed', 'waiting_opponent', 'abandoned'
  final int? rewardCoins;

  const MatchSubmitResponse({
    required this.matchId,
    required this.playerScore,
    this.opponentScore,
    required this.result,
    required this.status,
    this.rewardCoins,
  });

  factory MatchSubmitResponse.fromJson(Map<String, dynamic> json) {
    return MatchSubmitResponse(
      matchId: json['matchId']?.toString() ?? '',
      playerScore: (json['playerScore'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponentScore'] as num?)?.toInt(),
      result: json['result']?.toString() ?? 'ongoing',
      status: json['status']?.toString() ?? 'completed',
      rewardCoins: (json['rewardCoins'] as num?)?.toInt(),
    );
  }
}

class MatchDetailsResponse {
  final String matchId;
  final String playerId;
  final String? opponentId;
  final String? opponentName;
  final int playerScore;
  final int? opponentScore;
  final String gameMode;
  final String status;
  final String result;
  final DateTime createdAtUtc;
  final DateTime? completedAtUtc;
  final int? rewardCoins;

  const MatchDetailsResponse({
    required this.matchId,
    required this.playerId,
    this.opponentId,
    this.opponentName,
    required this.playerScore,
    this.opponentScore,
    required this.gameMode,
    required this.status,
    required this.result,
    required this.createdAtUtc,
    this.completedAtUtc,
    this.rewardCoins,
  });

  factory MatchDetailsResponse.fromJson(Map<String, dynamic> json) {
    return MatchDetailsResponse(
      matchId: json['matchId']?.toString() ?? '',
      playerId: json['playerId']?.toString() ?? '',
      opponentId: json['opponentId'] as String?,
      opponentName: json['opponentName'] as String?,
      playerScore: (json['playerScore'] as num?)?.toInt() ?? 0,
      opponentScore: (json['opponentScore'] as num?)?.toInt(),
      gameMode: json['gameMode']?.toString() ?? 'quiz',
      status: json['status']?.toString() ?? 'ongoing',
      result: json['result']?.toString() ?? 'ongoing',
      createdAtUtc:
          DateTime.tryParse(json['createdAtUtc']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc(),
      completedAtUtc: json['completedAtUtc'] != null
          ? DateTime.tryParse(json['completedAtUtc']?.toString() ?? '')?.toUtc()
          : null,
      rewardCoins: (json['rewardCoins'] as num?)?.toInt(),
    );
  }
}

class MatchListResponse {
  final List<MatchDetailsResponse> matches;
  final int totalCount;
  final int page;
  final int pageSize;

  const MatchListResponse({
    required this.matches,
    required this.totalCount,
    required this.page,
    required this.pageSize,
  });

  factory MatchListResponse.fromJson(Map<String, dynamic> json) {
    final List<dynamic> matchesList = json['matches'] as List<dynamic>? ?? [];
    return MatchListResponse(
      matches: matchesList
          .map((m) =>
              MatchDetailsResponse.fromJson(Map<String, dynamic>.from(m)))
          .toList(),
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      page: (json['page'] as num?)?.toInt() ?? 1,
      pageSize: (json['pageSize'] as num?)?.toInt() ?? 10,
    );
  }
}

/// REST-based API client for match operations.
///
/// **NOTE**: This client provides REST endpoints for match management.
/// For real-time multiplayer gameplay, the system also supports WebSocket
/// transport via multiplayer_service.dart (uses gRPC/SignalR).
///
/// Endpoints:
///   POST   /matches/start                  — create a new match
///   POST   /matches/submit                 — submit match result
///   GET    /matches/{matchId}              — get match details
///   GET    /matches                        — list player's matches (paginated)
///
/// Migration Guide:
/// - For real-time competitive play: Use MultiplayerService (WebSocket-based)
/// - For async turn-based play: Use this client (REST-based)
class MatchesApiClient {
  static final _log = Logger('MatchesApiClient');

  final ApiService _apiService;

  MatchesApiClient(this._apiService);

  /// Starts a new match (either vs opponent or in singleplayer mode).
  ///
  /// Pass [opponentId] to invite a specific player, or leave null for
  /// singleplayer/AI matches.
  ///
  /// Returns match details including matchId for subsequent operations.
  /// Throws [ApiRequestException] on server errors.
  Future<MatchStartResponse> startMatch({
    String? opponentId,
    String? gameMode,
  }) async {
    _log.info('Starting match: opponentId=$opponentId gameMode=$gameMode');
    final body = MatchStartRequest(
      opponentId: opponentId,
      gameMode: gameMode,
    ).toJson();

    final json = await _apiService.post('/matches/start', body: body);
    return MatchStartResponse.fromJson(json);
  }

  /// Submits match results and claims any rewards.
  ///
  /// Must be called after match completion to:
  /// - Record final scores
  /// - Determine win/loss/tie
  /// - Issue rewards (if applicable)
  /// - Update player statistics
  ///
  /// Returns match outcome and reward information.
  /// Throws [ApiRequestException] on server errors.
  Future<MatchSubmitResponse> submitMatch({
    required String matchId,
    required int playerScore,
    int? opponentScore,
    required List<String> answeredQuestionIds,
    DateTime? completedAtUtc,
  }) async {
    _log.info(
        'Submitting match result: matchId=$matchId playerScore=$playerScore');
    final body = MatchSubmitRequest(
      playerScore: playerScore,
      opponentScore: opponentScore,
      answeredQuestionIds: answeredQuestionIds,
      completedAtUtc: completedAtUtc,
    ).toJson();

    final json = await _apiService.post('/matches/submit', body: body);
    return MatchSubmitResponse.fromJson(json);
  }

  /// Retrieves details for a specific match.
  ///
  /// Includes final scores, opponent info, rewards, and completion status.
  /// Can be called before submission to check ongoing match state.
  /// Throws [ApiRequestException] on server errors or if match not found.
  Future<MatchDetailsResponse> getMatchDetails(String matchId) async {
    _log.info('Fetching match details: matchId=$matchId');
    final json = await _apiService.get('/matches/$matchId');
    return MatchDetailsResponse.fromJson(json);
  }

  /// Lists player's matches with pagination and filtering.
  ///
  /// Returns historical matches, ongoing matches, or matches with specific opponent.
  /// Supports pagination via [page] and [pageSize].
  /// Throws [ApiRequestException] on server errors.
  Future<MatchListResponse> listMatches({
    int page = 1,
    int pageSize = 10,
    String? status, // 'ongoing', 'completed', 'abandoned'
    String? gameMode, // 'quiz', 'duel', etc.
  }) async {
    _log.info(
        'Listing matches: page=$page pageSize=$pageSize status=$status gameMode=$gameMode');
    final params = {
      'page': page,
      'pageSize': pageSize,
      if (status != null) 'status': status,
      if (gameMode != null) 'gameMode': gameMode,
    };

    final json = await _apiService.get('/matches', queryParameters: params);
    return MatchListResponse.fromJson(json);
  }

  /// Abandons an ongoing match.
  ///
  /// This ends the match prematurely. The opponent may still be able to claim
  /// a win if configured on the backend.
  /// Throws [ApiRequestException] on server errors or if match not found.
  Future<void> abandonMatch(String matchId) async {
    _log.info('Abandoning match: matchId=$matchId');
    await _apiService.post('/matches/$matchId/abandon', body: {});
  }
}

/// Extension to support backwards compatibility during migration.
///
/// Old code may use `getActiveMatches()` expecting stub data.
/// This extension bridges to the REST API client.
extension LegacyMatchesSupport on MatchesApiClient {
  /// DEPRECATED: Use [listMatches] with status='ongoing' instead.
  /// Returns active (ongoing) matches for the current player.
  @Deprecated('Use listMatches(status: "ongoing") instead')
  Future<List<Map<String, dynamic>>> getActiveMatches() async {
    MatchesApiClient._log.warning(
        'DEPRECATED: getActiveMatches() called. Use listMatches(status: "ongoing") instead.');
    final response = await listMatches(status: 'ongoing');
    return response.matches
        .map((m) => {
              'id': m.matchId,
              'matchId': m.matchId,
              'opponentId': m.opponentId,
              'opponentName': m.opponentName,
              'playerScore': m.playerScore,
              'opponentScore': m.opponentScore,
              'gameMode': m.gameMode,
              'status': m.status,
              'result': m.result,
              'createdAt': m.createdAtUtc.toIso8601String(),
            })
        .toList();
  }
}
