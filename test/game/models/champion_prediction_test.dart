import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/champion_prediction.dart';

void main() {
  group('ChampionPrediction.fromJson', () {
    test('parses an open prediction with the caller pick and tally', () {
      final p = ChampionPrediction.fromJson({
        'gameEventId': 'e1',
        'open': true,
        'myPrediction': true,
        'defendCount': 12,
        'dethroneCount': 30,
        'rewardCoinPool': 1000,
        'resolved': false,
        'wasCorrect': null,
        'rewardCoins': 0,
        'rewardXp': 0,
      });

      expect(p.open, isTrue);
      expect(p.hasPicked, isTrue);
      expect(p.myPrediction, isTrue);
      expect(p.totalPredictions, 42);
      expect(p.rewardCoinPool, 1000);
    });

    test('parses a resolved winning prediction with reward', () {
      final p = ChampionPrediction.fromJson({
        'gameEventId': 'e1',
        'open': false,
        'myPrediction': false,
        'defendCount': 5,
        'dethroneCount': 10,
        'rewardCoinPool': 1000,
        'resolved': true,
        'wasCorrect': true,
        'rewardCoins': 100,
        'rewardXp': 25,
      });

      expect(p.resolved, isTrue);
      expect(p.wasCorrect, isTrue);
      expect(p.rewardCoins, 100);
      expect(p.rewardXp, 25);
    });

    test('handles no caller pick (anonymous / not predicted)', () {
      final p = ChampionPrediction.fromJson({
        'gameEventId': 'e1',
        'open': true,
        'myPrediction': null,
        'defendCount': 0,
        'dethroneCount': 0,
        'rewardCoinPool': 1000,
        'resolved': false,
      });

      expect(p.hasPicked, isFalse);
      expect(p.totalPredictions, 0);
    });
  });
}
