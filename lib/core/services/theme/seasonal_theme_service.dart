import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/models/seasonal_theme_models.dart';
import '../../theme/themes.dart';
import '../settings/general_key_value_storage_service.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// Service for managing seasonal themes
class SeasonalThemeService {
  final GeneralKeyValueStorageService _storage;
  static const String _seasonalThemeKey = 'seasonal_theme_config';
  static const String _userThemeOverrideKey = 'user_theme_override';

  SeasonalThemeService(this._storage);

  /// Get current active seasonal theme (if any)
  Future<SeasonalTheme?> getCurrentSeasonalTheme() async {
    try {
      // FIXED: Use getJson() instead of get()
      final json = await _storage.getJson(_seasonalThemeKey);
      if (json == null) return null;

      final theme = SeasonalTheme.fromJson(json);
      return theme.isCurrentlyActive() ? theme : null;
    } catch (e) {
      LogManager.debug('[SeasonalTheme] Error loading seasonal theme: $e');
      return null;
    }
  }

  /// Save seasonal theme from backend
  Future<void> saveSeasonalTheme(SeasonalTheme theme) async {
    try {
      // FIXED: Use setJson() instead of set()
      await _storage.setJson(_seasonalThemeKey, theme.toJson());
      LogManager.debug('[SeasonalTheme] ✓ Saved seasonal theme: ${theme.name}');
    } catch (e) {
      LogManager.debug('[SeasonalTheme] ❌ Error saving seasonal theme: $e');
    }
  }

  /// Update seasonal theme from backend API
  /// Call this method from your API service after fetching theme data
  Future<void> updateFromBackend(Map<String, dynamic> themeData) async {
    try {
      final theme = SeasonalTheme.fromJson(themeData);
      await saveSeasonalTheme(theme);
      LogManager.debug('[SeasonalTheme] ✓ Updated from backend: ${theme.name}');
    } catch (e) {
      LogManager.debug('[SeasonalTheme] ❌ Error updating from backend: $e');
    }
  }

  /// Check if user has overridden the seasonal theme
  Future<bool> hasUserOverride() async {
    // FIXED: Use getString() and make async
    final override = await _storage.getString(_userThemeOverrideKey);
    return override != null;
  }

  /// Get user's theme override (if set)
  Future<ThemeType?> getUserThemeOverride() async {
    try {
      // FIXED: Use getString() instead of get() and make async
      final themeName = await _storage.getString(_userThemeOverrideKey);
      if (themeName == null) return null;
      return AppTheme.fromString(themeName);
    } catch (e) {
      LogManager.debug('[SeasonalTheme] Error loading user override: $e');
      return null;
    }
  }

  /// Set user theme override (allows user to choose their own theme)
  Future<void> setUserThemeOverride(ThemeType? themeType) async {
    try {
      if (themeType == null) {
        await _storage.remove(_userThemeOverrideKey);
        LogManager.debug('[SeasonalTheme] ✓ Removed user theme override');
      } else {
        // FIXED: Use setString() instead of set()
        await _storage.setString(_userThemeOverrideKey, themeType.name);
        LogManager.debug('[SeasonalTheme] ✓ Set user theme override: ${themeType.name}');
      }
    } catch (e) {
      LogManager.debug('[SeasonalTheme] ❌ Error setting user override: $e');
    }
  }

  /// Get the theme to use (respects user override, then seasonal, then default)
  Future<ThemeType> getActiveTheme() async {
    // FIXED: Made async and await all calls
    // 1. Check user override first
    final userOverride = await getUserThemeOverride();
    if (userOverride != null) {
      LogManager.debug('[SeasonalTheme] Using user override: ${userOverride.name}');
      return userOverride;
    }

    // 2. Check seasonal theme
    final seasonalTheme = await getCurrentSeasonalTheme();
    if (seasonalTheme != null) {
      LogManager.debug('[SeasonalTheme] Using seasonal theme: ${seasonalTheme.name}');
      return seasonalTheme.themeType;
    }

    // 3. Default theme
    LogManager.debug('[SeasonalTheme] Using default theme');
    return AppTheme.defaultTheme;
  }

  /// Clear all seasonal theme data
  Future<void> clear() async {
    await _storage.remove(_seasonalThemeKey);
    await _storage.remove(_userThemeOverrideKey);
  }

  /// Example seasonal themes for testing
  static List<SeasonalTheme> getExampleSeasons() {
    final now = DateTime.now();

    return [
      // Christmas Theme (December 1 - December 31)
      SeasonalTheme(
        id: 'christmas_2025',
        name: 'Christmas Theme',
        themeType: ThemeType.allStar, // Red/Green colors
        startDate: DateTime(now.year, 12, 1),
        endDate: DateTime(now.year, 12, 31, 23, 59),
        isActive: true,
        description: 'Festive holiday theme with Christmas colors',
        iconEmoji: '🎄',
      ),

      // Summer Theme (June 1 - August 31)
      SeasonalTheme(
        id: 'summer_2025',
        name: 'Summer Theme',
        themeType: ThemeType.main, // Blue/Turquoise colors
        startDate: DateTime(now.year, 6, 1),
        endDate: DateTime(now.year, 8, 31, 23, 59),
        isActive: true,
        description: 'Cool summer vibes with ocean colors',
        iconEmoji: '☀️',
      ),

      // Competition Theme (October 1 - October 31)
      SeasonalTheme(
        id: 'halloween_2025',
        name: 'Halloween Theme',
        themeType: ThemeType.competition, // Red/Dark colors
        startDate: DateTime(now.year, 10, 1),
        endDate: DateTime(now.year, 10, 31, 23, 59),
        isActive: true,
        description: 'Spooky Halloween theme',
        iconEmoji: '🎃',
      ),
    ];
  }
}

/// Riverpod provider for GeneralKeyValueStorageService
/// ADD THIS to your riverpod_providers.dart if not already present
final generalKeyValueStorageProvider = Provider<GeneralKeyValueStorageService>((ref) {
  return GeneralKeyValueStorageService();
});

/// Riverpod provider for SeasonalThemeService
final seasonalThemeServiceProvider = Provider<SeasonalThemeService>((ref) {
  final storage = ref.watch(generalKeyValueStorageProvider);
  return SeasonalThemeService(storage);
});

/// Provider for current active theme type
/// FIXED: Changed to FutureProvider since getActiveTheme() is now async
final activeThemeTypeProvider = FutureProvider<ThemeType>((ref) async {
  final seasonalService = ref.watch(seasonalThemeServiceProvider);
  return await seasonalService.getActiveTheme();
});

/// Provider to check if seasonal theme is active
/// FIXED: Changed to FutureProvider since methods are now async
final isSeasonalThemeActiveProvider = FutureProvider<bool>((ref) async {
  final seasonalService = ref.watch(seasonalThemeServiceProvider);
  final hasTheme = await seasonalService.getCurrentSeasonalTheme() != null;
  final hasOverride = await seasonalService.hasUserOverride();
  return hasTheme && !hasOverride;
});

/// Provider for current seasonal theme (if any)
/// FIXED: Changed to FutureProvider since getCurrentSeasonalTheme() is now async
final currentSeasonalThemeProvider = FutureProvider<SeasonalTheme?>((ref) async {
  final seasonalService = ref.watch(seasonalThemeServiceProvider);
  return await seasonalService.getCurrentSeasonalTheme();
});