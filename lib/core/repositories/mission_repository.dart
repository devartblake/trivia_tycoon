import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Mission models currently live under lib/game/models.
// Keep this import stable to avoid breaking other call sites.
import '../../game/models/mission_model.dart';

/// ------------------------------------------------------------
/// Auth hook (so repo doesn’t depend on your whole auth stack)
/// You can wire this from your ServiceManager.
/// ------------------------------------------------------------
abstract class AccessTokenProvider {
  Future<String?> getAccessToken();
}

/// Mission repository abstraction.
///
/// IMPORTANT: Implementations should talk to the Synaptix
/// backend API (JWT-first) and optionally add local/offline fallbacks.
abstract class MissionRepository {
  Future<List<UserMission>> getUserMissions(String userId);
  Stream<List<UserMission>> watchUserMissions(String userId);

  Future<List<Mission>> getAvailableMissions(MissionType? type);
  Future<UserMission> assignMissionToUser(String userId, String missionId);
  Future<MissionClaimResult> claimMission({
    required String playerId,
    required String missionId,
    MissionType? type,
  });

  Future<UserMission> swapMission(String userMissionId);
  Future<UserMission> updateMissionProgress(
      String userMissionId, int newProgress);
  Future<void> recordMatchCompleted({
    required String eventId,
    required String playerId,
    required bool isWin,
    required int correctAnswers,
    required int totalQuestions,
    required int durationSeconds,
  });
  Future<void> recordRoundCompleted({
    required String eventId,
    required String playerId,
    required bool perfectRound,
    required int averageAnswerTimeMs,
  });

  Future<void> cleanupExpiredMissions();
}

/// JWT-first implementation backed by Synaptix backend.
/// Assumes ApiService is already configured with baseUrl.
/// You will add/confirm the actual endpoints on the backend during migration.
///
class MissionClaimResult {
  final String status;
  final String playerId;
  final String missionId;
  final int rewardXp;
  final int rewardCoins;
  final int rewardDiamonds;
  final bool completed;
  final bool claimed;
  final List<UserMission> updatedMissions;

  const MissionClaimResult({
    required this.status,
    required this.playerId,
    required this.missionId,
    required this.rewardXp,
    required this.rewardCoins,
    required this.rewardDiamonds,
    required this.completed,
    required this.claimed,
    required this.updatedMissions,
  });

  factory MissionClaimResult.fromJson(Map<String, dynamic> json) {
    final updated = json['updatedMissions'];
    return MissionClaimResult(
      status: (json['status'] ?? '').toString(),
      playerId: (json['playerId'] ?? '').toString(),
      missionId: (json['missionId'] ?? '').toString(),
      rewardXp: _asInt(json['rewardXp']),
      rewardCoins: _asInt(json['rewardCoins']),
      rewardDiamonds: _asInt(json['rewardDiamonds']),
      completed: json['completed'] == true,
      claimed: json['claimed'] == true,
      updatedMissions: updated is List
          ? updated
              .whereType<Map>()
              .map((e) => UserMission.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : const <UserMission>[],
    );
  }
}

int _asInt(Object? value) {
  if (value is num) return value.toInt();
  if (value == null) return 0;
  return int.tryParse(value.toString()) ?? 0;
}

class ApiMissionRepository implements MissionRepository {
  final String baseUrl;

  /// Optional: provide JWT access token when available.
  /// Returning null means "no auth header".
  final Future<String?> Function()? accessTokenProvider;

  /// Poll interval used by watchUserMissions().
  final Duration watchPollInterval;

  ApiMissionRepository({
    required this.baseUrl,
    this.accessTokenProvider,
    this.watchPollInterval = const Duration(seconds: 5),
  });

  // -------------------------
  // Route configuration
  // -------------------------
  // Confirmed backend routes in Synaptix.Backend.Api.Features.Missions.
  String _missions() => '/missions';
  String _claimMission(String missionId) => '/missions/$missionId/claim';
  String _matchCompleted() => '/missions/progress/match-completed';
  String _roundCompleted() => '/missions/progress/round-completed';
  // Not backend-confirmed yet. Kept for compatibility and local fallback paths.
  String _assignMission(String userId) => '/players/$userId/missions/assign';
  String _swapMission(String userMissionId) =>
      '/missions/user/$userMissionId/swap';
  String _updateProgress(String userMissionId) =>
      '/missions/user/$userMissionId/progress';
  String _cleanupExpired() => '/missions/cleanup-expired';

  Uri _uri(String path, [Map<String, String>? query]) {
    final cleanBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return Uri.parse('$cleanBase$cleanPath').replace(queryParameters: query);
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (accessTokenProvider != null) {
      final token = await accessTokenProvider!();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Never _httpError(Uri uri, int code, String body) {
    throw Exception('Mission API error [$code] ${uri.toString()}: $body');
  }

  dynamic _decodeBody(String body) {
    if (body.isEmpty) return null;
    return jsonDecode(body);
  }

  // -------------------------
  // MissionRepository impl
  // -------------------------

  @override
  Future<List<UserMission>> getUserMissions(String userId) async {
    final uri = _uri(_missions());
    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      _httpError(uri, res.statusCode, res.body);
    }

    final data = _decodeBody(res.body);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => UserMission.fromJson({
                ...Map<String, dynamic>.from(e),
                'playerId': userId,
              }))
          .toList();
    }

