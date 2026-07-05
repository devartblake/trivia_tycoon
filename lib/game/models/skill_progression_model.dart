import 'question_difficulty.dart';

/// Represents a skill node in the skill tree
class SkillNode {
  final String skillId;
  final String name;
  final String category; // e.g., 'math', 'science', 'logic'
  final String? description;
  final int level; // 1-10
  final int totalXpRequired; // Total XP to reach this level
  final int currentXp; // Current XP toward next level
  final List<String> prerequisites; // SKill IDs that must be mastered first
  final DateTime? unlockedAt;
  final DateTime? masteredAt;

  /// Server-defined tier (from the skills catalog), when known. Screens that
  /// group skills by tier prefer this over heuristics.
  final int? tier;

  SkillNode({
    required this.skillId,
    required this.name,
    required this.category,
    this.description,
    this.level = 1,
    this.totalXpRequired = 0,
    this.currentXp = 0,
    this.prerequisites = const [],
    this.unlockedAt,
    this.masteredAt,
    this.tier,
  });

  /// Check if this skill is fully mastered
  bool get isMastered => level >= 10;

  /// Get progress percentage to next level
  double get progressPercent {
    if (isMastered) return 1.0;
    final xpToNextLevel = _getXpRequiredForLevel(level + 1) - totalXpRequired;
    if (xpToNextLevel <= 0) return 0.0;
    return (currentXp / xpToNextLevel).clamp(0.0, 1.0);
  }

  /// Get XP required for a specific level
  static int _getXpRequiredForLevel(int level) {
    // Exponential scaling: each level requires 50% more XP than previous
    // Level 1: 1000, Level 2: 1500, Level 3: 2250, etc.
    if (level <= 1) return 0;
    return (1000 * (1.5 * (level - 1))).toInt();
  }

  /// Create a copy with optional modifications
  SkillNode copyWith({
    String? skillId,
    String? name,
    String? category,
    String? description,
    int? level,
    int? totalXpRequired,
    int? currentXp,
    List<String>? prerequisites,
    DateTime? unlockedAt,
    DateTime? masteredAt,
    int? tier,
  }) {
    return SkillNode(
      skillId: skillId ?? this.skillId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      level: level ?? this.level,
      totalXpRequired: totalXpRequired ?? this.totalXpRequired,
      currentXp: currentXp ?? this.currentXp,
      prerequisites: prerequisites ?? this.prerequisites,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      masteredAt: masteredAt ?? this.masteredAt,
      tier: tier ?? this.tier,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'skillId': skillId,
      'name': name,
      'category': category,
      'description': description,
      'level': level,
      'totalXpRequired': totalXpRequired,
      'currentXp': currentXp,
      'prerequisites': prerequisites,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'masteredAt': masteredAt?.toIso8601String(),
      'tier': tier,
    };
  }

  /// Create from JSON
  factory SkillNode.fromJson(Map<String, dynamic> json) {
    return SkillNode(
      skillId: json['skillId'] as String,
      name: json['name'] as String,
      category: json['category'] as String,
      description: json['description'] as String?,
      level: json['level'] as int? ?? 1,
      totalXpRequired: json['totalXpRequired'] as int? ?? 0,
      currentXp: json['currentXp'] as int? ?? 0,
      prerequisites: List<String>.from(json['prerequisites'] as List? ?? []),
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      masteredAt: json['masteredAt'] != null
          ? DateTime.parse(json['masteredAt'] as String)
          : null,
      tier: json['tier'] as int?,
    );
  }

  @override
  String toString() =>
      'SkillNode($name, lvl:$level, xp:$currentXp/$totalXpRequired)';
}

/// Category-level skill mastery
class SkillCategoryMastery {
  final String category; // e.g., 'math', 'science'
  final int totalSkills;
  final int masteredSkills;
  final int totalXp;
  final DateTime lastActivityAt;

  SkillCategoryMastery({
    required this.category,
    required this.totalSkills,
    required this.masteredSkills,
    required this.totalXp,
    required this.lastActivityAt,
  });

  /// Overall category mastery percentage
  double get masteryPercent =>
      totalSkills > 0 ? (masteredSkills / totalSkills * 100) : 0.0;

  /// Category rank based on mastery
  String get rankName {
    if (masteryPercent >= 90) return 'Expert';
    if (masteryPercent >= 70) return 'Advanced';
    if (masteryPercent >= 50) return 'Proficient';
    if (masteryPercent >= 25) return 'Familiar';
    return 'Novice';
  }

  /// Create a copy with optional modifications
  SkillCategoryMastery copyWith({
    String? category,
    int? totalSkills,
    int? masteredSkills,
    int? totalXp,
    DateTime? lastActivityAt,
  }) {
    return SkillCategoryMastery(
      category: category ?? this.category,
      totalSkills: totalSkills ?? this.totalSkills,
      masteredSkills: masteredSkills ?? this.masteredSkills,
      totalXp: totalXp ?? this.totalXp,
      lastActivityAt: lastActivityAt ?? this.lastActivityAt,
    );
  }

  @override
  String toString() =>
      '$category: $masteredSkills/$totalSkills skills, $masteryPercent% mastered';
}

/// Difficulty reward modifier for skill progression
extension DifficultySkillBonus on QuestionDifficulty {
  /// Skill XP multiplier based on difficulty
  double get skillXpMultiplier {
    switch (this) {
      case QuestionDifficulty.easy:
        return 1.0;
      case QuestionDifficulty.medium:
        return 1.3;
      case QuestionDifficulty.hard:
        return 1.6;
      case QuestionDifficulty.expert:
        return 2.0;
      case QuestionDifficulty.boss:
        return 2.5;
    }
  }
}
