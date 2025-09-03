import 'dart:convert';
import 'package:flutter/material.dart';
import '../../../core/services/settings/general_key_value_storage_service.dart';
import '../models/confetti_settings.dart';

/// Handles saving, loading, and managing confetti themes using instance-based key-value storage.
class ConfettiSettingsStorage {
  final GeneralKeyValueStorageService storage;

  ConfettiSettingsStorage({required this.storage});

  static const String _themePrefix = 'confetti_theme_';
  static const String _themesListKey = 'confetti_theme_names';

  /// Save a named confetti theme to Hive.
  Future<void> saveTheme(String name, ConfettiSettings settings) async {
    final themeMap = settings.toMap();
    final jsonString = jsonEncode(themeMap);
    await storage.setString("$_themePrefix$name", jsonString);
    await _addThemeName(name);
  }

  /// Load a confetti theme by name.
  Future<ConfettiSettings?> loadTheme(String name) async {
    final jsonString = await storage.getString("$_themePrefix$name");
    if (jsonString != null) {
      final map = jsonDecode(jsonString);

      // Migrate the old structure if needed
      final version = map['version'] ?? 1;
      final migrated = _migrate(map, version);

      return ConfettiSettings.fromMap(migrated);
    }
    try {
      final map = jsonDecode(jsonString!);
      final version = map['version'] ?? 1;
      final migrated = _migrate(map, version);
      return ConfettiSettings.fromMap(migrated);
    } catch (e) {
      debugPrint("Failed to load theme '$name': $e");
      return null;
    }
  }

  /// Migrate older theme formats to the latest version.
  Map<String, dynamic> _migrate(Map<String, dynamic> map, int version) {
    if (version < 2) {
      map.putIfAbsent('useImages', () => true);
      map.putIfAbsent('gravity', () => 0.1);
      map.putIfAbsent('wind', () => 0.0);
      map['version'] = 2;
    }
    // Future versions can add more migrations here
    return map;
  }

  /// Load all saved themes
  Future<List<ConfettiSettings>> loadAllThemes() async {
    final names = await getSavedThemeNames();
    final List<ConfettiSettings> themes = [];

    for (final name in names) {
      final theme = await loadTheme(name);
      if (theme != null) themes.add(theme);
    }

    return themes;
  }

  /// Get a list of all saved theme names.
  Future<List<String>> getSavedThemeNames() async {
    return await storage.getStringList(_themesListKey) ?? [];
  }

  /// Delete a saved confetti theme.
  Future<void> deleteTheme(String name) async {
    await storage.remove("$_themePrefix$name");
    final names = await getSavedThemeNames();
    names.remove(name);
    await storage.setStringList(_themesListKey, names);
  }

  /// Clear all saved themes.
  Future<void> clearAllThemes() async {
    final names = await getSavedThemeNames();
    for (final name in names) {
      await storage.remove("$_themePrefix$name");
    }
    await storage.remove(_themesListKey);
  }

  /// Add name to stored theme list
  Future<void> _addThemeName(String name) async {
    final names = await storage.getStringList(_themesListKey) ?? [];
    if (!names.contains(name)) {
      names.add(name);
      await storage.setStringList(_themesListKey, names);
    }
  }

// Other utilities (deleteTheme, listThemes...) would go here
}
