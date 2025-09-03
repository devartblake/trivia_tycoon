import 'package:flutter/material.dart';
import '../utils/color_storage.dart';

class ColorPickerSettings {
  Color selectedColor;
  bool useCustomPalette;
  List<Color> customPalette;
  String pickerMode; // "wheel", "grid", "sliders"
  List<Color> colors;

  ColorPickerSettings({
    this.selectedColor = Colors.blue,
    this.useCustomPalette = false,
    this.customPalette = const [],
    this.pickerMode = "wheel",
    this.colors = const [Colors.red, Colors.blue, Colors.green, Colors.yellow],
  });

  /// **🔄 Copy settings with modifications**
  ColorPickerSettings copyWith({
    Color? selectedColor,
    bool? useCustomPalette,
    List<Color>? customPalette,
    String? pickerMode,
    List<Color>? colors,
  }) {
    return ColorPickerSettings(
      selectedColor: selectedColor ?? this.selectedColor,
      useCustomPalette: useCustomPalette ?? this.useCustomPalette,
      customPalette: customPalette ?? List.from(this.customPalette),
      pickerMode: pickerMode ?? this.pickerMode,
      colors: colors ?? List.from(this.colors),
    );
  }

  /// Convert to a Map for local storage
  Map<String, dynamic> toMap() {
    return {
      'selectedColor': selectedColor.value,
      'useCustomPalette': useCustomPalette,
      'customPalette': customPalette.map((c) => c.value).toList(),
      'pickerMode': pickerMode,
    };
  }

  /// Create settings from a saved map
  factory ColorPickerSettings.fromMap(Map<String, dynamic> map) {
    return ColorPickerSettings(
      selectedColor: Color(map['selectedColor']),
      useCustomPalette: map['useCustomPalette'] ?? false,
      customPalette: (map['customPalette'] as List).map((c) => Color(c)).toList(),
      pickerMode: map['pickerMode'] ?? "wheel",
    );
  }

  /// Save settings
  Future<void> save() async {
    await ColorStorage.savePickerSettings(this);
  }

  /// Load settings
  static Future<ColorPickerSettings> load() async {
    return await ColorStorage.getPickerSettings() ?? ColorPickerSettings();
  }
}
