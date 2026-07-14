import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/dto/territory_dto.dart';
import 'package:synaptix/core/dto/hub_event_dto.dart';
import 'package:synaptix/core/dto/vote_dto.dart';

void main() {
  // -------------------------------------------------------------------------
  // TileDto
  // -------------------------------------------------------------------------

  group('TileDto', () {
    // Mirrors backend TerritoryTileDto: {category, ownerId, xpMultiplierBps}.
    test('fromJson parses category and converts bps to factor', () {
      final t = TileDto.fromJson(
          {'category': 'science', 'ownerId': 'p1', 'xpMultiplierBps': 15000});
      expect(t.category, 'science');
      expect(t.ownerId, 'p1');
      expect(t.xpMultiplier, 1.5);
    });

    test('fromJson ownerId null when absent', () {
      final t =
          TileDto.fromJson({'category': 'science', 'xpMultiplierBps': 10000});
      expect(t.ownerId, isNull);
    });

    test('fromJson xpMultiplier defaults 1.0 when bps absent', () {
      final t = TileDto.fromJson({'category': 'science'});
      expect(t.xpMultiplier, 1.0);
    });

    test('toJson round-trips multiplier back to basis points', () {
      final j = TileDto.fromJson({'category': 'arts', 'xpMultiplierBps': 12500})
          .toJson();
      for (final key in ['category', 'ownerId', 'xpMultiplierBps']) {
        expect(j.containsKey(key), isTrue, reason: 'missing: $key');
      }
      expect(j['xpMultiplierBps'], 12500);
    });
  });

  // -------------------------------------------------------------------------
  // TerritoryBoardDto
  // -------------------------------------------------------------------------

  group('TerritoryBoardDto', () {
    test('fromJson parses seasonId', () {
      final b = TerritoryBoardDto.fromJson({
        'seasonId': 's1',
        'tierNumber': 2,
        'tiles': [],
      });
      expect(b.seasonId, 's1');
    });

    test('fromJson tierNumber defaults 1 when absent', () {
      final b = TerritoryBoardDto.fromJson({'seasonId': 's1', 'tiles': []});
      expect(b.tierNumber, 1);
    });

    test('fromJson tiles empty when absent', () {
      final b = TerritoryBoardDto.fromJson({'seasonId': 's1', 'tierNumber': 1});
      expect(b.tiles, isEmpty);
    });

    test('fromJson tiles deserialized as TileDto list', () {
      final b = TerritoryBoardDto.fromJson({
        'seasonId': 's1',
        'tierNumber': 1,
        'tiles': [
          {'category': 'science', 'xpMultiplierBps': 10000},
          {'category': 'history', 'xpMultiplierBps': 15000},
        ],
      });
      expect(b.tiles.length, 2);
      expect(b.tiles.first, isA<TileDto>());
      expect(b.tiles.first.category, 'science');
    });

    test('toJson tiles as nested list of maps', () {
      final b = TerritoryBoardDto.fromJson({
        'seasonId': 's1',
        'tierNumber': 1,
        'tiles': [
          {'category': 'science', 'xpMultiplierBps': 10000}
        ],
      });
      final j = b.toJson();
      expect(j['tiles'], isA<List>());
      expect((j['tiles'] as List).first, isA<Map>());
    });
  });

  // -------------------------------------------------------------------------
  // DuelResultDto
  // -------------------------------------------------------------------------

  group('DuelResultDto', () {
    // Mirrors backend StartTerritoryDuelResponse: {matchId, tileOwnerId?, status?}.
    test('fromJson parses matchId, tileOwnerId, status', () {
      final d = DuelResultDto.fromJson(
          {'matchId': 'm1', 'tileOwnerId': 'p9', 'status': 'Started'});
      expect(d.matchId, 'm1');
      expect(d.tileOwnerId, 'p9');
      expect(d.status, 'Started');
    });

    test('fromJson optional fields null when absent', () {
      final d = DuelResultDto.fromJson({'matchId': 'm1'});
      expect(d.tileOwnerId, isNull);
      expect(d.status, isNull);
    });

    test('toJson contains matchId and tileOwnerId', () {
      final j = DuelResultDto.fromJson({'matchId': 'm2', 'tileOwnerId': 'p2'})
          .toJson();
      expect(j['matchId'], 'm2');
      expect(j['tileOwnerId'], 'p2');
    });
  });

  // -------------------------------------------------------------------------
  // VoteResultDto
  // -------------------------------------------------------------------------

  group('VoteResultDto', () {
    test('fromJson parses topic', () {
      final v = VoteResultDto.fromJson({
        'topic': 'next_category',
        'tally': {'science': 10, 'history': 5},
        'totalVotes': 15,
      });
      expect(v.topic, 'next_category');
    });

    test('fromJson parses tally as Map<String,int>', () {
      final v = VoteResultDto.fromJson({
        'topic': 't',
        'tally': {'a': 3, 'b': 7},
        'totalVotes': 10,
      });
      expect(v.tally['a'], 3);
      expect(v.tally['b'], 7);
    });

    test('fromJson totalVotes defaults 0 when absent', () {
      final v = VoteResultDto.fromJson({'topic': 't', 'tally': {}});
      expect(v.totalVotes, 0);
    });

    test('fromJson winningChoice null when absent', () {
      final v =
          VoteResultDto.fromJson({'topic': 't', 'tally': {}, 'totalVotes': 0});
      expect(v.winningChoice, isNull);
    });

    test('fromJson winningChoice stored when present', () {
      final v = VoteResultDto.fromJson({
        'topic': 't',
        'tally': {},
        'totalVotes': 5,
        'winningChoice': 'science',
      });
      expect(v.winningChoice, 'science');
    });

    test('toJson contains all 4 keys', () {
      final j =
          VoteResultDto.fromJson({'topic': 't', 'tally': {}, 'totalVotes': 0})
              .toJson();
      for (final key in ['topic', 'tally', 'totalVotes', 'winningChoice']) {
        expect(j.containsKey(key), isTrue, reason: 'missing: $key');
      }
    });
  });

  // -------------------------------------------------------------------------
  // PlayerNotificationDto
  // -------------------------------------------------------------------------

  group('PlayerNotificationDto', () {
    test('fromJson type defaults empty when absent', () {
      final d = PlayerNotificationDto.fromJson({'message': 'hello'});
      expect(d.type, '');
    });

    test('fromJson message defaults empty when absent', () {
      final d = PlayerNotificationDto.fromJson({'type': 'alert'});
      expect(d.message, '');
    });

    test('fromJson payload null when absent', () {
      final d = PlayerNotificationDto.fromJson({'type': 'x', 'message': 'y'});
      expect(d.payload, isNull);
    });

    test('fromJson payload stored when present', () {
      final d = PlayerNotificationDto.fromJson({
        'type': 'x',
        'message': 'y',
        'payload': {'key': 'value'},
      });
      expect(d.payload!['key'], 'value');
    });
  });

  // -------------------------------------------------------------------------
  // MatchUpdateDto
  // -------------------------------------------------------------------------

  group('MatchUpdateDto', () {
    test('fromJson parses matchId', () {
      final d = MatchUpdateDto.fromJson({'matchId': 'm1', 'status': 'started'});
      expect(d.matchId, 'm1');
    });

    test('fromJson status defaults empty when absent', () {
      final d = MatchUpdateDto.fromJson({'matchId': 'm1'});
      expect(d.status, '');
    });

    test('fromJson data null when absent', () {
      final d = MatchUpdateDto.fromJson({'matchId': 'm1', 'status': 'x'});
      expect(d.data, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // GameEventEliminationDto
  // -------------------------------------------------------------------------

  group('GameEventEliminationDto', () {
    test('fromJson parses gameEventId and eliminatedPlayerId', () {
      final d = GameEventEliminationDto.fromJson({
        'gameEventId': 'ge1',
        'eliminatedPlayerId': 'p1',
        'aliveCount': 10,
        'timestamp': '2025-06-01T20:30:00.000Z',
      });
      expect(d.gameEventId, 'ge1');
      expect(d.eliminatedPlayerId, 'p1');
    });

    test('fromJson aliveCount defaults 0 when absent', () {
      final d = GameEventEliminationDto.fromJson({
        'gameEventId': 'ge1',
        'eliminatedPlayerId': 'p1',
        'timestamp': '2025-06-01T20:30:00.000Z',
      });
      expect(d.aliveCount, 0);
    });

    test('fromJson timestamp as DateTime', () {
      final d = GameEventEliminationDto.fromJson({
        'gameEventId': 'ge1',
        'eliminatedPlayerId': 'p1',
        'aliveCount': 5,
        'timestamp': '2025-06-01T20:30:00.000Z',
      });
      expect(d.timestamp, isA<DateTime>());
    });

    test('fromJson invalid timestamp falls back to a DateTime', () {
      final d = GameEventEliminationDto.fromJson({
        'gameEventId': 'ge1',
        'eliminatedPlayerId': 'p1',
        'aliveCount': 0,
        'timestamp': 'not-a-date',
      });
      expect(d.timestamp, isA<DateTime>());
    });
  });

  // -------------------------------------------------------------------------
  // GameEventClosedDto
  // -------------------------------------------------------------------------

  group('GameEventClosedDto', () {
    test('fromJson parses gameEventId and winnerId', () {
      final d = GameEventClosedDto.fromJson({
        'gameEventId': 'ge1',
        'winnerId': 'p1',
        'closedAt': '2025-06-01T22:00:00.000Z',
      });
      expect(d.gameEventId, 'ge1');
      expect(d.winnerId, 'p1');
    });

    test('fromJson closedAt as DateTime', () {
      final d = GameEventClosedDto.fromJson({
        'gameEventId': 'ge1',
        'winnerId': 'p1',
        'closedAt': '2025-06-01T22:00:00.000Z',
      });
      expect(d.closedAt, isA<DateTime>());
    });

    test('fromJson invalid closedAt falls back to DateTime', () {
      final d = GameEventClosedDto.fromJson({
        'gameEventId': 'ge1',
        'winnerId': 'p1',
        'closedAt': 'bad',
      });
      expect(d.closedAt, isA<DateTime>());
    });
  });

  // -------------------------------------------------------------------------
  // GuardianChangedDto
  // -------------------------------------------------------------------------

  group('GuardianChangedDto', () {
    test('fromJson parses all required fields', () {
      final d = GuardianChangedDto.fromJson({
        'seasonId': 's1',
        'tierNumber': 3,
        'newGuardianPlayerId': 'p1',
        'newGuardianUsername': 'alice',
        'previousGuardianPlayerId': 'p0',
      });
      expect(d.seasonId, 's1');
      expect(d.newGuardianUsername, 'alice');
    });

    test('fromJson tierNumber defaults 1 when absent', () {
      final d = GuardianChangedDto.fromJson({
        'seasonId': 's1',
        'newGuardianPlayerId': 'p1',
        'newGuardianUsername': 'x',
        'previousGuardianPlayerId': 'p0',
      });
      expect(d.tierNumber, 1);
    });
  });

  // -------------------------------------------------------------------------
  // TerritoryCaptureDto
  // -------------------------------------------------------------------------

  group('TerritoryCaptureDto', () {
    test('fromJson parses required fields', () {
      final d = TerritoryCaptureDto.fromJson({
        'seasonId': 's1',
        'tierNumber': 2,
        'tileId': 't1',
        'newOwnerId': 'p1',
        'newOwnerUsername': 'alice',
      });
      expect(d.tileId, 't1');
      expect(d.newOwnerId, 'p1');
    });

    test('fromJson previousOwnerId null when absent', () {
      final d = TerritoryCaptureDto.fromJson({
        'seasonId': 's1',
        'tierNumber': 1,
        'tileId': 't1',
        'newOwnerId': 'p1',
        'newOwnerUsername': 'x',
      });
      expect(d.previousOwnerId, isNull);
    });

    test('fromJson previousOwnerId stored when present', () {
      final d = TerritoryCaptureDto.fromJson({
        'seasonId': 's1',
        'tierNumber': 1,
        'tileId': 't1',
        'newOwnerId': 'p1',
        'newOwnerUsername': 'x',
        'previousOwnerId': 'p0',
      });
      expect(d.previousOwnerId, 'p0');
    });
  });

  // -------------------------------------------------------------------------
  // VoteTallyUpdatedDto
  // -------------------------------------------------------------------------

  group('VoteTallyUpdatedDto', () {
    test('fromJson parses topic', () {
      final d = VoteTallyUpdatedDto.fromJson({
        'topic': 'category_vote',
        'tally': {'a': 5},
        'totalVotes': 5,
      });
      expect(d.topic, 'category_vote');
    });

    test('fromJson tally parsed as Map<String,int>', () {
      final d = VoteTallyUpdatedDto.fromJson({
        'topic': 't',
        'tally': {'x': 10, 'y': 20},
        'totalVotes': 30,
      });
      expect(d.tally['x'], 10);
      expect(d.tally['y'], 20);
    });

    test('fromJson tally empty map when absent', () {
      final d = VoteTallyUpdatedDto.fromJson({'topic': 't', 'totalVotes': 0});
      expect(d.tally, isEmpty);
    });

    test('fromJson totalVotes defaults 0 when absent', () {
      final d = VoteTallyUpdatedDto.fromJson({'topic': 't', 'tally': {}});
      expect(d.totalVotes, 0);
    });
  });

  // -------------------------------------------------------------------------
  // DirectMessagesUpdatedDto
  // -------------------------------------------------------------------------

  group('DirectMessagesUpdatedDto', () {
    test('fromJson parses all fields with defaults', () {
      final d = DirectMessagesUpdatedDto.fromJson({});
      expect(d.playerId, '');
      expect(d.conversationId, '');
      expect(d.unreadCount, 0);
      expect(d.reason, '');
      expect(d.occurredAtUtc, isA<DateTime>());
    });

    test('fromJson parses provided values', () {
      final d = DirectMessagesUpdatedDto.fromJson({
        'playerId': 'p1',
        'conversationId': 'c1',
        'unreadCount': 3,
        'reason': 'new_message',
        'occurredAtUtc': '2025-05-01T09:00:00.000Z',
      });
      expect(d.playerId, 'p1');
      expect(d.unreadCount, 3);
      expect(d.occurredAtUtc.year, 2025);
    });

    test('fromJson invalid occurredAtUtc falls back to DateTime', () {
      final d = DirectMessagesUpdatedDto.fromJson({
        'playerId': 'p1',
        'conversationId': 'c1',
        'unreadCount': 0,
        'reason': 'x',
        'occurredAtUtc': 'not-a-date',
      });
      expect(d.occurredAtUtc, isA<DateTime>());
    });
  });
}
