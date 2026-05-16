import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/game/services/leaderboard_service.dart';

// ---------------------------------------------------------------------------
// Stub
// ---------------------------------------------------------------------------

class _StubApiService extends ApiService {
  final List<Map<String, dynamic>> _entries;
  final bool _shouldThrow;

  _StubApiService({
    List<Map<String, dynamic>>? entries,
    bool shouldThrow = false,
  })  : _entries = entries ?? [],
        _shouldThrow = shouldThrow,
        super(
          baseUrl: 'http://test.invalid',
          dio: Dio(),
          initializeCache: false,
        );

  @override
  Future<List<Map<String, dynamic>>> fetchLeaderboard({int limit = 100}) async {
    if (_shouldThrow) throw Exception('network error');
    return _entries;
  }

  @override
  Future<void> submitScore(String playerName, int score) async {
    if (_shouldThrow) throw Exception('network error');
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _leaderboardJson({
  int userId = 1,
  String playerName = 'Alice',
  int score = 500,
  int rank = 1,
}) {
  final now = DateTime(2026, 1, 1).toIso8601String();
  return {
    'user_id': userId,
    'playerName': playerName,
    'score': score,
    'rank': rank,
    'tier': 1,
    'tierRank': 1,
    'isPromotionEligible': false,
    'isRewardEligible': false,
    'wins': 0,
    'country': 'US',
    'state': 'CA',
    'countryCode': 'US',
    'level': 1,
    'badges': '',
    'xpProgress': 0.0,
    'timeframe': 'daily',
    'avatar': '',
    'last_active': now,
    'timestamp': now,
    'gender': 'other',
    'ageGroup': 'teens',
    'joinedDate': now,
    'streak': 0,
    'accuracy': 0.0,
    'favoriteCategory': 'Science',
    'title': '',
    'status': 'active',
    'device': 'mobile',
    'language': 'en',
    'sessionLength': 0.0,
    'lastQuestionCategory': 'Science',
    'interests': <String>[],
    'emailVerified': false,
    'accountStatus': 'active',
    'timezone': 'UTC',
    'powerUps': <String>[],
    'lastDeviceType': 'mobile',
    'preferredNotificationMethod': 'push',
    'subscriptionStatus': 'free',
    'averageAnswerTime': 0.0,
    'isBot': false,
    'accountAgeDays': 0.0,
    'engagementScore': 0.0,
  };
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // fetchLeaderboard
  // -------------------------------------------------------------------------

  group('LeaderboardService.fetchLeaderboard', () {
    test('returns parsed LeaderboardEntry list on success', () async {
      final api = _StubApiService(entries: [
        _leaderboardJson(userId: 1, playerName: 'Alice', score: 900, rank: 1),
        _leaderboardJson(userId: 2, playerName: 'Bob', score: 800, rank: 2),
      ]);
      final svc = LeaderboardService(apiService: api);
      final entries = await svc.fetchLeaderboard();
      expect(entries.length, 2);
      expect(entries[0].playerName, 'Alice');
      expect(entries[0].score, 900);
      expect(entries[1].playerName, 'Bob');
      expect(entries[1].rank, 2);
    });

    test('returns empty list when api returns no entries', () async {
      final svc = LeaderboardService(apiService: _StubApiService());
      expect(await svc.fetchLeaderboard(), isEmpty);
    });

    test('returns empty list when api throws', () async {
      final svc = LeaderboardService(
        apiService: _StubApiService(shouldThrow: true),
      );
      expect(await svc.fetchLeaderboard(), isEmpty);
    });

    test('non-default limit is accepted without error', () async {
      final svc = LeaderboardService(
        apiService: _StubApiService(entries: [
          _leaderboardJson(playerName: 'X', rank: 1),
        ]),
      );
      final entries = await svc.fetchLeaderboard(limit: 25);
      expect(entries.length, 1);
    });

    test('parses userId correctly', () async {
      final svc = LeaderboardService(
        apiService: _StubApiService(entries: [_leaderboardJson(userId: 42)]),
      );
      final entries = await svc.fetchLeaderboard();
      expect(entries.first.userId, 42);
    });
  });

  // -------------------------------------------------------------------------
  // submitScore
  // -------------------------------------------------------------------------

  group('LeaderboardService.submitScore', () {
    test('completes without error on success', () async {
      final svc = LeaderboardService(apiService: _StubApiService());
      await expectLater(svc.submitScore('Alice', 1000), completes);
    });

    test('swallows exception when api throws', () async {
      final svc = LeaderboardService(
        apiService: _StubApiService(shouldThrow: true),
      );
      await expectLater(svc.submitScore('Alice', 1000), completes);
    });
  });
}
