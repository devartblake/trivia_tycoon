import 'package:flutter/material.dart';

class MultiplayerPalette {
  static const Color background = Color(0xFFF6FAFD);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFEFF6FB);
  static const Color primary = Color(0xFF2F6F8F);
  static const Color primaryDeep = Color(0xFF234F68);
  static const Color secondary = Color(0xFF63B3A5);
  static const Color accent = Color(0xFFE28A74);
  static const Color success = Color(0xFF3C9E74);
  static const Color warning = Color(0xFFD79A3E);
  static const Color danger = Color(0xFFD96C63);
  static const Color textPrimary = Color(0xFF173042);
  static const Color textSecondary = Color(0xFF5A7282);

  static const LinearGradient headerGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF3B7A9C), Color(0xFF63B3A5), Color(0xFFE7A17F)],
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF3B7A9C), Color(0xFF63B3A5)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [Color(0xFFE28A74), Color(0xFFD96C63)],
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF4EAD80), Color(0xFF3C9E74)],
  );
}
