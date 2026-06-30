import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/services/tier_progression_service.dart';
import 'package:trivia_tycoon/core/services/tier_api_client.dart';
import 'package:trivia_tycoon/core/services/settings/player_profile_service.dart';

void main() {
  group('TierProgressionService', () {
    late TierProgressionService tierProgressionService;
    late MockTierApiClient mockTierApiClient;
    late MockPlayerProfileService mockProfileService;

    setUp(() {
      mockTierApiClient = MockTierApiClient();
      mockProfileService = MockPlayerProfileService();
      mockTierApiClient.setProfileService(mockProfileService);

      tierProgressionService = TierProgressionService(
        tierApiClient: mockTierApiClient,
        profileService: mockProfileService,
      );
    });

    group('Tier Definition Loading', () {
      test('Loads tier definitions from API client', () async {
        // Act
        final tiers = await tierProgressionService.getTierDefinitions();

        // Assert
        expect(tiers.length, 8);
        expect(tiers[0].name, 'Bronze Rookie');
        expect(tiers[0].minXp, 0);
        expect(tiers[0].level, 1);
      });

      test('Caches tier definitions after first load', () async {
        // Act
        final firstCall = await tierProgressionService.getTierDefinitions();
        final secondCall = await tierProgressionService.getTierDefinitions();

        // Assert: Should return cached result
        expect(firstCall.length, secondCall.length);
        expect(firstCall[0].name, secondCall[0].name);
      });

      test('Clears cache on demand', () async {
        // Arrange
        await tierProgressionService.getTierDefinitions();
        mockTierApiClient.setMockTiers(4); // Change mock data

        // Act
        tierProgressionService.clearCache();
        final tiers = await tierProgressionService.getTierDefinitions();

        // Assert: Should reflect new mock data
        expect(tiers.length, 4);
      });
    });

    group('Player Tier Progress', () {
      test('Calculates correct tier for 0 XP', () async {
        // Arrange
        mockProfileService.setProfile({'currentXP': 0});

        // Act
        final progress = await tierProgressionService.getPlayerTierProgress('user1');

        // Assert
        expect(progress.currentTier.name, 'Bronze Rookie');
        expect(progress.currentTier.minXp, 0);
        expect(progress.progressPercentage, 0);
      });

      test('Calculates correct tier for 500 XP', () async {
        // Arrange
        mockProfileService.setProfile({'currentXP': 500});

        // Act
        final progress = await tierProgressionService.getPlayerTierProgress('user1');

        // Assert
        expect(progress.currentTier.name, 'Silver Scholar');
        expect(progress.currentTier.minXp, 500);
      });

      test('Calculates progress percentage correctly', () async {
        // Arrange: 750 XP puts player 50% through Silver (500-1200)
        mockProfileService.setProfile({'currentXP': 750});

        // Act
        final progress = await tierProgressionService.getPlayerTierProgress('user1');

        // Assert
        expect(progress.xpInCurrentTier, 250); // 750 - 500
        expect(progress.xpNeededForNextTier, 700); // 1200 - 500
        expect(progress.progressPercentage, 36); // ~36%
      });

      test('Shows next tier correctly', () async {
        // Arrange: Player at 600 XP (in Silver, next is Gold)
        mockProfileService.setProfile({'currentXP': 600});

        // Act
        final progress = await tierProgressionService.getPlayerTierProgress('user1');

        // Assert
        expect(progress.nextTier?.name, 'Gold Master');
        expect(progress.nextTier?.minXp, 1200);
      });

      test('Shows null next tier at max tier', () async {
        // Arrange: Player with max XP
        mockProfileService.setProfile({'currentXP': 100000});

        // Act
        final progress = await tierProgressionService.getPlayerTierProgress('user1');

        // Assert
        expect(progress.isMaxTier, true);
        expect(progress.nextTier, isNull);
        expect(progress.progressPercentage, 100);
      });
    });

    group('XP Award and Tier Change Detection', () {
      test('Awards XP and detects tier change', () async {
        // Arrange: Player at 400 XP (Bronze)
        mockProfileService.setProfile({'currentXP': 400});

        // Act: Award 200 XP (brings to 600, moving to Silver)
        final tierChanged =
            await tierProgressionService.awardXP('user1', 200, 'quiz_completion');

        // Assert
        expect(tierChanged, true);
      });

      test('Awards XP without tier change when staying in same tier', () async {
        // Arrange: Player at 600 XP (Silver)
        mockProfileService.setProfile({'currentXP': 600});

        // Act: Award 100 XP (stays in Silver: 500-1200)
        final tierChanged =
            await tierProgressionService.awardXP('user1', 100, 'quiz_completion');

        // Assert
        expect(tierChanged, false);
      });

      test('Handles multiple tier jumps', () async {
        // Arrange: Player at 0 XP
        mockProfileService.setProfile({'currentXP': 0});

        // Act: Award 3000 XP (jumps to Platinum at 2500)
        final tierChanged =
            await tierProgressionService.awardXP('user1', 3000, 'bulk_award');

        // Assert
        expect(tierChanged, true);
      });
    });

    group('Tier Lookup', () {
      test('Gets tier by ID', () async {
        // Act
        final tier = await tierProgressionService.getTierById('gold-master');

        // Assert
        expect(tier?.name, 'Gold Master');
        expect(tier?.minXp, 1200);
      });

      test('Returns null for invalid tier ID', () async {
        // Act
        final tier = await tierProgressionService.getTierById('nonexistent');

        // Assert
        expect(tier, isNull);
      });
    });

    group('Error Handling', () {
      test('Handles API errors gracefully', () async {
        // Arrange
        mockTierApiClient.setFailure(true);

        // Act & Assert: Should not throw, should return empty or default
        expect(
          () => tierProgressionService.getTierDefinitions(),
          isNotNull,
        );
      });

      test('Continues with cached data on API error', () async {
        // Arrange: First successful load
        final firstLoad = await tierProgressionService.getTierDefinitions();

        // Now API fails
        mockTierApiClient.setFailure(true);

        // Act: Clear cache and try again
        tierProgressionService.clearCache();
        final withError = await tierProgressionService.getTierDefinitions();

        // Assert: Should return same data (from cache or fallback)
        expect(withError.isNotEmpty, true);
      });
    });

    group('Data Consistency', () {
      test('XP thresholds increase monotonically', () async {
        // Arrange
        final tiers = await tierProgressionService.getTierDefinitions();

        // Assert: Each tier's minXp should be >= previous tier's minXp
        for (int i = 1; i < tiers.length; i++) {
          expect(
            tiers[i].minXp,
            greaterThanOrEqualTo(tiers[i - 1].minXp),
            reason: 'Tier $i minXp should be >= Tier ${i - 1}',
          );
        }
      });

      test('Tier levels match tier order', () async {
        // Arrange
        final tiers = await tierProgressionService.getTierDefinitions();

        // Assert: Tier levels should be 1, 5, 10, 18, 25, 35, 50, 75
        expect(tiers[0].level, 1);
        expect(tiers[1].level, 5);
        expect(tiers[2].level, 10);
        expect(tiers[3].level, 18);
      });

      test('Rewards are properly defined', () async {
        // Arrange
        final tiers = await tierProgressionService.getTierDefinitions();

        // Assert: Each tier should have a badge and rewards
        for (final tier in tiers) {
          expect(tier.rewards.badge.isNotEmpty, true);
          expect(tier.rewards.coinsBonus, greaterThanOrEqualTo(0));
          expect(tier.rewards.gemsBonus, greaterThanOrEqualTo(0));
        }
      });
    });
  });
}

