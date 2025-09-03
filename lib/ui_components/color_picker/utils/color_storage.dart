import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/color_picker_settings.dart';
import '../core/color_picker_theme.dart';
import '../models/color_palette.dart';

class ColorStorage {
  static const String _settingsBox = 'color_picker_settings';
  static const String _themeBox = "color_picker_theme";

  /// **🎨 Save selected color**
  static Future<void> saveColor(Color color) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('selectedColor', color.value);
  }

  /// **🎨 Retrieve last selected color**
  static Future<Color?> getSavedColor() async {
    final box = await Hive.openBox(_settingsBox);
    int? colorValue = box.get('selectedColor');
    return colorValue != null ? Color(colorValue) : null;
  }

  /// **🎨 Save custom color palette**
  static Future<void> saveCustomPalette(List<Color> palette) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('customPalette', palette.map((c) => c.value).toList());
  }

  /// **🎨 Retrieve custom color palette**
  static Future<List<Color>?> getCustomPalette() async {
    final box = await Hive.openBox(_settingsBox);
    List<int>? colorValues = box.get('customPalette');
    return colorValues?.map((c) => Color(c)).toList() ?? [];
  }

  /// **🎨 Load all saved colors from storage**
  static Future<List<Color>> loadSavedColors() async {
    final box = await Hive.openBox(_settingsBox);

    // Get saved palette colors
    List<int>? paletteValues = box.get('customPalette');

    // Get last selected color if exists
    int? selectedColorValue = box.get('selectedColor');
    Color? selectedColor = selectedColorValue != null ? Color(selectedColorValue) : null;

    // Convert palette values to `Color` list
    List<Color> savedColors = paletteValues?.map((c) => Color(c)).toList() ?? [];

    // Ensure selected color is included
    if (selectedColor != null && !savedColors.contains(selectedColor)) {
      savedColors.insert(0, selectedColor);
    }

    // Default palette if empty
    if (savedColors.isEmpty) {
      savedColors = _getDefaultColors();
    }

    return savedColors;
  }

  /// **🎨 Default fallback colors**
  static List<Color> _getDefaultColors() {
    return [
      Colors.red, Colors.blue, Colors.green, Colors.orange,
      Colors.purple, Colors.yellow, Colors.pink, Colors.teal,
    ];
  }

  /// **💾 Save user-selected picker mode** (Wheel, Grid, Sliders)
  static Future<void> savePickerMode(String mode) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('pickerMode', mode);
  }

  /// **🔍 Retrieve picker mode**
  static Future<String> getPickerMode() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('pickerMode', defaultValue: 'wheel');
  }

  /// **💾 Save full picker settings**
  static Future<void> savePickerSettings(ColorPickerSettings settings) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('pickerSettings', settings.toMap());
  }

  /// **🔍 Retrieve full picker settings**
  static Future<ColorPickerSettings?> getPickerSettings() async {
    final box = await Hive.openBox(_settingsBox);
    Map<String, dynamic>? settingsMap = box.get('pickerSettings');
    return settingsMap != null ? ColorPickerSettings.fromMap(settingsMap) : null;
  }

  /// **Save theme settings**
  static Future<void> savePickerTheme(ColorPickerTheme theme) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('pickerTheme', theme.toMap());
  }

  /// **Retrieve theme settings**
  static Future<Map<String, dynamic>?> getPickerTheme() async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('pickerTheme');
  }

  /// **🔄 Get all saved theme names**
  static Future<List<String>> getAvailableThemeNames() async {
    final box = await Hive.openBox(_settingsBox);

    /// Ensure keys are treated as Strings and filter those that start with "theme_"
    return box.keys
        .whereType<String>() // Ensures only String keys are processed
        .where((key) => key.startsWith('theme_'))
        .map((key) => key.substring(6)) // Remove 'theme_' prefix
        .toList(); // Convert iterable to List<String>
  }


  /// **🎨 Save a theme by name**
  static Future<void> saveTheme(String themeName, ColorPickerTheme theme) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('theme_$themeName', theme.toMap());
  }

  /// **📥 Retrieve a theme by name**
  static Future<Map<String, dynamic>?> getThemeByName(String themeName) async {
    final box = await Hive.openBox(_settingsBox);
    return box.get('theme_$themeName');
  }

  /// **💾 Save a color palette**
  static Future<void> savePalette(ColorPalette palette) async {
    final box = await Hive.openBox(_settingsBox);
    await box.put('palette_${palette.name}', palette.toMap());
  }

  /// **📥 Retrieve a saved palette by name**
  static Future<ColorPalette?> getPalette(String name) async {
    final box = await Hive.openBox(_settingsBox);
    Map<String, dynamic>? paletteMap = box.get('palette_$name');
    return paletteMap != null ? ColorPalette.fromMap(paletteMap) : null;
  }

  /// **📌 Get all saved palette names**
  static Future<List<String>> getAllPaletteNames() async {
    final box = await Hive.openBox(_settingsBox);
    return box.keys
        .whereType<String>()
        .where((key) => key.startsWith('palette_'))
        .map((key) => key.substring(8)) // Remove "palette_" prefix
        .toList();
  }

  /// **🗑️ Delete a palette**
  static Future<void> deletePalette(String name) async {
    final box = await Hive.openBox(_settingsBox);
    await box.delete('palette_$name');
  }

  /// **🔄 Save a custom palette theme**
  static Future<void> savePaletteTheme(ColorPickerTheme theme) async {
    final box = await Hive.openBox(_themeBox);
    await box.put('themeName', theme.toMap());
  }

  /// **📥 Load a saved theme**
  static Future<ColorPickerTheme?> getTheme(String name) async {
    final box = await Hive.openBox(_themeBox);
    Map<String, dynamic>? themeData = box.get(name);
    return themeData != null ? ColorPickerTheme.fromMap(themeData) : null;
  }

  /// **🗑 Delete a saved theme**
  static Future<void> deleteTheme(String name) async {
    final box = await Hive.openBox(_themeBox);
    await box.delete(name);
  }

  /// **📜 List all saved themes**
  static Future<List<String>> getAvailableThemes() async {
    final box = await Hive.openBox(_themeBox);
    return box.keys.cast<String>().toList();
  }
}
