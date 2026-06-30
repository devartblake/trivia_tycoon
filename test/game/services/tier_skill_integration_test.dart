import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/services/tier_skill_integration_service.dart';
import 'package:trivia_tycoon/game/services/tier_progression_service.dart';
import 'package:trivia_tycoon/core/services/tier_api_client.dart';

void main() {
  group('TierSkillIntegrationService', () {
    late TierSkillIntegrationService tierSkillService;
    late MockTierProgressionService mockTierProgressionService;

    setUp(() {
      mockTierProgressionService = MockTierProgressionService();
      tierSkillService = TierSkillIntegrationService(
        tierProgressionService: mockTierProgressionService,
      );
    });

    group('Skill Registration', () {
      test('Registers a single skill', () {
        // Arrange
        final skill = TierSkill(
          skillId: 'math_basic',
          name: 'Basic Math',
          category: 'math',
          description: 'Basic arithmetic operations',
        );

        // Act
        tierSkillService.registerSkill(skill);

        // Assert
        expect(tierSkillService.getSkill('math_basic'), isNotNull);
        expect(tierSkillService.getSkill('math_basic')?.name, 'Basic Math');
      });

      test('Registers multiple skills', () {
        // Arrange
        final skills = [
          TierSkill(
            skillId: 'math_basic',
            name: 'Basic Math',
            category: 'math',
            description: 'Basic arithmetic',
          ),
          TierSkill(
            skillId: 'math_algebra',
            name: 'Algebra',
            category: 'math',
            description: 'Algebra basics',
            prerequisites: ['math_basic'],
          ),
        ];

        // Act
        tierSkillService.registerSkills(skills);

        // Assert
        expect(tierSkillService.getSkill('math_basic'), isNotNull);
        expect(tierSkillService.getSkill('math_algebra'), isNotNull);
      });

      test('Retrieves skills by category', () {
        // Arrange
        final skills = [
          TierSkill(
            skillId: 'math_basic',
            name: 'Basic Math',
            category: 'math',
            description: 'Math skill',
          ),
          TierSkill(
            skillId: 'math_algebra',
            name: 'Algebra',
            category: 'math',
            description: 'Math skill',
          ),
          TierSkill(
            skillId: 'science_general',
            name: 'General Science',
            category: 'science',
            description: 'Science skill',
          ),
        ];

        tierSkillService.registerSkills(skills);

        // Act
        final mathSkills = tierSkillService.getSkillsByCategory('math');
        final scienceSkills = tierSkillService.getSkillsByCategory('science');

        // Assert
        expect(mathSkills.length, 2);
        expect(scienceSkills.length, 1);
      });
    });

    group('Skill Access Control', () {
      test('Allows access to skills with no tier requirement', () async {
        // Arrange
        final skill = TierSkill(
          skillId: 'free_skill',
          name: 'Free Skill',
          category: 'general',
          description: 'Available to all',
        );

        tierSkillService.registerSkill(skill);

        // Act
        final canAccess = await tierSkillService.canAccessSkill('user1', 'free_skill');

        // Assert
        expect(canAccess, true);
      });

      test('Blocks access to skills with unmet tier requirement', () async {
        // Arrange
        final skill = TierSkill(
          skillId: 'advanced_math',
          name: 'Advanced Math',
          category: 'math',
          description: 'Requires Gold tier',
          requiredTierId: 'gold-master',
        );

        tierSkillService.registerSkill(skill);

        // Set player to Bronze tier
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
        final canAccess =
            await tierSkillService.canAccessSkill('user1', 'advanced_math');

        // Assert
        expect(canAccess, false);
      });

      test('Allows access when tier requirement is met', () async {
        // Arrange
        final skill = TierSkill(
          skillId: 'gold_skill',
          name: 'Gold Skill',
          category: 'premium',
          description: 'Requires Gold tier',
          requiredTierId: 'gold-master',
        );

        tierSkillService.registerSkill(skill);

        // Set player to Gold tier
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
        final canAccess = await tierSkillService.canAccessSkill('user1', 'gold_skill');

        // Assert
        expect(canAccess, true);
      });
    });

    group('Unlock Information', () {
      test('Returns unlock info for a skill', () async {
        // Arrange
        final skill = TierSkill(
          skillId: 'advanced_skill',
          name: 'Advanced Skill',
          category: 'expert',
          description: 'For expert players',
          requiredTierId: 'platinum-elite',
        );

        tierSkillService.registerSkill(skill);

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

        // Act
        final info = await tierSkillService.getUnlockInfo('user1', 'advanced_skill');

        // Assert
        expect(info, isNotNull);
        expect(info?.skillName, 'Advanced Skill');
        expect(info?.isUnlocked, true);
        expect(info?.requiredTierId, 'platinum-elite');
      });

      test('Returns null for non-existent skill', () async {
        // Act
        final info = await tierSkillService.getUnlockInfo('user1', 'nonexistent');

        // Assert
        expect(info, isNull);
      });
    });

    group('Skill Listing', () {
      test('Returns unlocked skills', () async {
        // Arrange
        final skills = [
          TierSkill(
            skillId: 'free_skill',
            name: 'Free Skill',
            category: 'free',
            description: 'Free',
          ),
          TierSkill(
            skillId: 'locked_skill',
            name: 'Locked Skill',
            category: 'premium',
            description: 'Locked',
            requiredTierId: 'diamond-legend',
          ),
        ];

        tierSkillService.registerSkills(skills);

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
        final unlockedSkills = await tierSkillService.getUnlockedSkills('user1');

        // Assert
        expect(unlockedSkills.length, 1);
        expect(unlockedSkills[0].skillId, 'free_skill');
      });

      test('Returns locked skills', () async {
        // Arrange
        final skills = [
          TierSkill(
            skillId: 'free_skill',
            name: 'Free Skill',
            category: 'free',
            description: 'Free',
          ),
          TierSkill(
            skillId: 'locked_skill',
            name: 'Locked Skill',
            category: 'premium',
            description: 'Locked',
            requiredTierId: 'diamond-legend',
          ),
        ];

        tierSkillService.registerSkills(skills);

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
        final lockedSkills = await tierSkillService.getLockedSkills('user1');

        // Assert
        expect(lockedSkills.length, 1);
        expect(lockedSkills[0].skillId, 'locked_skill');
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
