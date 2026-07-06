import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/auth_token_store.dart';
import 'package:trivia_tycoon/core/services/daily_bonus_api_client.dart';
import 'package:trivia_tycoon/core/services/tier_api_client.dart';
import 'package:trivia_tycoon/core/services/weekly_rewards_api_client.dart';
import 'package:trivia_tycoon/game/providers/core_providers.dart';
import 'package:trivia_tycoon/game/providers/phase2_reward_providers.dart';

void main() {
  group('Phase 2 Reward Providers', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          currentUserIdProvider.overrideWithValue('test-user'),
          authTokenStoreProvider.overrideWithValue(_FakeAuthTokenStore()),
          dailyBonusApiClientProvider.overrideWithValue(
            _FakeDailyBonusApiClient(),
          ),
          weeklyRewardsApiClientProvider.overrideWithValue(
            _FakeWeeklyRewardsApiClient(),
          ),
          tierApiClientProvider.overrideWithValue(_FakeTierApiClient()),
        ],
      );
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
        final status = await container.read(dailyBonusStatusProvider.future);
        expect(status, isNotNull);
        expect(status.claimedToday, isFalse);
        expect(status.currentStreak, greaterThanOrEqualTo(0));
      });

      test('status tracking is consistent', () async {
        final status1 = await container.read(dailyBonusStatusProvider.future);
        final status2 = await container.read(dailyBonusStatusProvider.future);

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
        final progress = await container
            .read(playerTierProgressProvider('test-user').future);
        expect(progress, isNotNull);
        expect(progress.currentTier, isNotNull);
        expect(progress.currentXp, greaterThanOrEqualTo(0));
      });

      test('progress is within valid bounds', () async {
        final progress = await container
            .read(playerTierProgressProvider('test-user').future);
        expect(
          progress.currentTier.level,
          inInclusiveRange(1, 7),
        );
        expect(progress.progressPercentage, inInclusiveRange(0, 100));
      });

      test('calculates progress correctly', () async {
        final progress = await container
            .read(playerTierProgressProvider('test-user').future);
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
        final combined = await container
            .read(combinedRewardStatusProvider('test-user').future);
        expect(combined.dailyStatus, isNotNull);
        expect(combined.weeklySchedule, isNotEmpty);
        expect(combined.tierProgress, isNotNull);
      });

      test('provides complete reward snapshot', () async {
        final combined = await container
            .read(combinedRewardStatusProvider('test-user').future);
        expect(combined.dailyStatus.currentStreak, isNotNull);
        expect(combined.weeklySchedule.length, equals(7));
        expect(combined.tierProgress.currentXp, isNotNull);
      });

      test('canClaimDaily computed property works', () async {
        final combined = await container
            .read(combinedRewardStatusProvider('test-user').future);
        expect(combined.canClaimDaily, isA<bool>());
      });

      test('isMaxTier computed property works', () async {
        final combined = await container
            .read(combinedRewardStatusProvider('test-user').future);
        expect(combined.isMaxTier, isA<bool>());
      });
    });
  });
}

class _FakeAuthTokenStore implements AuthTokenStore {
  @override
  bool hasTokens() => true;