    // Some APIs wrap: { items: [...] }
    if (data is Map && data['items'] is List) {
      final items = data['items'] as List;
      return items
          .whereType<Map>()
          .map((e) => UserMission.fromJson({
                ...Map<String, dynamic>.from(e),
                'playerId': userId,
              }))
          .toList();
    }

    return <UserMission>[];
  }

  @override
  Stream<List<UserMission>> watchUserMissions(String userId) async* {
    // Simple polling stream (non-breaking).
    // Later you can replace with SignalR push without changing consumers.
    while (true) {
      yield await getUserMissions(userId);
      await Future.delayed(watchPollInterval);
    }
  }

  @override
  Future<List<Mission>> getAvailableMissions(MissionType? type) async {
    final query = <String, String>{};
    if (type != null) {
      query['type'] = _backendMissionType(type);
    }

    final uri = _uri(_missions(), query.isEmpty ? null : query);
    final res = await http.get(uri, headers: await _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      _httpError(uri, res.statusCode, res.body);
    }

    final data = _decodeBody(res.body);
    if (data is List) {
      return data
          .whereType<Map>()
          .map((e) => Mission.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    if (data is Map && data['items'] is List) {
      final items = data['items'] as List;
      return items
          .whereType<Map>()
          .map((e) => Mission.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    return <Mission>[];
  }

  @override
  Future<MissionClaimResult> claimMission({
    required String playerId,
    required String missionId,
    MissionType? type,
  }) async {
    final query = <String, String>{'playerId': playerId};
    if (type != null) {
      query['type'] = _backendMissionType(type);
    }

    final uri = _uri(_claimMission(missionId), query);
    final res = await http.post(uri, headers: await _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      _httpError(uri, res.statusCode, res.body);
    }

    final data = _decodeBody(res.body);
    if (data is Map) {
      return MissionClaimResult.fromJson(Map<String, dynamic>.from(data));
    }

    throw Exception('Unexpected response for claimMission: ${res.body}');
  }

  @override
  Future<UserMission> assignMissionToUser(
      String userId, String missionId) async {
    final uri = _uri(_assignMission(userId));
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({'missionId': missionId}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      _httpError(uri, res.statusCode, res.body);
    }

    final data = _decodeBody(res.body);
    if (data is Map<String, dynamic>) {
      return UserMission.fromJson(data);
    }

    throw Exception('Unexpected response for assignMissionToUser: ${res.body}');
  }

  @override
  Future<UserMission> swapMission(String userMissionId) async {
    final uri = _uri(_swapMission(userMissionId));
    final res = await http.post(uri, headers: await _headers());

    if (res.statusCode < 200 || res.statusCode >= 300) {
      _httpError(uri, res.statusCode, res.body);
    }

    final data = _decodeBody(res.body);
    if (data is Map<String, dynamic>) {
      return UserMission.fromJson(data);
    }

    throw Exception('Unexpected response for swapMission: ${res.body}');
  }

  @override
  Future<UserMission> updateMissionProgress(
      String userMissionId, int newProgress) async {
    final uri = _uri(_updateProgress(userMissionId));
    final res = await http.patch(
      uri,
      headers: await _headers(),
      body: jsonEncode({'progress': newProgress}),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      _httpError(uri, res.statusCode, res.body);
    }

    final data = _decodeBody(res.body);
    if (data is Map<String, dynamic>) {
      return UserMission.fromJson(data);
    }

    throw Exception(
        'Unexpected response for updateMissionProgress: ${res.body}');
  }

  @override
  Future<void> cleanupExpiredMissions() async {
    final uri = _uri(_cleanupExpired());

    // This endpoint may not exist yet; we keep it non-fatal for now.
    final res = await http.post(uri, headers: await _headers());

    // If backend doesn't implement it yet, don't break app flow.
    if (res.statusCode == 404) return;

    if (res.statusCode < 200 || res.statusCode >= 300) {
      _httpError(uri, res.statusCode, res.body);
    }
  }

  @override
  Future<void> recordMatchCompleted({
    required String eventId,
    required String playerId,
    required bool isWin,
    required int correctAnswers,
    required int totalQuestions,
    required int durationSeconds,
  }) async {
    final uri = _uri(_matchCompleted());
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'eventId': eventId,
        'playerId': playerId,
        'isWin': isWin,
        'correctAnswers': correctAnswers,
        'totalQuestions': totalQuestions,
        'durationSeconds': durationSeconds,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      _httpError(uri, res.statusCode, res.body);
    }
  }

  @override
  Future<void> recordRoundCompleted({
    required String eventId,
    required String playerId,
    required bool perfectRound,
    required int averageAnswerTimeMs,
  }) async {
    final uri = _uri(_roundCompleted());
    final res = await http.post(
      uri,
      headers: await _headers(),
      body: jsonEncode({
        'eventId': eventId,
        'playerId': playerId,
        'perfectRound': perfectRound,
        'avgAnswerTimeMs': averageAnswerTimeMs,
      }),
    );

    if (res.statusCode < 200 || res.statusCode >= 300) {
      _httpError(uri, res.statusCode, res.body);
    }
  }

  String _backendMissionType(MissionType type) {
    switch (type) {
      case MissionType.daily:
        return 'Daily';
      case MissionType.weekly:
        return 'Weekly';
      case MissionType.seasonal:
        return 'Seasonal';
      case MissionType.oneTime:
        return 'OneTime';
      default:
        return type.name;
    }
  }
}
