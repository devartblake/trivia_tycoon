import 'dart:convert';
import 'package:http/http.dart' as http;
import 'http_client.dart';
import '../dto/player_dto.dart';
import '../dto/season_dto.dart';
import '../dto/skill_dto.dart';
import '../dto/game_event_dto.dart';
import '../dto/guardian_dto.dart';
import '../dto/territory_dto.dart';
import '../dto/vote_dto.dart';

/// API client for Trivia Tycoon backend
///
/// Provides high-level methods for common API operations with
/// automatic authentication and error handling.
class TycoonApiClient {
  final HttpClient _http;

  TycoonApiClient({required HttpClient httpClient}) : _http = httpClient;

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

  /// Fetch quiz questions
  Future<List<Map<String, dynamic>>> getQuizQuestions({
    required int amount,
    String? category,
    String? difficulty,
  }) async {
    final questions = await _http.getJsonList(
      '/quiz/play',
      query: {
        'amount': amount.toString(),
        if (category != null) 'category': category,
        if (difficulty != null) 'difficulty': difficulty,
      },
    );

    return questions.cast<Map<String, dynamic>>();
  }

  /// Submit quiz results
  Future<Map<String, dynamic>> submitQuizResults({
    required String quizId,
    required List<Map<String, dynamic>> answers,
    required int score,
    required int totalQuestions,
  }) async {
    return await _http.postJson(
      '/quiz/submit',
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

  /// Get global leaderboard
  Future<List<Map<String, dynamic>>> getLeaderboard({
    int limit = 100,
    int offset = 0,
    String? category,
  }) async {
    final data = await _http.getJsonList(
      '/leaderboard',
      query: {
        'limit': limit.toString(),
        'offset': offset.toString(),
        if (category != null) 'category': category,
      },
    );

    return data.cast<Map<String, dynamic>>();
  }

  /// Get user rank
  Future<Map<String, dynamic>> getUserRank(String userId) async {
    return await _http.getJson('/leaderboard/user/$userId');
  }

  // ========================================
  // User Profile
  // ========================================

  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile(String userId) async {
    return await _http.getJson('/users/$userId');
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateUserProfile({
    required String userId,
    Map<String, dynamic>? updates,
  }) async {
    return await _http.patchJson(
      '/users/$userId',
      body: updates,
    );
  }

  // ========================================
  // Achievements
  // ========================================

  /// Get user achievements
  Future<List<Map<String, dynamic>>> getUserAchievements(String userId) async {
    final data = await _http.getJsonList('/users/$userId/achievements');
    return data.cast<Map<String, dynamic>>();
  }

  /// Unlock achievement
  Future<Map<String, dynamic>> unlockAchievement({
    required String userId,
    required String achievementId,
  }) async {
    return await _http.postJson(
      '/users/$userId/achievements/$achievementId',
    );
  }

  // ========================================
  // Friends/Social
  // ========================================

  /// Get user's friends
  Future<List<Map<String, dynamic>>> getFriends(String userId) async {
    final data = await _http.getJsonList('/users/$userId/friends');
    return data.cast<Map<String, dynamic>>();
  }

  /// Send friend request
  Future<Map<String, dynamic>> sendFriendRequest({
    required String userId,
    required String targetUserId,
  }) async {
    return await _http.postJson(
      '/users/$userId/friends/request',
      body: {'targetUserId': targetUserId},
    );
  }

  /// Accept friend request
  Future<Map<String, dynamic>> acceptFriendRequest({
    required String userId,
    required String requestId,
  }) async {
    return await _http.postJson(
      '/users/$userId/friends/accept',
      body: {'requestId': requestId},
    );
  }

  // ========================================
  // Matches/PvP
  // ========================================

  /// Create match
  Future<Map<String, dynamic>> createMatch({
    required String userId,
    required String mode,
    Map<String, dynamic>? settings,
  }) async {
    return await _http.postJson(
      '/matches',
      body: {
        'userId': userId,
        'mode': mode,
        if (settings != null) 'settings': settings,
      },
    );
  }

  /// Join match
  Future<Map<String, dynamic>> joinMatch({
    required String matchId,
    required String userId,
  }) async {
    return await _http.postJson(
      '/matches/$matchId/join',
      body: {'userId': userId},
    );
  }

  /// Leave match
  Future<void> leaveMatch({
    required String matchId,
    required String userId,
  }) async {
    await _http.post(
      '/matches/$matchId/leave',
      body: {'userId': userId},
    );
  }

  /// Get match details
  Future<Map<String, dynamic>> getMatch(String matchId) async {
    return await _http.getJson('/matches/$matchId');
  }

  // ========================================
  // Store/Shop
  // ========================================

  /// Get store items
  Future<List<Map<String, dynamic>>> getStoreItems({
    String? category,
  }) async {
    final data = await _http.getJsonList(
      '/store/items',
      query: {
        if (category != null) 'category': category,
      },
    );

    return data.cast<Map<String, dynamic>>();
  }

  /// Purchase item
  Future<Map<String, dynamic>> purchaseItem({
    required String userId,
    required String itemId,
    int quantity = 1,
  }) async {
    return await _http.postJson(
      '/store/purchase',
      body: {
        'userId': userId,
        'itemId': itemId,
        'quantity': quantity,
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

  /// Get current season
  Future<Map<String, dynamic>> getCurrentSeason() async {
    return await _http.getJson('/seasons/current');
  }

  /// Get season leaderboard
  Future<List<Map<String, dynamic>>> getSeasonLeaderboard({
    required String seasonId,
    int limit = 100,
    int offset = 0,
  }) async {
    final data = await _http.getJsonList(
      '/seasons/$seasonId/leaderboard',
      query: {
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );

    return data.cast<Map<String, dynamic>>();
  }

  // ========================================
  // Admin (if user has admin role)
  // ========================================

  /// Get admin stats
  Future<Map<String, dynamic>> getAdminStats() async {
    return await _http.getJson('/admin/stats');
  }

  /// Ban user
  Future<void> banUser({
    required String userId,
    required String reason,
    DateTime? until,
  }) async {
    await _http.post(
      '/admin/users/$userId/ban',
      body: {
        'reason': reason,
        if (until != null) 'until': until.toIso8601String(),
      },
    );
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

  Future<void> joinMatchmakingQueue({
    required String playerId,
    required String mode,
  }) async {
    await _http.postJson(
      '/matchmaking/queue',
      body: {'playerId': playerId, 'mode': mode},
    );
  }

  Future<void> cancelMatchmakingQueue({required String playerId}) async {
    await _http.deleteJson('/matchmaking/queue/$playerId');
  }

  // ========================================
  // Matches — list
  // ========================================

  Future<List<Map<String, dynamic>>> listMatches({
    required String playerId,
    int limit = 20,
    int offset = 0,
  }) async {
    final data = await _http.getJsonList(
      '/matches',
      query: {
        'playerId': playerId,
        'limit': limit.toString(),
        'offset': offset.toString(),
      },
    );
    return data.cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> submitMatch({
    required String matchId,
    required String playerId,
    required List<Map<String, dynamic>> answers,
    required int score,
  }) async {
    return await _http.postJson(
      '/matches/$matchId/submit',
      body: {'playerId': playerId, 'answers': answers, 'score': score},
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
    final j = await _http.getJson('/seasons/player-state/$playerId');
    return PlayerSeasonStateDto.fromJson(j);
  }

  // ========================================
  // Skills
  // ========================================

  Future<SkillTreeDto> getSkillTree({required String playerId}) async {
    final j = await _http.getJson('/skills/tree', query: {'playerId': playerId});
    return SkillTreeDto.fromJson(j);
  }

  Future<SkillNodeDto> unlockSkillNode({
    required String playerId,
    required String nodeId,
  }) async {
    final j = await _http.postJson(
      '/skills/$nodeId/unlock',
      body: {'playerId': playerId},
    );
    return SkillNodeDto.fromJson(j);
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
    final j = await _http.getJson('/game-events/$gameEventId/status');
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

  Future<List<GuardianDto>> getGuardians({
    required String seasonId,
    required int tierNumber,
  }) async {
    final data =
        await _http.getJsonList('/guardians/$seasonId/$tierNumber');
    return data.cast<Map<String, dynamic>>().map(GuardianDto.fromJson).toList();
  }

  /// Returns the matchId for the created guardian challenge match.
  Future<String> challengeGuardian({
    required String guardianId,
    required String playerId,
  }) async {
    final j = await _http.postJson(
      '/guardians/challenge',
      body: {'guardianId': guardianId, 'playerId': playerId},
    );
    return j['matchId'] as String;
  }

  Future<MyGuardianStatusDto> getMyGuardianStatus({
    required String playerId,
  }) async {
    final j = await _http.getJson('/guardians/my', query: {'playerId': playerId});
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

  /// Returns a [DuelResultDto] containing the matchId and the challenged tileId.
  Future<DuelResultDto> startTerritoryDuel({
    required String seasonId,
    required int tierNumber,
    required String tileId,
    required String playerId,
  }) async {
    final j = await _http.postJson(
      '/territory/duel',
      body: {
        'seasonId': seasonId,
        'tierNumber': tierNumber,
        'tileId': tileId,
        'playerId': playerId,
      },
    );
    return DuelResultDto.fromJson(j);
  }

  Future<List<TileDto>> getTerritoryDominanceLeaderboard({
    required String seasonId,
    required int tierNumber,
  }) async {
    final data = await _http.getJsonList(
      '/territory/$seasonId/$tierNumber/dominance',
    );
    return data.cast<Map<String, dynamic>>().map(TileDto.fromJson).toList();
  }

  Future<double> getPlayerTerritoryMultiplier({
    required String seasonId,
    required int tierNumber,
    required String playerId,
  }) async {
    final j = await _http.getJson(
      '/territory/$seasonId/$tierNumber/multiplier',
      query: {'playerId': playerId},
    );
    return (j['multiplier'] as num?)?.toDouble() ?? 1.0;
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
    try {
      final response = await _http.get('/health');
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Close HTTP client
  void dispose() {
    _http.close();
  }
}