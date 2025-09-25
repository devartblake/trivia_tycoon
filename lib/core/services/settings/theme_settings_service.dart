import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/game/controllers/theme_settings_controller.dart';

/// ThemeSettingsService handles the storage and retrieval of
/// primary theme attributes like brightness and color scheme.
class ThemeSettingsService {
  static const _boxName = 'settings';
  static const _presetsBoxName = 'theme_presets';
  static const _currentThemeKey = 'current_theme_snapshot';
  static const _lastModifiedKey = 'theme_last_modified';

  Color _cachedPrimaryColor = const Color(0xFF2196F3);
  Color _cachedSecondaryColor = const Color(0xFF03DAC6);
  Brightness _cachedBrightness = Brightness.light;
  String _cachedThemeName = 'Default';
  DateTime? _lastCacheUpdate;
  static const Duration _cacheTimeout = Duration(minutes: 10);

  Color get primaryColor => _cachedPrimaryColor;
  Color get secondaryColor => _cachedSecondaryColor;
  Brightness get brightness => _cachedBrightness;
  String get themeName => _cachedThemeName;

  /// Initializes cached values for theme settings.
  Future<void> init() async {
    final box = await Hive.openBox(_boxName);

    final brightnessName = box.get('brightness', defaultValue: 'light');
    _cachedBrightness = brightnessName == 'dark' ? Brightness.dark : Brightness.light;

    final colorValue = box.get('primary_color');
    _cachedPrimaryColor = colorValue is int ? Color(colorValue) : const Color(0xFF2196F3);

    final secondaryColorValue = box.get('secondary_color');
    _cachedSecondaryColor = secondaryColorValue is int ? Color(secondaryColorValue) : const Color(0xFF03DAC6);

    _cachedThemeName = box.get('theme_name', defaultValue: 'Default');
    _lastCacheUpdate = DateTime.now();
  }

  /// Sets the app brightness (light/dark).
  Future<void> setBrightness(Brightness brightness) async {
    final box = await Hive.openBox(_boxName);
    await box.put('brightness', brightness.name);
    await _updateLastModified();
    _cachedBrightness = brightness;
  }

  /// Retrieves the app brightness setting, defaulting to light.
  Future<Brightness> getBrightness() async {
    if (_isCacheValid()) return _cachedBrightness;

    final box = await Hive.openBox(_boxName);
    final name = box.get('brightness', defaultValue: 'light');
    _cachedBrightness = name == 'dark' ? Brightness.dark : Brightness.light;
    return _cachedBrightness;
  }

  /// Sets the theme name.
  Future<void> setThemeName(String name) async {
    final box = await Hive.openBox(_boxName);
    await box.put('theme_name', name);
    await _updateLastModified();
    _cachedThemeName = name;
  }

  /// Retrieves the theme name.
  Future<String> getThemeName() async {
    if (_isCacheValid()) return _cachedThemeName;

    final box = await Hive.openBox(_boxName);
    _cachedThemeName = box.get('theme_name', defaultValue: 'Default');
    return _cachedThemeName;
  }

  /// Saves the primary color.
  Future<void> setPrimaryColor(Color color) async {
    final box = await Hive.openBox(_boxName);
    await box.put('primary_color', color.value);
    await _updateLastModified();
    _cachedPrimaryColor = color;
  }

  /// Retrieves the primary color.
  Future<Color> getPrimaryColor() async {
    if (_isCacheValid()) return _cachedPrimaryColor;

    final box = await Hive.openBox(_boxName);
    final value = box.get('primary_color');
    _cachedPrimaryColor = value is int ? Color(value) : const Color(0xFF2196F3);
    return _cachedPrimaryColor;
  }

  /// Saves the secondary color.
  Future<void> setSecondaryColor(Color color) async {
    final box = await Hive.openBox(_boxName);
    await box.put('secondary_color', color.value);
    await _updateLastModified();
    _cachedSecondaryColor = color;
  }

  /// Retrieves the secondary color.
  Future<Color> getSecondaryColor() async {
    if (_isCacheValid()) return _cachedSecondaryColor;

    final box = await Hive.openBox(_boxName);
    final value = box.get('secondary_color');
    _cachedSecondaryColor = value is int ? Color(value) : const Color(0xFF03DAC6);
    return _cachedSecondaryColor;
  }

