import 'package:flutter/material.dart';

class DepthCardTheme {
  final String name;
  final Color shadowColor;
  final Color textColor;
  final double elevation;
  final Color overlayColor;
  final bool glowEnabled;

  const DepthCardTheme({
    this.name = "light",
    this.shadowColor = Colors.black38,
    this.textColor = Colors.white,
    this.elevation = 16,
    this.overlayColor = const Color.fromRGBO(0, 0, 0, 0.15),
    this.glowEnabled = false,
  });

  DepthCardTheme copyWith({
    Color? shadowColor,
    Color? textColor,
    double? elevation,
    Color? overlayColor,
    bool? glowEnabled,
  }) {
    return DepthCardTheme(
      shadowColor: shadowColor ?? this.shadowColor,
      textColor: textColor ?? this.textColor,
      elevation: elevation ?? this.elevation,
      overlayColor: overlayColor ?? this.overlayColor,
      glowEnabled: glowEnabled ?? this.glowEnabled,
    );
  }

  static const List<DepthCardTheme> presets = [
    DepthCardTheme(name: "Futuristic", shadowColor: Colors.blueAccent, textColor: Colors.cyanAccent),
    DepthCardTheme(name: "Neon", shadowColor: Colors.blueAccent, glowEnabled: true),
    DepthCardTheme(name: "Dark Mode", shadowColor: Colors.black87, textColor: Colors.white),
    DepthCardTheme(name: "Golden", shadowColor: Colors.amber, textColor: Colors.black),
  ];

  static DepthCardTheme fromName(String name) =>
      presets.firstWhere((e) => e.name == name, orElse: () => presets[0]);
}
