import 'package:flutter/material.dart';

class TycoonToastThemeManager {
  /// Gets the gradient for a given theme event string
  static LinearGradient getGradientForEvent(String themeEvent) {
    switch (themeEvent.toLowerCase()) {
      case 'spring':
        return const LinearGradient(colors: [Colors.pinkAccent, Colors.lightGreenAccent]);
      case 'halloween':
        return const LinearGradient(colors: [Colors.deepPurple, Colors.deepOrange]);
      case 'holiday':
        return const LinearGradient(colors: [Colors.red, Colors.green]);
      case 'summer':
        return const LinearGradient(colors: [Colors.yellow, Colors.orangeAccent]);
      case 'neon':
        return const LinearGradient(colors: [Color(0xFF00F0FF), Color(0xFF8E2DE2)]);
      default:
        return LinearGradient(colors: [Colors.grey[900]!, Colors.grey[800]!]);
    }
  }
}
