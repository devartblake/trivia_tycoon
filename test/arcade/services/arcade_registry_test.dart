import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_difficulty.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_game_id.dart';
import 'package:trivia_tycoon/arcade/services/arcade_registry.dart';

void main() {
  const registry = ArcadeRegistry();

  // -------------------------------------------------------------------------
  // games list
  // -------------------------------------------------------------------------

  group('ArcadeRegistry.games', () {
    test('returns exactly 3 game definitions', () {
      expect(registry.games.length, 3);
    });

    test('first game is patternSprint', () {
      expect(registry.games[0].id, ArcadeGameId.patternSprint);
    });

    test('second game is memoryFlip', () {
      expect(registry.games[1].id, ArcadeGameId.memoryFlip);
    });

    test('third game is quickMathRush', () {
      expect(registry.games[2].id, ArcadeGameId.quickMathRush);
    });

    test('all game IDs are unique', () {
      final ids = registry.games.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);
    });

    test('all titles are non-empty', () {
      for (final game in registry.games) {
        expect(game.title.isNotEmpty, isTrue,
            reason: '${game.id} has empty title');
      }
    });

    test('all subtitles are non-empty', () {
      for (final game in registry.games) {
        expect(game.subtitle.isNotEmpty, isTrue,
            reason: '${game.id} has empty subtitle');
      }
    });

    test('all builder functions are non-null', () {
      for (final game in registry.games) {
        expect(game.builder, isNotNull, reason: '${game.id} has null builder');
      }
    });
  });

  // -------------------------------------------------------------------------
  // patternSprint definition
  // -------------------------------------------------------------------------

  group('ArcadeRegistry — patternSprint definition', () {
    late final def = registry.games.firstWhere(
      (g) => g.id == ArcadeGameId.patternSprint,
    );

    test('title is "Pattern Sprint"', () {
      expect(def.title, 'Pattern Sprint');
    });

    test('supports easy, normal, hard difficulties', () {
      expect(
          def.supportedDifficulties,
          containsAll([
            ArcadeDifficulty.easy,
            ArcadeDifficulty.normal,
            ArcadeDifficulty.hard,
          ]));
    });

    test('does not list insane difficulty', () {
      expect(
          def.supportedDifficulties, isNot(contains(ArcadeDifficulty.insane)));
    });
  });

  // -------------------------------------------------------------------------
  // memoryFlip definition
  // -------------------------------------------------------------------------

  group('ArcadeRegistry — memoryFlip definition', () {
    late final def = registry.games.firstWhere(
      (g) => g.id == ArcadeGameId.memoryFlip,
    );

    test('title is "Memory Flip"', () {
      expect(def.title, 'Memory Flip');
    });

    test('supports easy, normal, hard difficulties', () {
      expect(
          def.supportedDifficulties,
          containsAll([
            ArcadeDifficulty.easy,
            ArcadeDifficulty.normal,
            ArcadeDifficulty.hard,
          ]));
    });

    test('does not list insane difficulty', () {
      expect(
          def.supportedDifficulties, isNot(contains(ArcadeDifficulty.insane)));
    });
  });

  // -------------------------------------------------------------------------
  // quickMathRush definition
  // -------------------------------------------------------------------------

  group('ArcadeRegistry — quickMathRush definition', () {
    late final def = registry.games.firstWhere(
      (g) => g.id == ArcadeGameId.quickMathRush,
    );

    test('title is "Quick Math Rush"', () {
      expect(def.title, 'Quick Math Rush');
    });

    test('supports all four difficulties including insane', () {
      expect(
          def.supportedDifficulties,
          containsAll([
            ArcadeDifficulty.easy,
            ArcadeDifficulty.normal,
            ArcadeDifficulty.hard,
            ArcadeDifficulty.insane,
          ]));
    });
  });

  // -------------------------------------------------------------------------
  // Lookup by game ID
  // -------------------------------------------------------------------------

  group('ArcadeRegistry — lookup by id', () {
    test('every ArcadeGameId has a definition in the registry', () {
      final registeredIds = registry.games.map((g) => g.id).toSet();
      for (final id in ArcadeGameId.values) {
        expect(registeredIds, contains(id),
            reason: 'No definition found for $id');
      }
    });
  });
}
