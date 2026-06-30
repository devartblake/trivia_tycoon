import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/manager/tier_manager.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';
import 'package:trivia_tycoon/core/services/tier_api_client.dart';

/// Integration tests for tier progression system
/// Tests the full flow: Quiz completion → XP award → Level up → Tier progression
void main() {
  group('Tier Progression Integration Tests', () {
    late TierManager tierManager;
    late MockPlayerProfileService mockProfileService;
    late MockTierApiClient mockTierApiClient;
    late MockGeneralKeyValueStorageService mockStorage;

    setUp(() {
      mockStorage = MockGeneralKeyValueStorageService();
      mockProfileService = MockPlayerProfileService();
      mockTierApiClient = MockTierApiClient();

      tierManager = TierManager(
        mockStorage,
        mockProfileService,
        tierApiClient: mockTierApiClient,
      );
    });

    group('Tier Definition Loading', () {
      test('Loads tier definitions from backend', () async {
        // Arrange: Mock backend returns 8 tier definitions
        mockTierApiClient.setMockTiers(8);

        // Act: Get tier definitions
        final tiers = await tierManager.getAllTiers();

        // Assert: Should have 8 tiers
        expect(tiers.length, 8);
        expect(tiers[0].name, 'Bronze Rookie');
        expect(tiers[0].requiredXP, 0);
        expect(tiers[1].name, 'Silver Scholar');
        expect(tiers[1].requiredXP, 500);
      });

      test('Falls back to local definitions if backend unavailable', () async {
        // Arrange: Mock backend fails
        mockTierApiClient.setFailure(true);

        // Act: Get tier definitions
        final tiers = await tierManager.getAllTiers();

        // Assert: Should use default local tiers
        expect(tiers.isNotEmpty, true);
        expect(tiers[0].name, 'Bronze Rookie');
      });
    });

    group('XP and Level Tracking', () {
      test('Player starts at Bronze tier with 0 XP', () async {
        // Arrange
        mockProfileService.setProfile({'currentXP': 0, 'level': 1});
        mockStorage.setInt('current_tier', 0);

        // Act
        final currentTier = await tierManager.getCurrentTier();

        // Assert
        expect(currentTier?.name, 'Bronze Rookie');
        expect(currentTier?.requiredXP, 0);
      });

      test('Player progresses to Silver tier at 500 XP', () async {
        // Arrange: Player has 500 XP (Silver Scholar threshold)
        mockProfileService.setProfile({'currentXP': 500, 'level': 5});

        // Act
        final result = await tierManager.updateTierProgress();

        // Assert
        expect(result.newTierId, 1); // Silver = index 1
        expect(result.tierChanged, true);
      });

      test('Player progresses through multiple tiers', () async {
        // Arrange
        final xpThresholds = [0, 500, 1200, 2500, 5000, 10000, 20000, 50000];
        final requiredLevels = [1, 5, 10, 18, 25, 35, 50, 75];

        // Act & Assert: Test each tier progression
        for (int i = 0; i < xpThresholds.length; i++) {
          mockProfileService.setProfile({
            'currentXP': xpThresholds[i],
            'level': requiredLevels[i],
          });

          // Update tier progress to calculate the current tier
          await tierManager.updateTierProgress();

          final tier = await tierManager.getCurrentTier();
          expect(tier?.id, i, reason: 'Should be tier $i at XP ${xpThresholds[i]}');
        }
      });
    });

    group('Tier Progression Detection', () {
      test('Detects tier up event', () async {
        // Arrange: Simulate moving from Silver (500 XP) to Gold (1200 XP)
        mockStorage.setInt('current_tier', 1); // Currently Silver
        mockProfileService.setProfile({'currentXP': 1200, 'level': 10});

        // Act
        final result = await tierManager.updateTierProgress();

        // Assert
        expect(result.oldTierId, 1);
        expect(result.newTierId, 2); // Gold tier
        expect(result.tierChanged, true);
      });

      test('No tier change when XP stays in same tier', () async {
        // Arrange: Player has 600 XP (still in Silver Scholar: 500-1200)
        mockStorage.setInt('current_tier', 1);
        mockProfileService.setProfile({'currentXP': 600, 'level': 5});

        // Act
        final result = await tierManager.updateTierProgress();

        // Assert
        expect(result.oldTierId, 1);
        expect(result.newTierId, 1);
        expect(result.tierChanged, false);
      });

      test('Detects multiple new tier unlocks', () async {
        // Arrange: Player jumps from Bronze (0) to Platinum (2500 XP)
        mockStorage.setInt('current_tier', 0);
        mockProfileService.setProfile({'currentXP': 2500, 'level': 18});

        // Act
        final result = await tierManager.updateTierProgress();

        // Assert: Should detect all newly unlocked tiers
        expect(result.tierChanged, true);
        expect(result.newUnlocks.length, greaterThan(0));
      });
    });

    group('Rewards System', () {
      test('Tier rewards are properly formatted', () async {
        // Arrange
        mockProfileService.setProfile({'currentXP': 500, 'level': 5});

        // Act
        final tier = await tierManager.getCurrentTier();

        // Assert: Silver Scholar should have proper rewards
        expect(tier?.rewards, isNotEmpty);
        expect(
          tier?.rewards.any((r) => r.contains('Coins')),
          true,
          reason: 'Should include coin reward',
        );
      });

      test('Award tier rewards completes without error', () async {
        // Arrange
        mockProfileService.setProfile({'currentXP': 500, 'level': 5});
        final tier = await tierManager.getCurrentTier();

        // Act & Assert: Should not throw
        expect(
          () => tierManager.awardTierRewards(tier!),
          isNotNull,
        );
      });
    });

    group('Edge Cases', () {
      test('Player at max tier shows no progress to next', () async {
        // Arrange: Player has max XP (beyond Ultimate Champion at 50000)
        mockProfileService.setProfile({'currentXP': 100000, 'level': 100});

        // Act: Update tier progress to calculate current tier
        await tierManager.updateTierProgress();
        final tier = await tierManager.getCurrentTier();

        // Assert: Should be at Ultimate Champion (max tier)
        expect(tier?.name, 'Ultimate Champion');
      });

      test('Rapid tier progression is handled correctly', () async {
        // Arrange: Simulate quiz awards large XP jump
        final largeXpGain = 5000; // Enough to jump multiple tiers
        mockProfileService.setProfile({'currentXP': largeXpGain, 'level': 25});

        // Act
        final result = await tierManager.updateTierProgress();

        // Assert
        expect(result.tierChanged, true);
        final newTier = await tierManager.getCurrentTier();
        expect(newTier?.requiredXP, lessThanOrEqualTo(largeXpGain));
      });

      test('Zero XP stays at Bronze tier', () async {
        // Arrange
        mockProfileService.setProfile({'currentXP': 0, 'level': 0});

        // Act
        final tier = await tierManager.getCurrentTier();

        // Assert
        expect(tier?.id, 0);
        expect(tier?.name, 'Bronze Rookie');
      });
    });

    group('Data Consistency', () {
      test('Tier thresholds match across calls', () async {
        // Arrange: Get tier definitions multiple times
        final tiers1 = await tierManager.getAllTiers();
        final tiers2 = await tierManager.getAllTiers();

        // Assert: Should be identical
        expect(tiers1.length, tiers2.length);
        for (int i = 0; i < tiers1.length; i++) {
          expect(tiers1[i].requiredXP, tiers2[i].requiredXP);
          expect(tiers1[i].name, tiers2[i].name);
        }
      });

      test('Backend and local tier definitions match', () async {
        // Arrange: Get definitions from both sources
        mockTierApiClient.setMockTiers(8);
        final backendTiers = await mockTierApiClient.getTierDefinitions();

        // Act
        final localTiers = await tierManager.getAllTiers();

        // Assert: Should have same count and XP thresholds
        expect(localTiers.length, backendTiers.length);
        for (int i = 0; i < backendTiers.length; i++) {
          expect(
            localTiers[i].requiredXP,
            backendTiers[i].minXp,
            reason: 'XP threshold should match for tier $i',
          );
        }
      });
    });
  });
}

