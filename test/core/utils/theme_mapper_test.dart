import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/utils/theme_mapper.dart';
import 'package:trivia_tycoon/core/utils/theme_utils.dart';
import 'package:trivia_tycoon/game/controllers/theme_settings_controller.dart';

void main() {
  // -------------------------------------------------------------------------
  // ThemeMapper.getThemeForAgeGroup
  // -------------------------------------------------------------------------

  group('ThemeMapper.getThemeForAgeGroup', () {
    test('kids theme has name "Kids"', () {
      final t = ThemeMapper.getThemeForAgeGroup('kids');
      expect(t.themeName, 'Kids');
    });

    test('kids theme primaryColor is pinkAccent', () {
      final t = ThemeMapper.getThemeForAgeGroup('kids');
      expect(t.primaryColor, Colors.pinkAccent);
    });

    test('kids theme brightness is light', () {
      final t = ThemeMapper.getThemeForAgeGroup('kids');
      expect(t.brightness, Brightness.light);
    });

    test('kids theme has non-null colorScheme', () {
      final t = ThemeMapper.getThemeForAgeGroup('kids');
      expect(t.colorScheme, isNotNull);
    });

    test('teens theme has name "Teens"', () {
      final t = ThemeMapper.getThemeForAgeGroup('teens');
      expect(t.themeName, 'Teens');
    });

    test('teens theme primaryColor is blueAccent', () {
      final t = ThemeMapper.getThemeForAgeGroup('teens');
      expect(t.primaryColor, Colors.blueAccent);
    });

    test('teens theme has non-null colorScheme', () {
      final t = ThemeMapper.getThemeForAgeGroup('teens');
      expect(t.colorScheme, isNotNull);
    });

    test('adults theme has name "Adults"', () {
      final t = ThemeMapper.getThemeForAgeGroup('adults');
      expect(t.themeName, 'Adults');
    });

    test('adults theme primaryColor is green', () {
      final t = ThemeMapper.getThemeForAgeGroup('adults');
      expect(t.primaryColor, Colors.green);
    });

    test('adults theme has non-null colorScheme', () {
      final t = ThemeMapper.getThemeForAgeGroup('adults');
      expect(t.colorScheme, isNotNull);
    });

    test('unknown age group returns "Defaults" theme', () {
      final t = ThemeMapper.getThemeForAgeGroup('unknown');
      expect(t.themeName, 'Defaults');
    });

    test('default theme primaryColor is grey', () {
      final t = ThemeMapper.getThemeForAgeGroup('unknown');
      expect(t.primaryColor, Colors.grey);
    });

    test('default theme has non-null colorScheme', () {
      final t = ThemeMapper.getThemeForAgeGroup('unknown');
      expect(t.colorScheme, isNotNull);
    });

    test('lookup is case-insensitive: "KIDS" → Kids theme', () {
      final t = ThemeMapper.getThemeForAgeGroup('KIDS');
      expect(t.themeName, 'Kids');
    });

    test('lookup is case-insensitive: "Teens" → Teens theme', () {
      final t = ThemeMapper.getThemeForAgeGroup('Teens');
      expect(t.themeName, 'Teens');
    });

    test('lookup is case-insensitive: "ADULTS" → Adults theme', () {
      final t = ThemeMapper.getThemeForAgeGroup('ADULTS');
      expect(t.themeName, 'Adults');
    });

    test('each age group returns a distinct theme name', () {
      final names = ['kids', 'teens', 'adults', 'unknown']
          .map((g) => ThemeMapper.getThemeForAgeGroup(g).themeName)
          .toSet();
      expect(names.length, 4);
    });
  });

  // -------------------------------------------------------------------------
  // ThemeSettings.copyWith
  // -------------------------------------------------------------------------

  group('ThemeSettings.copyWith', () {
    const base = ThemeSettings(
      themeName: 'Base',
      primaryColor: Colors.red,
      secondaryColor: Colors.blue,
      brightness: Brightness.light,
    );

    test('copyWith updates themeName', () {
      final updated = base.copyWith(themeName: 'New');
      expect(updated.themeName, 'New');
    });

    test('copyWith preserves unchanged themeName', () {
      final updated = base.copyWith(primaryColor: Colors.green);
      expect(updated.themeName, 'Base');
    });

    test('copyWith updates primaryColor', () {
      final updated = base.copyWith(primaryColor: Colors.green);
      expect(updated.primaryColor, Colors.green);
    });

    test('copyWith preserves unchanged primaryColor', () {
      final updated = base.copyWith(themeName: 'X');
      expect(updated.primaryColor, Colors.red);
    });

    test('copyWith updates secondaryColor', () {
      final updated = base.copyWith(secondaryColor: Colors.orange);
      expect(updated.secondaryColor, Colors.orange);
    });

    test('copyWith updates brightness', () {
      final updated = base.copyWith(brightness: Brightness.dark);
      expect(updated.brightness, Brightness.dark);
    });

    test('copyWith updates colorScheme', () {
      final scheme = ColorScheme.fromSeed(seedColor: Colors.purple);
      final updated = base.copyWith(colorScheme: scheme);
      expect(updated.colorScheme, scheme);
    });

    test('copyWith updates scaffoldBackgroundColor', () {
      final updated = base.copyWith(scaffoldBackgroundColor: Colors.grey);
      expect(updated.scaffoldBackgroundColor, Colors.grey);
    });

    test('copyWith preserves scaffoldBackgroundColor when not provided', () {
      const withBg = ThemeSettings(
        themeName: 'T',
        primaryColor: Colors.red,
        secondaryColor: Colors.blue,
        brightness: Brightness.light,
        scaffoldBackgroundColor: Colors.white,
      );
      final updated = withBg.copyWith(themeName: 'New');
      expect(updated.scaffoldBackgroundColor, Colors.white);
    });

    test('copyWith updates textTheme', () {
      const t = TextTheme(bodyMedium: TextStyle(fontSize: 20));
      final updated = base.copyWith(textTheme: t);
      expect(updated.textTheme, t);
    });

    test('copyWith with no args preserves all fields', () {
      final updated = base.copyWith();
      expect(updated.themeName, base.themeName);
      expect(updated.primaryColor, base.primaryColor);
      expect(updated.secondaryColor, base.secondaryColor);
      expect(updated.brightness, base.brightness);
    });
  });

  // -------------------------------------------------------------------------
  // ThemeUtils.getAccentColor
  // -------------------------------------------------------------------------

  group('ThemeUtils.getAccentColor', () {
    test('kids → pinkAccent', () {
      expect(ThemeUtils.getAccentColor('kids'), Colors.pinkAccent);
    });

    test('teens → blueAccent', () {
      expect(ThemeUtils.getAccentColor('teens'), Colors.blueAccent);
    });

    test('adults → green', () {
      expect(ThemeUtils.getAccentColor('adults'), Colors.green);
    });

    test('unknown → blueAccent (default)', () {
      expect(ThemeUtils.getAccentColor('seniors'), Colors.blueAccent);
    });

    test('empty string → blueAccent (default)', () {
      expect(ThemeUtils.getAccentColor(''), Colors.blueAccent);
    });

    test('KIDS (uppercase) → pinkAccent (case-insensitive)', () {
      expect(ThemeUtils.getAccentColor('KIDS'), Colors.pinkAccent);
    });

    test('TEENS (uppercase) → blueAccent (case-insensitive)', () {
      expect(ThemeUtils.getAccentColor('TEENS'), Colors.blueAccent);
    });

    test('ADULTS (uppercase) → green (case-insensitive)', () {
      expect(ThemeUtils.getAccentColor('ADULTS'), Colors.green);
    });

    test('kids and teens return distinct colors', () {
      expect(ThemeUtils.getAccentColor('kids'),
          isNot(equals(ThemeUtils.getAccentColor('teens'))));
    });

    test('kids and adults return distinct colors', () {
      expect(ThemeUtils.getAccentColor('kids'),
          isNot(equals(ThemeUtils.getAccentColor('adults'))));
    });
  });
}
