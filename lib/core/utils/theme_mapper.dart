import 'package:flutter/material.dart';
import '../../game/controllers/theme_settings_controller.dart';

class ThemeMapper {
  static ThemeSettings getThemeForAgeGroup(String ageGroup) {
    switch (ageGroup.toLowerCase()) {
      case 'kids':
        return ThemeSettings(
          themeName: 'Kids',
          brightness: Brightness.light,
          primaryColor: Colors.pinkAccent,
          secondaryColor: Colors.pink,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.pinkAccent),
          scaffoldBackgroundColor: Colors.pink.shade50,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontFamily: 'ComicSans', fontSize: 16),
          ),
        );

      case 'teens':
        return ThemeSettings(
          themeName: 'Teens',
          brightness: Brightness.light,
          primaryColor: Colors.blueAccent,
          secondaryColor: Colors.blue,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
          scaffoldBackgroundColor: Colors.blue.shade50,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontFamily: 'Montserrat', fontSize: 16),
          ),
        );

      case 'adults':
        return ThemeSettings(
          themeName: 'Adults',
          brightness: Brightness.light,
          primaryColor: Colors.green,
          secondaryColor: Colors.greenAccent,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          scaffoldBackgroundColor: Colors.green.shade50,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontFamily: 'Roboto', fontSize: 16),
          ),
        );

      default:
        return ThemeSettings(
          themeName: 'Defaults',
          brightness: Brightness.light,
          primaryColor: Colors.grey,
          secondaryColor: Colors.pink,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.grey),
          scaffoldBackgroundColor: Colors.grey.shade200,
          textTheme: const TextTheme(
            bodyMedium: TextStyle(fontFamily: 'Opensans', fontSize: 16),
          ),
        );
    }
  }
}
