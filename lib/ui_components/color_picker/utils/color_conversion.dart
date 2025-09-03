import 'package:flutter/material.dart';

class ColorConversion {
  /// **🎨 Convert Color to HEX String**
  static String colorToHex(Color color, {bool leadingHashSign = true}) {
    final hex = '${color.alpha.toRadixString(16).padLeft(2, '0')}'
        '${color.red.toRadixString(16).padLeft(2, '0')}'
        '${color.green.toRadixString(16).padLeft(2, '0')}'
        '${color.blue.toRadixString(16).padLeft(2, '0')}';
    return leadingHashSign ? '#$hex' : hex;
  }

  /// **🎨 Convert HEX String to Color**
  static Color hexToColor(String hex) {
    hex = hex.replaceAll('#', '');
    if (hex.length == 6) hex = 'FF$hex'; // Add Alpha if missing
    return Color(int.parse(hex, radix: 16));
  }

  /// **🎨 Convert RGB to HSV**
  static HSVColor rgbToHsv(Color color) {
    return HSVColor.fromColor(color);
  }

  /// **🎨 Convert HSV to RGB**
  static Color hsvToRgb(HSVColor hsv) {
    return hsv.toColor();
  }

  /// **🎨 Convert RGB to HSL**
  static HSLColor rgbToHsl(Color color) {
    return HSLColor.fromColor(color);
  }

  /// **🎨 Convert HSL to RGB**
  static Color hslToRgb(HSLColor hsl) {
    return hsl.toColor();
  }

  /// **🎨 Convert Color to Integer Value**
  static int colorToInt(Color color) {
    return color.value;
  }

  /// **🎨 Convert Integer to Color**
  static Color intToColor(int value) {
    return Color(value);
  }
}