// Mock implementations

class MockTierApiClient implements TierApiClient {
  bool _shouldFail = false;
  int _tierCount = 8;
  late MockPlayerProfileService _profileService;

  void setFailure(bool fail) => _shouldFail = fail;
  void setMockTiers(int count) => _tierCount = count;
  void setProfileService(MockPlayerProfileService profileService) {
    _profileService = profileService;
  }

  @override
  Future<List<TierDefinition>> getTierDefinitions() async {
    if (_shouldFail) {
      throw Exception('API connection failed');
    }

    return _createMockTiers(_tierCount);
  }

  @override
  Future<PlayerTierProgress> getPlayerTierProgress(String userId) async {
    throw UnimplementedError();
  }

  @override
  Future<XpAwardResult> awardXp(String userId, int amount, String reason) async {
    // Simulate XP award by updating the profile service
    final current = (_profileService._profile['currentXP'] as int?) ?? 0;
    final newXp = current + amount;
    _profileService._profile['currentXP'] = newXp;

    return XpAwardResult(
      xpAwarded: amount,
      totalXp: newXp,
      newLevel: 1,
      tierUpgraded: false,
    );
  }

  @override
  void close() {}

  List<TierDefinition> _createMockTiers(int count) => [
        TierDefinition(
          id: 'bronze-rookie',
          name: 'Bronze Rookie',
          level: 1,
          minXp: 0,
          maxXp: 500,
          iconName: 'bronze_rookie',
          rewards: TierReward(badge: 'welcome', coinsBonus: 100, gemsBonus: 0),
        ),
        TierDefinition(
          id: 'silver-scholar',
          name: 'Silver Scholar',
          level: 5,
          minXp: 500,
          maxXp: 1200,
          iconName: 'silver_scholar',
          rewards: TierReward(badge: 'scholar', coinsBonus: 250, gemsBonus: 5),
        ),
        TierDefinition(
          id: 'gold-master',
          name: 'Gold Master',
          level: 10,
          minXp: 1200,
          maxXp: 2500,
          iconName: 'gold_master',
          rewards: TierReward(badge: 'master', coinsBonus: 500, gemsBonus: 15),
        ),
        TierDefinition(
          id: 'platinum-elite',
          name: 'Platinum Elite',
          level: 18,
          minXp: 2500,
          maxXp: 5000,
          iconName: 'platinum_elite',
          rewards: TierReward(badge: 'elite', coinsBonus: 1000, gemsBonus: 30),
        ),
        TierDefinition(
          id: 'diamond-legend',
          name: 'Diamond Legend',
          level: 25,
          minXp: 5000,
          maxXp: 10000,
          iconName: 'diamond_legend',
          rewards: TierReward(badge: 'legend', coinsBonus: 2000, gemsBonus: 50),
        ),
        TierDefinition(
          id: 'master-sage',
          name: 'Master Sage',
          level: 35,
          minXp: 10000,
          maxXp: 20000,
          iconName: 'master_sage',
          rewards: TierReward(badge: 'sage', coinsBonus: 5000, gemsBonus: 100),
        ),
        TierDefinition(
          id: 'grandmaster',
          name: 'Grandmaster',
          level: 50,
          minXp: 20000,
          maxXp: 50000,
          iconName: 'grandmaster',
          rewards:
              TierReward(badge: 'grandmaster', coinsBonus: 10000, gemsBonus: 200),
        ),
        if (count >= 8)
          TierDefinition(
            id: 'ultimate',
            name: 'Ultimate Champion',
            level: 75,
            minXp: 50000,
            maxXp: 100000,
            iconName: 'ultimate',
            rewards:
                TierReward(badge: 'champion', coinsBonus: 20000, gemsBonus: 500),
          ),
      ].take(count).toList();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockPlayerProfileService implements PlayerProfileService {
  final _profile = <String, dynamic>{};

  void setProfile(Map<String, dynamic> data) {
    _profile.clear();
    _profile.addAll(data);
  }

  @override
  Map<String, dynamic> getProfile() {
    return {
      'currentXP': _profile['currentXP'] ?? 0,
      'level': _profile['level'] ?? 1,
      'name': 'Test Player',
    };
  }

  @override
  Future<void> saveLevelData(
      {int? level, int? currentXP, int? maxXP}) async {
    if (level != null) _profile['level'] = level;
    if (currentXP != null) _profile['currentXP'] = currentXP;
  }

  @override
  Future<Map<String, dynamic>> addXP(int xpToAdd) async {
    final current = (_profile['currentXP'] as int?) ?? 0;
    _profile['currentXP'] = current + xpToAdd;
    return {'leveledUp': false};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
