import 'package:flutter/material.dart';

class FlowAppColors {
  static const Color primaryColor = Color(0xFF6A5ACD); // Richer shade of purple
  static const Color accentColor = Color(0xFF48D1CC); // Turquoise
  static const Color backgroundColor = Color(0xFF212121); // Dark grey/black
  static const Color gridCellColor = Color(0xFF303030); // Lighter dark grey
  static const Color gridBorderColor = Color(0xFF424242); // Grey
  static const Color textColor = Color(0xFFE0E0E0); // Light grey
  static const Color highlightColor = Color(0xFFFFA726); // Warmer orange
  static const Color successColor = Color(0xFF66BB6A); // Soft green
  static const Color errorColor = Color(0xFFEF5350); // Soft red
}

class FlowAppTextStyles {
  static const TextStyle title = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: FlowAppColors.textColor,
  );

  static const TextStyle subtitle = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 18,
    fontWeight: FontWeight.w500,
    color: FlowAppColors.textColor,
  );

  static const TextStyle body = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 16,
    color: FlowAppColors.textColor,
  );

  static const TextStyle number = TextStyle(
    fontFamily: 'Roboto',
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}