import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/services/quiz_category.dart';

void main() {
  // -------------------------------------------------------------------------
  // QuizCategory enum values
  // -------------------------------------------------------------------------

  group('QuizCategory enum values', () {
    test('has exactly 36 values', () {
      expect(QuizCategory.values.length, 36);
    });

    test('contains core academic subjects', () {
      expect(QuizCategory.values, contains(QuizCategory.arts));
      expect(QuizCategory.values, contains(QuizCategory.science));
      expect(QuizCategory.values, contains(QuizCategory.mathematics));
      expect(QuizCategory.values, contains(QuizCategory.history));
      expect(QuizCategory.values, contains(QuizCategory.geography));
      expect(QuizCategory.values, contains(QuizCategory.literature));
      expect(QuizCategory.values, contains(QuizCategory.technology));
      expect(QuizCategory.values, contains(QuizCategory.health));
      expect(QuizCategory.values, contains(QuizCategory.sports));
      expect(QuizCategory.values, contains(QuizCategory.entertainment));
    });

    test('contains educational categories', () {
      expect(QuizCategory.values, contains(QuizCategory.kids));
      expect(QuizCategory.values, contains(QuizCategory.kidsGrade2));
      expect(QuizCategory.values, contains(QuizCategory.general));
    });

    test('contains specialized categories', () {
      expect(QuizCategory.values, contains(QuizCategory.astronomy));
      expect(QuizCategory.values, contains(QuizCategory.computerScience));
      expect(QuizCategory.values, contains(QuizCategory.worldLiterature));
    });
  });

  // -------------------------------------------------------------------------
  // QuizCategoryExtension — displayName
  // -------------------------------------------------------------------------

  group('displayName', () {
    test('science → "Science"', () {
      expect(QuizCategory.science.displayName, 'Science');
    });

    test('mathematics → "Mathematics"', () {
      expect(QuizCategory.mathematics.displayName, 'Mathematics');
    });

    test('history → "History"', () {
      expect(QuizCategory.history.displayName, 'History');
    });

    test('currentEvents → "Current Events"', () {
      expect(QuizCategory.currentEvents.displayName, 'Current Events');
    });

    test('computerScience → "Computer Science"', () {
      expect(QuizCategory.computerScience.displayName, 'Computer Science');
    });

    test('general → "General Knowledge"', () {
      expect(QuizCategory.general.displayName, 'General Knowledge');
    });

    test('all values have non-empty displayName', () {
      for (final category in QuizCategory.values) {
        expect(category.displayName.isNotEmpty, isTrue,
            reason: '${category.name}.displayName is empty');
      }
    });
  });

  // -------------------------------------------------------------------------
  // QuizCategoryExtension — description
  // -------------------------------------------------------------------------

  group('description', () {
    test('science has non-empty description', () {
      expect(QuizCategory.science.description.isNotEmpty, isTrue);
    });

    test('all values have non-empty description', () {
      for (final category in QuizCategory.values) {
        expect(category.description.isNotEmpty, isTrue,
            reason: '${category.name}.description is empty');
      }
    });
  });

  // -------------------------------------------------------------------------
  // QuizCategoryExtension — primaryColor
  // -------------------------------------------------------------------------

  group('primaryColor', () {
    test('science returns a Color', () {
      expect(QuizCategory.science.primaryColor, isA<Color>());
    });

    test('arts returns a Color', () {
      expect(QuizCategory.arts.primaryColor, isA<Color>());
    });

    test('all values return a Color', () {
      for (final category in QuizCategory.values) {
        expect(category.primaryColor, isA<Color>(),
            reason: '${category.name}.primaryColor is not a Color');
      }
    });
  });

  // -------------------------------------------------------------------------
  // QuizCategoryExtension — icon
  // -------------------------------------------------------------------------

  group('icon', () {
    test('science returns an IconData', () {
      expect(QuizCategory.science.icon, isA<IconData>());
    });

    test('general returns Icons.quiz', () {
      expect(QuizCategory.general.icon, Icons.quiz);
    });

    test('all values return an IconData', () {
      for (final category in QuizCategory.values) {
        expect(category.icon, isA<IconData>(),
            reason: '${category.name}.icon is not an IconData');
      }
    });
  });

  // -------------------------------------------------------------------------
  // QuizCategoryExtension — datasetName
  // -------------------------------------------------------------------------

  group('datasetName', () {
    test('science returns non-empty string', () {
      expect(QuizCategory.science.datasetName.isNotEmpty, isTrue);
    });

    test('all values have non-empty datasetName', () {
      for (final category in QuizCategory.values) {
        expect(category.datasetName.isNotEmpty, isTrue,
            reason: '${category.name}.datasetName is empty');
      }
    });
  });

  // -------------------------------------------------------------------------
  // QuizCategoryExtension — gradientColors
  // -------------------------------------------------------------------------

  group('gradientColors', () {
    test('science returns a list of 2 Colors', () {
      final colors = QuizCategory.science.gradientColors;
      expect(colors, isA<List<Color>>());
      expect(colors.length, 2);
    });

    test('all values return list with at least 2 colors', () {
      for (final category in QuizCategory.values) {
        expect(category.gradientColors.length, greaterThanOrEqualTo(2),
            reason: '${category.name}.gradientColors has fewer than 2 colors');
      }
    });

    test('first gradient color matches primaryColor', () {
      expect(QuizCategory.arts.gradientColors.first,
          QuizCategory.arts.primaryColor);
    });
  });

  // -------------------------------------------------------------------------
  // QuizCategoryManager — static lists
  // -------------------------------------------------------------------------

  group('QuizCategoryManager static lists', () {
    test('coreCategories contains science', () {
      expect(
          QuizCategoryManager.coreCategories, contains(QuizCategory.science));
    });

    test('coreCategories has 10 entries', () {
      expect(QuizCategoryManager.coreCategories.length, 10);
    });

    test('extendedCategories is non-empty', () {
      expect(QuizCategoryManager.extendedCategories, isNotEmpty);
    });

    test('extendedCategories does not overlap coreCategories', () {
      final core = QuizCategoryManager.coreCategories.toSet();
      final extended = QuizCategoryManager.extendedCategories.toSet();
      expect(core.intersection(extended), isEmpty);
    });

    test('specializedCategories is non-empty', () {
      expect(QuizCategoryManager.specializedCategories, isNotEmpty);
    });

    test('educationalCategories contains kids', () {
      expect(QuizCategoryManager.educationalCategories,
          contains(QuizCategory.kids));
    });

    test('educationalCategories contains general', () {
      expect(QuizCategoryManager.educationalCategories,
          contains(QuizCategory.general));
    });

    test('allCategories includes all core categories', () {
      for (final c in QuizCategoryManager.coreCategories) {
        expect(QuizCategoryManager.allCategories, contains(c));
      }
    });

    test('allCategories includes all extended categories', () {
      for (final c in QuizCategoryManager.extendedCategories) {
        expect(QuizCategoryManager.allCategories, contains(c));
      }
    });

    test('allCategories length equals total enum values', () {
      expect(
          QuizCategoryManager.allCategories.length, QuizCategory.values.length);
    });

    test('allCategories has no duplicates', () {
      final list = QuizCategoryManager.allCategories;
      expect(list.toSet().length, list.length);
    });
  });

  // -------------------------------------------------------------------------
  // QuizCategoryManager.fromString
  // -------------------------------------------------------------------------

  group('QuizCategoryManager.fromString', () {
    test('"science" → QuizCategory.science', () {
      expect(QuizCategoryManager.fromString('science'), QuizCategory.science);
    });

    test('"mathematics" → QuizCategory.mathematics', () {
      expect(QuizCategoryManager.fromString('mathematics'),
          QuizCategory.mathematics);
    });

    test('"history" → QuizCategory.history', () {
      expect(QuizCategoryManager.fromString('history'), QuizCategory.history);
    });

    test('"math" (alias) → QuizCategory.mathematics', () {
      expect(QuizCategoryManager.fromString('math'), QuizCategory.mathematics);
    });

    test('"maths" (alias) → QuizCategory.mathematics', () {
      expect(QuizCategoryManager.fromString('maths'), QuizCategory.mathematics);
    });

    test('"computing" (alias) → QuizCategory.technology', () {
      expect(
          QuizCategoryManager.fromString('computing'), QuizCategory.technology);
    });

    test('"tech" (alias) → QuizCategory.technology', () {
      expect(QuizCategoryManager.fromString('tech'), QuizCategory.technology);
    });

    test('"mixed" → QuizCategory.general', () {
      expect(QuizCategoryManager.fromString('mixed'), QuizCategory.general);
    });

    test('"cs" (alias) → QuizCategory.computerScience', () {
      expect(
          QuizCategoryManager.fromString('cs'), QuizCategory.computerScience);
    });

    test('case-insensitive: "SCIENCE" → QuizCategory.science', () {
      expect(QuizCategoryManager.fromString('SCIENCE'), QuizCategory.science);
    });

    test('case-insensitive: "Mathematics" → QuizCategory.mathematics', () {
      expect(QuizCategoryManager.fromString('Mathematics'),
          QuizCategory.mathematics);
    });

    test('empty string → null', () {
      expect(QuizCategoryManager.fromString(''), isNull);
    });

    test('unknown string → null', () {
      expect(QuizCategoryManager.fromString('nonexistent_xyz'), isNull);
    });

    test('"general knowledge" → QuizCategory.general', () {
      expect(QuizCategoryManager.fromString('general knowledge'),
          QuizCategory.general);
    });
  });

  // -------------------------------------------------------------------------
  // QuizCategoryManager.getCategoriesForClass
  // -------------------------------------------------------------------------

  group('QuizCategoryManager.getCategoriesForClass', () {
    test('level 1 returns non-empty list', () {
      expect(QuizCategoryManager.getCategoriesForClass('1'), isNotEmpty);
    });

    test('level 1 contains kids category', () {
      expect(QuizCategoryManager.getCategoriesForClass('1'),
          contains(QuizCategory.kids));
    });

    test('level 2 returns non-empty list', () {
      expect(QuizCategoryManager.getCategoriesForClass('2'), isNotEmpty);
    });

    test('level 5 returns non-empty list', () {
      expect(QuizCategoryManager.getCategoriesForClass('5'), isNotEmpty);
    });

    test('level 10 returns large list (all categories)', () {
      final result = QuizCategoryManager.getCategoriesForClass('10');
      expect(result.length, greaterThan(10));
    });

    test('higher level returns more categories than lower level', () {
      final level1 = QuizCategoryManager.getCategoriesForClass('1');
      final level10 = QuizCategoryManager.getCategoriesForClass('10');
      expect(level10.length, greaterThanOrEqualTo(level1.length));
    });

    test('invalid level string falls back gracefully', () {
      final result = QuizCategoryManager.getCategoriesForClass('abc');
      expect(result, isNotEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // QuizCategoryManager.searchCategories
  // -------------------------------------------------------------------------

  group('QuizCategoryManager.searchCategories', () {
    test('"sci" matches science', () {
      final results = QuizCategoryManager.searchCategories('sci');
      expect(results, contains(QuizCategory.science));
    });

    test('"history" matches history', () {
      final results = QuizCategoryManager.searchCategories('history');
      expect(results, contains(QuizCategory.history));
    });

    test('"zzz_nomatch" returns empty list', () {
      expect(QuizCategoryManager.searchCategories('zzz_nomatch'), isEmpty);
    });

    test('empty string returns all categories', () {
      final results = QuizCategoryManager.searchCategories('');
      expect(results.length, QuizCategoryManager.allCategories.length);
    });

    test('search is case-insensitive', () {
      final results = QuizCategoryManager.searchCategories('SCIENCE');
      expect(results, contains(QuizCategory.science));
    });

    test('"space" matches astronomy via description', () {
      final results = QuizCategoryManager.searchCategories('space');
      expect(results, contains(QuizCategory.astronomy));
    });
  });
}
