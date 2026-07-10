import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/services/tier_leaderboard_service.dart';
import 'package:trivia_tycoon/game/services/tier_progression_service.dart';
import 'package:trivia_tycoon/core/services/tier_api_client.dart';

void main() {
  group('TierLeaderboardService', () {
    late TierLeaderboardService tierLeaderboardService;
    late MockTierProgressionService mockTierProgressionService;

    setUp(() {
      mockTierProgressionService = MockTierProgressionService();
      tierLeaderboardService = TierLeaderboardService(
        tierProgressionService: mockTierProgressionService,
      );
    });

    group('Score Multipliers', () {
      test('Returns correct multiplier for Bronze tier', () async {
        // Arrange
        final bronzeTier = TierDefinition(
          id: 'bronze-rookie',
          name: 'Bronze Rookie',
          level: 1,
          minXp: 0,
          maxXp: 500,
          iconName: 'bronze',
          rewards: TierReward(badge: 'welcome', coinsBonus: 100, gemsBonus: 0),
        );

        mockTierProgressionService.setTierProgress(bronzeTier);

        // Act
        final multiplier =
            await tierLeaderboardService.getScoreMultiplier('user1');

        // Assert
        expect(multiplier, 1.0);
      });

      test('Returns correct multiplier for Gold tier', () async {
        // Arrange
        final goldTier = TierDefinition(
          id: 'gold-master',
          name: 'Gold Master',
          level: 10,
          minXp: 1200,
          maxXp: 2500,
          iconName: 'gold',
          rewards: TierReward(badge: 'master', coinsBonus: 500, gemsBonus: 15),
        );

        mockTierProgressionService.setTierProgress(goldTier);

        // Act
        final multiplier =
            await tierLeaderboardService.getScoreMultiplier('user1');

        // Assert
        expect(multiplier, 1.25);
      });

      test('Returns correct multiplier for Grandmaster tier', () async {
        // Arrange
        final grandmasterTier = TierDefinition(
          id: 'grandmaster',
          name: 'Grandmaster',
          level: 50,
          minXp: 20000,
          maxXp: 50000,
          iconName: 'grandmaster',
          rewards: TierReward(
              badge: 'grandmaster', coinsBonus: 10000, gemsBonus: 200),
        );

        mockTierProgressionService.setTierProgress(grandmasterTier);

        // Act
        final multiplier =
            await tierLeaderboardService.getScoreMultiplier('user1');

        // Assert
        expect(multiplier, 2.5);
      });
    });

    group('Score Calculation', () {
      test('Applies multiplier to base score correctly', () async {
        // Arrange
        final silverTier = TierDefinition(
          id: 'silver-scholar',
          name: 'Silver Scholar',
          level: 5,
          minXp: 500,
          maxXp: 1200,
          iconName: 'silver',
          rewards: TierReward(badge: 'scholar', coinsBonus: 250, gemsBonus: 5),
        );

        mockTierProgressionService.setTierProgress(silverTier);

        // Act
        final score =
            await tierLeaderboardService.applyTierMultiplier('user1', 1000);

        // Assert: 1000 × 1.1 = 1100
        expect(score, 1100);
      });

      test('Rounds multiplied score correctly', () async {
        // Arrange
        final platinumTier = TierDefinition(
          id: 'platinum-elite',
          name: 'Platinum Elite',
          level: 18,
          minXp: 2500,
          maxXp: 5000,
          iconName: 'platinum',
          rewards: TierReward(badge: 'elite', coinsBonus: 1000, gemsBonus: 30),
        );

        mockTierProgressionService.setTierProgress(platinumTier);

        // Act: 777 × 1.5 = 1165.5 → rounds to 1166
        final score =
            await tierLeaderboardService.applyTierMultiplier('user1', 777);

        // Assert
        expect(score, 1166);
      });
    });

    group('Tier Bonuses', () {
      test('Bronze tier gets no bonus', () async {
        // Arrange
        final bronzeTier = TierDefinition(
          id: 'bronze-rookie',
          name: 'Bronze Rookie',
          level: 1,
          minXp: 0,
          maxXp: 500,
          iconName: 'bronze',
          rewards: TierReward(badge: 'welcome', coinsBonus: 100, gemsBonus: 0),
        );

        mockTierProgressionService.setTierProgress(bronzeTier);

        // Act
        final bonus = await tierLeaderboardService.getTierBonus('user1');

        // Assert
        expect(bonus, 0);
      });

      test('Gold tier gets 100 bonus points', () async {
        // Arrange
        final goldTier = TierDefinition(
          id: 'gold-master',
          name: 'Gold Master',
          level: 10,
          minXp: 1200,
          maxXp: 2500,
          iconName: 'gold',
          rewards: TierReward(badge: 'master', coinsBonus: 500, gemsBonus: 15),
        );

        mockTierProgressionService.setTierProgress(goldTier);

        // Act
        final bonus = await tierLeaderboardService.getTierBonus('user1');

        // Assert
        expect(bonus, 100);
      });

      test('Grandmaster tier gets 800 bonus points', () async {
        // Arrange
        final grandmasterTier = TierDefinition(
          id: 'grandmaster',
          name: 'Grandmaster',
          level: 50,
          minXp: 20000,
          maxXp: 50000,
          iconName: 'grandmaster',
          rewards: TierReward(
              badge: 'grandmaster', coinsBonus: 10000, gemsBonus: 200),
        );

        mockTierProgressionService.setTierProgress(grandmasterTier);

        // Act
        final bonus = await tierLeaderboardService.getTierBonus('user1');

        // Assert
        expect(bonus, 800);
      });
    });

    group('Final Score Calculation', () {
      test('Calculates final score with multiplier and bonus', () async {
        // Arrange
        final platinumTier = TierDefinition(
          id: 'platinum-elite',
          name: 'Platinum Elite',
          level: 18,
          minXp: 2500,
          maxXp: 5000,
          iconName: 'platinum',
          rewards: TierReward(badge: 'elite', coinsBonus: 1000, gemsBonus: 30),
        );

        mockTierProgressionService.setTierProgress(platinumTier);

        // Act: 1000 × 1.5 + 200 = 1500 + 200 = 1700
        final score = await tierLeaderboardService.calculateLeaderboardScore(
            'user1', 1000);

        // Assert
        expect(score, 1700);
      });

      test('Gets score breakdown', () async {
        // Arrange
        final diamondTier = TierDefinition(
          id: 'diamond-legend',
          name: 'Diamond Legend',
          level: 25,
          minXp: 5000,
          maxXp: 10000,
          iconName: 'diamond',
          rewards: TierReward(badge: 'legend', coinsBonus: 2000, gemsBonus: 50),
        );

        mockTierProgressionService.setTierProgress(diamondTier);

        // Act
        final breakdown =
            await tierLeaderboardService.getScoreBreakdown('user1', 1000);

        // Assert
        expect(breakdown.baseScore, 1000);
        expect(breakdown.tierName, 'Diamond Legend');
        expect(breakdown.multiplier, 1.75);
        expect(breakdown.multipliedScore, 1750);
        expect(breakdown.bonusPoints, 350);
        expect(breakdown.finalScore, 2100);
      });
    });

    group('Tier Progression Impact', () {
      test('Score increases when advancing tiers', () async {
        // Arrange
        final baseTier = TierDefinition(
          id: 'silver-scholar',
          name: 'Silver Scholar',
          level: 5,
          minXp: 500,
          maxXp: 1200,
          iconName: 'silver',
          rewards: TierReward(badge: 'scholar', coinsBonus: 250, gemsBonus: 5),
        );

        mockTierProgressionService.setTierProgress(baseTier);
        final baseScore = await tierLeaderboardService
            .calculateLeaderboardScore('user1', 1000);

        final advancedTier = TierDefinition(
          id: 'gold-master',
          name: 'Gold Master',
          level: 10,
          minXp: 1200,
          maxXp: 2500,
          iconName: 'gold',
          rewards: TierReward(badge: 'master', coinsBonus: 500, gemsBonus: 15),
        );

        mockTierProgressionService.setTierProgress(advancedTier);
        final advancedScore = await tierLeaderboardService
            .calculateLeaderboardScore('user1', 1000);

        // Assert
        expect(advancedScore, greaterThan(baseScore));
      });

      test('Estimates score increase from tier advancement', () {
        // Act
        final increase = TierLeaderboardService.estimateScoreIncrease(
          'silver-scholar',
          'gold-master',
          1000,
        );

        // Assert
        // Silver: 1000 × 1.1 = 1100
        // Gold: 1000 × 1.25 = 1250
        // Increase: 1250 - 1100 = 150
        expect(increase, 150);
      });
    });

    group('Tier Multiplier Info', () {
      test('Gets multiplier for specific tier', () {
        // Act
        final multiplier =
            TierLeaderboardService.getTierMultiplier('platinum-elite');

        // Assert
        expect(multiplier, 1.5);
      });

      test('Returns null for invalid tier', () {
        // Act
        final multiplier =
            TierLeaderboardService.getTierMultiplier('invalid-tier');

        // Assert
        expect(multiplier, isNull);
      });

      test('Gets all tier multipliers', () {
        // Act
        final allMultipliers = TierLeaderboardService.getAllTierMultipliers();

        // Assert
        expect(allMultipliers.length, 8);
        expect(allMultipliers.first.multiplier, 1.0);
        expect(allMultipliers.last.multiplier, 3.0);
      });
    });

    group('Data Consistency', () {
      test('Multipliers are consistent across multiple calls', () async {
        // Arrange
        final goldTier = TierDefinition(
          id: 'gold-master',
          name: 'Gold Master',
          level: 10,
          minXp: 1200,
          maxXp: 2500,
          iconName: 'gold',
          rewards: TierReward(badge: 'master', coinsBonus: 500, gemsBonus: 15),
        );

        mockTierProgressionService.setTierProgress(goldTier);

        // Act
        final multiplier1 =
            await tierLeaderboardService.getScoreMultiplier('user1');
        final multiplier2 =
            await tierLeaderboardService.getScoreMultiplier('user1');

        // Assert
        expect(multiplier1, multiplier2);
      });
    });
  });
}

// Mock implementations

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
