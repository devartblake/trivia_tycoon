import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/game/services/tier_rewards_service.dart';
import 'package:synaptix/game/services/tier_progression_service.dart';
import 'package:synaptix/core/services/tier_api_client.dart';
import 'package:synaptix/core/services/settings/general_key_value_storage_service.dart';

void main() {
  group('TierRewardsService', () {
    late TierRewardsService tierRewardsService;
    late MockTierProgressionService mockTierProgressionService;
    late MockGeneralKeyValueStorageService mockStorage;
    setUp(() {
      mockStorage = MockGeneralKeyValueStorageService();
      mockTierProgressionService = MockTierProgressionService();

      // We pass a mock Ref - the service won't actually use it in these tests
      tierRewardsService = TierRewardsService(
        tierProgressionService: mockTierProgressionService,
        storage: mockStorage,
        ref: _MockRef(),
      );
    });

    group('Claiming Tier Rewards', () {
      test('Claims tier reward on first reach', () async {
        // Arrange
        final testTier = TierDefinition(
          id: 'silver-scholar',
          name: 'Silver Scholar',
          level: 5,
          minXp: 500,
          maxXp: 1200,
          iconName: 'silver_scholar',
          rewards: TierReward(badge: 'scholar', coinsBonus: 250, gemsBonus: 5),
        );

        mockTierProgressionService.setTierProgress(testTier);

        // Act
        final claimed = await tierRewardsService.claimPendingRewards('user1');

        // Assert
        expect(claimed.length, 1);
        expect(claimed[0], 'silver-scholar');
      });

      test('Does not claim same tier reward twice', () async {
        // Arrange
        final testTier = TierDefinition(
          id: 'gold-master',
          name: 'Gold Master',
          level: 10,
          minXp: 1200,
          maxXp: 2500,
          iconName: 'gold_master',
          rewards: TierReward(badge: 'master', coinsBonus: 500, gemsBonus: 15),
        );

        mockTierProgressionService.setTierProgress(testTier);

        // Act: Claim first time
        var claimed = await tierRewardsService.claimPendingRewards('user1');
        expect(claimed.length, 1);

        // Act: Claim second time
        claimed = await tierRewardsService.claimPendingRewards('user1');

        // Assert: Should not claim again
        expect(claimed.length, 0);
      });

      test('Tracks claimed tier rewards in storage', () async {
        // Arrange
        final testTier = TierDefinition(
          id: 'platinum-elite',
          name: 'Platinum Elite',
          level: 18,
          minXp: 2500,
          maxXp: 5000,
          iconName: 'platinum_elite',
          rewards: TierReward(badge: 'elite', coinsBonus: 1000, gemsBonus: 30),
        );

        mockTierProgressionService.setTierProgress(testTier);

        // Act
        await tierRewardsService.claimPendingRewards('user1');

        // Assert: Check storage has the claimed tier
        final storedTiers =
            await mockStorage.getStringList('claimed_tier_rewards');
        expect(storedTiers, contains('platinum-elite'));
      });
    });

    group('Checking Claimed Status', () {
      test('Returns true for claimed tier', () async {
        // Arrange
        final testTier = TierDefinition(
          id: 'bronze-rookie',
          name: 'Bronze Rookie',
          level: 1,
          minXp: 0,
          maxXp: 500,
          iconName: 'bronze_rookie',
          rewards: TierReward(badge: 'welcome', coinsBonus: 100, gemsBonus: 0),
        );

        mockTierProgressionService.setTierProgress(testTier);

        // Act: Claim the tier
        await tierRewardsService.claimPendingRewards('user1');

        // Assert: Check it's claimed
        final isClaimed =
            await tierRewardsService.hasTierRewardBeenClaimed('bronze-rookie');
        expect(isClaimed, true);
      });

      test('Returns false for unclaimed tier', () async {
        // Act & Assert
        final isClaimed =
            await tierRewardsService.hasTierRewardBeenClaimed('diamond-legend');
        expect(isClaimed, false);
      });
    });

    group('Getting Unclaimed Tiers', () {
      test('Returns current tier if not claimed', () async {
        // Arrange
        final testTier = TierDefinition(
          id: 'diamond-legend',
          name: 'Diamond Legend',
          level: 25,
          minXp: 5000,
          maxXp: 10000,
          iconName: 'diamond_legend',
          rewards: TierReward(badge: 'legend', coinsBonus: 2000, gemsBonus: 50),
        );

        mockTierProgressionService.setTierProgress(testTier);

        // Act
        final unclaimed = await tierRewardsService.getUnclaimedTiers('user1');

        // Assert
        expect(unclaimed.length, 1);
        expect(unclaimed[0], 'diamond-legend');
      });

      test('Returns empty list if all tiers claimed', () async {
        // Arrange
        final testTier = TierDefinition(
          id: 'master-sage',
          name: 'Master Sage',
          level: 35,
          minXp: 10000,
          maxXp: 20000,
          iconName: 'master_sage',
          rewards: TierReward(badge: 'sage', coinsBonus: 5000, gemsBonus: 100),
        );

        mockTierProgressionService.setTierProgress(testTier);

        // Act: Claim the tier
        await tierRewardsService.claimPendingRewards('user1');

        // Act: Get unclaimed
        final unclaimed = await tierRewardsService.getUnclaimedTiers('user1');

        // Assert
        expect(unclaimed.length, 0);
      });
    });

    group('Resetting Rewards', () {
      test('Clears claimed tier rewards', () async {
        // Arrange
        final testTier = TierDefinition(
          id: 'grandmaster',
          name: 'Grandmaster',
          level: 50,
          minXp: 20000,
          maxXp: 50000,
          iconName: 'grandmaster',
          rewards: TierReward(
              badge: 'grandmaster', coinsBonus: 10000, gemsBonus: 200),
        );

        mockTierProgressionService.setTierProgress(testTier);

        // Act: Claim reward
        var claimed = await tierRewardsService.claimPendingRewards('user1');
        expect(claimed.length, 1);

        // Act: Reset
        await tierRewardsService.resetClaimedRewards();

        // Act: Check unclaimed now
        final unclaimed = await tierRewardsService.getUnclaimedTiers('user1');

        // Assert
        expect(unclaimed.length, 1);
        expect(unclaimed[0], 'grandmaster');
      });
    });

    group('Reward Value Extraction', () {
      test('Handles high coin bonuses', () async {
        // Arrange
        final testTier = TierDefinition(
          id: 'ultimate-champion',
          name: 'Ultimate Champion',
          level: 75,
          minXp: 50000,
          maxXp: 100000,
          iconName: 'ultimate',
          rewards:
              TierReward(badge: 'champion', coinsBonus: 20000, gemsBonus: 500),
        );

        mockTierProgressionService.setTierProgress(testTier);

        // Act
        final claimed = await tierRewardsService.claimPendingRewards('user1');

        // Assert
        expect(claimed.length, 1);
        expect(testTier.rewards.coinsBonus, 20000);
        expect(testTier.rewards.gemsBonus, 500);
      });

      test('Handles zero gem rewards', () async {
        // Arrange
        final testTier = TierDefinition(
          id: 'starter-tier',
          name: 'Starter',
          level: 1,
          minXp: 0,
          maxXp: 100,
          iconName: 'starter',
          rewards: TierReward(badge: 'start', coinsBonus: 50, gemsBonus: 0),
        );

        mockTierProgressionService.setTierProgress(testTier);

        // Act
        final claimed = await tierRewardsService.claimPendingRewards('user1');

        // Assert
        expect(claimed.length, 1);
        expect(testTier.rewards.gemsBonus, 0);
      });
    });

    group('Data Consistency', () {
      test('Maintains claimed tiers list across operations', () async {
        // Arrange
        final tier1 = TierDefinition(
          id: 'tier-1',
          name: 'Tier 1',
          level: 1,
          minXp: 0,
          maxXp: 100,
          iconName: 'tier1',
          rewards: TierReward(badge: 'badge1', coinsBonus: 100, gemsBonus: 0),
        );

        final tier2 = TierDefinition(
          id: 'tier-2',
          name: 'Tier 2',
          level: 2,
          minXp: 100,
          maxXp: 200,
          iconName: 'tier2',
          rewards: TierReward(badge: 'badge2', coinsBonus: 200, gemsBonus: 5),
        );

        mockTierProgressionService.setTierProgress(tier1);

        // Act: Claim tier 1
        var claimed = await tierRewardsService.claimPendingRewards('user1');
        expect(claimed.length, 1);

        // Switch to tier 2
        mockTierProgressionService.setTierProgress(tier2);

        // Act: Check claimed status
        var isClaimed1 =
            await tierRewardsService.hasTierRewardBeenClaimed('tier-1');
        var isClaimed2 =
            await tierRewardsService.hasTierRewardBeenClaimed('tier-2');

        // Assert
        expect(isClaimed1, true);
        expect(isClaimed2, false);
      });
    });
  });
}

