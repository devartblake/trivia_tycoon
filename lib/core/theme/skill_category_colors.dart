import 'package:flutter/material.dart';
import '../../game/models/skill_tree_graph.dart';

class SkillCategoryColors {
  static const Map<SkillCategory, Color> background = {
    SkillCategory.Scholar: Color(0xFF3B5B8C),     // Deep blue-purple
    SkillCategory.Strategist: Color(0xFF8C3B5B),  // Deep crimson
    SkillCategory.XP: Color(0xFF3B8C5B),          // Deep green
  };

  static const Map<SkillCategory, Color> glow = {
    SkillCategory.Scholar: Color(0xFF6EA3FF),
    SkillCategory.Strategist: Color(0xFFFF6E9F),
    SkillCategory.XP: Color(0xFF6EFFC1),
  };
}
