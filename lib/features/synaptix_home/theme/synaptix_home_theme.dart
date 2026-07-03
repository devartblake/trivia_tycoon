import 'package:flutter/material.dart';

class SynaptixHomeTheme {
  static const page = Color(0xFF050816);
  static const panel = Color(0xFF101529);
  static const panelAlt = Color(0xFF151B33);
  static const stroke = Color(0xFF27314F);
  static const text = Color(0xFFF8FAFC);
  static const muted = Color(0xFF94A3B8);
  static const cyan = Color(0xFF22D3EE);
  static const blue = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const green = Color(0xFF22C55E);
  static const amber = Color(0xFFF59E0B);
  static const red = Color(0xFFEF4444);
  static const orange = Color(0xFFF97316);
  static const gold = Color(0xFFFBBF24);

  static const pageGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF15104A),
      Color(0xFF050816),
      Color(0xFF02040D),
    ],
  );

  static const heroGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      Color(0xFF1E0B4A),
      Color(0xFF071C44),
      Color(0xFF030713),
    ],
  );

  static const buttonGradient = LinearGradient(
    colors: [purple, blue],
  );

  static LinearGradient modeGradient(Color color) {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        color.withValues(alpha: 0.30),
        panelAlt.withValues(alpha: 0.92),
      ],
    );
  }
}
