import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/dto/game_event_dto.dart';
import 'package:trivia_tycoon/core/dto/season_dto.dart';
import 'package:trivia_tycoon/core/dto/guardian_dto.dart';

void main() {
  // -------------------------------------------------------------------------
  // GameEventDto
  // -------------------------------------------------------------------------

  group('GameEventDto', () {
    Map<String, dynamic> full() => {
          'id': 'e1',
          'name': 'Friday Night Quiz',
          'status': 'live',
          'startsAt': '2025-06-01T20:00:00.000Z',
          'entryFee': 50,
          'maxPlayers': 100,
          'currentPlayers': 42,
          'aliveCount': 38,
        };

    test('fromJson parses id', () {
      expect(GameEventDto.fromJson(full()).id, 'e1');
    });

    test('fromJson parses name', () {
      expect(GameEventDto.fromJson(full()).name, 'Friday Night Quiz');
    });

    test('fromJson parses status', () {
      expect(GameEventDto.fromJson(full()).status, 'live');
    });

    test('fromJson status defaults upcoming when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('status');
      expect(GameEventDto.fromJson(j).status, 'upcoming');
    });

    test('fromJson parses startsAt as DateTime', () {
      expect(GameEventDto.fromJson(full()).startsAt, isA<DateTime>());
      expect(GameEventDto.fromJson(full()).startsAt.year, 2025);
    });

    test('fromJson entryFee defaults 0 when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('entryFee');
      expect(GameEventDto.fromJson(j).entryFee, 0);
    });

    test('fromJson maxPlayers defaults 0 when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('maxPlayers');
      expect(GameEventDto.fromJson(j).maxPlayers, 0);
    });

    test('fromJson currentPlayers defaults 0 when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('currentPlayers');
      expect(GameEventDto.fromJson(j).currentPlayers, 0);
    });

    test('fromJson aliveCount defaults 0 when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('aliveCount');
      expect(GameEventDto.fromJson(j).aliveCount, 0);
    });

    test('toJson contains id', () {
      expect(GameEventDto.fromJson(full()).toJson()['id'], 'e1');
    });

    test('toJson startsAt is ISO string', () {
      final j = GameEventDto.fromJson(full()).toJson();
      expect(j['startsAt'], isA<String>());
      expect((j['startsAt'] as String).contains('2025'), isTrue);
    });

    test('toJson contains all 8 keys', () {
      final j = GameEventDto.fromJson(full()).toJson();
      for (final key in [
        'id',
        'name',
        'status',
        'startsAt',
        'entryFee',
        'maxPlayers',
        'currentPlayers',
        'aliveCount'
      ]) {
        expect(j.containsKey(key), isTrue, reason: 'missing key: $key');
      }
    });
  });

  // -------------------------------------------------------------------------
  // GameEventLeaderboardEntryDto
  // -------------------------------------------------------------------------

  group('GameEventLeaderboardEntryDto', () {
    test('fromJson parses playerId and username', () {
      final d = GameEventLeaderboardEntryDto.fromJson({
        'playerId': 'p1',
        'username': 'alice',
        'rank': 3,
        'score': 500,
        'isEliminated': false,
      });
      expect(d.playerId, 'p1');
      expect(d.username, 'alice');
    });

    test('fromJson rank defaults 0 when absent', () {
      final d = GameEventLeaderboardEntryDto.fromJson({
        'playerId': 'p1',
        'username': 'x',
      });
      expect(d.rank, 0);
    });

    test('fromJson score defaults 0 when absent', () {
      final d = GameEventLeaderboardEntryDto.fromJson({
        'playerId': 'p1',
        'username': 'x',
      });
      expect(d.score, 0);
    });

    test('fromJson isEliminated defaults false when absent', () {
      final d = GameEventLeaderboardEntryDto.fromJson({
        'playerId': 'p1',
        'username': 'x',
      });
      expect(d.isEliminated, isFalse);
    });

    test('toJson contains all 5 keys', () {
      final j = GameEventLeaderboardEntryDto.fromJson({
        'playerId': 'p2',
        'username': 'bob',
        'rank': 1,
        'score': 1000,
        'isEliminated': true,
      }).toJson();
      for (final key in [
        'playerId',
        'username',
        'rank',
        'score',
        'isEliminated'
      ]) {
        expect(j.containsKey(key), isTrue, reason: 'missing key: $key');
      }
    });
  });

  // -------------------------------------------------------------------------
  // SeasonDto
  // -------------------------------------------------------------------------

  group('SeasonDto', () {
    Map<String, dynamic> full() => {
          'id': 's1',
          'name': 'Season One',
          'startsAt': '2025-01-01T00:00:00.000Z',
          'endsAt': '2025-03-31T23:59:59.000Z',
          'isActive': true,
        };

    test('fromJson parses id and name', () {
      final s = SeasonDto.fromJson(full());
      expect(s.id, 's1');
      expect(s.name, 'Season One');
    });

    test('fromJson parses isActive true', () {
      expect(SeasonDto.fromJson(full()).isActive, isTrue);
    });

    test('fromJson isActive defaults false when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('isActive');
      expect(SeasonDto.fromJson(j).isActive, isFalse);
    });

    test('fromJson startsAt as DateTime with correct year', () {
      expect(SeasonDto.fromJson(full()).startsAt.year, 2025);
    });

    test('fromJson endsAt as DateTime', () {
      expect(SeasonDto.fromJson(full()).endsAt, isA<DateTime>());
    });

    test('toJson contains all 5 keys', () {
      final j = SeasonDto.fromJson(full()).toJson();
      for (final key in ['id', 'name', 'startsAt', 'endsAt', 'isActive']) {
        expect(j.containsKey(key), isTrue, reason: 'missing: $key');
      }
    });

    test('toJson dates are ISO strings', () {
      final j = SeasonDto.fromJson(full()).toJson();
      expect(j['startsAt'], isA<String>());
      expect(j['endsAt'], isA<String>());
    });

    test('round-trip preserves id and isActive', () {
      final s = SeasonDto.fromJson(full());
      final j = s.toJson();
      final s2 = SeasonDto.fromJson(j);
      expect(s2.id, 's1');
      expect(s2.isActive, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // PlayerSeasonStateDto
  // -------------------------------------------------------------------------

  group('PlayerSeasonStateDto', () {
    // Mirrors backend PlayerSeasonStateDto (GET /seasons/state/{playerId}).
    test('fromJson parses all fields', () {
      final d = PlayerSeasonStateDto.fromJson({
        'playerId': 'p1',
        'seasonId': 's1',
        'rankPoints': 120,
        'wins': 4,
        'losses': 2,
        'draws': 1,
        'matchesPlayed': 7,
        'tier': 3,
        'tierRank': 5,
        'seasonRank': 15,
      });
      expect(d.playerId, 'p1');
      expect(d.seasonId, 's1');
      expect(d.rankPoints, 120);
      expect(d.wins, 4);
      expect(d.losses, 2);
      expect(d.draws, 1);
      expect(d.matchesPlayed, 7);
      expect(d.tier, 3);
      expect(d.tierRank, 5);
      expect(d.seasonRank, 15);
    });

    test('fromJson tier defaults 1 when absent', () {
      final d =
          PlayerSeasonStateDto.fromJson({'playerId': 'p1', 'seasonId': 's1'});
      expect(d.tier, 1);
    });

    test('fromJson counters default 0 when absent', () {
      final d =
          PlayerSeasonStateDto.fromJson({'playerId': 'p1', 'seasonId': 's1'});
      expect(d.rankPoints, 0);
      expect(d.wins, 0);
      expect(d.losses, 0);
      expect(d.draws, 0);
      expect(d.matchesPlayed, 0);
      expect(d.tierRank, 0);
      expect(d.seasonRank, 0);
    });

    test('toJson contains all 10 keys', () {
      final j = PlayerSeasonStateDto.fromJson({
        'playerId': 'p1',
        'seasonId': 's1',
      }).toJson();
      for (final key in [
        'playerId',
        'seasonId',
        'rankPoints',
        'wins',
        'losses',
        'draws',
        'matchesPlayed',
        'tier',
        'tierRank',
        'seasonRank'
      ]) {
        expect(j.containsKey(key), isTrue, reason: 'missing: $key');
      }
    });
  });

  // -------------------------------------------------------------------------
  // GuardianDto
  // -------------------------------------------------------------------------

  group('GuardianDto', () {
    // Mirrors backend TierGuardianDto (GET /guardians/{tierNumber}?seasonId=).
    test('fromJson parses all required fields', () {
      final g = GuardianDto.fromJson({
        'id': 'g1',
        'seasonId': 's1',
        'tierNumber': 5,
        'playerId': 'p1',
        'defencesWon': 3,
        'defencesLost': 1,
      });
      expect(g.id, 'g1');
      expect(g.seasonId, 's1');
      expect(g.playerId, 'p1');
      expect(g.tierNumber, 5);
      expect(g.defencesWon, 3);
      expect(g.defencesLost, 1);
    });

    test('fromJson tierNumber defaults 1 when absent', () {
      final g = GuardianDto.fromJson(
          {'id': 'g1', 'seasonId': 's1', 'playerId': 'p1'});
      expect(g.tierNumber, 1);
    });

    test('fromJson defence counts default 0 when absent', () {
      final g = GuardianDto.fromJson(
          {'id': 'g1', 'seasonId': 's1', 'playerId': 'p1'});
      expect(g.defencesWon, 0);
      expect(g.defencesLost, 0);
    });

    test('fromJson timestamps null when absent', () {
      final g = GuardianDto.fromJson(
          {'id': 'g1', 'seasonId': 's1', 'playerId': 'p1'});
      expect(g.assignedAtUtc, isNull);
      expect(g.expiresAtUtc, isNull);
    });

    test('fromJson timestamps parsed when present', () {
      final g = GuardianDto.fromJson({
        'id': 'g1',
        'seasonId': 's1',
        'playerId': 'p1',
        'assignedAtUtc': '2025-05-01T10:00:00.000Z',
        'expiresAtUtc': '2025-05-08T10:00:00.000Z',
      });
      expect(g.assignedAtUtc, isA<DateTime>());
      expect(g.expiresAtUtc, isA<DateTime>());
    });

    test('toJson timestamps as ISO when non-null', () {
      final g = GuardianDto.fromJson({
        'id': 'g1',
        'seasonId': 's1',
        'playerId': 'p1',
        'assignedAtUtc': '2025-05-01T10:00:00.000Z',
      });
      expect(g.toJson()['assignedAtUtc'], isA<String>());
    });

    test('toJson timestamps null when absent', () {
      final g = GuardianDto.fromJson(
          {'id': 'g1', 'seasonId': 's1', 'playerId': 'p1'});
      expect(g.toJson()['assignedAtUtc'], isNull);
      expect(g.toJson()['expiresAtUtc'], isNull);
    });
  });

  // -------------------------------------------------------------------------
  // MyGuardianStatusDto
  // -------------------------------------------------------------------------

  group('MyGuardianStatusDto', () {
    test('fromJson parses playerId', () {
      final d = MyGuardianStatusDto.fromJson({
        'playerId': 'p1',
        'isGuardian': true,
        'tier': 3,
        'defenceCount': 5,
      });
      expect(d.playerId, 'p1');
    });

    test('fromJson isGuardian defaults false when absent', () {
      final d =
          MyGuardianStatusDto.fromJson({'playerId': 'p1', 'defenceCount': 0});
      expect(d.isGuardian, isFalse);
    });

    test('fromJson tier null when absent', () {
      final d =
          MyGuardianStatusDto.fromJson({'playerId': 'p1', 'defenceCount': 0});
      expect(d.tier, isNull);
    });

    test('fromJson tier stored when present', () {
      final d = MyGuardianStatusDto.fromJson(
          {'playerId': 'p1', 'defenceCount': 0, 'tier': 4});
      expect(d.tier, 4);
    });

    test('fromJson currentMatchId null when absent', () {
      final d =
          MyGuardianStatusDto.fromJson({'playerId': 'p1', 'defenceCount': 0});
      expect(d.currentMatchId, isNull);
    });

    test('toJson contains all 5 keys', () {
      final j = MyGuardianStatusDto.fromJson({
        'playerId': 'p1',
        'isGuardian': false,
        'defenceCount': 0,
      }).toJson();
      for (final key in [
        'playerId',
        'isGuardian',
        'tier',
        'defenceCount',
        'currentMatchId'
      ]) {
        expect(j.containsKey(key), isTrue, reason: 'missing: $key');
      }
    });
  });
}
