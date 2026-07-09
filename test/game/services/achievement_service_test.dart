import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/game/models/achievement.dart';
import 'package:trivia_tycoon/game/services/achievement_service.dart';

// Stub that throws on API calls to keep tests free of network I/O.
class _StubApiService extends ApiService {
  _StubApiService()
      : super(baseUrl: 'http://stub.invalid', initializeCache: false);

  @override
  Future<List<Map<String, dynamic>>> fetchAchievements({
    String? playerId,
  }) async {
    throw UnimplementedError('stub');
  }

  @override
  Future<void> unlockAchievement(String playerName, String achievement) async {
    throw UnimplementedError('stub');
  }
}

Achievement _makeAch({String id = 'ach1', bool unlocked = false}) =>
    Achievement(
      id: id,
      title: 'Title $id',
      description: 'Desc $id',
      isUnlocked: unlocked,
    );

void main() {
  late Directory tempDir;
  late AchievementService svc;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('achievement_test_');
    Hive.init(tempDir.path);
    svc = AchievementService(apiService: _StubApiService());
    await svc.initialize();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Achievement data class
  // ---------------------------------------------------------------------------

  group('Achievement data class', () {
    test('holds required fields', () {
      final a = _makeAch();
      expect(a.id, 'ach1');
      expect(a.title, 'Title ach1');
      expect(a.description, 'Desc ach1');
    });

    test('isUnlocked defaults to false', () {
      expect(_makeAch().isUnlocked, isFalse);
    });

    test('unlockedAt is null when not unlocked', () {
      expect(_makeAch().unlockedAt, isNull);
    });

    test('unlock() returns unlocked copy', () {
      final unlocked = _makeAch().unlock();
      expect(unlocked.isUnlocked, isTrue);
      expect(unlocked.unlockedAt, isNotNull);
    });

    test('unlock() preserves id and title', () {
      final a = _makeAch(id: 'x99');
      final unlocked = a.unlock();
      expect(unlocked.id, 'x99');
      expect(unlocked.title, 'Title x99');
    });

    test('copyWith updates fields', () {
      final a = _makeAch();
      final updated = a.copyWith(title: 'New Title');
      expect(updated.title, 'New Title');
      expect(updated.id, a.id); // preserved
    });

    test('toJson / fromJson round-trip', () {
      final a = Achievement(
          id: 'rt1', title: 'RoundTrip', description: 'Test', isUnlocked: true);
      final restored = Achievement.fromJson(a.toJson());
      expect(restored.id, 'rt1');
      expect(restored.title, 'RoundTrip');
      expect(restored.isUnlocked, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // initialize
  // ---------------------------------------------------------------------------

  group('initialize', () {
    test('opens Hive box without error', () async {
      expect(Hive.isBoxOpen('achievement_data'), isTrue);
    });

    test('idempotent: safe to call twice', () async {
      await expectLater(svc.initialize(), completes);
    });
  });

  // ---------------------------------------------------------------------------
  // getUnlockedAchievements
  // ---------------------------------------------------------------------------

  group('getUnlockedAchievements', () {
    test('returns empty list before any data', () async {
      final result = await svc.getUnlockedAchievements();
      expect(result, isEmpty);
    });

    test('returns seeded achievements from Hive', () async {
      final ach = _makeAch(id: 'seed1').unlock();
      final box = await Hive.openBox('achievement_data');
      await box.put('unlocked_achievements', [ach.toJson()]);

      // New service instance so cache is empty
      final svc2 = AchievementService(apiService: _StubApiService());
      final result = await svc2.getUnlockedAchievements();
      expect(result.length, 1);
      expect(result.first.id, 'seed1');
      expect(result.first.isUnlocked, isTrue);
    });

    test('returns correct count when multiple seeded', () async {
      final box = await Hive.openBox('achievement_data');
      await box.put('unlocked_achievements', [
        _makeAch(id: 'a1').toJson(),
        _makeAch(id: 'a2').toJson(),
        _makeAch(id: 'a3').toJson(),
      ]);

      final svc2 = AchievementService(apiService: _StubApiService());
      final result = await svc2.getUnlockedAchievements();
      expect(result.length, 3);
    });
  });

  // ---------------------------------------------------------------------------
  // isAchievementUnlocked
  // ---------------------------------------------------------------------------

  group('isAchievementUnlocked', () {
    test('returns false for unknown id', () async {
      final result = await svc.isAchievementUnlocked('nonexistent');
      expect(result, isFalse);
    });

    test('returns true after seeding achievement with matching id', () async {
      final box = await Hive.openBox('achievement_data');
      await box.put('unlocked_achievements', [_makeAch(id: 'x10').toJson()]);

      final svc2 = AchievementService(apiService: _StubApiService());
      expect(await svc2.isAchievementUnlocked('x10'), isTrue);
    });

    test('returns false for different id even when others are seeded',
        () async {
      final box = await Hive.openBox('achievement_data');
      await box.put('unlocked_achievements', [_makeAch(id: 'x20').toJson()]);

      final svc2 = AchievementService(apiService: _StubApiService());
      expect(await svc2.isAchievementUnlocked('x99'), isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // clearAllAchievementData
  // ---------------------------------------------------------------------------

  group('clearAllAchievementData', () {
    test('getUnlockedAchievements returns empty after clear', () async {
      final box = await Hive.openBox('achievement_data');
      await box.put('unlocked_achievements', [_makeAch(id: 'c1').toJson()]);

      final svc2 = AchievementService(apiService: _StubApiService());
      await svc2.clearAllAchievementData();
      final result = await svc2.getUnlockedAchievements();
      expect(result, isEmpty);
    });

    test('getAchievementStats returns empty after clear', () async {
      final box = await Hive.openBox('achievement_data');
      await box.put('achievement_stats', {'ach1': 'data'});

      final svc2 = AchievementService(apiService: _StubApiService());
      await svc2.clearAllAchievementData();
      final stats = await svc2.getAchievementStats();
      expect(stats, isEmpty);
    });
  });

  // ---------------------------------------------------------------------------
  // getAchievementStats
  // ---------------------------------------------------------------------------

  group('getAchievementStats', () {
    test('returns empty map initially', () async {
      final stats = await svc.getAchievementStats();
      expect(stats, isA<Map<String, dynamic>>());
      expect(stats, isEmpty);
    });

    test('returns stats seeded directly into Hive', () async {
      final box = await Hive.openBox('achievement_data');
      await box.put('achievement_stats', {
        'ach1': {'unlocked_at': '2026-01-01', 'player_name': 'Alice'},
      });

      final svc2 = AchievementService(apiService: _StubApiService());
      final stats = await svc2.getAchievementStats();
      expect(stats.containsKey('ach1'), isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // fetchAchievements — stub throws (error propagation)
  // ---------------------------------------------------------------------------

  group('fetchAchievements — stub throws', () {
    test('propagates error when API stub throws', () async {
      await expectLater(
        svc.fetchAchievements('player'),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // saveAchievements
  // ---------------------------------------------------------------------------

  group('saveAchievements', () {
    test('throws due to incompatible cast in AppSettings fallback', () async {
      // AppSettings.saveUnlockedAchievements receives a CastList<Map,String>
      // which throws a TypeError when Hive serializes it.
      // This documents a known incompatibility in the production code.
      await expectLater(
        svc.saveAchievements([_makeAch()]),
        throwsA(anything),
      );
    });
  });
}
