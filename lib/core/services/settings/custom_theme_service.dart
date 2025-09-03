import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/game/controllers/theme_settings_controller.dart';

/// Handles custom theme presets and persistent theme settings (e.g., selected theme, colors, age group).
class CustomThemeService {
  static const String _presetBoxName = 'custom_themes';
  static const String _settingsBoxName = 'theme_settings';

  static const String _themeNameKey = 'theme_name';
  static const String _primaryColorKey = 'primary_color';
  static const String _secondaryColorKey = 'secondary_color';
  static const String _darkModeKey = 'dark_mode';
  static const String _ageGroupKey = 'user_age_group';
  static const String _presetsKey = 'custom_presets';

  late final Box _settingsBox;

  CustomThemeService._(this._settingsBox);

  /// Initializes the theme settings box (used for saving color, brightness, etc.)
  static Future<CustomThemeService> initialize() async {
    final settingsBox = await Hive.openBox(_settingsBoxName);
    return CustomThemeService._(settingsBox);
  }

  // ---------------------- General Theme Settings ----------------------

  Future<void> setThemeSettings({
    required String name,
    required Color primary,
    required Color secondary,
    required bool isDark,
  }) async {
    await _settingsBox.put(_themeNameKey, name);
    await _settingsBox.put(_primaryColorKey, primary.value);
    await _settingsBox.put(_secondaryColorKey, secondary.value);
    await _settingsBox.put(_darkModeKey, isDark);
  }

  Future<String?> getThemeName() async => _settingsBox.get(_themeNameKey);

  Future<Color?> getPrimaryColor() async {
    final val = _settingsBox.get(_primaryColorKey);
    return val is int ? Color(val) : null;
  }

  Future<Color?> getSecondaryColor() async {
    final val = _settingsBox.get(_secondaryColorKey);
    return val is int ? Color(val) : null;
  }

  Future<bool?> getDarkMode() async => _settingsBox.get(_darkModeKey);

  // ---------------------- Age Group Theme Logic ----------------------

  Future<void> setAgeGroup(String group) async =>
      await _settingsBox.put(_ageGroupKey, group);

  Future<String?> getAgeGroup() async => _settingsBox.get(_ageGroupKey);

  // ---------------------- Custom Preset Management ----------------------

  /// Save or update a custom theme preset
  Future<void> saveCustomTheme(ThemeSettings theme) async {
    final box = await Hive.openBox(_presetBoxName);
    final encoded = {
      'name': theme.themeName,
      'primary': theme.primaryColor.value,
      'secondary': theme.secondaryColor.value,
      'brightness': theme.brightness == Brightness.dark ? 'dark' : 'light',
    };
    await box.put(theme.themeName, encoded);
  }

  /// Delete a saved custom theme by name
  Future<void> deleteCustomTheme(String themeName) async {
    final box = await Hive.openBox(_presetBoxName);
    await box.delete(themeName);
  }

  /// Retrieve a specific custom theme by name
  Future<ThemeSettings?> getCustomTheme(String themeName) async {
    final box = await Hive.openBox(_presetBoxName);
    final raw = box.get(themeName);
    if (raw is Map<String, dynamic>) {
      return ThemeSettings(
        themeName: raw['name'] ?? themeName,
        primaryColor: Color(raw['primary']),
        secondaryColor: Color(raw['secondary']),
        brightness:
        (raw['brightness'] ?? 'light') == 'dark' ? Brightness.dark : Brightness.light,
      );
    }
    return null;
  }

  /// Retrieve all saved custom theme presets
  Future<List<ThemeSettings>> getAllCustomThemes() async {
    final box = await Hive.openBox(_presetBoxName);
    return box.values.map((entry) {
      final map = Map<String, dynamic>.from(entry);
      return ThemeSettings(
        themeName: map['name'],
        primaryColor: Color(map['primary']),
        secondaryColor: Color(map['secondary']),
        brightness: map['brightness'] == 'dark' ? Brightness.dark : Brightness.light,
      );
    }).toList();
  }
}
