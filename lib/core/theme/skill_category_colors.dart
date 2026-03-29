import 'package:flutter/material.dart';
import '../../game/models/skill_tree_graph.dart';

class SkillCategoryColors {
  static const Map<SkillCategory, Color> background = {
    SkillCategory.scholar:    Color(0xFF3B5B8C), // Deep blue-purple
    SkillCategory.strategist: Color(0xFF8C3B5B), // Deep crimson
    SkillCategory.xp:         Color(0xFF3B8C5B), // Deep green
    SkillCategory.timer:      Color(0xFF5B3B8C), // Deep violet
    SkillCategory.combo:      Color(0xFF8C6B3B), // Deep amber
    SkillCategory.risk:       Color(0xFF8C3B3B), // Deep red
    SkillCategory.luck:       Color(0xFF3B8C8C), // Deep teal
    SkillCategory.elite:      Color(0xFF5B5B3B), // Deep olive
    SkillCategory.stealth:    Color(0xFF3B3B5B), // Deep indigo
    SkillCategory.combat:     Color(0xFF7C3B3B), // Deep burnt red
    SkillCategory.knowledge:  Color(0xFF3B5B7C), // Deep slate blue
    SkillCategory.wildcard:   Color(0xFF6B3B7C), // Deep purple
    SkillCategory.general:    Color(0xFF4A4A4A), // Dark grey
    SkillCategory.category:   Color(0xFF3B7C5B), // Deep emerald
    SkillCategory.unknown:    Color(0xFF3B3B3B), // Near black
  };

  static const Map<SkillCategory, Color> glow = {
    SkillCategory.scholar:    Color(0xFF6EA3FF),
    SkillCategory.strategist: Color(0xFFFF6E9F),
    SkillCategory.xp:         Color(0xFF6EFFC1),
    SkillCategory.timer:      Color(0xFFB06EFF),
    SkillCategory.combo:      Color(0xFFFFBF6E),
    SkillCategory.risk:       Color(0xFFFF6E6E),
    SkillCategory.luck:       Color(0xFF6EFFFF),
    SkillCategory.elite:      Color(0xFFFFFF6E),
    SkillCategory.stealth:    Color(0xFF9E9EFF),
    SkillCategory.combat:     Color(0xFFFF8E6E),
    SkillCategory.knowledge:  Color(0xFF6EC3FF),
    SkillCategory.wildcard:   Color(0xFFD46EFF),
    SkillCategory.general:    Color(0xFFB0B0B0),
    SkillCategory.category:   Color(0xFF6EFF9E),
    SkillCategory.unknown:    Color(0xFF888888),
  };

  static Color backgroundFor(SkillCategory c) =>
      background[c] ?? const Color(0xFF4A4A4A);

  static Color glowFor(SkillCategory c) =>
      glow[c] ?? const Color(0xFFB0B0B0);
}
