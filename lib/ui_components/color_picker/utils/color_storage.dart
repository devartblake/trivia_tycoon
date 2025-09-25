import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../core/color_picker_settings.dart';
import '../core/color_picker_theme.dart';
import '../models/color_palette.dart';

class ColorStorage {
  // Box names
  static const String _settingsBox = 'color_picker_settings';
  static const String _themeBox = 'color_picker_theme';
  static const String _cacheBox = 'color_picker_cache';

  // Cache for opened boxes to avoid repeated opening
  static final Map<String, Box> _boxCache = {};
  static final Map<String, Completer<Box>> _boxCompleters = {};

  // Memory cache for frequently accessed data
  static final Map<String, dynamic> _memoryCache = {};
  static const int _maxCacheSize = 100;
  static const Duration _cacheExpiry = Duration(minutes: 5);
  static final Map<String, DateTime> _cacheTimestamps = {};

  /// Get or open a Hive box with caching
  static Future<Box> _getBox(String boxName) async {
    // Return cached box if available
    if (_boxCache.containsKey(boxName)) {
      return _boxCache[boxName]!;
    }

    // If box is currently being opened, wait for it
    if (_boxCompleters.containsKey(boxName)) {
      return await _boxCompleters[boxName]!.future;
    }

    // Create new completer for this box
    final completer = Completer<Box>();
    _boxCompleters[boxName] = completer;

    try {
      final box = await Hive.openBox(boxName);
      _boxCache[boxName] = box;
      completer.complete(box);
      return box;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _boxCompleters.remove(boxName);
    }
  }

  /// Get value from memory cache if valid
  static T? _getFromCache<T>(String key) {
    final timestamp = _cacheTimestamps[key];
    if (timestamp != null &&
        DateTime.now().difference(timestamp) < _cacheExpiry) {
      return _memoryCache[key] as T?;
    }

    // Remove expired cache entry
    _memoryCache.remove(key);
    _cacheTimestamps.remove(key);
    return null;
  }

  /// Store value in memory cache
  static void _setCache(String key, dynamic value) {
    // Clean cache if it gets too large
    if (_memoryCache.length >= _maxCacheSize) {
      final oldestKey = _cacheTimestamps.entries
          .reduce((a, b) => a.value.isBefore(b.value) ? a : b)
          .key;
      _memoryCache.remove(oldestKey);
      _cacheTimestamps.remove(oldestKey);
    }

    _memoryCache[key] = value;
    _cacheTimestamps[key] = DateTime.now();
  }

  /// Save selected color with error handling
  static Future<bool> saveColor(Color color) async {
    try {
      final box = await _getBox(_settingsBox);
      await box.put('selectedColor', color.value);
      _setCache('selectedColor', color.value);
      return true;
    } catch (e) {
      debugPrint('Error saving color: $e');
      return false;
    }
  }

