import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/general_key_value_storage_service.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../theme/themes.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// River-pod provider for ThemeNotifier
final themeNotifierProvider = ChangeNotifierProvider<ThemeNotifier>((ref) {
  final storage = ref.read(generalKeyValueStorageProvider);
  return ThemeNotifier(storage);
});

class ThemeNotifier extends ChangeNotifier {
  static const String _themeKey = "selected_theme";
  static const String _themeModeKey = "theme_mode";

  final GeneralKeyValueStorageService storage;

  late AppTheme _currentTheme;
  late ThemeMode _themeMode;

  //final Completer<void> _initCompleter = Completer<void>();
  late final Future<void> initializationCompleted;

  /// Constructor is now public, as River-pod handles initialization.
  ThemeNotifier(this.storage) {
    _currentTheme = AppTheme.fromType(AppTheme.defaultTheme, ThemeMode.system);
    _themeMode = ThemeMode.system;
    initializationCompleted = _initializeTheme();
  }

  String get backgroundImage => _currentTheme.backgroundImage;
  ThemeData get themeData => _currentTheme.themeData;
  ThemeType get currentThemeType => _currentTheme.type;
  ThemeMode get themeMode => _themeMode;

  /// Initialize theme settings from persistent storage (Hive)
  Future<void> _initializeTheme() async {
    LogManager.debug("Initializing theme settings from Hive...");
    try {
      final savedTheme = await storage.getString(_themeKey);
      final savedThemeMode = await storage.getString(_themeModeKey);

      // Load ThemeType
      if (savedTheme != null) {
        final themeType = AppTheme.fromString(savedTheme);
        _currentTheme = AppTheme.fromType(themeType, _themeMode);
        LogManager.debug("Loaded theme type: $savedTheme");
      } else {
        await storage.setString(_themeKey, AppTheme.defaultTheme.name);
        LogManager.debug(
            "Default theme type saved: ${AppTheme.defaultTheme.name}");
      }

      /// Load ThemeMode
      if (savedThemeMode != null) {
        _themeMode = _themeModeFromString(savedThemeMode);
        LogManager.debug("Loaded theme mode: $savedThemeMode");
      } else {
        await storage.setString(_themeModeKey, _themeMode.name);
        LogManager.debug("Default theme mode saved: ${_themeMode.name}");
      }

      notifyListeners();
    } catch (e) {
      LogManager.debug("Error initializing theme: $e");
    }
  }

  /// Update ThemeType and persist it.
  Future<void> setTheme(ThemeType themeType) async {
    _currentTheme = AppTheme.fromType(themeType, _themeMode);
    await storage.setString(_themeKey, themeType.name);
    LogManager.debug("Theme type updated and saved: ${themeType.name}");
    notifyListeners();
  }

  /// Update ThemeMode (light, dark, system) and persist it
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    await storage.setString(_themeModeKey, mode.name);
    LogManager.debug("Theme mode updated and saved: ${mode.name}");
    notifyListeners();
  }

  /// Helper to convert string to ThemeMode
  ThemeMode _themeModeFromString(String mode) {
    switch (mode) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