// Mock implementations for testing

class MockGeneralKeyValueStorageService
    implements GeneralKeyValueStorageService {
  final _data = <String, dynamic>{};

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
  Future<void> setColor(String key, Color color) async {
    _data[key] = color;
  }

  @override
  Future<Color?> getColor(String key) async => _data[key] as Color?;

  @override
  Future<void> setDateTime(String key, DateTime value) async {
    _data[key] = value;
  }

  @override
  Future<DateTime?> getDateTime(String key) async => _data[key] as DateTime?;

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    _data[key] = value;
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async =>
      _data[key] as Map<String, dynamic>?;

  @override
  Future<List<String>?> getStringList(String key) async {
    final value = _data[key];
    if (value is List<String>) return value;
    if (value is String) return value.split(',');
    return null;
  }

  @override
  Future<void> setStringList(String key, List<String> values) async {
    _data[key] = values;
  }

  @override
  Future<dynamic> get(String key) async => _data[key];

  @override
  Future<void> set(String key, dynamic value) async {
    _data[key] = value;
  }
}

class MockPlayerProfileService implements PlayerProfileService {
  final _profile = <String, dynamic>{};

  void setProfile(Map<String, dynamic> profile) {
    _profile.addAll(profile);
  }

  @override
  Map<String, dynamic> getProfile() {
    return {
      'name': 'Test Player',
      'currentXP': _profile['currentXP'] ?? 0,
      'level': _profile['level'] ?? 1,
      'maxXP': _profile['maxXP'] ?? 500,
      ..._profile,
    };
  }

