import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/season_tiebreaker.dart';

void main() {
  group('SeasonTiebreaker.fromJson', () {
    test('parses the backend SeasonTiebreakerDto shape', () {
      final tiebreaker = SeasonTiebreaker.fromJson({
        'id': '11111111-2222-3333-4444-555555555555',
        'seasonId': 'aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee',
        'scope': 'top1',
        'tier': 1,
        'boundaryRank': 1,
        'rankPoints': 4200,
        'playerIds': ['p1', 'p2'],
        'scheduledAtUtc': '2026-07-11T04:00:00.000Z',
        'expiresAtUtc': '2026-07-12T04:00:00.000Z',
        'status': 'Scheduled',
        'matchId': null,
        'winnerPlayerId': null,
      });

      expect(tiebreaker.id, '11111111-2222-3333-4444-555555555555');
      expect(tiebreaker.scope, 'top1');
      expect(tiebreaker.isChampionship, isTrue);
      expect(tiebreaker.isPending, isTrue);
      expect(tiebreaker.playerIds, ['p1', 'p2']);
      expect(tiebreaker.scheduledAtUtc.isUtc, isTrue);
      expect(tiebreaker.rankPoints, 4200);
    });

    test('resolved statuses are not pending', () {
      for (final status in ['Completed', 'Cancelled', 'Expired']) {
        final tiebreaker = SeasonTiebreaker.fromJson({
          'id': 't1',
          'seasonId': 's1',
          'scope': 'tier-promotion',
          'playerIds': const [],
          'status': status,
        });
        expect(tiebreaker.isPending, isFalse, reason: status);
      }
    });

    test('tolerates missing optional fields', () {
      final tiebreaker = SeasonTiebreaker.fromJson({'id': 't1'});
      expect(tiebreaker.status, 'Scheduled');
      expect(tiebreaker.playerIds, isEmpty);
      expect(tiebreaker.matchId, isNull);
    });
  });
}
