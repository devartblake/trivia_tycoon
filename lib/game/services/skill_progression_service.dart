import '../models/skill_progression_model.dart';
import '../models/question_result_model.dart';
import 'package:synaptix/core/manager/log_manager.dart';

/// Service for managing skill tree progression based on question results
class SkillProgressionService {
  final Map<String, SkillNode> _skills = {};
  final Map<String, SkillCategoryMastery> _categoryMastery = {};

  /// Initialize with default skill tree
  void initializeDefaultSkills() {
    // Math skills
    _addSkill(
      'math_basic',
      'Basic Math',
      'math',
      'Addition, subtraction, multiplication, division',
    );
    _addSkill(
      'math_algebra',
      'Algebra',
      'math',
      'Variables, equations, and functions',
      prerequisites: ['math_basic'],
    );
    _addSkill(
      'math_geometry',
      'Geometry',
      'math',
      'Shapes, angles, and spatial reasoning',
      prerequisites: ['math_basic'],
    );

    // Science skills
    _addSkill(
      'science_general',
      'General Science',
      'science',
      'Basic scientific concepts',
    );
    _addSkill(
      'science_biology',
      'Biology',
      'science',
      'Living organisms and life processes',
      prerequisites: ['science_general'],
    );
    _addSkill(
      'science_physics',
      'Physics',
      'science',
      'Forces, motion, and energy',
      prerequisites: ['science_general'],
    );

    // Logic skills
    _addSkill(
      'logic_patterns',
      'Pattern Recognition',
      'logic',
      'Identifying sequences and patterns',
    );
    _addSkill(
      'logic_reasoning',
      'Logical Reasoning',
      'logic',
      'Deduction and problem solving',
      prerequisites: ['logic_patterns'],
    );

    LogManager.debug(
        '[SkillProgressionService] Initialized with default skills');
  }

  /// Add a skill to the tree
  void _addSkill(
    String skillId,
    String name,
    String category,
    String description, {
    List<String> prerequisites = const [],
  }) {
    _skills[skillId] = SkillNode(
      skillId: skillId,
      name: name,
      category: category,
      description: description,
      prerequisites: prerequisites,
      unlockedAt: prerequisites.isEmpty ? DateTime.now() : null,
    );

    // Initialize or update category mastery
    if (!_categoryMastery.containsKey(category)) {
      _categoryMastery[category] = SkillCategoryMastery(
        category: category,
        totalSkills: 0,
        masteredSkills: 0,
        totalXp: 0,
        lastActivityAt: DateTime.now(),
      );
    }

    final mastery = _categoryMastery[category]!;
    _categoryMastery[category] = mastery.copyWith(
      totalSkills: mastery.totalSkills + 1,
    );
  }

  /// Process a question result and update skill progression
  void processQuestionResult(QuestionResultModel result) {
    if (!result.isCorrect) {
      LogManager.debug(
        '[SkillProgressionService] Incorrect answer, no skill XP gained',
      );
      return;
    }

    // Calculate skill XP based on difficulty
    final skillXpGain =
        (result.xpEarned * result.difficulty.skillXpMultiplier).round();

    // Update skills related to this category
    _updateCategorySkills(result.category, skillXpGain);

    // Update category mastery
    _updateCategoryMastery(result.category, skillXpGain);

    LogManager.debug(
      '[SkillProgressionService] Gained $skillXpGain skill XP for ${result.category}',
    );
  }

  /// Update skills in a category
  void _updateCategorySkills(String category, int skillXpGain) {
    for (final skill in _skills.values) {
      if (skill.category.toLowerCase() != category.toLowerCase()) {
        continue;
      }

      if (skill.isMastered) {
        continue; // Don't add XP to mastered skills
      }

      // Add XP to skill
      var newXp = skill.currentXp + skillXpGain;
      var newLevel = skill.level;
      var newTotalXp = skill.totalXpRequired;

      // Check for level ups
      while (newLevel < 10) {
        final xpForNextLevel = _getXpForLevel(newLevel + 1);
        if (newXp >= xpForNextLevel - newTotalXp) {
          newXp -= (xpForNextLevel - newTotalXp);
          newTotalXp = xpForNextLevel;
          newLevel++;
        } else {
          break;
        }
      }

      final masteredAt = newLevel >= 10 ? DateTime.now() : null;

      _skills[skill.skillId] = skill.copyWith(
        level: newLevel,
        currentXp: newXp,
        totalXpRequired: newTotalXp,
        masteredAt: masteredAt,
      );
    }
  }

