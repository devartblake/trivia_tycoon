import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/theme/skill_category_colors.dart';
import 'package:synaptix/game/models/skill_tree_graph.dart';

void main() {
  // -------------------------------------------------------------------------
  // SkillCategoryColors — map lengths
  // -------------------------------------------------------------------------

  group('SkillCategoryColors — map lengths', () {
    test('background map has 15 entries', () {
      expect(SkillCategoryColors.background.length, 15);
    });

    test('glow map has 15 entries', () {
      expect(SkillCategoryColors.glow.length, 15);
    });
  });

  // -------------------------------------------------------------------------
  // SkillCategoryColors — backgroundFor spot checks
  // -------------------------------------------------------------------------

  group('SkillCategoryColors.backgroundFor — spot checks', () {
    test('scholar returns Color(0xFF3B5B8C)', () {
      expect(
        SkillCategoryColors.backgroundFor(SkillCategory.scholar),
        const Color(0xFF3B5B8C),
      );
    });

    test('unknown returns Color(0xFF3B3B3B)', () {
      expect(
        SkillCategoryColors.backgroundFor(SkillCategory.unknown),
        const Color(0xFF3B3B3B),
      );
    });
  });

  // -------------------------------------------------------------------------
  // SkillCategoryColors — glowFor spot checks
  // -------------------------------------------------------------------------

  group('SkillCategoryColors.glowFor — spot checks', () {
    test('xp returns Color(0xFF6EFFC1)', () {
      expect(
        SkillCategoryColors.glowFor(SkillCategory.xp),
        const Color(0xFF6EFFC1),
      );
    });

    test('combat returns Color(0xFFFF8E6E)', () {
      expect(
        SkillCategoryColors.glowFor(SkillCategory.combat),
        const Color(0xFFFF8E6E),
      );
    });
  });

  // -------------------------------------------------------------------------
  // SkillCategoryColors — all SkillCategory values return a Color
  // -------------------------------------------------------------------------

  group('SkillCategoryColors — all values return Color', () {
    test('backgroundFor returns a Color for every SkillCategory', () {
      for (final category in SkillCategory.values) {
        expect(
          SkillCategoryColors.backgroundFor(category),
          isA<Color>(),
          reason: 'backgroundFor($category) should return a Color',
        );
      }
    });

    test('glowFor returns a Color for every SkillCategory', () {
      for (final category in SkillCategory.values) {
        expect(
          SkillCategoryColors.glowFor(category),
          isA<Color>(),
          reason: 'glowFor($category) should return a Color',
        );
      }
    });
  });
}
