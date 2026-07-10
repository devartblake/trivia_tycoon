import 'package:trivia_tycoon/core/manager/log_manager.dart';
import 'tier_progression_service.dart';

/// Defines a skill with tier requirements
class TierSkill {
  final String skillId;
  final String name;
  final String category;
  final String description;
  final String? requiredTierId;
  final int? requiredTierLevel;
  final List<String> prerequisites;

  TierSkill({
    required this.skillId,
    required this.name,
    required this.category,
    required this.description,
    this.requiredTierId,
    this.requiredTierLevel,
    this.prerequisites = const [],
  });
}

/// Service for managing tier-based skill unlocking
class TierSkillIntegrationService {
  final TierProgressionService _tierProgressionService;
  final Map<String, TierSkill> _tieredSkills = {};

  TierSkillIntegrationService({
    required TierProgressionService tierProgressionService,
  }) : _tierProgressionService = tierProgressionService;

  /// Register a skill with tier requirements
  void registerSkill(TierSkill skill) {
    _tieredSkills[skill.skillId] = skill;
    LogManager.debug(
      '[TierSkillIntegration] Registered skill: ${skill.name} '
      '(requires: ${skill.requiredTierId ?? "none"})',
    );
  }

  /// Register multiple skills at once
  void registerSkills(List<TierSkill> skills) {
    for (final skill in skills) {
      registerSkill(skill);
    }
  }

  /// Check if player can access a skill
  Future<bool> canAccessSkill(String userId, String skillId) async {
    try {
      final skill = _tieredSkills[skillId];
      if (skill == null) {
        LogManager.warning('[TierSkillIntegration] Skill not found: $skillId');
        return false;
      }

      // Check tier requirement
      if (skill.requiredTierId != null) {
        final progress =
            await _tierProgressionService.getPlayerTierProgress(userId);

        // Check if player has reached the required tier
        if (progress.currentTier.id != skill.requiredTierId) {
          LogManager.debug(
            '[TierSkillIntegration] Player tier ${progress.currentTier.id} '
            'does not meet requirement ${skill.requiredTierId}',
          );
          return false;
        }

        // Check if player has reached the required level within the tier
        if (skill.requiredTierLevel != null &&
            progress.currentTier.level < skill.requiredTierLevel!) {
          LogManager.debug(
            '[TierSkillIntegration] Player level ${progress.currentTier.level} '
            'does not meet requirement ${skill.requiredTierLevel}',
          );
          return false;
        }
      }

      // All requirements met
      return true;
    } catch (e) {
      LogManager.error(
        '[TierSkillIntegration] Error checking skill access: $e',
        error: e,
      );
      return false;
    }
  }

  /// Get skill with tier requirements info
  TierSkill? getSkill(String skillId) {
    return _tieredSkills[skillId];
  }

  /// Get all skills for a category with tier requirements
  List<TierSkill> getSkillsByCategory(String category) {
    return _tieredSkills.values
        .where((skill) => skill.category == category)
        .toList();
  }

  /// Get information about what's needed to unlock a skill
  Future<SkillUnlockInfo?> getUnlockInfo(String userId, String skillId) async {
    try {
      final skill = _tieredSkills[skillId];
      if (skill == null) return null;

      final progress =
          await _tierProgressionService.getPlayerTierProgress(userId);
      final canAccess = await canAccessSkill(userId, skillId);

      return SkillUnlockInfo(
        skillId: skillId,
        skillName: skill.name,
        isUnlocked: canAccess,
        requiredTierId: skill.requiredTierId,
        requiredTierLevel: skill.requiredTierLevel,
        currentTierId: progress.currentTier.id,
        currentTierLevel: progress.currentTier.level,
        tierProgressPercentage: progress.progressPercentage,
      );
    } catch (e) {
      LogManager.error(
        '[TierSkillIntegration] Error getting unlock info: $e',
        error: e,
      );
      return null;
    }
  }

  /// Get all unlocked skills for a player
  Future<List<TierSkill>> getUnlockedSkills(String userId) async {
    try {
      final unlockedSkills = <TierSkill>[];

      for (final skill in _tieredSkills.values) {
        if (await canAccessSkill(userId, skill.skillId)) {
          unlockedSkills.add(skill);
        }
      }

      return unlockedSkills;
    } catch (e) {
      LogManager.error(
        '[TierSkillIntegration] Error getting unlocked skills: $e',
        error: e,
      );
      return [];
    }
  }

  /// Get all locked skills for a player
  Future<List<TierSkill>> getLockedSkills(String userId) async {
    try {
      final lockedSkills = <TierSkill>[];

      for (final skill in _tieredSkills.values) {
        if (!await canAccessSkill(userId, skill.skillId)) {
          lockedSkills.add(skill);
        }
      }

      return lockedSkills;
    } catch (e) {
      LogManager.error(
        '[TierSkillIntegration] Error getting locked skills: $e',
        error: e,
      );
      return [];
    }
  }

  /// Get the next tier that unlocks new skills
  Future<String?> getNextUnlockingTier(String userId) async {
    try {
      final progress =
          await _tierProgressionService.getPlayerTierProgress(userId);
      final currentTierId = progress.currentTier.id;

      // Find the next tier that has skills to unlock
      for (final skill in _tieredSkills.values) {
        if (skill.requiredTierId != null &&
            skill.requiredTierId != currentTierId &&
            !await canAccessSkill(userId, skill.skillId)) {
          return skill.requiredTierId;
        }
      }

      return null;
    } catch (e) {
      LogManager.error(
        '[TierSkillIntegration] Error getting next unlocking tier: $e',
        error: e,
      );
      return null;
    }
  }
}

/// Information about a skill's unlock requirements
class SkillUnlockInfo {
  final String skillId;
  final String skillName;
  final bool isUnlocked;
  final String? requiredTierId;
  final int? requiredTierLevel;
  final String currentTierId;
  final int currentTierLevel;
  final int tierProgressPercentage;

  SkillUnlockInfo({
    required this.skillId,
    required this.skillName,
    required this.isUnlocked,
    this.requiredTierId,
    this.requiredTierLevel,
    required this.currentTierId,
    required this.currentTierLevel,
    required this.tierProgressPercentage,
  });
}
