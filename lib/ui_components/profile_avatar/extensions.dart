import 'dart:math';
import 'package:flutter/material.dart';

enum AvatarMinLength {
  one,
  two;

  bool get isOne => this == one;
  bool get isTwo => this == two; // FIXED: was checking 'this == one'
}

/// String utility extension for avatar functionality
extension StringExtension on String? {
  /// Returns a string abbreviation for avatar initials
  ///
  /// Examples:
  /// - "John Doe" -> "JD"
  /// - "Alice" -> "A" (with minLength.one) or "AL" (with minLength.two if available)
  /// - null or empty -> ""
  String toAbbreviation([AvatarMinLength minLength = AvatarMinLength.one]) {
    final trimmed = this?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '';
    }

    final nameParts = trimmed.toUpperCase().split(RegExp(r'[\s/]+'));

    if (nameParts.length > 1) {
      // Multiple parts: take first char of first two parts
      return nameParts.first.characters.first + nameParts[1].characters.first;
    }

    // Single part
    if (minLength.isTwo && nameParts.first.characters.length > 1) {
      // FIXED: was using codeUnits.take(2).toString() which returns "(104, 101)"
      // Now correctly takes first 2 characters
      return nameParts.first.characters.take(2).join();
    }

    return nameParts.first.characters.first;
  }

  /// Returns an extended abbreviation (up to maxLength characters)
  ///
  /// Examples:
  /// - "John Doe Smith" -> "JDS"
  /// - "Alice Bob" -> "AB"
  /// - "Charlie" -> "C" (or "CH" with maxLength: 2)
  String toAbbreviationExtended({int maxLength = 3}) {
    final trimmed = this?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return '';
    }

    final nameParts = trimmed.toUpperCase().split(RegExp(r'[\s/]+'));

    if (nameParts.isEmpty) {
      return '';
    }

    // If single part and maxLength > 1, take multiple chars from same word
    if (nameParts.length == 1 && maxLength > 1) {
      return nameParts.first.characters.take(maxLength).join();
    }

    // Multiple parts: take first char of each part up to maxLength
    return nameParts
        .take(maxLength)
        .map((part) => part.isNotEmpty ? part.characters.first : '')
        .join();
  }

  /// Generates a consistent color from a string
  ///
  /// Uses the string's hash code to generate a deterministic color
  /// that will be the same for the same input string.
  Color toAvatarColor() {
    if (this == null || this!.isEmpty) {
      return const Color(0xFF9E9E9E); // Grey for empty/null
    }

    final hash = this!.hashCode;
    final hue = (hash % 360).toDouble();

    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }
}

/// Alignment utility extension for circular positioning
extension AlignmentExtension on Alignment {
  /// Converts the alignment to an [Offset] instance using polar coordinates
  ///
  /// This provides accurate positioning around circular avatars by using
  /// trigonometric calculations to determine the exact position on the circle.
  Offset toOffsetWithRadius({double radius = 0.0}) {
    final angle = atan2(y, x);
    final polarRadius = radius * min(1.0, sqrt(x * x + y * y));
    final offsetX = polarRadius * cos(angle) + radius;
    final offsetY = polarRadius * sin(angle) + radius;
    return Offset(offsetX, offsetY);
  }

  /// Converts alignment to an angle in radians
  ///
  /// Useful for positioning elements at specific angles around a circle.
  double toRadians() {
    return atan2(y, x);
  }

  /// Creates an alignment from an angle in radians
  static Alignment fromRadians(double radians) {
    return Alignment(
      cos(radians),
      sin(radians),
    );
  }

  /// Creates an alignment from an angle in degrees
  static Alignment fromDegrees(double degrees) {
    final radians = degrees * pi / 180.0;
    return fromRadians(radians);
  }
}

/// Color utility extensions for avatar theming
extension ColorAvatarExtension on Color {
  /// Returns a contrasting color (black or white) for text visibility
  Color get contrastingColor {
    final luminance = computeLuminance();
    return luminance > 0.5 ? const Color(0xFF000000) : const Color(0xFFFFFFFF);
  }

  /// Lightens the color by a percentage (0.0 to 1.0)
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness + amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Darkens the color by a percentage (0.0 to 1.0)
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final lightness = (hsl.lightness - amount).clamp(0.0, 1.0);
    return hsl.withLightness(lightness).toColor();
  }

  /// Returns a complementary color (opposite on color wheel)
  Color get complementary {
    final hsl = HSLColor.fromColor(this);
    final hue = (hsl.hue + 180) % 360;
    return hsl.withHue(hue).toColor();
  }

  /// Returns an analogous color (adjacent on color wheel)
  Color analogous([double degrees = 30]) {
    final hsl = HSLColor.fromColor(this);
    final hue = (hsl.hue + degrees) % 360;
    return hsl.withHue(hue).toColor();
  }

  /// Returns a triadic color (120° on color wheel)
  Color get triadic {
    final hsl = HSLColor.fromColor(this);
    final hue = (hsl.hue + 120) % 360;
    return hsl.withHue(hue).toColor();
  }

  /// Adjusts the saturation of the color
  Color withSaturation(double saturation) {
    assert(saturation >= 0 && saturation <= 1);
    final hsl = HSLColor.fromColor(this);
    return hsl.withSaturation(saturation).toColor();
  }
}
