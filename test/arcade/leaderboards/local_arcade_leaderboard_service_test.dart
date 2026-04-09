import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_difficulty.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_game_id.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_result.dart';
import 'package:trivia_tycoon/arcade/leaderboards/local_arcade_leaderboard_service.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ArcadeResult _result({
  ArcadeGameId gameId = ArcadeGameId.quickMathRush,
  ArcadeDifficulty difficulty = ArcadeDifficulty.normal,
  int score = 500,
  Duration duration = const Duration(seconds: 60),
}) =>
    ArcadeResult(
      gameId: gameId,
      difficulty: difficulty,
      score: score,
      duration: duration,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  late Directory tempDir;
  late AppCacheService cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('leaderboard_test');
    Hive.init(tempDir.path);
    cache = await AppCacheService.initialize();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('cache');
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // top() — initial state
  // -------------------------------------------------------------------------

  group('LocalArcadeLeaderboardService.top() — initial state', () {
    test('returns empty list when no runs recorded', () {
      final svc = LocalArcadeLeaderboardService(cache);
      expect(svc.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal), isEmpty);
    });

    test('best() returns null when no runs recorded', () {
      final svc = LocalArcadeLeaderboardService(cache);
      expect(svc.best(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // recordRun() and top()
  // -------------------------------------------------------------------------

  group('LocalArcadeLeaderboardService.recordRun()', () {
    test('recorded run appears in top()', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(_result(score: 300));
      final list = svc.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal);
      expect(list.length, 1);
      expect(list.first.score, 300);
    });

    test('multiple runs are returned in score-descending order', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(_result(score: 100));
      await svc.recordRun(_result(score: 500));
      await svc.recordRun(_result(score: 300));
      final list = svc.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal);
      expect(list.map((e) => e.score).toList(), [500, 300, 100]);
    });

    test('entries with equal score are sorted by duration ascending', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(_result(score: 500, duration: const Duration(seconds: 90)));
      await svc.recordRun(_result(score: 500, duration: const Duration(seconds: 45)));
      final list = svc.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal);
      expect(list[0].durationMs, lessThan(list[1].durationMs));
    });

    test('records are isolated per game', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(_result(gameId: ArcadeGameId.quickMathRush, score: 400));
      await svc.recordRun(_result(gameId: ArcadeGameId.memoryFlip, score: 800));

      expect(svc.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal).first.score, 400);
      expect(svc.top(ArcadeGameId.memoryFlip, ArcadeDifficulty.normal).first.score, 800);
    });

    test('records are isolated per difficulty', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(_result(difficulty: ArcadeDifficulty.easy, score: 111));
      await svc.recordRun(_result(difficulty: ArcadeDifficulty.hard, score: 999));

      expect(svc.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.easy).first.score, 111);
      expect(svc.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.hard).first.score, 999);
    });

    test('stored entries have correct gameId and difficulty', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(_result(
        gameId: ArcadeGameId.patternSprint,
        difficulty: ArcadeDifficulty.hard,
        score: 750,
      ));
      final entry = svc
          .top(ArcadeGameId.patternSprint, ArcadeDifficulty.hard)
          .first;
      expect(entry.gameId, ArcadeGameId.patternSprint);
      expect(entry.difficulty, ArcadeDifficulty.hard);
    });
  });

  // -------------------------------------------------------------------------
  // top() — limit parameter
  // -------------------------------------------------------------------------

  group('LocalArcadeLeaderboardService.top() — limit', () {
    test('default limit of 10 is respected', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      for (int i = 0; i < 15; i++) {
        await svc.recordRun(_result(score: i * 10));
      }
      expect(svc.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal).length, 10);
    });

    test('custom limit is respected', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      for (int i = 0; i < 8; i++) {
        await svc.recordRun(_result(score: i * 10));
      }
      expect(
        svc.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal, limit: 3).length,
        3,
      );
    });

    test('limit larger than actual entries returns all entries', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(_result(score: 200));
      await svc.recordRun(_result(score: 100));
      expect(
        svc.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal, limit: 50).length,
        2,
      );
    });
  });

  // -------------------------------------------------------------------------
  // best()
  // -------------------------------------------------------------------------

  group('LocalArcadeLeaderboardService.best()', () {
    test('returns the entry with the highest score', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(_result(score: 200));
      await svc.recordRun(_result(score: 800));
      await svc.recordRun(_result(score: 500));
      expect(svc.best(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal)!.score, 800);
    });

    test('returns null for an empty board', () {
      final svc = LocalArcadeLeaderboardService(cache);
      expect(svc.best(ArcadeGameId.patternSprint, ArcadeDifficulty.insane), isNull);
    });
  });

  // -------------------------------------------------------------------------
  // wouldBeNewBest()
  // -------------------------------------------------------------------------

  group('LocalArcadeLeaderboardService.wouldBeNewBest()', () {
    test('returns true when board is empty', () {
      final svc = LocalArcadeLeaderboardService(cache);
      expect(svc.wouldBeNewBest(_result(score: 100)), isTrue);
    });

    test('returns true when new score exceeds current best', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(_result(score: 300));
      expect(svc.wouldBeNewBest(_result(score: 301)), isTrue);
    });

    test('returns false when new score equals current best (same duration)', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(
        _result(score: 300, duration: const Duration(seconds: 60)),
      );
      expect(
        svc.wouldBeNewBest(
          _result(score: 300, duration: const Duration(seconds: 60)),
        ),
        isFalse,
      );
    });

    test('returns false when new score is lower than current best', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(_result(score: 500));
      expect(svc.wouldBeNewBest(_result(score: 400)), isFalse);
    });

    test('returns true when score is equal but duration is shorter', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(
        _result(score: 300, duration: const Duration(seconds: 90)),
      );
      expect(
        svc.wouldBeNewBest(
          _result(score: 300, duration: const Duration(seconds: 60)),
        ),
        isTrue,
      );
    });
  });

  // -------------------------------------------------------------------------
  // clearBoard()
  // -------------------------------------------------------------------------

  group('LocalArcadeLeaderboardService.clearBoard()', () {
    test('removes all entries for the specified game+difficulty', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(_result(
          gameId: ArcadeGameId.quickMathRush,
          difficulty: ArcadeDifficulty.normal,
          score: 400));
      await svc.recordRun(_result(
          gameId: ArcadeGameId.memoryFlip,
          difficulty: ArcadeDifficulty.normal,
          score: 600));

      await svc.clearBoard(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal);

      expect(svc.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal), isEmpty);
      // Other boards unaffected
      expect(svc.top(ArcadeGameId.memoryFlip, ArcadeDifficulty.normal), isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // clearAll()
  // -------------------------------------------------------------------------

  group('LocalArcadeLeaderboardService.clearAll()', () {
    test('removes all entries across all boards', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(_result(gameId: ArcadeGameId.quickMathRush, score: 400));
      await svc.recordRun(
          _result(gameId: ArcadeGameId.memoryFlip, difficulty: ArcadeDifficulty.easy, score: 600));

      await svc.clearAll();

      for (final id in ArcadeGameId.values) {
        for (final diff in ArcadeDifficulty.values) {
          expect(svc.top(id, diff), isEmpty, reason: 'Board $id/$diff not cleared');
        }
      }
    });
  });

  // -------------------------------------------------------------------------
  // Persistence across re-creation
  // -------------------------------------------------------------------------

  group('LocalArcadeLeaderboardService persistence', () {
    test('recorded scores survive service re-creation', () async {
      final svc1 = LocalArcadeLeaderboardService(cache);
      await svc1.recordRun(_result(score: 777));

      final svc2 = LocalArcadeLeaderboardService(cache);
      expect(svc2.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal).first.score, 777);
    });

    test('clearAll survives service re-creation', () async {
      final svc1 = LocalArcadeLeaderboardService(cache);
      await svc1.recordRun(_result(score: 100));
      await svc1.clearAll();

      final svc2 = LocalArcadeLeaderboardService(cache);
      expect(svc2.top(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal), isEmpty);
    });

    test('multiple game/difficulty entries all persist', () async {
      final svc1 = LocalArcadeLeaderboardService(cache);
      await svc1.recordRun(_result(
          gameId: ArcadeGameId.patternSprint,
          difficulty: ArcadeDifficulty.easy,
          score: 111));
      await svc1.recordRun(_result(
          gameId: ArcadeGameId.memoryFlip,
          difficulty: ArcadeDifficulty.hard,
          score: 888));

      final svc2 = LocalArcadeLeaderboardService(cache);
      expect(
        svc2.top(ArcadeGameId.patternSprint, ArcadeDifficulty.easy).first.score,
        111,
      );
      expect(
        svc2.top(ArcadeGameId.memoryFlip, ArcadeDifficulty.hard).first.score,
        888,
      );
    });
  });

  // -------------------------------------------------------------------------
  // topForGame()
  // -------------------------------------------------------------------------

  group('LocalArcadeLeaderboardService.topForGame()', () {
    test('merges entries across all difficulties for a game', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(
          _result(gameId: ArcadeGameId.quickMathRush, difficulty: ArcadeDifficulty.easy, score: 100));
      await svc.recordRun(
          _result(gameId: ArcadeGameId.quickMathRush, difficulty: ArcadeDifficulty.hard, score: 900));

      final list = svc.topForGame(ArcadeGameId.quickMathRush, limit: 10);
      expect(list.any((e) => e.score == 100), isTrue);
      expect(list.any((e) => e.score == 900), isTrue);
    });

    test('topForGame is sorted by score descending', () async {
      final svc = LocalArcadeLeaderboardService(cache);
      await svc.recordRun(
          _result(gameId: ArcadeGameId.quickMathRush, difficulty: ArcadeDifficulty.easy, score: 200));
      await svc.recordRun(
          _result(gameId: ArcadeGameId.quickMathRush, difficulty: ArcadeDifficulty.hard, score: 800));

      final list = svc.topForGame(ArcadeGameId.quickMathRush);
      expect(list.first.score, 800);
    });
  });
}