// Mock implementations

class _MockRef implements Ref {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockTierProgressionService implements TierProgressionService {
  late PlayerTierProgress _currentProgress;

  void setTierProgress(TierDefinition tier) {
    _currentProgress = PlayerTierProgress(
      currentTier: tier,
      nextTier: null,
      currentXp: tier.minXp,
      xpInCurrentTier: 0,
      xpNeededForNextTier: tier.maxXp - tier.minXp,
      progressPercentage: 0,
    );
  }

  @override
  Future<List<TierDefinition>> getTierDefinitions() {
    throw UnimplementedError();
  }

  @override
  Future<PlayerTierProgress> getPlayerTierProgress(String userId) async {
    return _currentProgress;
  }

  @override
  Future<bool> awardXP(String userId, int amount, String reason) {
    throw UnimplementedError();
  }

  @override
  Future<TierDefinition?> getTierById(String tierId) {
    throw UnimplementedError();
  }

  @override
  void clearCache() {}
}

class MockGeneralKeyValueStorageService
    implements GeneralKeyValueStorageService {
  final _data = <String, dynamic>{};

  @override
  Future<void> setStringList(String key, List<String> values) async {
    _data[key] = values;
  }

  @override
  Future<List<String>?> getStringList(String key) async {
    return _data[key] as List<String>?;
  }

  @override
  Future<String?> getString(String key) async => _data[key] as String?;

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  Future<int> getInt(String key) async => (_data[key] as int?) ?? 0;

  @override
  Future<void> setInt(String key, int value) async {
    _data[key] = value;
  }

  @override
  Future<bool?> getBool(String key) async => _data[key] as bool?;

  @override
  Future<void> setBool(String key, bool value) async {
    _data[key] = value;
  }

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> setColor(String key, Color color) async {}

  @override
  Future<Color?> getColor(String key) async => null;

  @override
  Future<void> setDateTime(String key, DateTime value) async {}

  @override
  Future<DateTime?> getDateTime(String key) async => null;

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {}

  @override
  Future<Map<String, dynamic>?> getJson(String key) async => null;

  @override
  Future<dynamic> get(String key) async => _data[key];

  @override
  Future<void> set(String key, dynamic value) async {
    _data[key] = value;
  }
}
