import 'package:flutter/material.dart';

class DepthCardTheme {
  final String name;
  final Color shadowColor;
  final Color textColor;
  final double elevation;
  final Color overlayColor;
  final bool glowEnabled;
  final double titleFontSize;
  final Color titleColor;

  const DepthCardTheme({
    this.name = "light",
    this.shadowColor = Colors.black38,
    this.textColor = Colors.white,
    this.elevation = 16,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.15),
    this.glowEnabled = false,
    this.titleFontSize = 16,
    this.titleColor = Colors.white,
  });

  DepthCardTheme copyWith({
    Color? shadowColor,
    Color? textColor,
    double? elevation,
    Color? overlayColor,
    bool? glowEnabled,
    double? titleFontSize,
    Color? titleColor,
  }) {
    return DepthCardTheme(
      shadowColor: shadowColor ?? this.shadowColor,
      textColor: textColor ?? this.textColor,
      elevation: elevation ?? this.elevation,
      overlayColor: overlayColor ?? this.overlayColor,
      glowEnabled: glowEnabled ?? this.glowEnabled,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      titleColor: titleColor ?? this.titleColor,
    );
  }

  static const List<DepthCardTheme> presets = [
    DepthCardTheme(
      name: "Futuristic",
      shadowColor: Colors.blueAccent,
      textColor: Colors.cyanAccent,
      titleColor: Colors.cyanAccent,
      titleFontSize: 28.0,
    ),
    DepthCardTheme(
      name: "Neon",
      shadowColor: Colors.blueAccent,
      glowEnabled: true,
      titleColor: Color(0xFF00FFFF),
      titleFontSize: 26.0,
    ),
    DepthCardTheme(
      name: "Dark Mode",
      shadowColor: Colors.black87,
      textColor: Colors.white,
      titleColor: Colors.white,
      titleFontSize: 24.0,
    ),
    DepthCardTheme(
      name: "Golden",
      shadowColor: Colors.amber,
      textColor: Colors.black,
      titleColor: Color(0xFFFFD700),
      titleFontSize: 26.0,
    ),
  ];

  static DepthCardTheme fromName(String name) =>
      presets.firstWhere((e) => e.name == name, orElse: () => presets[0]);
}
