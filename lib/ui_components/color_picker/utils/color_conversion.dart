import 'dart:math';
import 'package:flutter/material.dart';

class ColorConversion {
  // Cache for expensive conversions
  static final Map<String, Color> _hexCache = {};
  static final Map<int, String> _colorToHexCache = {};
  static const int _maxCacheSize = 200;

  /// Convert Color to HEX String with caching
  static String colorToHex(Color color, {bool leadingHashSign = true}) {
    final cacheKey = color.value;

    // Check cache first
    if (_colorToHexCache.containsKey(cacheKey)) {
      final cached = _colorToHexCache[cacheKey]!;
      return leadingHashSign ? cached : cached.substring(1);
    }

    // Generate hex string
    final hex = color.value.toRadixString(16).padLeft(8, '0').toUpperCase();
    final result = '#$hex';

    // Cache the result
    _cacheConversion(cacheKey, result);

    return leadingHashSign ? result : result.substring(1);
  }

  /// Convert HEX String to Color with validation and caching
  static Color? hexToColor(String hex) {
    if (hex.isEmpty) return null;

    // Normalize hex string
    String cleanHex = hex.trim().toUpperCase();
    if (cleanHex.startsWith('#')) {
      cleanHex = cleanHex.substring(1);
    }

    // Check cache first
    if (_hexCache.containsKey(cleanHex)) {
      return _hexCache[cleanHex];
    }

    // Validate hex format
    if (!_isValidHex(cleanHex)) {
      return null;
    }

    try {
      Color color;

      switch (cleanHex.length) {
        case 3: // RGB format (e.g., "F0A")
          final r = int.parse(cleanHex[0] * 2, radix: 16);
          final g = int.parse(cleanHex[1] * 2, radix: 16);
          final b = int.parse(cleanHex[2] * 2, radix: 16);
          color = Color.fromARGB(255, r, g, b);
          break;

        case 4: // ARGB format (e.g., "FF0A")
          final a = int.parse(cleanHex[0] * 2, radix: 16);
          final r = int.parse(cleanHex[1] * 2, radix: 16);
          final g = int.parse(cleanHex[2] * 2, radix: 16);
          final b = int.parse(cleanHex[3] * 2, radix: 16);
          color = Color.fromARGB(a, r, g, b);
          break;

        case 6: // RRGGBB format (e.g., "FF00AA")
          final value = int.parse('FF$cleanHex', radix: 16);
          color = Color(value);
          break;

        case 8: // AARRGGBB format (e.g., "FFFF00AA")
          final value = int.parse(cleanHex, radix: 16);
          color = Color(value);
          break;

        default:
          return null;
      }

      // Cache the result
      _hexCache[cleanHex] = color;
      _cleanCache();

      return color;
    } catch (e) {
      return null;
    }
  }

  /// Validate hex string format
  static bool _isValidHex(String hex) {
    if (hex.isEmpty || ![3, 4, 6, 8].contains(hex.length)) {
      return false;
    }
    return RegExp(r'^[0-9A-F]+$').hasMatch(hex);
  }

  /// Clean cache if it gets too large
  static void _cleanCache() {
    if (_hexCache.length > _maxCacheSize) {
      // Remove oldest entries (simple FIFO)
      final keysToRemove = _hexCache.keys.take(_maxCacheSize ~/ 4).toList();
      for (final key in keysToRemove) {
        _hexCache.remove(key);
      }
    }
  }

  /// Cache color to hex conversion
  static void _cacheConversion(int colorValue, String hex) {
    if (_colorToHexCache.length > _maxCacheSize) {
      // Remove oldest entries
      final keysToRemove = _colorToHexCache.keys.take(_maxCacheSize ~/ 4).toList();
      for (final key in keysToRemove) {
        _colorToHexCache.remove(key);
      }
    }
    _colorToHexCache[colorValue] = hex;
  }

  /// Convert RGB to HSV with optimized calculation
  static HSVColor rgbToHsv(Color color) {
    return HSVColor.fromColor(color);
  }

  /// Convert HSV to RGB
  static Color hsvToRgb(HSVColor hsv) {
    return hsv.toColor();
  }

  /// Convert RGB to HSL with optimized calculation
  static HSLColor rgbToHsl(Color color) {
    return HSLColor.fromColor(color);
  }

