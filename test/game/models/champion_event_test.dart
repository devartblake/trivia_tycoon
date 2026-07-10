import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/champion_event.dart';

void main() {
  group('ChampionEvent.fromJson', () {
    test('parses the full status shape (GET /game-events/{id})', () {
      final event = ChampionEvent.fromJson({
        'id': 'e1',
        'kind': 'champion_vs_tier',
        'status': 'Open',
        'tierId': 7,
        'scheduledAtUtc': '2026-07-15T18:00:00.000Z',
        'participantCount': 42,
        'aliveCount': 30,
        'jackpotPool': 500,
        'entryFeeCoins': 100,
        'maxParticipants': 100,
        'championPlayerId': 'champ-1',
        'jackpotMultiplier': 2.0,
        'effectiveJackpot': 1000,
      });

      expect(event.isChampionVsTier, isTrue);
      expect(event.isOpenForEntry, isTrue);
      expect(event.aliveCount, 30);
      expect(event.championPlayerId, 'champ-1');
      // Multiplied jackpot is preferred for display.
      expect(event.displayJackpot, 1000);
      expect(event.jackpotMultiplier, 2.0);
    });

    test('parses the summary shape (GET /game-events/upcoming)', () {
      final event = ChampionEvent.fromJson({
        'id': 'e2',
        'kind': 'champion_vs_tier',
        'status': 'Scheduled',
        'tierId': 5,
        'scheduledAtUtc': '2026-07-20T18:00:00.000Z',
        'entryFeeCoins': 50,
        'maxParticipants': 100,
      });

      expect(event.isOpenForEntry, isFalse);
      expect(event.jackpotPool, 0);
      expect(event.displayJackpot, 0);
      expect(event.championPlayerId, isNull);
    });

    test('tolerates a numeric status enum', () {
      final event = ChampionEvent.fromJson({
        'id': 'e3',
        'kind': 'champion_vs_tier',
        'status': 3, // Live
        'scheduledAtUtc': '2026-07-20T18:00:00.000Z',
      });
      expect(event.status, 'Live');
      expect(event.isLive, isTrue);
    });
  });
}
