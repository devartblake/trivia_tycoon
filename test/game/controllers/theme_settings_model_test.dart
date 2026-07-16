import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/controllers/theme_settings_controller.dart';

void main() {
  // -------------------------------------------------------------------------
  // ThemeSettings constructor
  // -------------------------------------------------------------------------

  group('ThemeSettings constructor', () {
    test('fields are accessible after construction', () {
      const settings = ThemeSettings(
        themeName: 'Custom',
        primaryColor: Colors.red,
        secondaryColor: Colors.green,
        brightness: Brightness.dark,
      );
      expect(settings.themeName, 'Custom');
      expect(settings.primaryColor, Colors.red);
      expect(settings.secondaryColor, Colors.green);
      expect(settings.brightness, Brightness.dark);
    });

    test('optional fields default to null', () {
      const settings = ThemeSettings(
        themeName: 'Test',
        primaryColor: Colors.blue,
        secondaryColor: Colors.teal,
        brightness: Brightness.light,
      );
      expect(settings.colorScheme, isNull);
      expect(settings.scaffoldBackgroundColor, isNull);
      expect(settings.textTheme, isNull);
    });

    test('optional fields can be set', () {
      final settings = ThemeSettings(
        themeName: 'Full',
        primaryColor: Colors.purple,
        secondaryColor: Colors.amber,
        brightness: Brightness.dark,
        colorScheme: const ColorScheme.dark(),
        scaffoldBackgroundColor: Colors.black,
        textTheme: const TextTheme(),
      );
      expect(settings.colorScheme, isNotNull);
      expect(settings.scaffoldBackgroundColor, Colors.black);
      expect(settings.textTheme, isNotNull);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  group('copyWith', () {
    const original = ThemeSettings(
      themeName: 'Original',
      primaryColor: Colors.blue,
      secondaryColor: Colors.teal,
      brightness: Brightness.light,
    );

    test('partial copyWith updates only named fields', () {
      final updated = original.copyWith(themeName: 'Updated');
      expect(updated.themeName, 'Updated');
      expect(updated.primaryColor, Colors.blue); // unchanged
      expect(updated.secondaryColor, Colors.teal); // unchanged
      expect(updated.brightness, Brightness.light); // unchanged
    });

    test('copyWith primaryColor', () {
      final updated = original.copyWith(primaryColor: Colors.red);
      expect(updated.primaryColor, Colors.red);
      expect(updated.themeName, 'Original'); // unchanged
    });

    test('copyWith secondaryColor', () {
      final updated = original.copyWith(secondaryColor: Colors.orange);
      expect(updated.secondaryColor, Colors.orange);
    });

    test('copyWith brightness', () {
      final updated = original.copyWith(brightness: Brightness.dark);
      expect(updated.brightness, Brightness.dark);
    });

    test('copyWith colorScheme', () {
      final updated = original.copyWith(colorScheme: const ColorScheme.dark());
      expect(updated.colorScheme, isNotNull);
    });

    test('copyWith without args returns equivalent object', () {
      final copy = original.copyWith();
      expect(copy.themeName, original.themeName);
      expect(copy.primaryColor, original.primaryColor);
      expect(copy.brightness, original.brightness);
    });

    test('multiple successive copyWith calls accumulate changes', () {
      final result = original
          .copyWith(themeName: 'Step1')
          .copyWith(primaryColor: Colors.pink)
          .copyWith(brightness: Brightness.dark);
      expect(result.themeName, 'Step1');
      expect(result.primaryColor, Colors.pink);
      expect(result.brightness, Brightness.dark);
      expect(result.secondaryColor, Colors.teal); // from original
    });
  });

  // -------------------------------------------------------------------------
  // static presets
  // -------------------------------------------------------------------------

  group('ThemeSettings.presets', () {
    test('contains exactly 5 presets', () {
      expect(ThemeSettings.presets, hasLength(5));
    });

    test('preset names are all distinct', () {
      final names = ThemeSettings.presets.map((p) => p.themeName).toList();
      expect(names.toSet().length, names.length);
    });

    test('contains Default preset', () {
      final names = ThemeSettings.presets.map((p) => p.themeName);
      expect(names, contains('Default'));
    });

    test('contains Dark preset', () {
      final names = ThemeSettings.presets.map((p) => p.themeName);
      expect(names, contains('Dark'));
    });

    test('contains Sunset preset', () {
      final names = ThemeSettings.presets.map((p) => p.themeName);
      expect(names, contains('Sunset'));
    });

    test('contains Ocean preset', () {
      final names = ThemeSettings.presets.map((p) => p.themeName);
      expect(names, contains('Ocean'));
    });

    test('contains Neon preset', () {
      final names = ThemeSettings.presets.map((p) => p.themeName);
      expect(names, contains('Neon'));
    });

    test('all presets have valid brightness', () {
      for (final preset in ThemeSettings.presets) {
        expect(
          [Brightness.light, Brightness.dark],
          contains(preset.brightness),
          reason: '${preset.themeName} has unexpected brightness',
        );
      }
    });

    test('Default preset has Brightness.light', () {
      final preset =
          ThemeSettings.presets.firstWhere((p) => p.themeName == 'Default');
      expect(preset.brightness, Brightness.light);
    });

    test('Dark preset has Brightness.dark', () {
      final preset =
          ThemeSettings.presets.firstWhere((p) => p.themeName == 'Dark');
      expect(preset.brightness, Brightness.dark);
    });

    test('Neon preset has Brightness.dark', () {
      final preset =
          ThemeSettings.presets.firstWhere((p) => p.themeName == 'Neon');
      expect(preset.brightness, Brightness.dark);
    });

    test('Default preset primaryColor is Colors.blue', () {
      final preset =
          ThemeSettings.presets.firstWhere((p) => p.themeName == 'Default');
      expect(preset.primaryColor, Colors.blue);
    });

    test('Sunset preset primaryColor is Colors.deepOrange', () {
      final preset =
          ThemeSettings.presets.firstWhere((p) => p.themeName == 'Sunset');
      expect(preset.primaryColor, Colors.deepOrange);
    });
  });
}