  /// Convert HSL to RGB
  static Color hslToRgb(HSLColor hsl) {
    return hsl.toColor();
  }

  /// Convert Color to CSS-style RGB string
  static String colorToRgb(Color color) {
    return 'rgb(${color.red}, ${color.green}, ${color.blue})';
  }

  /// Convert Color to CSS-style RGBA string
  static String colorToRgba(Color color) {
    final alpha = (color.alpha / 255.0).toStringAsFixed(2);
    return 'rgba(${color.red}, ${color.green}, ${color.blue}, $alpha)';
  }

  /// Convert Color to HSL CSS string
  static String colorToHslString(Color color) {
    final hsl = HSLColor.fromColor(color);
    final h = hsl.hue.round();
    final s = (hsl.saturation * 100).round();
    final l = (hsl.lightness * 100).round();
    return 'hsl($h, $s%, $l%)';
  }

  /// Convert Color to HSLA CSS string
  static String colorToHslaString(Color color) {
    final hsl = HSLColor.fromColor(color);
    final h = hsl.hue.round();
    final s = (hsl.saturation * 100).round();
    final l = (hsl.lightness * 100).round();
    final a = (color.alpha / 255.0).toStringAsFixed(2);
    return 'hsla($h, $s%, $l%, $a)';
  }

  /// Parse CSS RGB/RGBA string to Color
  static Color? parseRgbString(String rgbString) {
    final cleaned = rgbString.trim().toLowerCase();

    // Match rgb(r, g, b) or rgba(r, g, b, a)
    final rgbMatch = RegExp(r'rgba?\(\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*(?:,\s*([\d.]+))?\s*\)').firstMatch(cleaned);

    if (rgbMatch != null) {
      final r = int.tryParse(rgbMatch.group(1)!) ?? 0;
      final g = int.tryParse(rgbMatch.group(2)!) ?? 0;
      final b = int.tryParse(rgbMatch.group(3)!) ?? 0;
      final a = rgbMatch.group(4) != null ? (double.tryParse(rgbMatch.group(4)!) ?? 1.0) : 1.0;

      return Color.fromARGB((a * 255).round(), r, g, b);
    }

    return null;
  }

  /// Parse CSS HSL/HSLA string to Color
  static Color? parseHslString(String hslString) {
    final cleaned = hslString.trim().toLowerCase();

    // Match hsl(h, s%, l%) or hsla(h, s%, l%, a)
    final hslMatch = RegExp(r'hsla?\(\s*(\d+)\s*,\s*(\d+)%\s*,\s*(\d+)%\s*(?:,\s*([\d.]+))?\s*\)').firstMatch(cleaned);

    if (hslMatch != null) {
      final h = (int.tryParse(hslMatch.group(1)!) ?? 0).toDouble();
      final s = (int.tryParse(hslMatch.group(2)!) ?? 0) / 100.0;
      final l = (int.tryParse(hslMatch.group(3)!) ?? 0) / 100.0;
      final a = hslMatch.group(4) != null ? (double.tryParse(hslMatch.group(4)!) ?? 1.0) : 1.0;

      final hslColor = HSLColor.fromAHSL(a, h, s, l);
      return hslColor.toColor();
    }

    return null;
  }

  /// Get color brightness (0.0 to 1.0)
  static double getBrightness(Color color) {
    return color.computeLuminance();
  }

  /// Check if color is light (good for dark text)
  static bool isLight(Color color) {
    return getBrightness(color) > 0.5;
  }

  /// Check if color is dark (good for light text)
  static bool isDark(Color color) {
    return getBrightness(color) <= 0.5;
  }

  /// Get contrasting text color (black or white)
  static Color getContrastingTextColor(Color backgroundColor) {
    return isLight(backgroundColor) ? Colors.black : Colors.white;
  }

  /// Calculate color contrast ratio between two colors
  static double getContrastRatio(Color color1, Color color2) {
    final lum1 = color1.computeLuminance();
    final lum2 = color2.computeLuminance();
    final brightest = max(lum1, lum2);
    final darkest = min(lum1, lum2);
    return (brightest + 0.05) / (darkest + 0.05);
  }