  /// Update category mastery stats
  void _updateCategoryMastery(String category, int skillXpGain) {
    if (!_categoryMastery.containsKey(category)) {
      return;
    }

    final mastery = _categoryMastery[category]!;
    final masteredCount = _skills.values
        .where((s) => s.category == category && s.isMastered)
        .length;

    _categoryMastery[category] = SkillCategoryMastery(
      category: category,
      totalSkills: mastery.totalSkills,
      masteredSkills: masteredCount,
      totalXp: mastery.totalXp + skillXpGain,
      lastActivityAt: DateTime.now(),
    );
  }

  /// Get XP required for a specific level
  int _getXpForLevel(int level) {
    if (level <= 1) return 0;
    return (1000 * (1.5 * (level - 1))).toInt();
  }

  /// Get a specific skill by ID
  SkillNode? getSkill(String skillId) => _skills[skillId];

  /// Get all skills for a category
  List<SkillNode> getSkillsForCategory(String category) {
    return _skills.values
        .where(
            (skill) => skill.category.toLowerCase() == category.toLowerCase())
        .toList();
  }

  /// Get all skills
  List<SkillNode> getAllSkills() => _skills.values.toList();

  /// Get category mastery stats
  SkillCategoryMastery? getCategoryMastery(String category) {
    return _categoryMastery[category];
  }

  /// Get all category mastery stats
  List<SkillCategoryMastery> getAllCategoryMastery() =>
      _categoryMastery.values.toList();

  /// Get overall progress
  SkillProgressOverview getProgressOverview() {
    final totalSkills = _skills.length;
    final masteredSkills = _skills.values.where((s) => s.isMastered).length;
    final totalXp = _skills.values
        .fold(0, (sum, s) => sum + s.totalXpRequired + s.currentXp);
    final categories = _categoryMastery.values.toList();

    return SkillProgressOverview(
      totalSkills: totalSkills,
      masteredSkills: masteredSkills,
      totalXp: totalXp,
      categories: categories,
      overallMasteryPercent:
          totalSkills > 0 ? (masteredSkills / totalSkills * 100) : 0.0,
    );
  }

  /// Check if a skill can be unlocked (prerequisites met)
  bool canUnlockSkill(String skillId) {
    final skill = _skills[skillId];
    if (skill == null) return false;
    if (skill.unlockedAt != null) return false; // Already unlocked

    // Check prerequisites
    for (final prereq in skill.prerequisites) {
      final prereqSkill = _skills[prereq];
      if (prereqSkill == null || !prereqSkill.isMastered) {
        return false;
      }
    }

    return true;
  }

  /// Unlock a skill (when prerequisites are met)
  bool unlockSkill(String skillId) {
    if (!canUnlockSkill(skillId)) {
      return false;
    }

    final skill = _skills[skillId];
    if (skill != null) {
      _skills[skillId] = skill.copyWith(unlockedAt: DateTime.now());
      return true;
    }

    return false;
  }
}

/// Overall skill progression summary
class SkillProgressOverview {
  final int totalSkills;
  final int masteredSkills;
  final int totalXp;
  final List<SkillCategoryMastery> categories;
  final double overallMasteryPercent;

  SkillProgressOverview({
    required this.totalSkills,
    required this.masteredSkills,
    required this.totalXp,
    required this.categories,
    required this.overallMasteryPercent,
  });

  int get unlockedSkills => totalSkills - masteredSkills;

  /// Get rank based on overall mastery
  String get overallRank {
    if (overallMasteryPercent >= 90) return 'Master';
    if (overallMasteryPercent >= 70) return 'Expert';
    if (overallMasteryPercent >= 50) return 'Advanced';
    if (overallMasteryPercent >= 25) return 'Intermediate';
    return 'Novice';
  }

  @override
  String toString() =>
      'SkillProgress($masteredSkills/$totalSkills mastered, ${overallMasteryPercent.toStringAsFixed(1)}%, $totalXp total XP)';
}
