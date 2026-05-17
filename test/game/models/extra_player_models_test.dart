import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/player.dart';
import 'package:trivia_tycoon/game/models/player_progress.dart';
import 'package:trivia_tycoon/game/models/typing_status_model.dart';

void main() {
  // -------------------------------------------------------------------------
  // Player
  // -------------------------------------------------------------------------

  group('Player', () {
    test('stores name and score', () {
      final p = Player(name: 'Alice', score: 42);
      expect(p.name, 'Alice');
      expect(p.score, 42);
    });

    test('score can be zero', () {
      final p = Player(name: 'Bob', score: 0);
      expect(p.score, 0);
    });

    test('score can be negative', () {
      final p = Player(name: 'Charlie', score: -10);
      expect(p.score, -10);
    });
  });

  // -------------------------------------------------------------------------
  // PlayerProgress
  // -------------------------------------------------------------------------

  group('PlayerProgress.fromJson', () {
    test('parses score and streak', () {
      final p = PlayerProgress.fromJson({'score': 100, 'streak': 5});
      expect(p.score, 100);
      expect(p.streak, 5);
    });

    test('score defaults to 0 when absent', () {
      final p = PlayerProgress.fromJson({'streak': 3});
      expect(p.score, 0);
    });

    test('streak defaults to 0 when absent', () {
      final p = PlayerProgress.fromJson({'score': 50});
      expect(p.streak, 0);
    });

    test('both default to 0 when json is empty', () {
      final p = PlayerProgress.fromJson({});
      expect(p.score, 0);
      expect(p.streak, 0);
    });
  });

  group('PlayerProgress.toJson', () {
    test('serialises score and streak', () {
      final p = PlayerProgress(score: 200, streak: 7);
      final json = p.toJson();
      expect(json['score'], 200);
      expect(json['streak'], 7);
    });

    test('contains exactly two keys', () {
      final p = PlayerProgress(score: 0, streak: 0);
      expect(p.toJson().keys.toSet(), {'score', 'streak'});
    });

    test('round-trip preserves all values', () {
      final original = PlayerProgress(score: 999, streak: 12);
      final restored = PlayerProgress.fromJson(original.toJson());
      expect(restored.score, original.score);
      expect(restored.streak, original.streak);
    });
  });

  // -------------------------------------------------------------------------
  // TypingStatus
  // -------------------------------------------------------------------------

  group('TypingStatus', () {
    test('stores all four fields', () {
      final ts = DateTime.utc(2026, 1, 1, 12, 0, 0);
      final status = TypingStatus(
        userId: 'u1',
        userName: 'Alice',
        isTyping: true,
        timestamp: ts,
      );
      expect(status.userId, 'u1');
      expect(status.userName, 'Alice');
      expect(status.isTyping, isTrue);
      expect(status.timestamp, ts);
    });

    test('isTyping can be false', () {
      final status = TypingStatus(
        userId: 'u2',
        userName: 'Bob',
        isTyping: false,
        timestamp: DateTime.now(),
      );
      expect(status.isTyping, isFalse);
    });
  });
}
