import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/arcade/services/arcade_mission_claim_service.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';

void main() {
  late Directory tempDir;
  late AppCacheService cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('mission_claim_test');
    Hive.init(tempDir.path);
    cache = await AppCacheService.initialize();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('cache');
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // isClaimedToday
  // ---------------------------------------------------------------------------

  group('ArcadeMissionClaimService.isClaimedToday', () {
    test('returns false when nothing has been claimed', () {
      final svc = ArcadeMissionClaimService(cache);
      expect(svc.isClaimedToday('mission_1'), isFalse);
    });

    test('returns false for a different mission id after claiming one',
        () async {
      final svc = ArcadeMissionClaimService(cache);
      await svc.markClaimedToday('mission_1');
      expect(svc.isClaimedToday('mission_2'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // markClaimedToday
  // ---------------------------------------------------------------------------

  group('ArcadeMissionClaimService.markClaimedToday', () {
    test('isClaimedToday returns true after marking', () async {
      final svc = ArcadeMissionClaimService(cache);
      await svc.markClaimedToday('mission_a');
      expect(svc.isClaimedToday('mission_a'), isTrue);
    });

    test('can mark multiple missions in the same day', () async {
      final svc = ArcadeMissionClaimService(cache);
      await svc.markClaimedToday('m1');
      await svc.markClaimedToday('m2');
      await svc.markClaimedToday('m3');

      expect(svc.isClaimedToday('m1'), isTrue);
      expect(svc.isClaimedToday('m2'), isTrue);
      expect(svc.isClaimedToday('m3'), isTrue);
    });

    test('marking the same mission twice is idempotent', () async {
      final svc = ArcadeMissionClaimService(cache);
      await svc.markClaimedToday('mission_a');
      await svc.markClaimedToday('mission_a');
      expect(svc.isClaimedToday('mission_a'), isTrue);
    });

    test('persists across service re-creation', () async {
      final svc1 = ArcadeMissionClaimService(cache);
      await svc1.markClaimedToday('mission_x');

      // Re-create with same cache instance
      final svc2 = ArcadeMissionClaimService(cache);
      expect(svc2.isClaimedToday('mission_x'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // clearToday
  // ---------------------------------------------------------------------------

  group('ArcadeMissionClaimService.clearToday', () {
    test('clears all missions claimed today', () async {
      final svc = ArcadeMissionClaimService(cache);
      await svc.markClaimedToday('m1');
      await svc.markClaimedToday('m2');

      await svc.clearToday();

      expect(svc.isClaimedToday('m1'), isFalse);
      expect(svc.isClaimedToday('m2'), isFalse);
    });

    test('clearToday on an empty day is a no-op', () async {
      final svc = ArcadeMissionClaimService(cache);
      await svc.clearToday(); // should not throw
      expect(svc.isClaimedToday('m1'), isFalse);
    });

    test('after clear, new claims can be made', () async {
      final svc = ArcadeMissionClaimService(cache);
      await svc.markClaimedToday('m1');
      await svc.clearToday();
      await svc.markClaimedToday('m1');
      expect(svc.isClaimedToday('m1'), isTrue);
    });
  });
}
