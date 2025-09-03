import 'package:flutter/material.dart';
import 'depth_card_theme.dart';

class DepthCardThemes {
  static const dark = DepthCardTheme(
    shadowColor: Colors.black87,
    textColor: Colors.white,
    elevation: 16,
    overlayColor: Color.fromRGBO(0, 0, 0, 0.2),
    glowEnabled: false,
  );

  static const DepthCardTheme light = DepthCardTheme(
    shadowColor: Colors.black26,
    textColor: Colors.black,
    elevation: 10,
    overlayColor: Color.fromRGBO(255, 255, 255, 0.12),
    glowEnabled: false,
  );

  static const DepthCardTheme futuristic = DepthCardTheme(
    shadowColor: Colors.blueAccent,
    textColor: Colors.cyanAccent,
    elevation: 20,
    overlayColor: Color.fromRGBO(0, 255, 255, 0.2),
    glowEnabled: true,
  );

  static const DepthCardTheme neon = DepthCardTheme(
    shadowColor: Colors.pinkAccent,
    textColor: Colors.white,
    elevation: 24,
    overlayColor: Color.fromRGBO(255, 20, 147, 0.3),
    glowEnabled: true,
  );

  static const DepthCardTheme fantasy = DepthCardTheme(
    shadowColor: Colors.purpleAccent,
    textColor: Colors.amber,
    elevation: 18,
    overlayColor: Color.fromRGBO(138, 43, 226, 0.25),
    glowEnabled: true,
  );

  static const DepthCardTheme minimalist = DepthCardTheme(
    shadowColor: Colors.black26,
    textColor: Colors.black87,
    elevation: 12,
    overlayColor: Color.fromRGBO(255, 255, 255, 0.1),
    glowEnabled: false,
  );

  static const DepthCardTheme oceanic = DepthCardTheme(
    shadowColor: Colors.teal,
    textColor: Colors.lightBlueAccent,
    elevation: 20,
    overlayColor: Color.fromRGBO(0, 128, 128, 0.2),
    glowEnabled: true,
  );

  static const DepthCardTheme blueSteel = DepthCardTheme(
    shadowColor: Colors.blueGrey,
    textColor: Colors.lightBlueAccent,
    elevation: 18,
    overlayColor: Color.fromRGBO(0, 50, 100, 0.2),
    glowEnabled: true,
  );

  static List<DepthCardTheme> get all => [
    light,
    dark,
    futuristic,
    neon,
    fantasy,
    minimalist,
    oceanic,
    blueSteel
  ];
}
