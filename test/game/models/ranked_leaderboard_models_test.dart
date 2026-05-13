import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/ranked_leaderboard_models.dart';

Map<String, dynamic> _entryJson({
  String playerId = 'p1',
  int seasonRank = 1,
  int tier = 2,
  int tierRank = 5,
  int rankPoints = 1200,
  int wins = 10,
  int losses = 3,
  int draws = 1,
  int matchesPlayed = 14,
}) =>
    {
      'playerId': playerId,
      'seasonRank': seasonRank,
      'tier': tier,
      'tierRank': tierRank,
      'rankPoints': rankPoints,
      'wins': wins,
      'losses': losses,
      'draws': draws,
      'matchesPlayed': matchesPlayed,
    };

void main() {
  // -------------------------------------------------------------------------
  // RankedLeaderboardEntry.fromJson
  // -------------------------------------------------------------------------

  group('RankedLeaderboardEntry.fromJson', () {
    test('parses playerId', () {
      expect(
          RankedLeaderboardEntry.fromJson(_entryJson(playerId: 'uid_x'))
              .playerId,
          'uid_x');
    });

    test('parses seasonRank', () {
      expect(
          RankedLeaderboardEntry.fromJson(_entryJson(seasonRank: 42))
              .seasonRank,
          42);
    });

    test('parses tier', () {
      expect(RankedLeaderboardEntry.fromJson(_entryJson(tier: 3)).tier, 3);
    });

    test('parses tierRank', () {
      expect(
          RankedLeaderboardEntry.fromJson(_entryJson(tierRank: 12)).tierRank,
          12);
    });

    test('parses rankPoints', () {
      expect(
          RankedLeaderboardEntry.fromJson(_entryJson(rankPoints: 2500))
              .rankPoints,
          2500);
    });

    test('parses wins', () {
      expect(RankedLeaderboardEntry.fromJson(_entryJson(wins: 25)).wins, 25);
    });

    test('parses losses', () {
      expect(
          RankedLeaderboardEntry.fromJson(_entryJson(losses: 7)).losses, 7);
    });

    test('parses draws', () {
      expect(RankedLeaderboardEntry.fromJson(_entryJson(draws: 3)).draws, 3);
    });

    test('parses matchesPlayed', () {
      expect(
          RankedLeaderboardEntry.fromJson(_entryJson(matchesPlayed: 35))
              .matchesPlayed,
          35);
    });
  });

  // -------------------------------------------------------------------------
  // RankedLeaderboardResponse.fromJson
  // -------------------------------------------------------------------------

  group('RankedLeaderboardResponse.fromJson', () {
    Map<String, dynamic> _responseJson({
      String seasonId = 's2025',
      int page = 1,
      int pageSize = 10,
      int total = 100,
      List<Map<String, dynamic>>? items,
    }) =>
        {
          'seasonId': seasonId,
          'page': page,
          'pageSize': pageSize,
          'total': total,
          'items': items ?? [_entryJson()],
        };

    test('parses seasonId', () {
      final resp = RankedLeaderboardResponse.fromJson(
          _responseJson(seasonId: 'season_7'));
      expect(resp.seasonId, 'season_7');
    });

    test('parses page', () {
      expect(
          RankedLeaderboardResponse.fromJson(_responseJson(page: 3)).page, 3);
    });

    test('parses pageSize', () {
      expect(
          RankedLeaderboardResponse.fromJson(_responseJson(pageSize: 25))
              .pageSize,
          25);
    });

    test('parses total', () {
      expect(
          RankedLeaderboardResponse.fromJson(_responseJson(total: 500)).total,
          500);
    });

    test('parses items list', () {
      final resp = RankedLeaderboardResponse.fromJson(
          _responseJson(items: [_entryJson(playerId: 'p1'), _entryJson(playerId: 'p2')]));
      expect(resp.items.length, 2);
    });

    test('item fields parsed correctly', () {
      final resp = RankedLeaderboardResponse.fromJson(
          _responseJson(items: [_entryJson(playerId: 'top_player', seasonRank: 1)]));
      expect(resp.items.first.playerId, 'top_player');
      expect(resp.items.first.seasonRank, 1);
    });

    test('empty items list', () {
      final resp = RankedLeaderboardResponse.fromJson(
          _responseJson(items: []));
      expect(resp.items, isEmpty);
    });
  });
}
