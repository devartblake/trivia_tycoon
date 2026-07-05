import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

import 'http_client.dart';
import '../dto/player_dto.dart';
import '../dto/season_dto.dart';
import '../dto/skill_dto.dart';
import '../dto/game_event_dto.dart';
import '../dto/guardian_dto.dart';
import '../dto/territory_dto.dart';
import '../dto/vote_dto.dart';
import '../dto/economy_dto.dart';
import '../dto/personalization_dto.dart';
import '../dto/powerup_dto.dart';
import '../dto/party_dto.dart';

/// API client for Synaptix backend
///
/// Provides high-level methods for common API operations with
/// automatic authentication and error handling.
class SynaptixApiClient {
  static const _uuid = Uuid();

  final HttpClient _http;
  final String? _healthCheckUrl;

  SynaptixApiClient({
    required HttpClient httpClient,
    String? healthCheckUrl,
  })  : _http = httpClient,
        _healthCheckUrl = healthCheckUrl;

  // ========================================
  // Low-Level Convenience Methods
  // ========================================

  /// GET request returning JSON object
  /// For backward compatibility with existing screens
  Future<Map<String, dynamic>> getJson(
    String path, {
    Map<String, String>? query,
  }) async {
    return await _http.getJson(path, query: query);
  }

  /// POST request with JSON body, returning JSON
  /// For backward compatibility
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? query,
  }) async {
    return await _http.postJson(path, body: body, query: query);
  }

  // ========================================
  // Quiz/Questions
  // ========================================

  @Deprecated('Use QuestionHubService instead. '
      'Direct question fetching is handled by /questions endpoints.')
  Future<List<Map<String, dynamic>>> getQuizQuestions({
    required int amount,
    String? category,
    String? difficulty,
  }) async {
    final raw = await _http.getJson(
      '/questions/set',
      query: {
        'count': amount.toString(),
        if (category != null) 'category': category,
        if (difficulty != null) 'difficulty': difficulty,
      },
    );
    final items = raw['questions'] ?? raw['items'] ?? const [];
    return List<Map<String, dynamic>>.from(items);
  }

  /// Submit quiz results via canonical batch-check endpoint.
  Future<Map<String, dynamic>> submitQuizResults({
    required String quizId,
    required List<Map<String, dynamic>> answers,
    required int score,
    required int totalQuestions,
  }) async {
    return await _http.postJson(
      '/questions/check-batch',
      body: {
        'quizId': quizId,
        'answers': answers,
        'score': score,
        'totalQuestions': totalQuestions,
      },
    );
  }

  // ========================================
  // Leaderboard
  // ========================================

  /// Get global leaderboard.
  /// Backend: legacy GET /leaderboard?limit= (server caps at 500).
  Future<List<Map<String, dynamic>>> getLeaderboard({int limit = 100}) async {
    final data = await _http.getJsonList(
      '/leaderboard',
      query: {'limit': limit.toString()},
    );

    return data.cast<Map<String, dynamic>>();
  }

  /// Get a player's leaderboard entry (rank, tier, score).
  /// Backend: GET /leaderboards/me/{playerId}
  Future<Map<String, dynamic>> getUserRank(String userId) async {
    return await _http.getJson('/leaderboards/me/$userId');
  }

  // ========================================
  // User Profile (self-scoped — the backend only exposes /users/me)
  // ========================================

  /// Get the authenticated user's profile.
  Future<Map<String, dynamic>> getMyProfile() async {
    return await _http.getJson('/users/me');
  }

  /// Update the authenticated user's profile.
  Future<Map<String, dynamic>> updateMyProfile({
    Map<String, dynamic>? updates,
  }) async {
    return await _http.patchJson(
      '/users/me',
      body: updates,
    );
  }

  // ========================================
  // Achievements
  // ========================================

  /// Get the achievement catalog.
  /// Backend: GET /achievements → {achievements: [...]}
  Future<List<Map<String, dynamic>>> getAchievementCatalog() async {
    final j = await _http.getJson('/achievements');
    return (j['achievements'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
  }

  /// Get a player's unlocked achievements.
  /// Backend: GET /achievements/player/{playerId} → {playerId, unlocked: [...]}
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    final j = await _http.getJson('/achievements/player/$userId');
    return (j['unlocked'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
  }

  /// Unlock an achievement by its stable key.
  /// Backend: POST /achievements/unlock; status is
  /// "Unlocked" | "Duplicate" | "NotFound".
  Future<Map<String, dynamic>> unlockAchievement({
    required String userId,
    required String achievementKey,
  }) async {
    return await _http.postJson(
      '/achievements/unlock',
      body: {'playerId': userId, 'achievementKey': achievementKey},
    );
  }

  // ========================================
  // Friends/Social (self-scoped under /users/me/friends)
  // ========================================

  /// Get the authenticated user's friends (paged response).
  Future<Map<String, dynamic>> getFriends({
    int page = 1,
    int pageSize = 50,
  }) async {
    return await _http.getJson(
      '/users/me/friends',
      query: {'page': page.toString(), 'pageSize': pageSize.toString()},
    );
  }

  /// Send friend request
  Future<Map<String, dynamic>> sendFriendRequest({
    required String targetUserId,
  }) async {
    return await _http.postJson(
      '/users/me/friends/request',
      body: {'targetUserId': targetUserId},
    );
  }

  /// Accept friend request
  Future<Map<String, dynamic>> acceptFriendRequest({
    required String requestId,
  }) async {
    return await _http.postJson(
      '/users/me/friends/requests/$requestId/accept',
    );
  }

  // ========================================
  // Matches/PvP
  // ========================================

  /// Create (start) a match.
  /// Backend: POST /matches/start with StartMatchRequest {hostPlayerId, mode};
  /// returns {matchId, startedAt}.
  Future<Map<String, dynamic>> createMatch({
    required String userId,
    required String mode,
  }) async {
    return await _http.postJson(
      '/matches/start',
      body: {
        'hostPlayerId': userId,
        'mode': mode,
      },
    );
  }

  /// Get match details
  Future<Map<String, dynamic>> getMatch(String matchId) async {
    return await _http.getJson('/matches/$matchId');
  }

  // ========================================
  // Store/Shop
  // ========================================

  /// Get store catalog items.
  /// Backend: GET /store/catalog?itemType=&category=
  Future<List<Map<String, dynamic>>> getStoreItems({
    String? category,
    String? itemType,
  }) async {
    final data = await _http.getJsonList(
      '/store/catalog',
      query: {
        if (category != null) 'category': category,
        if (itemType != null) 'itemType': itemType,
      },
    );

    return data.cast<Map<String, dynamic>>();
  }

  /// Purchase a catalog item with soft currency.
  /// Backend: POST /store/purchase with StorePurchaseRequest
  /// {playerId, sku, quantity, currency}. Note: this endpoint requires the
  /// secure channel (security-session handshake), not just a JWT.
  Future<Map<String, dynamic>> purchaseItem({
    required String userId,
    required String sku,
    int quantity = 1,
    String currency = 'Coins',
  }) async {
    return await _http.postJson(
      '/store/purchase',
      body: {
        'playerId': userId,
        'sku': sku,
        'quantity': quantity,
        'currency': currency,
      },
    );
  }

  // ========================================
  // Analytics
  // ========================================

  /// Track event
  Future<void> trackEvent({
    required String userId,
    required String eventName,
    Map<String, dynamic>? properties,
  }) async {
    await _http.post(
      '/analytics/track',
      body: {
        'userId': userId,
        'eventName': eventName,
        'timestamp': DateTime.now().toIso8601String(),
        if (properties != null) 'properties': properties,
      },
    );
  }

  // ========================================
  // Seasons/Competitions
  // ========================================

  /// Get current season as a raw map. Same endpoint as [getActiveSeason];
  /// prefer that method when you want a typed [SeasonDto].
  Future<Map<String, dynamic>> getCurrentSeason() async {
    return await _http.getJson('/seasons/active');
  }

  /// Get season leaderboard.
  /// Backend: GET /game-events/season-leaderboard?seasonId=&page=&pageSize=
  Future<List<Map<String, dynamic>>> getSeasonLeaderboard({
    required String seasonId,
    int page = 1,
    int pageSize = 100,
  }) async {
    final data = await _http.getJsonList(
      '/game-events/season-leaderboard',
      query: {
        'seasonId': seasonId,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
    );

    return data.cast<Map<String, dynamic>>();
  }

  // ========================================
  // Players
  // ========================================

  Future<PlayerDto> getPlayer(String playerId) async {
    final j = await _http.getJson('/players/$playerId');
    return PlayerDto.fromJson(j);
  }

  Future<PlayerDto> createPlayer({
    required String username,
    required String ageGroup,
    String? country,
    String? avatarUrl,
  }) async {
    final j = await _http.postJson(
      '/players',
      body: {
        'username': username,
        'ageGroup': ageGroup,
        if (country != null) 'country': country,
        if (avatarUrl != null) 'avatarUrl': avatarUrl,
      },
    );
    return PlayerDto.fromJson(j);
  }

  // ========================================
  // Matchmaking
  // ========================================

  /// Backend: POST /matchmaking/enqueue {playerId, mode, tier}.
  Future<void> joinMatchmakingQueue({
    required String playerId,
    required String mode,
    required int tier,
  }) async {
    await _http.postJson(
      '/matchmaking/enqueue',
      body: {'playerId': playerId, 'mode': mode, 'tier': tier},
    );
  }

  /// Backend: POST /matchmaking/cancel {playerId}.
  Future<void> cancelMatchmakingQueue({required String playerId}) async {
    await _http.postJson(
      '/matchmaking/cancel',
      body: {'playerId': playerId},
    );
  }

  /// Backend: GET /matchmaking/status/{playerId}.
  Future<Map<String, dynamic>> getMatchmakingStatus({
    required String playerId,
  }) async {
    return await _http.getJson('/matchmaking/status/$playerId');
  }

  // ========================================
  // Matches — list
  // ========================================

  /// Player match history (most recent first).
  /// Backend: GET /matches?playerId=&page=&pageSize= →
  /// {page, pageSize, total, items: [...]}.
  Future<List<Map<String, dynamic>>> listMatches({
    required String playerId,
    int page = 1,
    int pageSize = 20,
  }) async {
    final j = await _http.getJson(
      '/matches',
      query: {
        'playerId': playerId,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
    );
    return (j['items'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
  }

  /// Submit a completed match.
  /// Backend: POST /matches/submit with SubmitMatchRequest; eventId is an
  /// idempotency key. Each participant map must carry
  /// {playerId, score, correct, wrong, avgAnswerTimeMs}; each answer map
  /// {playerId, questionId, selectedOptionId, answerTimeMs}.
  /// Returns SubmitMatchResponse {eventId, matchId, status, awards}.
  Future<Map<String, dynamic>> submitMatch({
    required String matchId,
    required String mode,
    required String category,
    required int questionCount,
    required DateTime startedAtUtc,
    required DateTime endedAtUtc,
    required List<Map<String, dynamic>> participants,
    List<Map<String, dynamic>>? answers,
    String status = 'Completed', // "Completed" | "Aborted"
  }) async {
    return await _http.postJson(
      '/matches/submit',
      body: {
        'eventId': _uuid.v4(),
        'matchId': matchId,
        'mode': mode,
        'category': category,
        'questionCount': questionCount,
        'startedAtUtc': startedAtUtc.toUtc().toIso8601String(),
        'endedAtUtc': endedAtUtc.toUtc().toIso8601String(),
        'status': status,
        'participants': participants,
        if (answers != null) 'answers': answers,
      },
    );
  }

  // ========================================
  // Seasons
  // ========================================

  Future<SeasonDto> getActiveSeason() async {
    final j = await _http.getJson('/seasons/active');
    return SeasonDto.fromJson(j);
  }

  Future<PlayerSeasonStateDto> getPlayerSeasonState({
    required String playerId,
  }) async {
    final j = await _http.getJson('/seasons/state/$playerId');
    return PlayerSeasonStateDto.fromJson(j);
  }

  // ========================================
  // Skills
  // ========================================

  Future<SkillTreeDto> getSkillTree({required String playerId}) async {
    final j =
        await _http.getJson('/skills/tree', query: {'playerId': playerId});
    return SkillTreeDto.fromJson(j);
  }

  /// Unlocks skill node [nodeId] for [playerId].
  /// Backend contract: POST /skills/unlock with UnlockSkillRequest
  /// {eventId, playerId, nodeKey}; eventId is an idempotency key.
  Future<void> unlockSkillNode({
    required String playerId,
    required String nodeId,
  }) async {
    await _http.postJson(
      '/skills/unlock',
      body: {
        'eventId': _uuid.v4(),
        'playerId': playerId,
        'nodeKey': nodeId,
      },
    );
  }

  /// Resets all unlocked nodes for [playerId] and refunds spent points.
  /// refundPercent mirrors the client-side respec, which refunds 100%.
  Future<void> respecSkillTree({required String playerId}) async {
    await _http.postJson(
      '/skills/respec',
      body: {
        'eventId': _uuid.v4(),
        'playerId': playerId,
        'refundPercent': 100,
      },
    );
  }

  /// Records that [playerId] activated the active skill [nodeId].
  /// Backend contract: POST /skills/use with UseSkillRequest
  /// {eventId, playerId, nodeKey}; eventId is an idempotency key.
  Future<void> useSkillNode({
    required String playerId,
    required String nodeId,
  }) async {
    await _http.postJson(
      '/skills/use',
      body: {
        'eventId': _uuid.v4(),
        'playerId': playerId,
        'nodeKey': nodeId,
      },
    );
  }

  // ========================================
  // Game Events
  // ========================================

  Future<List<GameEventDto>> getUpcomingGameEvents() async {
    final data = await _http.getJsonList('/game-events/upcoming');
    return data
        .cast<Map<String, dynamic>>()
        .map(GameEventDto.fromJson)
        .toList();
  }

  Future<GameEventDto> getGameEventStatus({
    required String gameEventId,
  }) async {
    final j = await _http.getJson('/game-events/$gameEventId');
    return GameEventDto.fromJson(j);
  }

  Future<void> enterGameEvent({
    required String gameEventId,
    required String playerId,
  }) async {
    await _http.postJson(
      '/game-events/enter',
      body: {'gameEventId': gameEventId, 'playerId': playerId},
    );
  }

  Future<void> reviveInGameEvent({
    required String gameEventId,
    required String playerId,
  }) async {
    await _http.postJson(
      '/game-events/revive',
      body: {'gameEventId': gameEventId, 'playerId': playerId},
    );
  }

  Future<List<GameEventLeaderboardEntryDto>> getGameEventLeaderboard({
    required String gameEventId,
  }) async {
    final data =
        await _http.getJsonList('/game-events/$gameEventId/leaderboard');
    return data
        .cast<Map<String, dynamic>>()
        .map(GameEventLeaderboardEntryDto.fromJson)
        .toList();
  }

  Future<List<GameEventLeaderboardEntryDto>> getGameEventSeasonLeaderboard({
    required String seasonId,
    String? sortBy,
  }) async {
    final data = await _http.getJsonList(
      '/game-events/season-leaderboard',
      query: {
        'seasonId': seasonId,
        if (sortBy != null) 'sortBy': sortBy,
      },
    );
    return data
        .cast<Map<String, dynamic>>()
        .map(GameEventLeaderboardEntryDto.fromJson)
        .toList();
  }

  // ========================================
  // Guardians
  // ========================================

  /// Backend: GET /guardians/{tierNumber}?seasonId=
  Future<List<GuardianDto>> getGuardians({
    required String seasonId,
    required int tierNumber,
  }) async {
    final data = await _http
        .getJsonList('/guardians/$tierNumber', query: {'seasonId': seasonId});
    return data.cast<Map<String, dynamic>>().map(GuardianDto.fromJson).toList();
  }

  /// Returns the matchId for the created guardian challenge match.
  /// Backend: POST /guardians/challenge with ChallengeGuardianRequest
  /// {eventId, seasonId, tierNumber, challengerId, guardianId}; guardianId is
  /// the guardian *player's* id, eventId an idempotency key.
  Future<String> challengeGuardian({
    required String seasonId,
    required int tierNumber,
    required String guardianId,
    required String playerId,
  }) async {
    final j = await _http.postJson(
      '/guardians/challenge',
      body: {
        'eventId': _uuid.v4(),
        'seasonId': seasonId,
        'tierNumber': tierNumber,
        'challengerId': playerId,
        'guardianId': guardianId,
      },
    );
    return j['matchId'] as String;
  }

  /// Backend: GET /guardians/my/{playerId}?seasonId=
  Future<MyGuardianStatusDto> getMyGuardianStatus({
    required String playerId,
    String? seasonId,
  }) async {
    final j = await _http.getJson(
      '/guardians/my/$playerId',
      query: {if (seasonId != null) 'seasonId': seasonId},
    );
    return MyGuardianStatusDto.fromJson(j);
  }

  // ========================================
  // Territory
  // ========================================

  Future<TerritoryBoardDto> getTerritoryBoard({
    required String seasonId,
    required int tierNumber,
  }) async {
    final j = await _http.getJson('/territory/$seasonId/$tierNumber');
    return TerritoryBoardDto.fromJson(j);
  }

  /// Starts a duel for the tile owning [category].
  /// Backend: POST /territory/duel with StartTerritoryDuelRequest
  /// {eventId, seasonId, tierNumber, category, challengerId} — territory tiles
  /// are keyed by quiz category, not tile ids.
  Future<DuelResultDto> startTerritoryDuel({
    required String seasonId,
    required int tierNumber,
    required String category,
    required String playerId,
  }) async {
    final j = await _http.postJson(
      '/territory/duel',
      body: {
        'eventId': _uuid.v4(),
        'seasonId': seasonId,
        'tierNumber': tierNumber,
        'category': category,
        'challengerId': playerId,
      },
    );
    return DuelResultDto.fromJson(j);
  }

  /// Backend: GET /territory/{seasonId}/{tierNumber}/dominance?top=
  Future<List<TerritoryDominanceDto>> getTerritoryDominanceLeaderboard({
    required String seasonId,
    required int tierNumber,
    int top = 20,
  }) async {
    final data = await _http.getJsonList(
      '/territory/$seasonId/$tierNumber/dominance',
      query: {'top': top.toString()},
    );
    return data
        .cast<Map<String, dynamic>>()
        .map(TerritoryDominanceDto.fromJson)
        .toList();
  }

  /// Backend: GET /territory/multiplier/{seasonId}/{tierNumber}/{playerId}
  /// → {totalMultiplierBps}; converted here from basis points to a factor.
  Future<double> getPlayerTerritoryMultiplier({
    required String seasonId,
    required int tierNumber,
    required String playerId,
  }) async {
    final j = await _http.getJson(
      '/territory/multiplier/$seasonId/$tierNumber/$playerId',
    );
    return ((j['totalMultiplierBps'] as num?) ?? 10000) / 10000.0;
  }

  // ========================================
  // Votes
  // ========================================

  Future<void> castVote({
    required String topic,
    required String choice,
    required String playerId,
  }) async {
    await _http.postJson(
      '/votes',
      body: {'topic': topic, 'choice': choice, 'playerId': playerId},
    );
  }

  Future<VoteResultDto> getVoteResults({required String topic}) async {
    final j = await _http.getJson('/votes/$topic/results');
    return VoteResultDto.fromJson(j);
  }

  // ========================================
  // Utility
  // ========================================

  /// Health check
  Future<bool> healthCheck() async {
    final apiRoot = _http.baseUrl.replaceFirst(RegExp(r'/api/v1/?$'), '');
    final urls = <String>[
      if (_healthCheckUrl != null && _healthCheckUrl!.trim().isNotEmpty)
        _healthCheckUrl!.trim(),
      '$apiRoot/healthz',
      '$apiRoot/health/readiness',
      '$apiRoot/health/liveness',
      '${_http.baseUrl}/health',
    ];

    for (final url in urls.toSet()) {
      try {
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 200) return true;
      } catch (_) {
        // Try the next configured/fallback health endpoint.
      }
    }

    return false;
  }

  // ========================================
  // Economy  (GET/POST /mobile/economy/*)
  // ========================================

  /// GET /mobile/economy/state
  Future<EconomyStateDto> getEconomyState({required String playerId}) async {
    final j = await _http.getJson(
      '/mobile/economy/state',
      query: {'playerId': playerId},
    );
    return EconomyStateDto.fromJson(j);
  }

  /// POST /mobile/economy/session/start
  Future<SessionStartDto> startEconomySession(
      {required String playerId}) async {
    final j = await _http.postJson(
      '/mobile/economy/session/start',
      query: {'playerId': playerId},
    );
    return SessionStartDto.fromJson(j);
  }

  /// POST /mobile/economy/daily-jackpot-ticket/claim
  Future<DailyTicketClaimDto> claimDailyJackpotTicket(
      {required String playerId}) async {
    final j = await _http.postJson(
      '/mobile/economy/daily-jackpot-ticket/claim',
      query: {'playerId': playerId},
    );
    return DailyTicketClaimDto.fromJson(j);
  }

  /// POST /mobile/economy/revive/quote
  Future<ReviveQuoteDto> getReviveQuote(
      {required String playerId, required bool almostWin}) async {
    final j = await _http.postJson(
      '/mobile/economy/revive/quote',
      query: {'playerId': playerId, 'almostWin': almostWin.toString()},
    );
    return ReviveQuoteDto.fromJson(j);
  }

  /// POST /mobile/economy/pity/report-loss
  Future<PityResponseDto> reportPityLoss({required String playerId}) async {
    final j = await _http.postJson(
      '/mobile/economy/pity/report-loss',
      query: {'playerId': playerId},
    );
    return PityResponseDto.fromJson(j);
  }

  /// POST /mobile/economy/pity/report-win
  Future<PityResponseDto> reportPityWin({required String playerId}) async {
    final j = await _http.postJson(
      '/mobile/economy/pity/report-win',
      query: {'playerId': playerId},
    );
    return PityResponseDto.fromJson(j);
  }

  /// POST /mobile/matches/start — policy-enforced.
  /// Returns [MatchStartResultDto] with started=false + denyReason on 409 CONFLICT.
  Future<MatchStartResultDto> startPolicyMatch({
    required String playerId,
    required String mode,
    Map<String, dynamic>? settings,
  }) async {
    try {
      final j = await _http.postJson(
        '/mobile/matches/start',
        body: {
          'playerId': playerId,
          'mode': mode,
          if (settings != null) ...settings,
        },
      );
      return MatchStartResultDto(
        started: true,
        matchId: j['matchId'] as String?,
      );
    } on HttpException catch (e) {
      if (e.statusCode == 409) {
        return MatchStartResultDto(
          started: false,
          denyReason: e.message,
        );
      }
      rethrow;
    }
  }

  // ========================================
  // PERSONALIZATION
  // ========================================

  /// GET /personalization/profile/{playerId}
  Future<PlayerMindProfileDto> getPlayerMindProfile(
      {required String playerId}) async {
    final j = await _http.getJson('/personalization/profile/$playerId');
    return PlayerMindProfileDto.fromJson(j);
  }

  /// GET /personalization/home/{playerId}
  Future<PlayerHomePersonalizationDto> getHomePersonalization(
      {required String playerId}) async {
    final j = await _http.getJson('/personalization/home/$playerId');
    return PlayerHomePersonalizationDto.fromJson(j);
  }

  /// POST /personalization/profile/{playerId}/event — fire-and-forget
  /// behaviour event.
  Future<void> recordBehaviourEvent({
    required String playerId,
    required BehaviourEventDto event,
  }) async {
    await _http.post('/personalization/profile/$playerId/event',
        body: event.toJson());
  }

  /// GET /personalization/recommendations/{playerId}
  Future<List<PlayerRecommendationDto>> getRecommendations(
      {required String playerId}) async {
    final data =
        await _http.getJsonList('/personalization/recommendations/$playerId');
    return data
        .whereType<Map<String, dynamic>>()
        .map(PlayerRecommendationDto.fromJson)
        .toList();
  }

  /// POST /personalization/profile/{playerId}/toggle
  /// Returns the updated PlayerMindProfile's personalizationEnabled flag.
  Future<bool> togglePersonalization(
      {required String playerId, required bool enabled}) async {
    final j = await _http.postJson(
      '/personalization/profile/$playerId/toggle',
      body: {'enabled': enabled},
    );
    return j['personalizationEnabled'] as bool? ?? enabled;
  }

  /// GET /coach/{playerId}/daily-brief
  Future<CoachBriefDto> getDailyBrief({required String playerId}) async {
    final j = await _http.getJson('/coach/$playerId/daily-brief');
    return CoachBriefDto.fromJson(j);
  }

  /// POST /coach/{playerId}/feedback
  /// [feedback] is one of: "engage", "dismiss", "helpful", "not_helpful"
  Future<void> postCoachFeedback({
    required String playerId,
    required String briefId,
    required String feedback,
  }) async {
    await _http.post('/coach/$playerId/feedback', body: {
      'briefId': briefId,
      'feedback': feedback,
    });
  }

  // ========================================
  // A/B EXPERIMENTS
  // ========================================

  /// GET /experiments/player/{playerId} — bootstrap all assignments at session start.
  Future<PlayerExperimentsDto> getPlayerExperiments(
      {required String playerId}) async {
    final j = await _http.getJson('/experiments/player/$playerId');
    return PlayerExperimentsDto.fromJson(j);
  }

  /// GET /experiments/player/{playerId}/{experimentKey}
  Future<SingleExperimentResultDto> getPlayerExperiment({
    required String playerId,
    required String experimentKey,
  }) async {
    final j =
        await _http.getJson('/experiments/player/$playerId/$experimentKey');
    return SingleExperimentResultDto.fromJson(j);
  }

  /// POST /experiments/player/{playerId}/{experimentKey}/impression
  Future<void> recordExperimentImpression({
    required String playerId,
    required String experimentKey,
  }) async {
    await _http.post('/experiments/player/$playerId/$experimentKey/impression');
  }

  /// POST /experiments/player/{playerId}/{experimentKey}/outcome
  Future<void> recordExperimentOutcome({
    required String playerId,
    required String experimentKey,
  }) async {
    await _http.post('/experiments/player/$playerId/$experimentKey/outcome');
  }

  // ========================================
  // Powerups  (GET/POST /powerups/*)
  // ========================================

  /// GET /powerups/state/{playerId} — current powerup balances + cooldowns.
  Future<PowerupStateDto> getPowerupState({required String playerId}) async {
    final j = await _http.getJson('/powerups/state/$playerId');
    return PowerupStateDto.fromJson(j);
  }

  /// POST /powerups/use — consume one powerup of [type] within game [eventId].
  ///
  /// [eventId] ties the use to a specific match/game event and acts as the
  /// idempotency key; the result `status` is one of
  /// `Used | Duplicate | Insufficient | Cooldown`.
  Future<UsePowerupResultDto> usePowerup({
    required String eventId,
    required String playerId,
    required PowerupType type,
  }) async {
    final j = await _http.postJson(
      '/powerups/use',
      body: {
        'eventId': eventId,
        'playerId': playerId,
        'type': type.wire,
      },
    );
    return UsePowerupResultDto.fromJson(j);
  }

  // ========================================
  // Season Rewards  (GET/POST /seasons/rewards/*)
  // ========================================

  /// GET /seasons/rewards/eligibility/{playerId} — claimable reward + state.
  Future<RewardEligibilityDto> getSeasonRewardEligibility({
    required String playerId,
    String? seasonId,
  }) async {
    final j = await _http.getJson(
      '/seasons/rewards/eligibility/$playerId',
      query: {if (seasonId != null) 'seasonId': seasonId},
    );
    return RewardEligibilityDto.fromJson(j);
  }

  /// POST /seasons/rewards/claim/{playerId} — claim the player's season reward.
  ///
  /// [eventId] is the idempotency key (reuse the same value across retries);
  /// the result `status` is one of `Applied | Duplicate | NotEligible`.
  Future<ClaimSeasonRewardResultDto> claimSeasonReward({
    required String playerId,
    required String eventId,
    String? seasonId,
  }) async {
    final j = await _http.postJson(
      '/seasons/rewards/claim/$playerId',
      body: {
        'eventId': eventId,
        if (seasonId != null) 'seasonId': seasonId,
      },
    );
    return ClaimSeasonRewardResultDto.fromJson(j);
  }

  // ========================================
  // Party / Group Play  (/party/*)
  // ========================================
  // NOTE: gated server-side behind the `social_enabled` feature flag; calls
  // return 403 when disabled. Real-time party events arrive on MatchHub.

  /// POST /party — create a party led by [leaderPlayerId].
  Future<PartyRosterDto> createParty({required String leaderPlayerId}) async {
    final j = await _http.postJson(
      '/party',
      body: {'leaderPlayerId': leaderPlayerId},
    );
    return PartyRosterDto.fromJson(j);
  }

  /// GET /party/{partyId} — current roster.
  Future<PartyRosterDto> getPartyRoster(String partyId) async {
    final j = await _http.getJson('/party/$partyId');
    return PartyRosterDto.fromJson(j);
  }

  /// POST /party/{partyId}/invite — invite [toPlayerId] to the party.
  Future<PartyInviteDto> inviteToParty({
    required String partyId,
    required String fromPlayerId,
    required String toPlayerId,
  }) async {
    final j = await _http.postJson(
      '/party/$partyId/invite',
      body: {'fromPlayerId': fromPlayerId, 'toPlayerId': toPlayerId},
    );
    return PartyInviteDto.fromJson(j);
  }

  /// POST /party/invites/{inviteId}/accept
  Future<PartyInviteDto> acceptPartyInvite({
    required String inviteId,
    required String playerId,
  }) async {
    final j = await _http.postJson(
      '/party/invites/$inviteId/accept',
      body: {'playerId': playerId},
    );
    return PartyInviteDto.fromJson(j);
  }

  /// POST /party/invites/{inviteId}/decline
  Future<PartyInviteDto> declinePartyInvite({
    required String inviteId,
    required String playerId,
  }) async {
    final j = await _http.postJson(
      '/party/invites/$inviteId/decline',
      body: {'playerId': playerId},
    );
    return PartyInviteDto.fromJson(j);
  }

  /// POST /party/{partyId}/leave
  Future<void> leaveParty({
    required String partyId,
    required String playerId,
  }) async {
    await _http.post(
      '/party/$partyId/leave',
      body: {'playerId': playerId},
    );
  }

  /// GET /party/invites — invites for [playerId].
  /// [box] is `incoming` | `outgoing` | `all`.
  Future<PartyInvitesListDto> listPartyInvites({
    required String playerId,
    String box = 'incoming',
    int page = 1,
    int pageSize = 50,
  }) async {
    final j = await _http.getJson(
      '/party/invites',
      query: {
        'playerId': playerId,
        'box': box,
        'page': page.toString(),
        'pageSize': pageSize.toString(),
      },
    );
    return PartyInvitesListDto.fromJson(j);
  }

  /// POST /party/{partyId}/enqueue — enter matchmaking as a party.
  Future<PartyEnqueueResultDto> enqueueParty({
    required String partyId,
    required String leaderPlayerId,
    required String mode,
    required int tier,
  }) async {
    final j = await _http.postJson(
      '/party/$partyId/enqueue',
      body: {'leaderPlayerId': leaderPlayerId, 'mode': mode, 'tier': tier},
    );
    return PartyEnqueueResultDto.fromJson(j);
  }

  /// POST /party/{partyId}/queue/cancel
  Future<void> cancelPartyQueue({
    required String partyId,
    required String leaderPlayerId,
  }) async {
    await _http.post(
      '/party/$partyId/queue/cancel',
      body: {'leaderPlayerId': leaderPlayerId},
    );
  }

  /// Close HTTP client
  void dispose() {
    _http.close();
  }
}
