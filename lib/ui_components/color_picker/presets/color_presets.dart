import 'package:flutter/material.dart';

class ColorPresets {
  /// Default set of colors for quick selection
  static final List<Color> defaultColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.yellow,
    Colors.purple,
    Colors.orange,
    Colors.pink,
    Colors.teal,
    Colors.cyan,
    Colors.brown,
    Colors.lime,
    Colors.indigo,
    Colors.grey,
  ];

  /// Extended color palettes (can be used for custom themes)
  static final Map<String, List<Color>> extendedPalettes = {
    "Warm": [Colors.red, Colors.orange, Colors.yellow],
    "Cool": [Colors.blue, Colors.teal, Colors.cyan],
    "Pastel": [Colors.pink, Colors.lightBlueAccent],
    "Neon": [Colors.greenAccent, Colors.cyanAccent, Colors.purpleAccent],
  };
}
