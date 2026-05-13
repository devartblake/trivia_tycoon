import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/services/settings/theme_settings_service.dart';
import 'package:trivia_tycoon/game/controllers/theme_settings_controller.dart';

void main() {
  late Directory tempDir;
  late ThemeSettingsService svc;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('theme_settings_test_');
    Hive.init(tempDir.path);
    svc = ThemeSettingsService();
    await svc.init();
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // defaults after init
  // -------------------------------------------------------------------------

  group('defaults after init', () {
    test('brightness is light', () async {
      expect(await svc.getBrightness(), Brightness.light);
    });

    test('theme name is Default', () async {
      expect(await svc.getThemeName(), 'Default');
    });

    test('primary color is 0xFF2196F3', () async {
      expect((await svc.getPrimaryColor()).value, 0xFF2196F3);
    });

    test('secondary color is 0xFF03DAC6', () async {
      expect((await svc.getSecondaryColor()).value, 0xFF03DAC6);
    });

    test('cached primaryColor getter matches default', () {
      expect(svc.primaryColor.value, 0xFF2196F3);
    });

    test('cached secondaryColor getter matches default', () {
      expect(svc.secondaryColor.value, 0xFF03DAC6);
    });

    test('cached brightness getter is light', () {
      expect(svc.brightness, Brightness.light);
    });

    test('cached themeName getter is Default', () {
      expect(svc.themeName, 'Default');
    });
  });

  // -------------------------------------------------------------------------
  // setBrightness / getBrightness
  // -------------------------------------------------------------------------

  group('setBrightness / getBrightness', () {
    test('set dark → get dark', () async {
      await svc.setBrightness(Brightness.dark);
      expect(await svc.getBrightness(), Brightness.dark);
    });

    test('set light → get light', () async {
      await svc.setBrightness(Brightness.dark);
      await svc.setBrightness(Brightness.light);
      expect(await svc.getBrightness(), Brightness.light);
    });

    test('cached brightness updated after set', () async {
      await svc.setBrightness(Brightness.dark);
      expect(svc.brightness, Brightness.dark);
    });

    test('persisted across new service instance', () async {
      await svc.setBrightness(Brightness.dark);
      final svc2 = ThemeSettingsService();
      await svc2.init();
      expect(await svc2.getBrightness(), Brightness.dark);
    });
  });

  // -------------------------------------------------------------------------
  // setThemeName / getThemeName
  // -------------------------------------------------------------------------

  group('setThemeName / getThemeName', () {
    test('saves and retrieves custom name', () async {
      await svc.setThemeName('Ocean Blue');
      expect(await svc.getThemeName(), 'Ocean Blue');
    });

    test('cached themeName updated after set', () async {
      await svc.setThemeName('Night Mode');
      expect(svc.themeName, 'Night Mode');
    });

    test('persisted across new service instance', () async {
      await svc.setThemeName('Sunset');
      final svc2 = ThemeSettingsService();
      await svc2.init();
      expect(await svc2.getThemeName(), 'Sunset');
    });
  });

  // -------------------------------------------------------------------------
  // setPrimaryColor / getPrimaryColor
  // -------------------------------------------------------------------------

  group('setPrimaryColor / getPrimaryColor', () {
    test('set color value and retrieve', () async {
      const color = Color(0xFFFF5722);
      await svc.setPrimaryColor(color);
      expect((await svc.getPrimaryColor()).value, 0xFFFF5722);
    });

    test('returned as Color type', () async {
      await svc.setPrimaryColor(const Color(0xFF9C27B0));
      expect(await svc.getPrimaryColor(), isA<Color>());
    });

    test('cached primaryColor updated after set', () async {
      await svc.setPrimaryColor(const Color(0xFF607D8B));
      expect(svc.primaryColor.value, 0xFF607D8B);
    });
  });

  // -------------------------------------------------------------------------
  // setSecondaryColor / getSecondaryColor
  // -------------------------------------------------------------------------

  group('setSecondaryColor / getSecondaryColor', () {
    test('set color value and retrieve', () async {
      const color = Color(0xFF4CAF50);
      await svc.setSecondaryColor(color);
      expect((await svc.getSecondaryColor()).value, 0xFF4CAF50);
    });

    test('returned as Color type', () async {
      await svc.setSecondaryColor(const Color(0xFFE91E63));
      expect(await svc.getSecondaryColor(), isA<Color>());
    });

    test('cached secondaryColor updated after set', () async {
      await svc.setSecondaryColor(const Color(0xFF009688));
      expect(svc.secondaryColor.value, 0xFF009688);
    });
  });

  // -------------------------------------------------------------------------
  // saveThemePreset / getAllThemePresets / deleteThemePreset
  // -------------------------------------------------------------------------

  group('saveThemePreset / getAllThemePresets / deleteThemePreset', () {
    final preset = ThemeSettings(
      themeName: 'MyPreset',
      primaryColor: const Color(0xFF3F51B5),
      secondaryColor: const Color(0xFFFF4081),
      brightness: Brightness.dark,
    );

    test('saveThemePreset → getAllThemePresets returns it', () async {
      await svc.saveThemePreset(preset);
      final presets = await svc.getAllThemePresets();
      expect(presets.any((p) => p.themeName == 'MyPreset'), isTrue);
    });

    test('getAllThemePresets empty before saving', () async {
      final presets = await svc.getAllThemePresets();
      expect(presets, isEmpty);
    });

    test('deleteThemePreset removes the preset', () async {
      await svc.saveThemePreset(preset);
      await svc.deleteThemePreset('MyPreset');
      final presets = await svc.getAllThemePresets();
      expect(presets.any((p) => p.themeName == 'MyPreset'), isFalse);
    });

    test('preset stored with correct primaryColor', () async {
      await svc.saveThemePreset(preset);
      final presets = await svc.getAllThemePresets();
      final saved = presets.firstWhere((p) => p.themeName == 'MyPreset');
      expect(saved.primaryColor.value, 0xFF3F51B5);
    });

    test('preset stored with correct brightness', () async {
      await svc.saveThemePreset(preset);
      final presets = await svc.getAllThemePresets();
      final saved = presets.firstWhere((p) => p.themeName == 'MyPreset');
      expect(saved.brightness, Brightness.dark);
    });
  });

  // -------------------------------------------------------------------------
  // applyThemePreset
  // -------------------------------------------------------------------------

  group('applyThemePreset', () {
    test('applies saved preset values', () async {
      final preset = ThemeSettings(
        themeName: 'NeonTheme',
        primaryColor: const Color(0xFFE040FB),
        secondaryColor: const Color(0xFF64FFDA),
        brightness: Brightness.dark,
      );
      await svc.saveThemePreset(preset);
      await svc.applyThemePreset('NeonTheme');
      expect(svc.primaryColor.value, 0xFFE040FB);
      expect(svc.secondaryColor.value, 0xFF64FFDA);
      expect(svc.brightness, Brightness.dark);
      expect(svc.themeName, 'NeonTheme');
    });

    test('unknown preset name → defaults applied', () async {
      await svc.setBrightness(Brightness.dark);
      await svc.applyThemePreset('NonExistentPreset');
      expect(await svc.getThemeName(), 'Default');
      expect((await svc.getPrimaryColor()).value, 0xFF2196F3);
      expect(await svc.getBrightness(), Brightness.light);
    });
  });

  // -------------------------------------------------------------------------
  // getCurrentTheme
  // -------------------------------------------------------------------------

  group('getCurrentTheme', () {
    test('returns ThemeSettings instance', () async {
      final theme = await svc.getCurrentTheme();
      expect(theme, isA<ThemeSettings>());
    });

    test('returns current theme name', () async {
      await svc.setThemeName('Cosmic');
      final theme = await svc.getCurrentTheme();
      expect(theme.themeName, 'Cosmic');
    });

    test('returns current primary color', () async {
      await svc.setPrimaryColor(const Color(0xFF1A237E));
      final theme = await svc.getCurrentTheme();
      expect(theme.primaryColor.value, 0xFF1A237E);
    });

    test('returns current brightness', () async {
      await svc.setBrightness(Brightness.dark);
      final theme = await svc.getCurrentTheme();
      expect(theme.brightness, Brightness.dark);
    });
  });

  // -------------------------------------------------------------------------
  // getLastModified
  // -------------------------------------------------------------------------

  group('getLastModified', () {
    test('null before any modification', () async {
      expect(await svc.getLastModified(), isNull);
    });

    test('non-null after setBrightness', () async {
      await svc.setBrightness(Brightness.dark);
      expect(await svc.getLastModified(), isNotNull);
    });

    test('non-null after setThemeName', () async {
      await svc.setThemeName('Changed');
      expect(await svc.getLastModified(), isNotNull);
    });

    test('returns a DateTime', () async {
      await svc.setPrimaryColor(const Color(0xFF000000));
      final modified = await svc.getLastModified();
      expect(modified, isA<DateTime>());
    });
  });

  // -------------------------------------------------------------------------
  // exportTheme
  // -------------------------------------------------------------------------

  group('exportTheme', () {
    test('contains name key', () async {
      final export = await svc.exportTheme();
      expect(export.containsKey('name'), isTrue);
    });

    test('contains primaryColor key', () async {
      final export = await svc.exportTheme();
      expect(export.containsKey('primaryColor'), isTrue);
    });

    test('contains secondaryColor key', () async {
      final export = await svc.exportTheme();
      expect(export.containsKey('secondaryColor'), isTrue);
    });

    test('contains brightness key', () async {
      final export = await svc.exportTheme();
      expect(export.containsKey('brightness'), isTrue);
    });

    test('contains exported key', () async {
      final export = await svc.exportTheme();
      expect(export.containsKey('exported'), isTrue);
    });

    test('name matches current theme name', () async {
      await svc.setThemeName('ExportTest');
      final export = await svc.exportTheme();
      expect(export['name'], 'ExportTest');
    });

    test('primaryColor is an int', () async {
      final export = await svc.exportTheme();
      expect(export['primaryColor'], isA<int>());
    });

    test('brightness is a string', () async {
      final export = await svc.exportTheme();
      expect(export['brightness'], isA<String>());
    });
  });

  // -------------------------------------------------------------------------
  // importTheme
  // -------------------------------------------------------------------------

  group('importTheme', () {
    test('sets theme name from import data', () async {
      await svc.importTheme({
        'name': 'ImportedTheme',
        'primaryColor': 0xFF880E4F,
        'secondaryColor': 0xFF1A237E,
        'brightness': 'dark',
      });
      expect(await svc.getThemeName(), 'ImportedTheme');
    });

    test('sets primary color from import data', () async {
      await svc.importTheme({
        'name': 'Test',
        'primaryColor': 0xFF880E4F,
        'secondaryColor': 0xFF1A237E,
        'brightness': 'light',
      });
      expect((await svc.getPrimaryColor()).value, 0xFF880E4F);
    });

    test('sets brightness from import data', () async {
      await svc.importTheme({
        'name': 'Test',
        'primaryColor': 0xFF2196F3,
        'secondaryColor': 0xFF03DAC6,
        'brightness': 'dark',
      });
      expect(await svc.getBrightness(), Brightness.dark);
    });

    test('missing name defaults to Imported', () async {
      await svc.importTheme({
        'primaryColor': 0xFF2196F3,
        'secondaryColor': 0xFF03DAC6,
        'brightness': 'light',
      });
      expect(await svc.getThemeName(), 'Imported');
    });
  });

  // -------------------------------------------------------------------------
  // validateThemeIntegrity
  // -------------------------------------------------------------------------

  group('validateThemeIntegrity', () {
    test('completes without error on valid data', () async {
      await expectLater(svc.validateThemeIntegrity(), completes);
    });

    test('repairs missing primary color to default', () async {
      final box = await Hive.openBox('settings');
      await box.delete('primary_color');
      await svc.validateThemeIntegrity();
      expect((await svc.getPrimaryColor()).value, 0xFF2196F3);
    });

    test('repairs missing brightness to light', () async {
      final box = await Hive.openBox('settings');
      await box.delete('brightness');
      await svc.validateThemeIntegrity();
      expect(await svc.getBrightness(), Brightness.light);
    });

    test('repairs missing theme name to Default', () async {
      final box = await Hive.openBox('settings');
      await box.delete('theme_name');
      await svc.validateThemeIntegrity();
      expect(await svc.getThemeName(), 'Default');
    });

    test('repairs invalid brightness value to light', () async {
      final box = await Hive.openBox('settings');
      await box.put('brightness', 'invalid_value');
      await svc.validateThemeIntegrity();
      expect(await svc.getBrightness(), Brightness.light);
    });
  });

  // -------------------------------------------------------------------------
  // getThemeStats
  // -------------------------------------------------------------------------

  group('getThemeStats', () {
    test('returns map with currentTheme key', () async {
      final stats = await svc.getThemeStats();
      expect(stats.containsKey('currentTheme'), isTrue);
    });

    test('returns map with totalPresets key', () async {
      final stats = await svc.getThemeStats();
      expect(stats.containsKey('totalPresets'), isTrue);
    });

    test('returns map with lastModified key', () async {
      final stats = await svc.getThemeStats();
      expect(stats.containsKey('lastModified'), isTrue);
    });

    test('returns map with cacheValid key', () async {
      final stats = await svc.getThemeStats();
      expect(stats.containsKey('cacheValid'), isTrue);
    });

    test('returns map with brightness key', () async {
      final stats = await svc.getThemeStats();
      expect(stats.containsKey('brightness'), isTrue);
    });

    test('currentTheme matches theme name', () async {
      await svc.setThemeName('StatsTest');
      final stats = await svc.getThemeStats();
      expect(stats['currentTheme'], 'StatsTest');
    });

    test('totalPresets is 0 initially', () async {
      final stats = await svc.getThemeStats();
      expect(stats['totalPresets'], 0);
    });

    test('totalPresets increments after saveThemePreset', () async {
      await svc.saveThemePreset(ThemeSettings(
        themeName: 'Preset1',
        primaryColor: const Color(0xFF2196F3),
        secondaryColor: const Color(0xFF03DAC6),
        brightness: Brightness.light,
      ));
      final stats = await svc.getThemeStats();
      expect(stats['totalPresets'], 1);
    });

    test('brightness value matches current brightness', () async {
      await svc.setBrightness(Brightness.dark);
      final stats = await svc.getThemeStats();
      expect(stats['brightness'], 'dark');
    });
  });

  // -------------------------------------------------------------------------
  // saveCurrentTheme
  // -------------------------------------------------------------------------

  group('saveCurrentTheme', () {
    test('completes without error', () async {
      await expectLater(svc.saveCurrentTheme(), completes);
    });
  });
}
