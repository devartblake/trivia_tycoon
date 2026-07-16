import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:synaptix/core/services/settings/achievement_settings_service.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir =
        await Directory.systemTemp.createTemp('achievement_settings_test_');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  AchievementSettingsService makeService() => AchievementSettingsService();

  // -------------------------------------------------------------------------
  // getUnlockedBadges
  // -------------------------------------------------------------------------

  group('getUnlockedBadges', () {
    test('returns empty list when nothing is stored', () async {
      final svc = makeService();
      expect(await svc.getUnlockedBadges(), isEmpty);
    });

    test('returns stored badges after unlocking', () async {
      final svc = makeService();
      await svc.unlockBadge('first_win');
      await svc.unlockBadge('speedster');
      final badges = await svc.getUnlockedBadges();
      expect(badges, containsAll(['first_win', 'speedster']));
    });
  });

  // -------------------------------------------------------------------------
  // unlockBadge
  // -------------------------------------------------------------------------

  group('unlockBadge', () {
    test('adds a new badge to the list', () async {
      final svc = makeService();
      await svc.unlockBadge('newcomer');
      expect(await svc.getUnlockedBadges(), contains('newcomer'));
    });

    test('does not duplicate an already-unlocked badge', () async {
      final svc = makeService();
      await svc.unlockBadge('winner');
      await svc.unlockBadge('winner');
      final badges = await svc.getUnlockedBadges();
      expect(badges.where((b) => b == 'winner').length, 1);
    });

    test('unlocking multiple distinct badges stores all of them', () async {
      final svc = makeService();
      await svc.unlockBadge('a');
      await svc.unlockBadge('b');
      await svc.unlockBadge('c');
      final badges = await svc.getUnlockedBadges();
      expect(badges.length, 3);
    });

    test('duplicate unlock does not change total badge count', () async {
      final svc = makeService();
      await svc.unlockBadge('dup');
      await svc.unlockBadge('dup');
      expect((await svc.getUnlockedBadges()).length, 1);
    });

    test('persists across separate service instances', () async {
      await makeService().unlockBadge('persistent');
      expect(await makeService().getUnlockedBadges(), contains('persistent'));
    });
  });
}
