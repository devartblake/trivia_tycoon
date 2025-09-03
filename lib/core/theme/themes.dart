import 'package:flutter/material.dart';
import '../../core/utils/color_utils.dart';

enum ThemeType { main, allStar, competition }

class AppTheme {
  static ThemeType defaultTheme = ThemeType.main;

  final ThemeType type; // New property to store the theme type
  final ThemeMode themeMode;
  final bool isDark;
  final Color bg1;
  final Color bg2;
  final Color surface;
  final Color accent1;
  final Color accent1Dark;
  final Color accent1Darker;
  final Color accent2;
  final Color grey;
  final Color greyStrong;
  final Color greyWeak;
  final Color error;
  final Color focus;
  final Color txt;
  final Color accentTxt;
  final String backgroundImage;
  final String fontFamily;

  /// Default constructor
  AppTheme({
    required this.type,
    required this.themeMode,
    required this.isDark,
    required this.bg1,
    required this.bg2,
    required this.surface,
    required this.accent1,
    required this.accent1Dark,
    required this.accent1Darker,
    required this.accent2,
    required this.grey,
    required this.greyStrong,
    required this.greyWeak,
    required this.error,
    required this.focus,
    required this.txt,
    required this.accentTxt,
    required this.backgroundImage,
    required this.fontFamily,
  });

  // Converts a string into a ThemeType enum, safe fallback to defaultTheme
  static ThemeType fromString(String? themeName) {
    return ThemeType.values.firstWhere(
          (e) => e.name == themeName,
      orElse: () {
        debugPrint("Invalid theme type found ($themeName), using default.");
        return defaultTheme;
      },
    );
  }

  /// Factory constructor to create AppTheme using only ThemeType.
  factory AppTheme.fromType(ThemeType type, ThemeMode themeMode) {
    bool isDark = themeMode == ThemeMode.dark;
    switch (type) {
      case ThemeType.allStar:
        return AppTheme(
          type: type, // Added theme type
          themeMode: themeMode,
          isDark: isDark,
          bg1: Color(0xFFF83535),
          bg2: Colors.green[100]!,
          surface: Colors.yellow[50]!,
          accent1: Colors.green[700]!,
          accent1Dark: Colors.green[800]!,
          accent1Darker: Colors.green[900]!,
          accent2: Colors.yellow[700]!,
          grey: Colors.grey[600]!,
          greyStrong: Colors.grey[900]!,
          greyWeak: Colors.grey[300]!,
          error: Colors.red,
          focus: Colors.green[500]!,
          txt: Colors.black,
          accentTxt: Colors.white,
          backgroundImage: 'assets/images/backgrounds/geometry_background.jpeg',
          fontFamily: 'OpenSans',
        );

      case ThemeType.competition:
        return AppTheme(
          type: type, // Added theme type
          themeMode: themeMode,
          isDark: isDark,
          bg1: Colors.blueGrey,
          bg2: Colors.red[50]!,
          surface: Colors.white,
          accent1: Colors.red[800]!,
          accent1Dark: Colors.red[900]!,
          accent1Darker: Colors.red[900]!,
          accent2: Colors.white,
          grey: Colors.grey[600]!,
          greyStrong: Colors.grey[800]!,
          greyWeak: Colors.grey[300]!,
          error: Colors.red,
          focus: Colors.red[500]!,
          txt: Colors.black,
          accentTxt: Colors.white,
          backgroundImage: 'assets/images/backgrounds/versus_background.jpg',
          fontFamily: 'Faustina',
        );

      case ThemeType.main:
        return AppTheme(
          type: type, // Added theme type
          themeMode: themeMode,
          isDark: isDark,
          bg1: Colors.purple[900]!,
          bg2: Color(0xFFF5F5F5),
          surface: Colors.grey,
          accent1: Color(0xFF1E90FF), // Blue
          accent1Dark: Color(0xFF1C86EE),
          accent1Darker: Color(0xFF1874CD),
          accent2: Color(0xFF40E0D0), // Turquoise
          grey: Colors.grey[600]!,
          greyStrong: Colors.grey[800]!,
          greyWeak: Colors.grey[300]!,
          error: Colors.red.shade900,
          focus: Color(0xFFFFD700), // Yellow
          txt: Colors.black,
          accentTxt: Colors.grey[400]!,
          backgroundImage: 'assets/images/backgrounds/question_background.jpg',
          fontFamily: 'Faustina',
        );
    }
  }

  /// Generates ThemeData for the app
  ThemeData get themeData => ThemeData.from(
      textTheme: (isDark ? ThemeData.dark() : ThemeData.light()).textTheme,
      colorScheme: ColorScheme(
        brightness: isDark ? Brightness.dark : Brightness.light,
        primary: accent1,
        primaryContainer: accent1Darker,
        secondary: accent2,
        secondaryContainer: accent1Dark,
        surface: surface,
        onSurface: txt,
        onError: txt,
        onPrimary: accentTxt,
        onSecondary: accentTxt,
        error: error,
      ),
    ).copyWith(
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: greyWeak),
        ),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      textSelectionTheme: TextSelectionThemeData(
        selectionColor: accent1.withOpacity(0.5),
        cursorColor: accent1,
        selectionHandleColor: accent1,
      ),
      highlightColor: accent1,
    );

  Color shift(Color c, double d) => ColorUtils.shiftHsl(c, d * (isDark? -1 : 1));
}
