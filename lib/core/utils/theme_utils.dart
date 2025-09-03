import 'package:flutter/material.dart';

class ThemeUtils {
  static Color getAccentColor(String ageGroup) {
    switch (ageGroup.toLowerCase()) {
      case 'kids':
        return Colors.pinkAccent;
      case 'teens':
        return Colors.blueAccent;
      case 'adults':
        return Colors.green;
      default:
        return Colors.blueAccent;
    }
  }
}
