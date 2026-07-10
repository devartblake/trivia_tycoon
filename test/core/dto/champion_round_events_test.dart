import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/dto/champion_round_events.dart';

void main() {
  test('ChampionRoundStartedDto parses camelCase payload', () {
    final dto = ChampionRoundStartedDto.fromJson({
      'gameEventId': 'e1',
      'roundNumber': 3,
      'questionId': 'q1',
      'prompt': 'What is 2+2?',
      'options': [
        {'optionId': 'A', 'text': '4'},
        {'optionId': 'B', 'text': '5'},
      ],
      'deadlineUtc': '2026-07-15T18:00:12.000Z',
      'aliveCount': 42,
      'jackpotPool': 500,
    });

    expect(dto.roundNumber, 3);
    expect(dto.options, hasLength(2));
    expect(dto.options.first.text, '4');
    expect(dto.aliveCount, 42);
    expect(dto.deadlineUtc.isUtc, isTrue);
  });

  test('ChampionRoundResolvedDto parses eliminations and champion flag', () {
    final dto = ChampionRoundResolvedDto.fromJson({
      'gameEventId': 'e1',
      'roundNumber': 3,
      'correctOptionId': 'A',
      'eliminatedPlayerIds': ['p2', 'p3'],
      'survivorsRemaining': 5,
      'championAlive': true,
      'jackpotPool': 600,
    });

    expect(dto.correctOptionId, 'A');
    expect(dto.eliminatedPlayerIds, ['p2', 'p3']);
    expect(dto.championAlive, isTrue);
  });

  test('ChampionMatchEndedDto normalizes empty winner to null', () {
    final defended = ChampionMatchEndedDto.fromJson({
      'gameEventId': 'e1',
      'winnerPlayerId': '',
      'championDefended': true,
      'jackpotAwarded': 1000,
      'roundsPlayed': 8,
    });
    expect(defended.winnerPlayerId, isNull);
    expect(defended.championDefended, isTrue);
    expect(defended.jackpotAwarded, 1000);
  });
}
