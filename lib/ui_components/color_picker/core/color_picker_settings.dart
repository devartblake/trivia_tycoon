import 'package:flutter/material.dart';
import '../utils/color_storage.dart';

@immutable
class ColorPickerSettings {
  final Color selectedColor;
  final bool useCustomPalette;
  final List<Color> customPalette;
  final String pickerMode; // "wheel", "grid", "sliders"
  final List<Color> colors;

  // Cache for expensive operations
  final int _hashCode;

  const ColorPickerSettings._({
    required this.selectedColor,
    required this.useCustomPalette,
    required this.customPalette,
    required this.pickerMode,
    required this.colors,
    required int hashCode,
  }) : _hashCode = hashCode;

  factory ColorPickerSettings({
    Color selectedColor = Colors.blue,
    bool useCustomPalette = false,
    List<Color> customPalette = const [],
    String pickerMode = "wheel",
    List<Color> colors = const [Colors.red, Colors.blue, Colors.green, Colors.yellow],
  }) {
    // Ensure immutability
    final immutableCustomPalette = List<Color>.unmodifiable(customPalette);
    final immutableColors = List<Color>.unmodifiable(colors);

    // Pre-calculate hash code for performance
    final hashCode = Object.hash(
      selectedColor,
      useCustomPalette,
      Object.hashAll(immutableCustomPalette),
      pickerMode,
      Object.hashAll(immutableColors),
    );

    return ColorPickerSettings._(
      selectedColor: selectedColor,
      useCustomPalette: useCustomPalette,
      customPalette: immutableCustomPalette,
      pickerMode: pickerMode,
      colors: immutableColors,
      hashCode: hashCode,
    );
  }

  /// Copy settings with modifications - optimized to avoid unnecessary allocations
  ColorPickerSettings copyWith({
    Color? selectedColor,
    bool? useCustomPalette,
    List<Color>? customPalette,
    String? pickerMode,
    List<Color>? colors,
  }) {
    // Return same instance if no changes
    if (selectedColor == null &&
        useCustomPalette == null &&
        customPalette == null &&
        pickerMode == null &&
        colors == null) {
      return this;
    }

    // Check if values are actually different
    final newSelectedColor = selectedColor ?? this.selectedColor;
    final newUseCustomPalette = useCustomPalette ?? this.useCustomPalette;
    final newCustomPalette = customPalette ?? this.customPalette;
    final newPickerMode = pickerMode ?? this.pickerMode;
    final newColors = colors ?? this.colors;

    // Return same instance if values haven't changed
    if (newSelectedColor == this.selectedColor &&
        newUseCustomPalette == this.useCustomPalette &&
        _listsEqual(newCustomPalette, this.customPalette) &&
        newPickerMode == this.pickerMode &&
        _listsEqual(newColors, this.colors)) {
      return this;
    }

    return ColorPickerSettings(
      selectedColor: newSelectedColor,
      useCustomPalette: newUseCustomPalette,
      customPalette: newCustomPalette,
      pickerMode: newPickerMode,
      colors: newColors,
    );
  }

  /// Efficient list comparison
  static bool _listsEqual<T>(List<T> a, List<T> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Convert to a Map for local storage - optimized
  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'selectedColor': selectedColor.value,
      'useCustomPalette': useCustomPalette,
      'customPalette': customPalette.map((c) => c.value).toList(growable: false),
      'pickerMode': pickerMode,
      'colors': colors.map((c) => c.value).toList(growable: false),
    };
  }

  /// Create settings from a saved map - with validation
  factory ColorPickerSettings.fromMap(Map<String, dynamic> map) {
    try {
      final selectedColorValue = map['selectedColor'];
      final selectedColor = selectedColorValue is int
          ? Color(selectedColorValue)
          : Colors.blue;

      final useCustomPalette = map['useCustomPalette'] is bool
          ? map['useCustomPalette'] as bool
          : false;

      final customPaletteData = map['customPalette'];
      List<Color> customPalette = const [];
      if (customPaletteData is List) {
        customPalette = customPaletteData
            .whereType<int>()
            .map((c) => Color(c))
            .toList(growable: false);
      }

      final pickerMode = map['pickerMode'] is String
          ? map['pickerMode'] as String
          : "wheel";

      final colorsData = map['colors'];
      List<Color> colors = const [Colors.red, Colors.blue, Colors.green, Colors.yellow];
      if (colorsData is List) {
        final parsedColors = colorsData
            .whereType<int>()
            .map((c) => Color(c))
            .toList();
        if (parsedColors.isNotEmpty) {
          colors = List<Color>.unmodifiable(parsedColors);
        }
      }

      return ColorPickerSettings(
        selectedColor: selectedColor,
        useCustomPalette: useCustomPalette,
        customPalette: customPalette,
        pickerMode: pickerMode,
        colors: colors,
      );
    } catch (e) {
      debugPrint('Error parsing ColorPickerSettings from map: $e');
      return ColorPickerSettings(); // Return default settings
    }
  }

  /// Save settings with error handling
  Future<bool> save() async {
    try {
      await ColorStorage.savePickerSettings(this);
      return true;
    } catch (e) {
      debugPrint('Error saving ColorPickerSettings: $e');
      return false;
    }
  }

  /// Load settings with fallback to defaults
  static Future<ColorPickerSettings> load() async {
    try {
      final settings = await ColorStorage.getPickerSettings();
      return settings ?? ColorPickerSettings();
    } catch (e) {
      debugPrint('Error loading ColorPickerSettings: $e');
      return ColorPickerSettings();
    }
  }

  /// Validate settings integrity
  bool isValid() {
    try {
      // Check if picker mode is valid
      const validModes = ["wheel", "grid", "sliders"];
      if (!validModes.contains(pickerMode)) {
        return false;
      }

      // Check if colors are valid (not null/transparent unless intended)
      if (colors.isEmpty) {
        return false;
      }

      // All checks passed
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get a validated copy of settings
  ColorPickerSettings validated() {
    if (isValid()) return this;

    return ColorPickerSettings(
      selectedColor: selectedColor,
      useCustomPalette: useCustomPalette,
      customPalette: customPalette,
      pickerMode: ["wheel", "grid", "sliders"].contains(pickerMode)
          ? pickerMode
          : "wheel",
      colors: colors.isNotEmpty
          ? colors
          : const [Colors.red, Colors.blue, Colors.green, Colors.yellow],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ColorPickerSettings) return false;
    return _hashCode == other._hashCode;
  }

  @override
  int get hashCode => _hashCode;

  @override
  String toString() {
    return 'ColorPickerSettings('
        'selectedColor: $selectedColor, '
        'useCustomPalette: $useCustomPalette, '
        'customPalette: ${customPalette.length} colors, '
        'pickerMode: $pickerMode, '
        'colors: ${colors.length} colors)';
  }
}