  @override
  AuthSession load() => AuthSession(
        accessToken: 'access-token',
        refreshToken: 'refresh-token',
        userId: 'test-user',
      );

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeDailyBonusApiClient implements DailyBonusApiClient {
  @override
  Future<DailyRewardConfig> getDailyConfig() async {
    return DailyRewardConfig(
      rewardType: 'coins',
      coinsAmount: 100,
      displayName: 'Daily Mystery Box',
      iconName: 'daily_box',
    );
  }

  @override
  Future<AccountRewardStatus> getAccountRewardStatus() async {
    return AccountRewardStatus(
      claimedToday: false,
      currentStreak: 2,
      rewardType: 'coins',
      coinsAmount: 100,
    );
  }

  @override
  Future<RewardClaimResult> claimDailyReward() async {
    return RewardClaimResult(
      coinsAwarded: 100,
      newTotalCoins: 500,
      newTotalGems: 0,
      newStreak: 3,
    );
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeWeeklyRewardsApiClient implements WeeklyRewardsApiClient {
  @override
  Future<List<WeeklyRewardDay>> getWeeklySchedule() async {
    return [
      WeeklyRewardDay(
        day: 1,
        type: 'coins',
        coinsAmount: 100,
        gemsAmount: 0,
        displayName: 'Day 1',
        claimed: false,
      ),
      WeeklyRewardDay(
        day: 2,
        type: 'gems',
        coinsAmount: 0,
        gemsAmount: 5,
        displayName: 'Day 2',
        claimed: false,
      ),
      WeeklyRewardDay(
        day: 3,
        type: 'coins',
        coinsAmount: 200,
        gemsAmount: 0,
        displayName: 'Day 3',
        claimed: false,
      ),
      WeeklyRewardDay(
        day: 4,
        type: 'coins',
        coinsAmount: 250,
        gemsAmount: 0,
        displayName: 'Day 4',
        claimed: false,
      ),
      WeeklyRewardDay(
        day: 5,
        type: 'gems',
        coinsAmount: 0,
        gemsAmount: 10,
        displayName: 'Day 5',
        claimed: false,
      ),
      WeeklyRewardDay(
        day: 6,
        type: 'coins',
        coinsAmount: 300,
        gemsAmount: 0,
        displayName: 'Day 6',
        claimed: false,
      ),
      WeeklyRewardDay(
        day: 7,
        type: 'coins',
        coinsAmount: 500,
        gemsAmount: 0,
        displayName: 'Day 7',
        claimed: false,
      ),
    ];
  }

  @override
  Future<WeeklyStreakStatus> getWeeklyStreak(String userId) async {
    final now = DateTime.now();
    return WeeklyStreakStatus(
      currentDay: 1,
      daysClaimedCount: 0,
      daysClaimedDates: const [],
      streakStartDate: now,
      weekResetDate: now.add(const Duration(days: 7)),
    );
  }

  @override
  Future<WeeklyRewardClaimResult> claimWeeklyReward({int day = 1}) async {
    return WeeklyRewardClaimResult(
      dayNumber: day,
      coinsAwarded: 100,
      gemsAwarded: 0,
      newTotalCoins: 600,
      newTotalGems: 0,
      currentStreak: day,
      nextClaimDate: DateTime.now().add(const Duration(days: 1)),
    );
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTierApiClient implements TierApiClient {
  @override
  Future<List<TierDefinition>> getTierDefinitions() async => _fakeTiers;

  @override
  Future<PlayerTierProgress> getPlayerTierProgress(String userId) async {
    return PlayerTierProgress(
      currentTier: _fakeTiers.first,
      nextTier: _fakeTiers[1],
      currentXp: 0,
      xpInCurrentTier: 0,
      xpNeededForNextTier: 500,
      progressPercentage: 0,
    );
  }

  @override
  Future<XpAwardResult> awardXp(
      String userId, int amount, String reason) async {
    return XpAwardResult(
      xpAwarded: amount,
      totalXp: amount,
      newLevel: 1,
      tierUpgraded: false,
    );
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _fakeTiers = [
  TierDefinition(
    id: 'bronze-rookie',
    name: 'Bronze Rookie',
    level: 1,
    minXp: 0,
    maxXp: 500,
    iconName: 'bronze_rookie',
    rewards: TierReward(badge: 'welcome_badge', coinsBonus: 100, gemsBonus: 0),
  ),
  TierDefinition(
    id: 'silver-scholar',
    name: 'Silver Scholar',
    level: 2,
    minXp: 500,
    maxXp: 1200,
    iconName: 'silver_scholar',
    rewards: TierReward(badge: 'scholar_badge', coinsBonus: 250, gemsBonus: 5),
  ),
  TierDefinition(
    id: 'gold-master',
    name: 'Gold Master',
    level: 3,
    minXp: 1200,
    maxXp: 2500,
    iconName: 'gold_master',
    rewards: TierReward(badge: 'master_badge', coinsBonus: 500, gemsBonus: 15),
  ),
  TierDefinition(
    id: 'platinum-elite',
    name: 'Platinum Elite',
    level: 4,
    minXp: 2500,
    maxXp: 5000,
    iconName: 'platinum_elite',
    rewards: TierReward(badge: 'elite_badge', coinsBonus: 1000, gemsBonus: 30),
  ),
  TierDefinition(
    id: 'diamond-legend',
    name: 'Diamond Legend',
    level: 5,
    minXp: 5000,
    maxXp: 10000,
    iconName: 'diamond_legend',
    rewards: TierReward(badge: 'legend_badge', coinsBonus: 2000, gemsBonus: 50),
  ),
  TierDefinition(
    id: 'master-sage',
    name: 'Master Sage',
    level: 6,
    minXp: 10000,
    maxXp: 20000,
    iconName: 'master_sage',
    rewards: TierReward(badge: 'sage_badge', coinsBonus: 5000, gemsBonus: 100),
  ),
  TierDefinition(
    id: 'celestial-ascendant',
    name: 'Celestial Ascendant',
    level: 7,
    minXp: 20000,
    maxXp: 2147483647,
    iconName: 'celestial_ascendant',
    rewards:
        TierReward(badge: 'ascendant_badge', coinsBonus: 5000, gemsBonus: 100),
  ),
];
