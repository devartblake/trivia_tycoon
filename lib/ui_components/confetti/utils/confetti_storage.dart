import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../models/confetti_settings.dart';

class ConfettiStorage {
  static const String _settingsKey = 'confetti_settings';

  /// 🔐 Save ConfettiSettings as JSON
  static Future<void> saveSettings(ConfettiSettings settings) async {
    final String jsonStr = jsonEncode(settings.toMap());
    await AppSettings.setString(_settingsKey, jsonStr);
  }

  /// 🔓 Load ConfettiSettings from JSON
  static Future<ConfettiSettings> loadSettings() async {
    final String? jsonStr = await AppSettings.getString(_settingsKey);

    if (jsonStr != null) {
      try {
        final Map<String, dynamic> data = jsonDecode(jsonStr);
        return ConfettiSettings.fromMap(data);
      } catch (e) {
        debugPrint('Failed to parse ConfettiSettings: $e');
      }
    }
    return ConfettiSettings(); // Fallback default
  }

  /// Reset last used settings
  static Future<void> resetSettings() async {
    await AppSettings.remove(_settingsKey);
  }
}
