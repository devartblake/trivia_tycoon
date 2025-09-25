import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

@immutable
class ColorPickerTheme {
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;
  final Color indicatorColor;
  final Color sliderTrackColor;
  final Color presetButtonColor;
  final double presetButtonSize;

  // Enhanced theme properties
  final Color surfaceColor;
  final Color onSurfaceColor;
  final Color primaryColor;
  final Color secondaryColor;
  final Color errorColor;
  final Color shadowColor;
  final double elevation;
  final BorderRadius borderRadius;
  final TextStyle textStyle;
  final bool useMaterial3;
  final ColorScheme? colorScheme;

  // Cached hash code for performance
  final int _hashCode;

  const ColorPickerTheme._({
    required this.backgroundColor,
    required this.borderColor,
    required this.borderWidth,
    required this.indicatorColor,
    required this.sliderTrackColor,
    required this.presetButtonColor,
    required this.presetButtonSize,
    required this.surfaceColor,
    required this.onSurfaceColor,
    required this.primaryColor,
    required this.secondaryColor,
    required this.errorColor,
    required this.shadowColor,
    required this.elevation,
    required this.borderRadius,
    required this.textStyle,
    required this.useMaterial3,
    required this.colorScheme,
    required int hashCode,
  }) : _hashCode = hashCode;

  factory ColorPickerTheme({
    Color backgroundColor = Colors.white,
    Color borderColor = Colors.black,
    double borderWidth = 2.0,
    Color indicatorColor = Colors.black,
    Color sliderTrackColor = Colors.grey,
    Color presetButtonColor = Colors.blueAccent,
    double presetButtonSize = 40.0,
    Color? surfaceColor,
    Color? onSurfaceColor,
    Color? primaryColor,
    Color? secondaryColor,
    Color? errorColor,
    Color? shadowColor,
    double elevation = 4.0,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    bool useMaterial3 = true,
    ColorScheme? colorScheme,
  }) {
    // Set defaults based on Material Design 3
    final effectiveSurfaceColor = surfaceColor ?? backgroundColor;
    final effectiveOnSurfaceColor = onSurfaceColor ??
        (backgroundColor.computeLuminance() > 0.5 ? Colors.black87 : Colors.white);
    final effectivePrimaryColor = primaryColor ?? presetButtonColor;
    final effectiveSecondaryColor = secondaryColor ?? sliderTrackColor;
    final effectiveErrorColor = errorColor ?? Colors.red.shade600;
    final effectiveShadowColor = shadowColor ?? Colors.black.withOpacity(0.2);
    final effectiveBorderRadius = borderRadius ?? BorderRadius.circular(12.0);
    final effectiveTextStyle = textStyle ?? const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    // Pre-calculate hash code for performance
    final hashCode = Object.hash(
      backgroundColor,
      borderColor,
      borderWidth,
      indicatorColor,
      sliderTrackColor,
      presetButtonColor,
      presetButtonSize,
      effectiveSurfaceColor,
      effectiveOnSurfaceColor,
      effectivePrimaryColor,
      effectiveSecondaryColor,
      effectiveErrorColor,
      effectiveShadowColor,
      elevation,
      effectiveBorderRadius,
      effectiveTextStyle,
      useMaterial3,
      colorScheme,
    );

    return ColorPickerTheme._(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      indicatorColor: indicatorColor,
      sliderTrackColor: sliderTrackColor,
      presetButtonColor: presetButtonColor,
      presetButtonSize: presetButtonSize,
      surfaceColor: effectiveSurfaceColor,
      onSurfaceColor: effectiveOnSurfaceColor,
      primaryColor: effectivePrimaryColor,
      secondaryColor: effectiveSecondaryColor,
      errorColor: effectiveErrorColor,
      shadowColor: effectiveShadowColor,
      elevation: elevation,
      borderRadius: effectiveBorderRadius,
      textStyle: effectiveTextStyle,
      useMaterial3: useMaterial3,
      colorScheme: colorScheme,
      hashCode: hashCode,
    );
  }

