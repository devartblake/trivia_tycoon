import 'package:flutter/material.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';

class SkillTreeCategoryColors {
  static Map<SkillCategory, Color> categoryColors = {
    SkillCategory.xp: Color(0xFF40C4FF),          // Bright blue
    SkillCategory.strategist: Color(0xFF8E24AA),  // Deep purple
    SkillCategory.scholar: Color(0xFFFFB300),     // Amber
    SkillCategory.combat: Color(0xFFEF5350),      // Red
    SkillCategory.stealth: Color(0xFF66BB6A),     // Green
    SkillCategory.luck: Color(0xFFFFD600),        // Yellow
    SkillCategory.wildcard: Color(0xFF7C4DFF),    // Violet
    SkillCategory.general: Colors.blue,
    SkillCategory.timer: Colors.purple,
    SkillCategory.combo: Colors.orange,
    SkillCategory.knowledge: Colors.green,
    SkillCategory.risk: Colors.red,
    SkillCategory.elite: Colors.amber,
    SkillCategory.unknown: Colors.grey,
  };

  static Color getColor(SkillCategory category) {
    return categoryColors[category] ?? Colors.grey;
  }
}