  /// Saves a named custom theme preset.
  Future<void> saveThemePreset(ThemeSettings preset) async {
    final box = await Hive.openBox(_presetsBoxName);
    await box.put(preset.themeName, {
      'name': preset.themeName,
      'primaryColor': preset.primaryColor.value,
      'secondaryColor': preset.secondaryColor.value,
      'brightness': preset.brightness == Brightness.dark ? 'dark' : 'light',
      'created': DateTime.now().toIso8601String(),
    });
  }

  /// Loads all saved custom theme presets.
  Future<List<ThemeSettings>> getAllThemePresets() async {
    final box = await Hive.openBox(_presetsBoxName);
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
    final box = await Hive.openBox(_presetsBoxName);
    await box.delete(name);
  }

  /// Applies a theme preset by loading its settings
  Future<void> applyThemePreset(String presetName) async {
    final presets = await getAllThemePresets();
    final preset = presets.firstWhere(
          (p) => p.themeName == presetName,
      orElse: () => ThemeSettings(
        themeName: 'Default',
        primaryColor: const Color(0xFF2196F3),
        secondaryColor: const Color(0xFF03DAC6),
        brightness: Brightness.light,
      ),
    );

    await setPrimaryColor(preset.primaryColor);
    await setSecondaryColor(preset.secondaryColor);
    await setBrightness(preset.brightness);
    await setThemeName(preset.themeName);
  }

  /// Creates a current theme settings object
  Future<ThemeSettings> getCurrentTheme() async {
    return ThemeSettings(
      themeName: await getThemeName(),
      primaryColor: await getPrimaryColor(),
      secondaryColor: await getSecondaryColor(),
      brightness: await getBrightness(),
    );
  }