  /// Copy with updated values - optimized to avoid unnecessary allocations
  ColorPickerTheme copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    Color? indicatorColor,
    Color? sliderTrackColor,
    Color? presetButtonColor,
    double? presetButtonSize,
    Color? surfaceColor,
    Color? onSurfaceColor,
    Color? primaryColor,
    Color? secondaryColor,
    Color? errorColor,
    Color? shadowColor,
    double? elevation,
    BorderRadius? borderRadius,
    TextStyle? textStyle,
    bool? useMaterial3,
    ColorScheme? colorScheme,
  }) {
    // Return same instance if no changes
    if (backgroundColor == null &&
        borderColor == null &&
        borderWidth == null &&
        indicatorColor == null &&
        sliderTrackColor == null &&
        presetButtonColor == null &&
        presetButtonSize == null &&
        surfaceColor == null &&
        onSurfaceColor == null &&
        primaryColor == null &&
        secondaryColor == null &&
        errorColor == null &&
        shadowColor == null &&
        elevation == null &&
        borderRadius == null &&
        textStyle == null &&
        useMaterial3 == null &&
        colorScheme == null) {
      return this;
    }

    return ColorPickerTheme(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      indicatorColor: indicatorColor ?? this.indicatorColor,
      sliderTrackColor: sliderTrackColor ?? this.sliderTrackColor,
      presetButtonColor: presetButtonColor ?? this.presetButtonColor,
      presetButtonSize: presetButtonSize ?? this.presetButtonSize,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      onSurfaceColor: onSurfaceColor ?? this.onSurfaceColor,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      errorColor: errorColor ?? this.errorColor,
      shadowColor: shadowColor ?? this.shadowColor,
      elevation: elevation ?? this.elevation,
      borderRadius: borderRadius ?? this.borderRadius,
      textStyle: textStyle ?? this.textStyle,
      useMaterial3: useMaterial3 ?? this.useMaterial3,
      colorScheme: colorScheme ?? this.colorScheme,
    );
  }

  /// Convert theme to a map for JSON storage
  Map<String, dynamic> toMap() {
    return {
      'backgroundColor': backgroundColor.value,
      'borderColor': borderColor.value,
      'borderWidth': borderWidth,
      'indicatorColor': indicatorColor.value,
      'sliderTrackColor': sliderTrackColor.value,
      'presetButtonColor': presetButtonColor.value,
      'presetButtonSize': presetButtonSize,
      'surfaceColor': surfaceColor.value,
      'onSurfaceColor': onSurfaceColor.value,
      'primaryColor': primaryColor.value,
      'secondaryColor': secondaryColor.value,
      'errorColor': errorColor.value,
      'shadowColor': shadowColor.value,
      'elevation': elevation,
      'borderRadius': {
        'topLeft': borderRadius.topLeft.x,
        'topRight': borderRadius.topRight.x,
        'bottomLeft': borderRadius.bottomLeft.x,
        'bottomRight': borderRadius.bottomRight.x,
      },
      'textStyle': {
        'fontSize': textStyle.fontSize,
        'fontWeight': textStyle.fontWeight?.index,
        'color': textStyle.color?.value,
        'fontFamily': textStyle.fontFamily,
      },
      'useMaterial3': useMaterial3,
      'version': '2.0', // Version for migration support
    };
  }

  /// Create theme from stored map with migration support
  factory ColorPickerTheme.fromMap(Map<String, dynamic> map) {
    try {
      // Handle legacy format (version 1.0)
      if (!map.containsKey('version') || map['version'] == '1.0') {
        return _fromLegacyMap(map);
      }

      // Modern format (version 2.0+)
      final borderRadiusMap = map['borderRadius'] as Map<String, dynamic>? ?? {};
      final textStyleMap = map['textStyle'] as Map<String, dynamic>? ?? {};

      return ColorPickerTheme(
        backgroundColor: Color(map['backgroundColor'] ?? Colors.white.value),
        borderColor: Color(map['borderColor'] ?? Colors.black.value),
        borderWidth: (map['borderWidth'] ?? 2.0).toDouble(),
        indicatorColor: Color(map['indicatorColor'] ?? Colors.black.value),
        sliderTrackColor: Color(map['sliderTrackColor'] ?? Colors.grey.value),
        presetButtonColor: Color(map['presetButtonColor'] ?? Colors.blueAccent.value),
        presetButtonSize: (map['presetButtonSize'] ?? 40.0).toDouble(),
        surfaceColor: Color(map['surfaceColor'] ?? Colors.white.value),
        onSurfaceColor: Color(map['onSurfaceColor'] ?? Colors.black87.value),
        primaryColor: Color(map['primaryColor'] ?? Colors.blueAccent.value),
        secondaryColor: Color(map['secondaryColor'] ?? Colors.grey.value),
        errorColor: Color(map['errorColor'] ?? Colors.red.value),
        shadowColor: Color(map['shadowColor'] ?? Colors.black26.value),
        elevation: (map['elevation'] ?? 4.0).toDouble(),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular((borderRadiusMap['topLeft'] ?? 12.0).toDouble()),
          topRight: Radius.circular((borderRadiusMap['topRight'] ?? 12.0).toDouble()),
          bottomLeft: Radius.circular((borderRadiusMap['bottomLeft'] ?? 12.0).toDouble()),
          bottomRight: Radius.circular((borderRadiusMap['bottomRight'] ?? 12.0).toDouble()),
        ),
        textStyle: TextStyle(
          fontSize: (textStyleMap['fontSize'] ?? 14.0).toDouble(),
          fontWeight: textStyleMap['fontWeight'] != null
              ? FontWeight.values[textStyleMap['fontWeight']]
              : FontWeight.w500,
          color: textStyleMap['color'] != null
              ? Color(textStyleMap['color'])
              : null,
          fontFamily: textStyleMap['fontFamily'],
        ),
        useMaterial3: map['useMaterial3'] ?? true,
      );
    } catch (e) {
      debugPrint('Error parsing ColorPickerTheme: $e');
      return ColorPickerTheme.light; // Fallback to default
    }
  }

  /// Handle legacy theme format
  static ColorPickerTheme _fromLegacyMap(Map<String, dynamic> map) {
    return ColorPickerTheme(
      backgroundColor: Color(map['backgroundColor'] ?? Colors.white.value),
      borderColor: Color(map['borderColor'] ?? Colors.black.value),
      borderWidth: (map['borderWidth'] ?? 2.0).toDouble(),
      indicatorColor: Color(map['indicatorColor'] ?? Colors.black.value),
      sliderTrackColor: Color(map['sliderTrackColor'] ?? Colors.grey.value),
      presetButtonColor: Color(map['presetButtonColor'] ?? Colors.blueAccent.value),
      presetButtonSize: (map['presetButtonSize'] ?? 40.0).toDouble(),
    );
  }

  /// Create theme from Flutter's ColorScheme
  factory ColorPickerTheme.fromColorScheme(ColorScheme colorScheme) {
    return ColorPickerTheme(
      backgroundColor: colorScheme.surface,
      borderColor: colorScheme.outline,
      borderWidth: 1.0,
      indicatorColor: colorScheme.onSurface,
      sliderTrackColor: colorScheme.surfaceVariant,
      presetButtonColor: colorScheme.primary,
      surfaceColor: colorScheme.surface,
      onSurfaceColor: colorScheme.onSurface,
      primaryColor: colorScheme.primary,
      secondaryColor: colorScheme.secondary,
      errorColor: colorScheme.error,
      shadowColor: colorScheme.shadow,
      colorScheme: colorScheme,
      useMaterial3: true,
    );
  }

  /// Modern light theme with Material 3 design
  static final ColorPickerTheme light = ColorPickerTheme(
    backgroundColor: const Color(0xFFFFFBFE),
    borderColor: const Color(0xFF79747E),
    borderWidth: 1.0,
    indicatorColor: const Color(0xFF1D1B20),
    sliderTrackColor: const Color(0xFFE7E0EC),
    presetButtonColor: const Color(0xFF6750A4),
    surfaceColor: const Color(0xFFFFFBFE),
    onSurfaceColor: const Color(0xFF1D1B20),
    primaryColor: const Color(0xFF6750A4),
    secondaryColor: const Color(0xFF625B71),
    errorColor: const Color(0xFFBA1A1A),
    shadowColor: const Color(0xFF000000),
    elevation: 3.0,
    borderRadius: BorderRadius.circular(12.0),
    useMaterial3: true,
  );

  /// Modern dark theme with Material 3 design
  static final ColorPickerTheme dark = ColorPickerTheme(
    backgroundColor: const Color(0xFF141218),
    borderColor: const Color(0xFF938F99),
    borderWidth: 1.0,
    indicatorColor: const Color(0xFFE6E0E9),
    sliderTrackColor: const Color(0xFF49454F),
    presetButtonColor: const Color(0xFFD0BCFF),
    surfaceColor: const Color(0xFF141218),
    onSurfaceColor: const Color(0xFFE6E0E9),
    primaryColor: const Color(0xFFD0BCFF),
    secondaryColor: const Color(0xFFCCC2DC),
    errorColor: const Color(0xFFFFB4AB),
    shadowColor: const Color(0xFF000000),
    elevation: 3.0,
    borderRadius: BorderRadius.circular(12.0),
    useMaterial3: true,
  );

  /// High contrast light theme for accessibility
  static final ColorPickerTheme highContrastLight = ColorPickerTheme(
    backgroundColor: Colors.white,
    borderColor: Colors.black,
    borderWidth: 2.0,
    indicatorColor: Colors.black,
    sliderTrackColor: const Color(0xFFE0E0E0),
    presetButtonColor: const Color(0xFF0000FF),
    surfaceColor: Colors.white,
    onSurfaceColor: Colors.black,
    primaryColor: const Color(0xFF0000FF),
    secondaryColor: const Color(0xFF666666),
    errorColor: const Color(0xFFCC0000),
    shadowColor: Colors.black,
    elevation: 6.0,
    useMaterial3: true,
  );

  /// High contrast dark theme for accessibility
  static final ColorPickerTheme highContrastDark = ColorPickerTheme(
    backgroundColor: Colors.black,
    borderColor: Colors.white,
    borderWidth: 2.0,
    indicatorColor: Colors.white,
    sliderTrackColor: const Color(0xFF404040),
    presetButtonColor: const Color(0xFF66B3FF),
    surfaceColor: Colors.black,
    onSurfaceColor: Colors.white,
    primaryColor: const Color(0xFF66B3FF),
    secondaryColor: const Color(0xFFCCCCCC),
    errorColor: const Color(0xFFFF6666),
    shadowColor: Colors.white,
    elevation: 6.0,
    useMaterial3: true,
  );

  /// Validate theme values for consistency
  bool isValid() {
    try {
      return borderWidth >= 0 &&
          presetButtonSize > 0 &&
          elevation >= 0 &&
          textStyle.fontSize != null &&
          textStyle.fontSize! > 0;
    } catch (e) {
      return false;
    }
  }

  /// Get a validated copy of the theme
  ColorPickerTheme validated() {
    if (isValid()) return this;

    return copyWith(
      borderWidth: borderWidth < 0 ? 1.0 : borderWidth,
      presetButtonSize: presetButtonSize <= 0 ? 40.0 : presetButtonSize,
      elevation: elevation < 0 ? 3.0 : elevation,
      textStyle: textStyle.fontSize == null || textStyle.fontSize! <= 0
          ? textStyle.copyWith(fontSize: 14.0)
          : textStyle,
    );
  }

  /// Check if theme is suitable for the given brightness
  bool isSuitableForBrightness(Brightness brightness) {
    final bgLuminance = backgroundColor.computeLuminance();
    return brightness == Brightness.light
        ? bgLuminance > 0.5
        : bgLuminance <= 0.5;
  }

  /// Get theme optimized for specific brightness
  ColorPickerTheme optimizedFor(Brightness brightness) {
    if (isSuitableForBrightness(brightness)) return this;
    return brightness == Brightness.light ? light : dark;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! ColorPickerTheme) return false;
    return _hashCode == other._hashCode;
  }

  @override
  int get hashCode => _hashCode;

  @override
  String toString() {
    return 'ColorPickerTheme('
        'backgroundColor: $backgroundColor, '
        'primaryColor: $primaryColor, '
        'useMaterial3: $useMaterial3, '
        'elevation: $elevation)';
  }
}
