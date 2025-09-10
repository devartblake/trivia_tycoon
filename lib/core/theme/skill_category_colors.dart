import 'package:flutter/material.dart';
import '../../game/models/skill_tree_graph.dart';

class SkillCategoryColors {
  static const Map<SkillCategory, Color> background = {
    SkillCategory.scholar: Color(0xFF3B5B8C),     // Deep blue-purple
    SkillCategory.strategist: Color(0xFF8C3B5B),  // Deep crimson
    SkillCategory.xp: Color(0xFF3B8C5B),          // Deep green
  };

  static const Map<SkillCategory, Color> glow = {
    SkillCategory.scholar: Color(0xFF6EA3FF),
    SkillCategory.strategist: Color(0xFFFF6E9F),
    SkillCategory.xp: Color(0xFF6EFFC1),
  };
}
