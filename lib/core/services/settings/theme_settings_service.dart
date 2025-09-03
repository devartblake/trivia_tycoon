import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/game/controllers/theme_settings_controller.dart';

/// ThemeSettingsService handles the storage and retrieval of
/// primary theme attributes like brightness and color scheme.
class ThemeSettingsService {
  static const _boxName = 'settings';

  Color _cachedPrimaryColor = const Color(0xFF2196F3);
  Brightness _cachedBrightness = Brightness.light;

  Color get primaryColor => _cachedPrimaryColor;
  Brightness get brightness => _cachedBrightness;

  /// Initializes cached values for theme settings.
  Future<void> init() async {
    final box = await Hive.openBox(_boxName);

    final brightnessName = box.get('brightness', defaultValue: 'light');
    _cachedBrightness = brightnessName == 'dark' ? Brightness.dark : Brightness.light;

    final colorValue = box.get('primary_color');
    _cachedPrimaryColor = colorValue is int ? Color(colorValue) : const Color(0xFF2196F3);
  }

  /// Sets the app brightness (light/dark).
  Future<void> setBrightness(Brightness brightness) async {
    final box = await Hive.openBox(_boxName);
    await box.put('brightness', brightness.name);
  }

  /// Retrieves the app brightness setting, defaulting to light.
  Future<Brightness> getBrightness() async {
    final box = await Hive.openBox(_boxName);
    final name = box.get('brightness', defaultValue: 'light');
    return name == 'dark' ? Brightness.dark : Brightness.light;
  }

  /// Sets the theme name.
  Future<void> setThemeName(String name) async {
    final box = await Hive.openBox(_boxName);
    await box.put('theme_name', name);
  }

  /// Retrieves the theme name.
  Future<String> getThemeName() async {
    final box = await Hive.openBox(_boxName);
    return box.get('theme_name', defaultValue: 'Default');
  }

  /// Saves the primary color.
  Future<void> setPrimaryColor(Color color) async {
    final box = await Hive.openBox(_boxName);
    await box.put('primary_color', color.value);
  }

  /// Retrieves the primary color.
  Future<Color> getPrimaryColor() async {
    final box = await Hive.openBox(_boxName);
    final value = box.get('primary_color');
    return value is int ? Color(value) : const Color(0xFF2196F3);
  }

  /// Saves a named custom theme preset.
  Future<void> saveThemePreset(ThemeSettings preset) async {
    final box = await Hive.openBox('theme_presets');
    await box.put(preset.themeName, {
      'name': preset.themeName,
      'primaryColor': preset.primaryColor.value,
      'secondaryColor': preset.secondaryColor.value,
      'brightness': preset.brightness == Brightness.dark ? 'dark' : 'light',
    });
  }

  /// Loads all saved custom theme presets.
  Future<List<ThemeSettings>> getAllThemePresets() async {
    final box = await Hive.openBox('theme_presets');
    return box.values.map((e) {
      return ThemeSettings(
        themeName: e['name'],
        primaryColor: Color(e['primaryColor']),
        secondaryColor: Color(e['secondaryColor']),
        brightness: e['brightness'] == 'dark' ? Brightness.dark : Brightness.light,
      );
    }).toList();
  }

  /// Deletes a custom theme preset by name.
  Future<void> deleteThemePreset(String name) async {
    final box = await Hive.openBox('theme_presets');
    await box.delete(name);
  }
}