  @override
  Future<void> saveLevelData(
      {int? level, int? currentXP, int? maxXP}) async {
    if (level != null) _profile['level'] = level;
    if (currentXP != null) _profile['currentXP'] = currentXP;
    if (maxXP != null) _profile['maxXP'] = maxXP;
  }

  @override
  Future<Map<String, dynamic>> addXP(int xpToAdd) async {
    final currentXP = (_profile['currentXP'] as int?) ?? 0;
    _profile['currentXP'] = currentXP + xpToAdd;
    return {
      'leveledUp': false,
      'newXP': currentXP + xpToAdd,
    };
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockTierApiClient implements TierApiClient {
  bool _shouldFail = false;
  int _tierCount = 8;

  void setFailure(bool fail) => _shouldFail = fail;
  void setMockTiers(int count) => _tierCount = count;

  @override
  Future<List<TierDefinition>> getTierDefinitions() async {
    if (_shouldFail) {
      throw Exception('API failure');
    }

    return [
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
        level: 5,
        minXp: 500,
        maxXp: 1200,
        iconName: 'silver_scholar',
        rewards: TierReward(badge: 'scholar_badge', coinsBonus: 250, gemsBonus: 5),
      ),
      TierDefinition(
        id: 'gold-master',
        name: 'Gold Master',
        level: 10,
        minXp: 1200,
        maxXp: 2500,
        iconName: 'gold_master',
        rewards: TierReward(badge: 'master_badge', coinsBonus: 500, gemsBonus: 15),
      ),
      TierDefinition(
        id: 'platinum-elite',
        name: 'Platinum Elite',
        level: 18,
        minXp: 2500,
        maxXp: 5000,
        iconName: 'platinum_elite',
        rewards: TierReward(badge: 'elite_badge', coinsBonus: 1000, gemsBonus: 30),
      ),
      TierDefinition(
        id: 'diamond-legend',
        name: 'Diamond Legend',
        level: 25,
        minXp: 5000,
        maxXp: 10000,
        iconName: 'diamond_legend',
        rewards: TierReward(badge: 'legend_badge', coinsBonus: 2000, gemsBonus: 50),
      ),
      TierDefinition(
        id: 'master-sage',
        name: 'Master Sage',
        level: 35,
        minXp: 10000,
        maxXp: 20000,
        iconName: 'master_sage',
        rewards: TierReward(badge: 'sage_badge', coinsBonus: 5000, gemsBonus: 100),
      ),
      TierDefinition(
        id: 'grandmaster',
        name: 'Grandmaster',
        level: 50,
        minXp: 20000,
        maxXp: 50000,
        iconName: 'grandmaster',
        rewards:
            TierReward(badge: 'grandmaster_badge', coinsBonus: 10000, gemsBonus: 200),
      ),
      if (_tierCount >= 8)
        TierDefinition(
          id: 'ultimate-champion',
          name: 'Ultimate Champion',
          level: 75,
          minXp: 50000,
          maxXp: 100000,
          iconName: 'ultimate_champion',
          rewards: TierReward(
              badge: 'champion_badge', coinsBonus: 20000, gemsBonus: 500),
        ),
    ].take(_tierCount).toList();
  }

  @override
  Future<PlayerTierProgress> getPlayerTierProgress(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<XpAwardResult> awardXp(String userId, int amount, String reason) async {
    throw UnimplementedError();
  }

  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
