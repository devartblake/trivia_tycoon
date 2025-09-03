import 'package:flutter/material.dart';

class ColorPickerTheme {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Color indicatorColor;
  final Color sliderTrackColor;
  final Color presetButtonColor;
  final double presetButtonSize;

  const ColorPickerTheme({
    this.backgroundColor = Colors.white,
    this.borderColor = Colors.black,
    this.borderWidth = 2.0,
    this.indicatorColor = Colors.black,
    this.sliderTrackColor = Colors.grey,
    this.presetButtonColor = Colors.blueAccent,
    this.presetButtonSize = 40.0,
  });

  /// **🔄 Copy with updated values**
  ColorPickerTheme copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    Color? indicatorColor,
    Color? sliderTrackColor,
    Color? presetButtonColor,
    double? presetButtonSize,
  }) {
    return ColorPickerTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      sliderTrackColor: sliderTrackColor ?? this.sliderTrackColor,
      presetButtonColor: presetButtonColor ?? this.presetButtonColor,
      presetButtonSize: presetButtonSize ?? this.presetButtonSize,
    );
  }

  /// **🔄 Convert theme to a map for JSON storage**
  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor.value,
      'borderColor': borderColor.value,
      'borderWidth': borderWidth,
      'indicatorColor': indicatorColor.value,
      'sliderTrackColor': sliderTrackColor.value,
      'presetButtonColor': presetButtonColor.value,
      'presetButtonSize': presetButtonSize,
    };
  }

  /// **📥 Create theme from stored map**
  factory ColorPickerTheme.fromMap(Map<String, dynamic> map) {
    return ColorPickerTheme(
      backgroundColor: Color(map['backgroundColor']),
      borderColor: Color(map['borderColor']),
      borderWidth: map['borderWidth'] ?? 2.0,
      indicatorColor: Color(map['indicatorColor']),
      sliderTrackColor: Color(map['sliderTrackColor']),
      presetButtonColor: Color(map['presetButtonColor']),
      presetButtonSize: map['presetButtonSize'] ?? 40.0,
    );
  }

  /// **🎨 Default light and dark themes**
  static final ColorPickerTheme light = ColorPickerTheme(
    backgroundColor: Colors.white,
    borderColor: Colors.grey,
    indicatorColor: Colors.black,
    sliderTrackColor: Colors.grey[300]!,
    presetButtonColor: Colors.blueAccent,
  );

  static final ColorPickerTheme dark = ColorPickerTheme(
    backgroundColor: Colors.black,
    borderColor: Colors.white,
    indicatorColor: Colors.white,
    sliderTrackColor: Colors.grey[700]!,
    presetButtonColor: Colors.tealAccent,
  );
}