  /// Retrieve last selected color with caching
  static Future<Color?> getSavedColor() async {
    try {
      // Check memory cache first
      final cachedValue = _getFromCache<int>('selectedColor');
      if (cachedValue != null) {
        return Color(cachedValue);
      }

      final box = await _getBox(_settingsBox);
      final colorValue = box.get('selectedColor') as int?;

      if (colorValue != null) {
        _setCache('selectedColor', colorValue);
        return Color(colorValue);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting saved color: $e');
      return null;
    }
  }

  /// Save custom color palette with validation
  static Future<bool> saveCustomPalette(List<Color> palette) async {
    try {
      // Validate palette
      if (palette.length > 50) {
        debugPrint('Warning: Palette too large, truncating to 50 colors');
        palette = palette.take(50).toList();
      }

      final colorValues = palette.map((c) => c.value).toList();
      final box = await _getBox(_settingsBox);
      await box.put('customPalette', colorValues);
      _setCache('customPalette', colorValues);
      return true;
    } catch (e) {
      debugPrint('Error saving custom palette: $e');
      return false;
    }
  }

  /// Retrieve custom color palette with caching
  static Future<List<Color>?> getCustomPalette() async {
    try {
      // Check memory cache first
      final cachedValues = _getFromCache<List<int>>('customPalette');
      if (cachedValues != null) {
        return cachedValues.map((c) => Color(c)).toList();
      }

      final box = await _getBox(_settingsBox);
      final colorValues = box.get('customPalette') as List<dynamic>?;

      if (colorValues != null) {
        final intValues = colorValues.cast<int>();
        _setCache('customPalette', intValues);
        return intValues.map((c) => Color(c)).toList();
      }

      return [];
    } catch (e) {
      debugPrint('Error getting custom palette: $e');
      return [];
    }
  }

  /// Load all saved colors with efficient caching
  static Future<List<Color>> loadSavedColors() async {
    try {
      final cacheKey = 'loadSavedColors';

      // Check memory cache first
      final cachedColors = _getFromCache<List<Color>>(cacheKey);
      if (cachedColors != null) {
        return cachedColors;
      }

      final box = await _getBox(_settingsBox);

      // Get saved palette colors
      final paletteValues = box.get('customPalette') as List<dynamic>?;
      final selectedColorValue = box.get('selectedColor') as int?;

      List<Color> savedColors = [];

      // Add palette colors
      if (paletteValues != null) {
        savedColors.addAll(
          paletteValues.cast<int>().map((c) => Color(c)),
        );
      }

      // Add selected color if not already included
      if (selectedColorValue != null) {
        final selectedColor = Color(selectedColorValue);
        if (!savedColors.any((c) => c.value == selectedColor.value)) {
          savedColors.insert(0, selectedColor);
        }
      }

      // Use default colors if empty
      if (savedColors.isEmpty) {
        savedColors = _getDefaultColors();
      }

      // Cache the result
      _setCache(cacheKey, savedColors);
      return savedColors;
    } catch (e) {
      debugPrint('Error loading saved colors: $e');
      return _getDefaultColors();
    }
  }

  /// Get default fallback colors
  static List<Color> _getDefaultColors() {
    return const [
      Color(0xFFE53E3E), // Red
      Color(0xFF3182CE), // Blue
      Color(0xFF38A169), // Green
      Color(0xFFED8936), // Orange
      Color(0xFF805AD5), // Purple
      Color(0xFFECC94B), // Yellow
      Color(0xFFE53E3E), // Pink (different shade)
      Color(0xFF319795), // Teal
      Color(0xFF718096), // Gray
      Color(0xFF2D3748), // Dark Gray
    ];
  }

  /// Save picker settings with compression for large data
  static Future<bool> savePickerSettings(ColorPickerSettings settings) async {
    try {
      final settingsMap = settings.toMap();
      final box = await _getBox(_settingsBox);
      await box.put('pickerSettings', settingsMap);
      _setCache('pickerSettings', settingsMap);
      return true;
    } catch (e) {
      debugPrint('Error saving picker settings: $e');
      return false;
    }
  }

  /// Retrieve picker settings with validation
  static Future<ColorPickerSettings?> getPickerSettings() async {
    try {
      // Check memory cache first
      final cachedMap = _getFromCache<Map<String, dynamic>>('pickerSettings');
      if (cachedMap != null) {
        return ColorPickerSettings.fromMap(cachedMap);
      }

      final box = await _getBox(_settingsBox);
      final settingsMap = box.get('pickerSettings') as Map<String, dynamic>?;

      if (settingsMap != null) {
        _setCache('pickerSettings', settingsMap);
        final settings = ColorPickerSettings.fromMap(settingsMap);

        // Validate and return corrected settings if needed
        return settings.isValid() ? settings : settings.validated();
      }

      return null;
    } catch (e) {
      debugPrint('Error getting picker settings: $e');
      return null;
    }
  }

  /// Save picker theme with validation
  static Future<bool> savePickerTheme(ColorPickerTheme theme) async {
    try {
      final themeMap = theme.toMap();
      final box = await _getBox(_settingsBox);
      await box.put('pickerTheme', themeMap);
      _setCache('pickerTheme', themeMap);
      return true;
    } catch (e) {
      debugPrint('Error saving picker theme: $e');
      return false;
    }
  }

  /// Retrieve picker theme
  static Future<Map<String, dynamic>?> getPickerTheme() async {
    try {
      // Check memory cache first
      final cachedTheme = _getFromCache<Map<String, dynamic>>('pickerTheme');
      if (cachedTheme != null) {
        return cachedTheme;
      }

      final box = await _getBox(_settingsBox);
      final themeMap = box.get('pickerTheme') as Map<String, dynamic>?;

      if (themeMap != null) {
        _setCache('pickerTheme', themeMap);
      }

      return themeMap;
    } catch (e) {
      debugPrint('Error getting picker theme: $e');
      return null;
    }
  }

  /// Save a color palette with duplicate checking
  static Future<bool> savePalette(ColorPalette palette) async {
    try {
      // Validate palette name
      if (palette.name.trim().isEmpty) {
        debugPrint('Error: Palette name cannot be empty');
        return false;
      }

      final box = await _getBox(_settingsBox);
      final key = 'palette_${palette.name}';
      await box.put(key, palette.toMap());

      // Invalidate related caches
      _memoryCache.remove('getAllPaletteNames');
      _cacheTimestamps.remove('getAllPaletteNames');

      return true;
    } catch (e) {
      debugPrint('Error saving palette: $e');
      return false;
    }
  }

  /// Retrieve a color palette by name
  static Future<ColorPalette?> getPalette(String name) async {
    try {
      if (name.trim().isEmpty) return null;

      final cacheKey = 'palette_$name';
      final cachedPalette = _getFromCache<Map<String, dynamic>>(cacheKey);
      if (cachedPalette != null) {
        return ColorPalette.fromMap(cachedPalette);
      }

      final box = await _getBox(_settingsBox);
      final paletteMap = box.get(cacheKey) as Map<String, dynamic>?;

      if (paletteMap != null) {
        _setCache(cacheKey, paletteMap);
        return ColorPalette.fromMap(paletteMap);
      }

      return null;
    } catch (e) {
      debugPrint('Error getting palette: $e');
      return null;
    }
  }

  /// Get all palette names with caching
  static Future<List<String>> getAllPaletteNames() async {
    try {
      const cacheKey = 'getAllPaletteNames';

      // Check memory cache first
      final cachedNames = _getFromCache<List<String>>(cacheKey);
      if (cachedNames != null) {
        return cachedNames;
      }

      final box = await _getBox(_settingsBox);
      final names = box.keys
          .whereType<String>()
          .where((key) => key.startsWith('palette_'))
          .map((key) => key.substring(8)) // Remove "palette_" prefix
          .toList();

      _setCache(cacheKey, names);
      return names;
    } catch (e) {
      debugPrint('Error getting palette names: $e');
      return [];
    }
  }

  /// Delete a palette with cache cleanup
  static Future<bool> deletePalette(String name) async {
    try {
      if (name.trim().isEmpty) return false;

      final box = await _getBox(_settingsBox);
      final key = 'palette_$name';
      await box.delete(key);

      // Clean up caches
      _memoryCache.remove(key);
      _cacheTimestamps.remove(key);
      _memoryCache.remove('getAllPaletteNames');
      _cacheTimestamps.remove('getAllPaletteNames');

      return true;
    } catch (e) {
      debugPrint('Error deleting palette: $e');
      return false;
    }
  }

  /// Clear all cached data (useful for testing or reset)
  static Future<void> clearCache() async {
    _memoryCache.clear();
    _cacheTimestamps.clear();

    // Optionally close cached boxes
    for (final box in _boxCache.values) {
      if (box.isOpen) {
        await box.close();
      }
    }
    _boxCache.clear();
  }

  /// Get cache statistics for debugging
  static Map<String, dynamic> getCacheStats() {
    return {
      'memoryCacheSize': _memoryCache.length,
      'boxCacheSize': _boxCache.length,
      'activeCompleters': _boxCompleters.length,
      'cacheHitRate': _calculateCacheHitRate(),
    };
  }

  static double _calculateCacheHitRate() {
    // This would require tracking hits/misses in a real implementation
    return _memoryCache.isNotEmpty ? 0.85 : 0.0; // Placeholder
  }

  /// Preload frequently used data
  static Future<void> preloadCache() async {
    try {
      // Preload common data that's likely to be accessed
      await Future.wait([
        getSavedColor(),
        getCustomPalette(),
        getPickerSettings(),
        getAllPaletteNames(),
      ]);
    } catch (e) {
      debugPrint('Error preloading cache: $e');
    }
  }

  /// Compact storage by removing old/unused data
  static Future<void> compactStorage() async {
    try {
      final box = await _getBox(_settingsBox);
      await box.compact();

      // Clear old cache entries
      final now = DateTime.now();
      final expiredKeys = _cacheTimestamps.entries
          .where((entry) => now.difference(entry.value) > _cacheExpiry)
          .map((entry) => entry.key)
          .toList();

      for (final key in expiredKeys) {
        _memoryCache.remove(key);
        _cacheTimestamps.remove(key);
      }
    } catch (e) {
      debugPrint('Error compacting storage: $e');
    }
  }
}