  /// Check if color combination meets WCAG AA accessibility standards
  static bool meetsWcagAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 4.5;
  }

  /// Check if color combination meets WCAG AAA accessibility standards
  static bool meetsWcagAAA(Color foreground, Color background) {
    return getContrastRatio(foreground, background) >= 7.0;
  }

  /// Blend two colors with given ratio (0.0 to 1.0)
  static Color blendColors(Color color1, Color color2, double ratio) {
    ratio = ratio.clamp(0.0, 1.0);
    final r = (color1.red * (1 - ratio) + color2.red * ratio).round();
    final g = (color1.green * (1 - ratio) + color2.green * ratio).round();
    final b = (color1.blue * (1 - ratio) + color2.blue * ratio).round();
    final a = (color1.alpha * (1 - ratio) + color2.alpha * ratio).round();
    return Color.fromARGB(a, r, g, b);
  }

  /// Lighten color by percentage (0.0 to 1.0)
  static Color lighten(Color color, double amount) {
    amount = amount.clamp(0.0, 1.0);
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness + amount * (1.0 - hsl.lightness)).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  /// Darken color by percentage (0.0 to 1.0)
  static Color darken(Color color, double amount) {
    amount = amount.clamp(0.0, 1.0);
    final hsl = HSLColor.fromColor(color);
    final newLightness = (hsl.lightness * (1.0 - amount)).clamp(0.0, 1.0);
    return hsl.withLightness(newLightness).toColor();
  }

  /// Saturate color by percentage (0.0 to 1.0)
  static Color saturate(Color color, double amount) {
    amount = amount.clamp(0.0, 1.0);
    final hsl = HSLColor.fromColor(color);
    final newSaturation = (hsl.saturation + amount * (1.0 - hsl.saturation)).clamp(0.0, 1.0);
    return hsl.withSaturation(newSaturation).toColor();
  }

  /// Desaturate color by percentage (0.0 to 1.0)
  static Color desaturate(Color color, double amount) {
    amount = amount.clamp(0.0, 1.0);
    final hsl = HSLColor.fromColor(color);
    final newSaturation = (hsl.saturation * (1.0 - amount)).clamp(0.0, 1.0);
    return hsl.withSaturation(newSaturation).toColor();
  }

  /// Convert color to grayscale
  static Color toGrayscale(Color color) {
    final gray = (color.red * 0.299 + color.green * 0.587 + color.blue * 0.114).round();
    return Color.fromARGB(color.alpha, gray, gray, gray);
  }

  /// Get complementary color (opposite on color wheel)
  static Color getComplementary(Color color) {
    final hsl = HSLColor.fromColor(color);
    final newHue = (hsl.hue + 180) % 360;
    return hsl.withHue(newHue).toColor();
  }

  /// Get analogous colors (adjacent on color wheel)
  static List<Color> getAnalogous(Color color, {int count = 2, double step = 30}) {
    final hsl = HSLColor.fromColor(color);
    final colors = <Color>[];

    for (int i = 1; i <= count; i++) {
      final hue1 = (hsl.hue + step * i) % 360;
      final hue2 = (hsl.hue - step * i) % 360;
      colors.add(hsl.withHue(hue1).toColor());
      colors.add(hsl.withHue(hue2).toColor());
    }

    return colors;
  }

  /// Get triadic colors (120 degrees apart)
  static List<Color> getTriadic(Color color) {
    final hsl = HSLColor.fromColor(color);
    return [
      hsl.withHue((hsl.hue + 120) % 360).toColor(),
      hsl.withHue((hsl.hue + 240) % 360).toColor(),
    ];
  }

  /// Convert Color to integer value
  static int colorToInt(Color color) {
    return color.value;
  }

  /// Convert integer to Color
  static Color intToColor(int value) {
    return Color(value);
  }

  /// Clear conversion caches
  static void clearCache() {
    _hexCache.clear();
    _colorToHexCache.clear();
  }

  /// Get cache statistics
  static Map<String, int> getCacheStats() {
    return {
      'hexCacheSize': _hexCache.length,
      'colorToHexCacheSize': _colorToHexCache.length,
      'maxCacheSize': _maxCacheSize,
    };
  }

  /// Validate color format and return standardized string
  static String? validateAndFormatHex(String input) {
    final color = hexToColor(input);
    return color != null ? colorToHex(color) : null;
  }
}