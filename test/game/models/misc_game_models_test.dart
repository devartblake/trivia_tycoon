import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/player_progress.dart';
import 'package:synaptix/game/models/game_mode.dart';

void main() {
  // ---------------------------------------------------------------------------
  // PlayerProgress.fromJson
  // ---------------------------------------------------------------------------

  group('PlayerProgress.fromJson', () {
    test('parses score', () {
      expect(PlayerProgress.fromJson({'score': 42, 'streak': 0}).score, 42);
    });

    test('parses streak', () {
      expect(PlayerProgress.fromJson({'score': 0, 'streak': 5}).streak, 5);
    });

    test('score defaults to 0 when absent', () {
      expect(PlayerProgress.fromJson({'streak': 3}).score, 0);
    });

    test('streak defaults to 0 when absent', () {
      expect(PlayerProgress.fromJson({'score': 10}).streak, 0);
    });

    test('both default to 0 when empty map', () {
      final p = PlayerProgress.fromJson({});
      expect(p.score, 0);
      expect(p.streak, 0);
    });
  });

  // ---------------------------------------------------------------------------
  // PlayerProgress.toJson
  // ---------------------------------------------------------------------------

  group('PlayerProgress.toJson', () {
    test('serializes score', () {
      expect(PlayerProgress(score: 99, streak: 0).toJson()['score'], 99);
    });

    test('serializes streak', () {
      expect(PlayerProgress(score: 0, streak: 7).toJson()['streak'], 7);
    });

    test('round-trip preserves score and streak', () {
      final original = PlayerProgress(score: 500, streak: 12);
      final restored = PlayerProgress.fromJson(original.toJson());
      expect(restored.score, 500);
      expect(restored.streak, 12);
    });
  });

  // ---------------------------------------------------------------------------
  // normalizeGameModeName
  // ---------------------------------------------------------------------------

  group('normalizeGameModeName', () {
    test('strips "GameMode." prefix', () {
      expect(normalizeGameModeName('GameMode.classic'), 'classic');
    });

    test('strips prefix for all GameMode values', () {
      for (final mode in GameMode.values) {
        final raw = 'GameMode.${mode.name}';
        expect(normalizeGameModeName(raw), mode.name);
      }
    });

    test('returns plain value unchanged', () {
      expect(normalizeGameModeName('classic'), 'classic');
    });

    test('returns unknown plain value unchanged', () {
      expect(normalizeGameModeName('mystery'), 'mystery');
    });

    test('does not strip partial prefix', () {
      expect(normalizeGameModeName('GameModeclassic'), 'GameModeclassic');
    });

    test('returns empty string unchanged', () {
      expect(normalizeGameModeName(''), '');
    });
  });

  // ---------------------------------------------------------------------------
  // GameMode enum values
  // ---------------------------------------------------------------------------

  group('GameMode enum', () {
    test('has classic', () {
      expect(GameMode.values.contains(GameMode.classic), isTrue);
    });

    test('has all 6 values', () {
      expect(GameMode.values.length, 6);
    });
  });
}
