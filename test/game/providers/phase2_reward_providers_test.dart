import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/phase2_reward_providers.dart';

void main() {
  group('Phase 2 Reward Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // ────────────────────────────────────────────────────────────────────────
    // Daily Bonus Providers
    // ────────────────────────────────────────────────────────────────────────

    group('dailyBonusConfigProvider', () {
      test('provides daily bonus configuration', () async {
        final config = await container.read(dailyBonusConfigProvider.future);
        expect(config, isNotNull);
        expect(config.coinsAmount, greaterThan(0));
        expect(config.displayName, isNotEmpty);
      });

      test('config has valid reward type', () async {
        final config = await container.read(dailyBonusConfigProvider.future);
        expect(['coins', 'gems'], contains(config.rewardType));
        expect(config.iconName, isNotEmpty);
      });
    });

    group('dailyBonusStatusProvider', () {
      test('provides daily bonus status', () async {
        final status =
            await container.read(dailyBonusStatusProvider.future);
        expect(status, isNotNull);
        expect(status.claimedToday, isFalse);
        expect(status.currentStreak, greaterThanOrEqualTo(0));
      });

      test('status tracking is consistent', () async {
        final status1 =
            await container.read(dailyBonusStatusProvider.future);
        final status2 =
            await container.read(dailyBonusStatusProvider.future);

        expect(status1.claimedToday, status2.claimedToday);
        expect(status1.currentStreak, status2.currentStreak);
        expect(status1.coinsAmount, status2.coinsAmount);
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // Weekly Rewards Providers
    // ────────────────────────────────────────────────────────────────────────

    group('weeklyScheduleProvider', () {
      test('provides 7-day reward schedule', () async {
        final schedule = await container.read(weeklyScheduleProvider.future);
        expect(schedule, isNotEmpty);
        expect(schedule.length, equals(7));
      });

      test('schedule has valid reward data', () async {
        final schedule = await container.read(weeklyScheduleProvider.future);
        for (final day in schedule) {
          expect(day.day, inInclusiveRange(1, 7));
          expect(['coins', 'gems'], contains(day.type));
          if (day.type == 'coins') {
            expect(day.coinsAmount, greaterThan(0));
          } else {
            expect(day.gemsAmount, greaterThan(0));
          }
        }
      });

      test('reward amounts increase throughout week', () async {
        final schedule = await container.read(weeklyScheduleProvider.future);
        final coinRewards = schedule
            .where((d) => d.type == 'coins')
            .map((d) => d.coinsAmount)
            .toList();

        if (coinRewards.length >= 2) {
          for (int i = 1; i < coinRewards.length; i++) {
            expect(
              coinRewards[i],
              greaterThanOrEqualTo(coinRewards[i - 1]),
              reason: 'Rewards should not decrease',
            );
          }
        }
      });
    });

    group('weeklyStreakProvider', () {
      test('provides weekly streak status', () async {
        final streak = await container.read(weeklyStreakProvider.future);
        expect(streak, isNotNull);
        expect(streak.currentDay, inInclusiveRange(1, 7));
        expect(streak.daysClaimedCount, inInclusiveRange(0, 7));
      });

      test('streak data is valid', () async {
        final streak = await container.read(weeklyStreakProvider.future);
        expect(streak.weekResetDate.isAfter(DateTime.now()), true);
        expect(streak.daysClaimedCount, lessThanOrEqualTo(7));
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // Tier Progression Providers
    // ────────────────────────────────────────────────────────────────────────

    group('tierDefinitionsProvider', () {
      test('provides 7 tier definitions', () async {
        final tiers = await container.read(tierDefinitionsProvider.future);
        expect(tiers.length, equals(7));
      });

      test('tiers have valid progression', () async {
        final tiers = await container.read(tierDefinitionsProvider.future);
        for (int i = 0; i < tiers.length; i++) {
          expect(tiers[i].level, equals(i + 1));
          expect(tiers[i].name, isNotEmpty);
          expect(tiers[i].xpRange, greaterThan(0));
        }
      });

      test('tier XP requirements increase', () async {
        final tiers = await container.read(tierDefinitionsProvider.future);
        for (int i = 1; i < tiers.length; i++) {
          expect(
            tiers[i].xpRange,
            greaterThan(tiers[i - 1].xpRange),
            reason: 'XP requirements should increase per tier',
          );
        }
      });
    });

    group('playerTierProgressProvider', () {
      test('provides player tier progress', () async {
        final progress =
            await container.read(playerTierProgressProvider.future);
        expect(progress, isNotNull);
        expect(progress.currentTier, isNotNull);
        expect(progress.currentXp, greaterThanOrEqualTo(0));
      });

      test('progress is within valid bounds', () async {
        final progress =
            await container.read(playerTierProgressProvider.future);
        expect(
          progress.currentTier.level,
          inInclusiveRange(1, 7),
        );
        expect(progress.progressPercentage, inInclusiveRange(0, 100));
      });

      test('calculates progress correctly', () async {
        final progress =
            await container.read(playerTierProgressProvider.future);
        if (!progress.isMaxTier) {
          expect(progress.nextTier, isNotNull);
          expect(
            progress.xpNeededForNextTier,
            greaterThan(0),
          );
        }
      });
    });

    // ────────────────────────────────────────────────────────────────────────
    // Combined Status Provider
    // ────────────────────────────────────────────────────────────────────────

    group('combinedRewardStatusProvider', () {
      test('combines all reward statuses', () async {
        final combined =
            await container.read(combinedRewardStatusProvider.future);
        expect(combined.dailyStatus, isNotNull);
        expect(combined.weeklySchedule, isNotEmpty);
        expect(combined.tierProgress, isNotNull);
      });

      test('provides complete reward snapshot', () async {
        final combined =
            await container.read(combinedRewardStatusProvider.future);
        expect(combined.dailyStatus.currentStreak, isNotNull);
        expect(combined.weeklySchedule.length, equals(7));
        expect(combined.tierProgress.currentXp, isNotNull);
      });

      test('canClaimDaily computed property works', () async {
        final combined =
            await container.read(combinedRewardStatusProvider.future);
        expect(combined.canClaimDaily, isA<bool>());
      });

      test('isMaxTier computed property works', () async {
        final combined =
            await container.read(combinedRewardStatusProvider.future);
        expect(combined.isMaxTier, isA<bool>());
      });
    });
  });
}
