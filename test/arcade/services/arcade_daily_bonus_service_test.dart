import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/arcade/services/arcade_daily_bonus_service.dart';
import 'package:trivia_tycoon/core/services/storage/app_cache_service.dart';

void main() {
  late Directory tempDir;
  late AppCacheService cache;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('daily_bonus_test');
    Hive.init(tempDir.path);
    cache = await AppCacheService.initialize();
  });

  tearDown(() async {
    await Hive.deleteBoxFromDisk('cache');
    await tempDir.delete(recursive: true);
  });

  // ---------------------------------------------------------------------------
  // Initial state
  // ---------------------------------------------------------------------------

  group('ArcadeDailyBonusService initial state', () {
    test('isClaimedToday is false on first use', () {
      final svc = ArcadeDailyBonusService(cache);
      expect(svc.isClaimedToday, isFalse);
    });

    test('streakDays is 0 on first use', () {
      final svc = ArcadeDailyBonusService(cache);
      expect(svc.currentStreak, 0);
    });

    test('todayReward returns Day 1 schedule on first use', () {
      final svc = ArcadeDailyBonusService(cache);
      expect(svc.todayCoins, 250);
      expect(svc.todayGems, 2);
    });
  });

  // ---------------------------------------------------------------------------
  // tryClaimToday
  // ---------------------------------------------------------------------------

  group('ArcadeDailyBonusService.tryClaimToday', () {
    test('returns true on first claim', () {
      final svc = ArcadeDailyBonusService(cache);
      expect(svc.tryClaimToday(), isTrue);
    });

    test('isClaimedToday is true after successful claim', () {
      final svc = ArcadeDailyBonusService(cache);
      svc.tryClaimToday();
      expect(svc.isClaimedToday, isTrue);
    });

    test('returns false on second claim (same day)', () {
      final svc = ArcadeDailyBonusService(cache);
      svc.tryClaimToday();
      expect(svc.tryClaimToday(), isFalse);
    });

    test('streakDays increments to 1 after first claim', () {
      final svc = ArcadeDailyBonusService(cache);
      svc.tryClaimToday();
      expect(svc.currentStreak, 1);
    });

    test('bestStreakDays matches streakDays after first claim', () {
      final svc = ArcadeDailyBonusService(cache);
      svc.tryClaimToday();
      expect(svc.bestStreakDays, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Streak continuity — simulate yesterday claim
  // ---------------------------------------------------------------------------

  group('ArcadeDailyBonusService streak continuity', () {
    test('streak increments when yesterday was claimed', () async {
      // Seed storage: claim was on yesterday's date
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      await cache.put('arcade_daily_bonus_v1.lastDay', yesterdayKey);
      await cache.put('arcade_daily_bonus_v1.streak', 3);
      await cache.put('arcade_daily_bonus_v1.bestStreak', 3);
      // claimed flag is cleared for today automatically
      await cache.put('arcade_daily_bonus_v1.claimed', false);

      final svc = ArcadeDailyBonusService(cache);
      svc.tryClaimToday();

      expect(svc.currentStreak, 4);
    });

    test('streak resets to 1 when more than 1 day has passed', () async {
      // Seed storage: last claim was 3 days ago
      final old = DateTime.now().subtract(const Duration(days: 3));
      final oldKey =
          '${old.year}-${old.month.toString().padLeft(2, '0')}-${old.day.toString().padLeft(2, '0')}';

      await cache.put('arcade_daily_bonus_v1.lastDay', oldKey);
      await cache.put('arcade_daily_bonus_v1.streak', 5);
      await cache.put('arcade_daily_bonus_v1.claimed', false);

      final svc = ArcadeDailyBonusService(cache);
      svc.tryClaimToday();

      expect(svc.currentStreak, 1);
    });
  });

  // ---------------------------------------------------------------------------
  // Reward schedule
  // ---------------------------------------------------------------------------

  group('ArcadeDailyBonusService reward schedule', () {
    test('Day 7 reward is larger than Day 1 reward', () {
      // Seed streak = 6 (so claiming would advance to 7)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final key =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      cache.put('arcade_daily_bonus_v1.lastDay', key);
      cache.put('arcade_daily_bonus_v1.streak', 6);
      cache.put('arcade_daily_bonus_v1.claimed', false);

      final svc = ArcadeDailyBonusService(cache);
      final d7reward = svc.todayReward;
      expect(d7reward.coins, greaterThan(250)); // Day 1 is 250
      expect(d7reward.gems, greaterThan(2)); // Day 1 is 2
    });

    test('reward caps at Day 7 (no wrap beyond schedule)', () {
      // Seed streak = 100 (beyond schedule length of 7)
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final key =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';

      cache.put('arcade_daily_bonus_v1.lastDay', key);
      cache.put('arcade_daily_bonus_v1.streak', 100);
      cache.put('arcade_daily_bonus_v1.claimed', false);

      final svc = ArcadeDailyBonusService(cache);
      // todayReward at streak 100 should be same as Day 7 (cap)
      expect(svc.todayReward.coins, 900);
      expect(svc.todayReward.gems, 5);
    });
  });

  // ---------------------------------------------------------------------------
  // previewTomorrowReward
  // ---------------------------------------------------------------------------

  group('ArcadeDailyBonusService.previewTomorrowReward', () {
    test('tomorrow reward has more coins than today on Day 1', () {
      final svc = ArcadeDailyBonusService(cache);
      final today = svc.todayReward;
      final tomorrow = svc.previewTomorrowReward();
      expect(tomorrow.coins, greaterThan(today.coins));
    });
  });

  // ---------------------------------------------------------------------------
  // DailyBonusReward serialisation
  // ---------------------------------------------------------------------------

  group('DailyBonusReward serialisation', () {
    test('round-trips through toJson / fromJson', () {
      const r = DailyBonusReward(coins: 300, gems: 3);
      final rt = DailyBonusReward.fromJson(r.toJson());
      expect(rt.coins, r.coins);
      expect(rt.gems, r.gems);
    });

    test('fromJson defaults on empty map', () {
      final r = DailyBonusReward.fromJson({});
      expect(r.coins, 0);
      expect(r.gems, 0);
    });
  });
}
