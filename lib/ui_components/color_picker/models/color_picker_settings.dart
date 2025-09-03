import 'package:flutter/material.dart';

class ColorPickerSettings {
  final String pickerMode; // "wheel", "grid", or "sliders"
  final bool useCustomPalette;
  final List<Color> customPalette;

  ColorPickerSettings({
    this.pickerMode = "wheel",
    this.useCustomPalette = false,
    this.customPalette = const [Colors.red, Colors.blue, Colors.green, Colors.yellow],
  });

  /// **🔄 Copy settings with modifications**
  ColorPickerSettings copyWith({
    String? pickerMode,
    bool? useCustomPalette,
    List<Color>? customPalette,
  }) {
    return ColorPickerSettings(
      pickerMode: pickerMode ?? this.pickerMode,
      useCustomPalette: useCustomPalette ?? this.useCustomPalette,
      customPalette: customPalette ?? List.from(this.customPalette),
    );
  }

  /// **🔄 Convert settings to a map for Hive storage**
  Map<String, dynamic> toMap() {
    return {
      'pickerMode': pickerMode,
      'useCustomPalette': useCustomPalette,
      'customPalette': customPalette.map((c) => c.value).toList(),
    };
  }

  /// **📥 Create settings from a stored map**
  factory ColorPickerSettings.fromMap(Map<String, dynamic> map) {
    return ColorPickerSettings(
      pickerMode: map['pickerMode'] ?? "wheel",
      useCustomPalette: map['useCustomPalette'] ?? false,
      customPalette: (map['customPalette'] as List).map((c) => Color(c)).toList(),
    );
  }
}
