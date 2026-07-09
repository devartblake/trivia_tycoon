import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/seasonal_competition_model.dart';

void main() {
  group('SeasonPlayer.fromJson', () {
    test('parses a backend season leaderboard entry '
        '(GET /seasons/{id}/leaderboard item shape)', () {
      final player = SeasonPlayer.fromJson({
        'rank': 3,
        'playerId': '0d6f9c5a-6f3e-4a2b-9c1d-2e8b7a654321',
        'handle': 'quizqueen',
        'displayName': 'quizqueen',
        'avatarUrl': null,
        'rankPoints': 4200,
        'wins': 61,
        'losses': 12,
        'draws': 2,
        'tier': 5,
        'tierRank': 1,
      });

      expect(player.playerId, '0d6f9c5a-6f3e-4a2b-9c1d-2e8b7a654321');
      expect(player.playerName, 'quizqueen');
      expect(player.points, 4200);
      expect(player.rank, 3);
      // Backend entries carry no activity timestamp; epoch sentinel.
      expect(player.lastActive, DateTime.fromMillisecondsSinceEpoch(0));
    });

    test('still parses the legacy client shape', () {
      final player = SeasonPlayer.fromJson({
        'playerId': 'p1',
        'playerName': 'Alice',
        'points': 120,
        'rank': 1,
        'lastActive': '2026-07-01T12:00:00.000Z',
      });

      expect(player.playerName, 'Alice');
      expect(player.points, 120);
      expect(player.lastActive, DateTime.parse('2026-07-01T12:00:00.000Z'));
    });

    test('falls back to handle and zero values when fields are missing', () {
      final player = SeasonPlayer.fromJson({
        'playerId': 'p2',
        'handle': 'bob',
      });

      expect(player.playerName, 'bob');
      expect(player.points, 0);
      expect(player.rank, 0);
    });
  });
}
