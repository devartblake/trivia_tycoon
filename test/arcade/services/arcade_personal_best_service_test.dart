import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_difficulty.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_game_id.dart';
import 'package:trivia_tycoon/arcade/domain/arcade_result.dart';
import 'package:trivia_tycoon/arcade/services/arcade_personal_best_service.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';

ArcadeResult _result({
  ArcadeGameId gameId = ArcadeGameId.quickMathRush,
  ArcadeDifficulty difficulty = ArcadeDifficulty.normal,
  int score = 500,
}) =>
    ArcadeResult(
      gameId: gameId,
      difficulty: difficulty,
      score: score,
      duration: const Duration(seconds: 60),
    );

void main() {
  late Directory tempDir;
  late AppCacheService cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('personal_best_test');
    Hive.init(tempDir.path);
    cache = await AppCacheService.initialize();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('cache');
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // getBest — initial state
  // ---------------------------------------------------------------------------

  group('ArcadePersonalBestService.getBest initial', () {
    test('returns 0 when no best has been recorded', () {
      final svc = ArcadePersonalBestService(cache);
      expect(
        svc.getBest(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal),
        0,
      );
    });

    test('returns 0 for an unseen game/difficulty combination', () {
      final svc = ArcadePersonalBestService(cache);
      expect(svc.getBest(ArcadeGameId.memoryFlip, ArcadeDifficulty.hard), 0);
    });
  });

  // ---------------------------------------------------------------------------
  // trySetBest
  // ---------------------------------------------------------------------------

  group('ArcadePersonalBestService.trySetBest', () {
    test('returns true when score exceeds the current best (0)', () {
      final svc = ArcadePersonalBestService(cache);
      expect(svc.trySetBest(_result(score: 100)), isTrue);
    });

    test('stores the new best', () {
      final svc = ArcadePersonalBestService(cache);
      svc.trySetBest(_result(score: 100));
      expect(
        svc.getBest(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal),
        100,
      );
    });

    test('returns false when score equals the current best', () {
      final svc = ArcadePersonalBestService(cache);
      svc.trySetBest(_result(score: 200));
      expect(svc.trySetBest(_result(score: 200)), isFalse);
    });

    test('returns false when score is lower than the current best', () {
      final svc = ArcadePersonalBestService(cache);
      svc.trySetBest(_result(score: 500));
      expect(svc.trySetBest(_result(score: 300)), isFalse);
    });

    test('best score does not decrease', () {
      final svc = ArcadePersonalBestService(cache);
      svc.trySetBest(_result(score: 500));
      svc.trySetBest(_result(score: 200));
      expect(
        svc.getBest(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal),
        500,
      );
    });

    test('records are independent per difficulty', () {
      final svc = ArcadePersonalBestService(cache);
      svc.trySetBest(_result(difficulty: ArcadeDifficulty.easy, score: 100));
      svc.trySetBest(_result(difficulty: ArcadeDifficulty.hard, score: 800));

      expect(svc.getBest(ArcadeGameId.quickMathRush, ArcadeDifficulty.easy), 100);
      expect(svc.getBest(ArcadeGameId.quickMathRush, ArcadeDifficulty.hard), 800);
    });

    test('records are independent per game', () {
      final svc = ArcadePersonalBestService(cache);
      svc.trySetBest(_result(gameId: ArcadeGameId.quickMathRush, score: 400));
      svc.trySetBest(_result(gameId: ArcadeGameId.memoryFlip, score: 900));

      expect(svc.getBest(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal), 400);
      expect(svc.getBest(ArcadeGameId.memoryFlip, ArcadeDifficulty.normal), 900);
    });
  });

  // ---------------------------------------------------------------------------
  // Persistence across re-creation
  // ---------------------------------------------------------------------------

  group('ArcadePersonalBestService persistence', () {
    test('persists best score across service re-creation', () {
      final svc1 = ArcadePersonalBestService(cache);
      svc1.trySetBest(_result(score: 750));

      // Re-create service with same cache
      final svc2 = ArcadePersonalBestService(cache);
      expect(
        svc2.getBest(ArcadeGameId.quickMathRush, ArcadeDifficulty.normal),
        750,
      );
    });

    test('persists multiple game/difficulty entries', () {
      final svc1 = ArcadePersonalBestService(cache);
      svc1.trySetBest(_result(gameId: ArcadeGameId.patternSprint,
          difficulty: ArcadeDifficulty.easy, score: 111));
      svc1.trySetBest(_result(gameId: ArcadeGameId.quickMathRush,
          difficulty: ArcadeDifficulty.insane, score: 999));

      final svc2 = ArcadePersonalBestService(cache);
      expect(svc2.getBest(ArcadeGameId.patternSprint, ArcadeDifficulty.easy), 111);
      expect(svc2.getBest(ArcadeGameId.quickMathRush, ArcadeDifficulty.insane), 999);
    });
  });
}