  /// LIFECYCLE METHOD: Saves current theme configuration
  /// Called when app goes to background or is about to be terminated
  Future<void> saveCurrentTheme() async {
    try {
      final box = await Hive.openBox(_boxName);

      // Create a snapshot of current theme state
      final currentTheme = {
        'themeName': _cachedThemeName,
        'primaryColor': _cachedPrimaryColor.value,
        'secondaryColor': _cachedSecondaryColor.value,
        'brightness': _cachedBrightness.name,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await box.put(_currentThemeKey, currentTheme);
      await box.flush(); // Ensure data is written to disk

      // Also flush presets box
      final presetsBox = await Hive.openBox(_presetsBoxName);
      await presetsBox.flush();

      if (kDebugMode) {
        print('✅ Current theme saved successfully: ${_cachedThemeName}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to save current theme: $e');
      }
      rethrow;
    }
  }

  /// LIFECYCLE METHOD: Validates and restores theme integrity
  /// Called when app resumes or starts
  Future<void> validateThemeIntegrity() async {
    try {
      final box = await Hive.openBox(_boxName);

      // Check for corrupted or missing theme data
      final primaryColor = box.get('primary_color');
      final secondaryColor = box.get('secondary_color');
      final brightness = box.get('brightness');
      final themeName = box.get('theme_name');

      bool needsRepair = false;

      // Validate primary color
      if (primaryColor == null || primaryColor is! int) {
        await box.put('primary_color', const Color(0xFF2196F3).value);
        _cachedPrimaryColor = const Color(0xFF2196F3);
        needsRepair = true;
      }

      // Validate secondary color
      if (secondaryColor == null || secondaryColor is! int) {
        await box.put('secondary_color', const Color(0xFF03DAC6).value);
        _cachedSecondaryColor = const Color(0xFF03DAC6);
        needsRepair = true;
      }

      // Validate brightness
      if (brightness == null || (brightness != 'light' && brightness != 'dark')) {
        await box.put('brightness', 'light');
        _cachedBrightness = Brightness.light;
        needsRepair = true;
      }

      // Validate theme name
      if (themeName == null || themeName is! String || themeName.isEmpty) {
        await box.put('theme_name', 'Default');
        _cachedThemeName = 'Default';
        needsRepair = true;
      }

      if (needsRepair) {
        await _updateLastModified();
        if (kDebugMode) {
          print('🔧 Theme data integrity restored');
        }
      }

      // Validate presets integrity
      await _validatePresetsIntegrity();

      _lastCacheUpdate = DateTime.now();
      if (kDebugMode) {
        print('✅ Theme integrity validation completed');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Theme integrity validation failed: $e');
      }
      // Fallback to defaults
      await _resetToDefaults();
    }
  }

  /// Reset theme to default values
  Future<void> _resetToDefaults() async {
    try {
      final box = await Hive.openBox(_boxName);
      await box.put('primary_color', const Color(0xFF2196F3).value);
      await box.put('secondary_color', const Color(0xFF03DAC6).value);
      await box.put('brightness', 'light');
      await box.put('theme_name', 'Default');

      _cachedPrimaryColor = const Color(0xFF2196F3);
      _cachedSecondaryColor = const Color(0xFF03DAC6);
      _cachedBrightness = Brightness.light;
      _cachedThemeName = 'Default';

      await _updateLastModified();
      if (kDebugMode) {
        print('🔄 Theme reset to defaults');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to reset theme to defaults: $e');
      }
    }
  }

  /// Validate theme presets integrity
  Future<void> _validatePresetsIntegrity() async {
    try {
      final box = await Hive.openBox(_presetsBoxName);
      final keys = box.keys.toList();
      bool needsCleanup = false;

      for (final key in keys) {
        final preset = box.get(key);
        if (preset == null || preset is! Map) {
          await box.delete(key);
          needsCleanup = true;
          continue;
        }

        // Validate required fields
        if (!preset.containsKey('name') ||
            !preset.containsKey('primaryColor') ||
            !preset.containsKey('secondaryColor') ||
            !preset.containsKey('brightness')) {
          await box.delete(key);
          needsCleanup = true;
        }
      }

      if (needsCleanup) {
        debugPrint('🔧 Theme presets cleaned up');
      }
    } catch (e) {
      debugPrint('❌ Failed to validate presets integrity: $e');
    }
  }

  /// Updates the last modified timestamp
  Future<void> _updateLastModified() async {
    final box = await Hive.openBox(_boxName);
    await box.put(_lastModifiedKey, DateTime.now().toIso8601String());
  }

  /// Gets the last modified timestamp
  Future<DateTime?> getLastModified() async {
    final box = await Hive.openBox(_boxName);
    final raw = box.get(_lastModifiedKey);
    return raw != null ? DateTime.parse(raw) : null;
  }

  /// Cache management helpers
  bool _isCacheValid() {
    return _lastCacheUpdate != null &&
        DateTime.now().difference(_lastCacheUpdate!) < _cacheTimeout;
  }

  void _invalidateCache() {
    _lastCacheUpdate = null;
  }

  /// Export current theme as JSON
  Future<Map<String, dynamic>> exportTheme() async {
    final current = await getCurrentTheme();
    return {
      'name': current.themeName,
      'primaryColor': current.primaryColor.value,
      'secondaryColor': current.secondaryColor.value,
      'brightness': current.brightness.name,
      'exported': DateTime.now().toIso8601String(),
    };
  }

  /// Import theme from JSON
  Future<void> importTheme(Map<String, dynamic> themeData) async {
    try {
      final name = themeData['name'] as String? ?? 'Imported';
      final primaryColor = Color(themeData['primaryColor'] as int? ?? 0xFF2196F3);
      final secondaryColor = Color(themeData['secondaryColor'] as int? ?? 0xFF03DAC6);
      final brightness = themeData['brightness'] == 'dark' ? Brightness.dark : Brightness.light;

      await setPrimaryColor(primaryColor);
      await setSecondaryColor(secondaryColor);
      await setBrightness(brightness);
      await setThemeName(name);

      if (kDebugMode) {
        print('✅ Theme imported successfully: $name');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Failed to import theme: $e');
      }
      rethrow;
    }
  }

  /// Get theme statistics
  Future<Map<String, dynamic>> getThemeStats() async {
    final presets = await getAllThemePresets();
    final lastModified = await getLastModified();

    return {
      'currentTheme': _cachedThemeName,
      'totalPresets': presets.length,
      'lastModified': lastModified?.toIso8601String(),
      'cacheValid': _isCacheValid(),
      'brightness': _cachedBrightness.name,
    };
  }
}
