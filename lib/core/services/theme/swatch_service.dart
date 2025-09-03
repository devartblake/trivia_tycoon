import 'package:flutter/material.dart';
import '../settings/app_settings.dart';

class SwatchService {
  static const _key = 'custom_swatch_colors';

  /// Save custom swatches as a list of hex strings
  static Future<void> saveSwatches(List<Color> colors) async {
    final hexList = colors.map((c) => c.value.toRadixString(16)).toList();
    await AppSettings.setStringList(_key, hexList);
  }

  /// Load saved swatches or return an empty list
  static Future<List<Color>> loadSwatches() async {
    final hexList = await AppSettings.getStringList(_key);
    if (hexList == null || hexList.isEmpty) return [];
    return hexList.map((hex) => Color(int.parse(hex, radix: 16))).toList();
  }

  /// Reset to default swatches (clears saved list)
  static Future<void> resetSwatches() async {
    await AppSettings.remove(_key);
  }

  /// Check if any swatches are saved
  static Future<bool> hasCustomSwatches() async {
    final list = await AppSettings.getStringList(_key);
    return list != null && list.isNotEmpty;
  }


  static Future<void> setCustomSwatches(List<Color> colors) async {
    final hexList = colors.map((c) => c.value.toRadixString(16)).toList();
    await AppSettings.setStringList(_key, hexList);
  }

  static Future<List<Color>> getCustomSwatches() async {
    final hexList = await AppSettings.getStringList(_key);
    if (hexList == null || hexList.isEmpty) return [];
    return hexList.map((hex) => Color(int.parse(hex, radix: 16))).toList();
  }

  static Future<void> resetSwatchesToDefault() async {
    await AppSettings.remove(_key);
  }
}
