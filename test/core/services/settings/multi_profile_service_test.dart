import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/multi_profile_service.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir =
        await Directory.systemTemp.createTemp('multi_profile_service_test');
    Hive.init(tempDir.path);
  });

  tearDown(() async {
    for (final name in ['multi_profiles', 'settings']) {
      if (Hive.isBoxOpen(name)) {
        await Hive.box(name).clear();
        await Hive.box(name).close();
        await Hive.deleteBoxFromDisk(name);
      }
    }
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // ProfileData data class
  // ---------------------------------------------------------------------------

  group('ProfileData', () {
    test('rank: Trivia Novice for level < 5', () {
      final p = ProfileData(
        id: '1',
        name: 'Test',
        createdAt: DateTime(2026),
        lastActive: DateTime(2026),
        level: 3,
      );
      expect(p.rank, 'Trivia Novice');
    });

    test('rank: Quiz Enthusiast for level 5', () {
      final p = ProfileData(
        id: '1',
        name: 'Test',
        createdAt: DateTime(2026),
        lastActive: DateTime(2026),
        level: 5,
      );
      expect(p.rank, 'Quiz Enthusiast');
    });

    test('rank: Trivia Legend for level 50', () {
      final p = ProfileData(
        id: '1',
        name: 'Test',
        createdAt: DateTime(2026),
        lastActive: DateTime(2026),
        level: 50,
      );
      expect(p.rank, 'Trivia Legend');
    });

    test('defaults: isPremium false, level 1, currentXP 0, maxXP 500', () {
      final p = ProfileData(
        id: '1',
        name: 'Test',
        createdAt: DateTime(2026),
        lastActive: DateTime(2026),
      );
      expect(p.isPremium, isFalse);
      expect(p.level, 1);
      expect(p.currentXP, 0);
      expect(p.maxXP, 500);
      expect(p.gameStats, isEmpty);
      expect(p.preferences, isEmpty);
      expect(p.userRoles, isEmpty);
    });

    test('copyWith name updated, id preserved', () {
      final p = ProfileData(
        id: 'orig',
        name: 'Old',
        createdAt: DateTime(2026),
        lastActive: DateTime(2026),
      );
      final updated = p.copyWith(name: 'New');
      expect(updated.id, 'orig');
      expect(updated.name, 'New');
    });

    test('copyWith level and XP updated', () {
      final p = ProfileData(
        id: '1',
        name: 'Test',
        createdAt: DateTime(2026),
        lastActive: DateTime(2026),
      );
      final updated = p.copyWith(level: 5, currentXP: 200, maxXP: 750);
      expect(updated.level, 5);
      expect(updated.currentXP, 200);
      expect(updated.maxXP, 750);
    });

    test('toJson / fromJson round-trip', () {
      final p = ProfileData(
        id: 'id1',
        name: 'Alice',
        level: 2,
        currentXP: 100,
        maxXP: 600,
        createdAt: DateTime(2026, 1, 1),
        lastActive: DateTime(2026, 1, 2),
      );
      final json = p.toJson();
      final restored = ProfileData.fromJson(json);
      expect(restored.id, 'id1');
      expect(restored.name, 'Alice');
      expect(restored.level, 2);
      expect(restored.currentXP, 100);
      expect(restored.maxXP, 600);
    });
  });

  // ---------------------------------------------------------------------------
  // empty state
  // ---------------------------------------------------------------------------

  group('empty state', () {
    test('getAllProfiles returns empty list before any profiles', () async {
      final svc = MultiProfileService();
      expect(await svc.getAllProfiles(), isEmpty);
    });

    test('getActiveProfile returns null before any profiles', () async {
      final svc = MultiProfileService();
      expect(await svc.getActiveProfile(), isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // createProfile
  // ---------------------------------------------------------------------------

  group('createProfile', () {
    test('persists new profile and sets first active profile', () async {
      final service = MultiProfileService();

      final created = await service.createProfile(name: 'Player One');

      expect(created, isNotNull);

      final allProfiles = await service.getAllProfiles();
      expect(allProfiles.length, 1);
      expect(allProfiles.first.name, 'Player One');

      final activeProfile = await service.getActiveProfile();
      expect(activeProfile, isNotNull);
      expect(activeProfile!.id, created!.id);
    });

    test('id is non-empty UUID', () async {
      final svc = MultiProfileService();
      final p = await svc.createProfile(name: 'UUID Test');
      expect(p!.id.isNotEmpty, isTrue);
    });

    test('createdAt and lastActive are set', () async {
      final svc = MultiProfileService();
      final before = DateTime.now().subtract(const Duration(seconds: 1));
      final p = await svc.createProfile(name: 'Time Test');
      expect(p!.createdAt.isAfter(before), isTrue);
      expect(p.lastActive.isAfter(before), isTrue);
    });

    test('duplicate name returns null', () async {
      final svc = MultiProfileService();
      await svc.createProfile(name: 'Alice');
      final dup = await svc.createProfile(name: 'Alice');
      expect(dup, isNull);
    });

    test('max 5 profiles — 6th create returns null', () async {
      final svc = MultiProfileService();
      for (int i = 1; i <= 5; i++) {
        final p = await svc.createProfile(name: 'Player $i');
        expect(p, isNotNull, reason: 'Profile $i should be created');
      }
      final sixth = await svc.createProfile(name: 'Player 6');
      expect(sixth, isNull);
    });
  });

  // ---------------------------------------------------------------------------
  // setActiveProfile / getActiveProfile
  // ---------------------------------------------------------------------------

  group('setActiveProfile / getActiveProfile', () {
    test('setActiveProfile returns true for valid id', () async {
      final svc = MultiProfileService();
      final p = await svc.createProfile(name: 'P1');
      final result = await svc.setActiveProfile(p!.id);
      expect(result, isTrue);
    });

    test('setActiveProfile returns false for unknown id', () async {
      final svc = MultiProfileService();
      await svc.createProfile(name: 'P1');
      final result = await svc.setActiveProfile('nonexistent_id');
      expect(result, isFalse);
    });

    test('getActiveProfile returns correct profile after setActiveProfile',
        () async {
      final svc = MultiProfileService();
      final p1 = await svc.createProfile(name: 'P1');
      final p2 = await svc.createProfile(name: 'P2');

      await svc.setActiveProfile(p2!.id);
      final active = await svc.getActiveProfile();
      expect(active!.id, p2.id);
      expect(active.name, 'P2');

      await svc.setActiveProfile(p1!.id);
      final active2 = await svc.getActiveProfile();
      expect(active2!.id, p1.id);
    });
  });

  // ---------------------------------------------------------------------------
  // getAllProfiles
  // ---------------------------------------------------------------------------

  group('getAllProfiles', () {
    test('returns all created profiles', () async {
      final svc = MultiProfileService();
      await svc.createProfile(name: 'A');
      await svc.createProfile(name: 'B');
      await svc.createProfile(name: 'C');
      final profiles = await svc.getAllProfiles();
      expect(profiles.length, 3);
    });

    test('empty after clearAllProfiles', () async {
      final svc = MultiProfileService();
      await svc.createProfile(name: 'ToDelete');
      await svc.clearAllProfiles();
      expect(await svc.getAllProfiles(), isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // updateProfile
  // ---------------------------------------------------------------------------

  group('updateProfile', () {
    test('returns true and persists new name', () async {
      final svc = MultiProfileService();
      final p = await svc.createProfile(name: 'OldName');
      final ok = await svc.updateProfile(p!.id, name: 'NewName');
      expect(ok, isTrue);

      final profiles = await svc.getAllProfiles();
      expect(profiles.any((x) => x.name == 'NewName'), isTrue);
    });

    test('returns false for unknown profile id', () async {
      final svc = MultiProfileService();
      await svc.createProfile(name: 'Base');
      final ok = await svc.updateProfile('unknown_id', name: 'X');
      expect(ok, isFalse);
    });

    test('level and XP updated', () async {
      final svc = MultiProfileService();
      final p = await svc.createProfile(name: 'LevelUp');
      await svc.updateProfile(p!.id, level: 10, currentXP: 250, maxXP: 1000);

      final profiles = await svc.getAllProfiles();
      final updated = profiles.firstWhere((x) => x.id == p.id);
      expect(updated.level, 10);
      expect(updated.currentXP, 250);
      expect(updated.maxXP, 1000);
    });
  });

  // ---------------------------------------------------------------------------
  // deleteProfile
  // ---------------------------------------------------------------------------

  group('deleteProfile', () {
    test('removes profile from getAllProfiles()', () async {
      final svc = MultiProfileService();
      final p1 = await svc.createProfile(name: 'Keep');
      final p2 = await svc.createProfile(name: 'Delete');
      await svc.deleteProfile(p2!.id);

      final profiles = await svc.getAllProfiles();
      expect(profiles.length, 1);
      expect(profiles.first.id, p1!.id);
    });

    test('returns false when only 1 profile remains', () async {
      final svc = MultiProfileService();
      final p = await svc.createProfile(name: 'LastOne');
      final result = await svc.deleteProfile(p!.id);
      expect(result, isFalse);

      final profiles = await svc.getAllProfiles();
      expect(profiles.length, 1); // still present
    });

    test('active profile switches to remaining when active profile deleted',
        () async {
      final svc = MultiProfileService();
      final p1 = await svc.createProfile(name: 'Active');
      final p2 = await svc.createProfile(name: 'Other');
      await svc.setActiveProfile(p1!.id);

      await svc.deleteProfile(p1.id);
      final active = await svc.getActiveProfile();
      expect(active, isNotNull);
      expect(active!.id, p2!.id);
    });
  });

  // ---------------------------------------------------------------------------
  // addXPToProfile
  // ---------------------------------------------------------------------------

  group('addXPToProfile', () {
    test('increments XP without level-up', () async {
      final svc = MultiProfileService();
      final p = await svc.createProfile(name: 'XPTest');
      final result = await svc.addXPToProfile(p!.id, 200);

      expect(result['newXP'], 200);
      expect(result['newLevel'], 1);
      expect(result['leveledUp'], isFalse);
      expect(result['xpGained'], 200);
    });

    test('triggers level-up when XP >= maxXP (500)', () async {
      final svc = MultiProfileService();
      final p = await svc.createProfile(name: 'LevelTest');
      // Default maxXP is 500; add 600 to trigger level-up
      final result = await svc.addXPToProfile(p!.id, 600);

      expect(result['leveledUp'], isTrue);
      expect(result['newLevel'], 2);
      expect(result['newXP'], 100); // 600 - 500 = 100
      expect(result['newMaxXP'], greaterThan(500));
    });

    test('result contains required keys', () async {
      final svc = MultiProfileService();
      final p = await svc.createProfile(name: 'KeyTest');
      final result = await svc.addXPToProfile(p!.id, 50);

      for (final key in [
        'leveledUp',
        'newLevel',
        'newXP',
        'newMaxXP',
        'xpGained'
      ]) {
        expect(result.containsKey(key), isTrue, reason: 'Missing key: $key');
      }
    });

    test('returns error map for unknown profile', () async {
      final svc = MultiProfileService();
      await svc.createProfile(name: 'Exists');
      final result = await svc.addXPToProfile('unknown_id', 100);
      expect(result.containsKey('error'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // updateActiveProfileGameStats
  // ---------------------------------------------------------------------------

  group('updateActiveProfileGameStats', () {
    test('merges stats into active profile', () async {
      final svc = MultiProfileService();
      await svc.createProfile(name: 'StatsTest'); // auto-active

      final ok = await svc.updateActiveProfileGameStats({
        'totalQuizzes': 5,
        'highScore': 1000,
      });
      expect(ok, isTrue);

      final active = await svc.getActiveProfile();
      expect(active!.gameStats['totalQuizzes'], 5);
      expect(active.gameStats['highScore'], 1000);
    });

    test('returns false when no active profile', () async {
      final svc = MultiProfileService();
      // No profiles created → no active profile
      final ok = await svc.updateActiveProfileGameStats({'score': 100});
      expect(ok, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // getAccountData / saveAccountData
  // ---------------------------------------------------------------------------

  group('getAccountData / saveAccountData', () {
    test('getAccountData returns empty map before any save', () async {
      final svc = MultiProfileService();
      final data = await svc.getAccountData();
      expect(data, isEmpty);
    });

    test('round-trip: saved data is retrieved correctly', () async {
      final svc = MultiProfileService();
      await svc.saveAccountData({'userId': 'u123', 'plan': 'premium'});
      final data = await svc.getAccountData();
      expect(data['userId'], 'u123');
      expect(data['plan'], 'premium');
    });
  });

  // ---------------------------------------------------------------------------
  // getProfileStats
  // ---------------------------------------------------------------------------

  group('getProfileStats', () {
    test('returns expected keys', () async {
      final svc = MultiProfileService();
      await svc.getAllProfiles(); // open box lazily
      final stats = svc.getProfileStats();

      expect(stats.containsKey('total_profiles'), isTrue);
      expect(stats.containsKey('max_profiles'), isTrue);
      expect(stats.containsKey('active_profile_id'), isTrue);
      expect(stats.containsKey('has_account_data'), isTrue);
    });

    test('total_profiles reflects created count', () async {
      final svc = MultiProfileService();
      await svc.createProfile(name: 'S1');
      await svc.createProfile(name: 'S2');
      final stats = svc.getProfileStats();
      expect(stats['total_profiles'], 2);
    });

    test('max_profiles is 5', () async {
      final svc = MultiProfileService();
      await svc.getAllProfiles(); // ensure box open
      final stats = svc.getProfileStats();
      expect(stats['max_profiles'], 5);
    });
  });
}
