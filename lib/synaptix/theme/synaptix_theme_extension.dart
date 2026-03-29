import 'dart:ui';
import 'package:flutter/material.dart';
import '../mode/synaptix_mode.dart';

/// Mode-aware theme extension for Synaptix.
///
/// Layered on top of the existing [AppTheme] system via
/// `ThemeData.extensions`. Widgets access it with:
/// ```dart
/// final synaptix = Theme.of(context).extension<SynaptixTheme>();
/// ```
///
/// This is purely additive — the existing AppTheme / ThemeType system
/// remains completely untouched.
class SynaptixTheme extends ThemeExtension<SynaptixTheme> {
  final Color primarySurface;
  final Color accentGlow;
  final bool useHighEnergyMotion;
  final bool useSoftCorners;
  final double cardRadius;

  const SynaptixTheme({
    required this.primarySurface,
    required this.accentGlow,
    required this.useHighEnergyMotion,
    required this.useSoftCorners,
    required this.cardRadius,
  });

  /// Build a preset from the active [SynaptixMode].
  factory SynaptixTheme.fromMode(SynaptixMode mode) {
    switch (mode) {
      case SynaptixMode.kids:
        return kidsPreset;
      case SynaptixMode.teen:
        return teenPreset;
      case SynaptixMode.adult:
        return adultPreset;
    }
  }

  // ---- Presets ----

  /// Kids: bright, soft corners, large radius, high-energy motion.
  static const kidsPreset = SynaptixTheme(
    primarySurface: Color(0xFFFFF3E0),
    accentGlow: Color(0xFFFF9800),
    useHighEnergyMotion: true,
    useSoftCorners: true,
    cardRadius: 20,
  );

  /// Teen: dark navy, neon cyan accent, high-energy motion.
  static const teenPreset = SynaptixTheme(
    primarySurface: Color(0xFF0D1B2A),
    accentGlow: Color(0xFF00E5FF),
    useHighEnergyMotion: true,
    useSoftCorners: false,
    cardRadius: 14,
  );

  /// Adult: charcoal, muted teal accent, restrained motion.
  static const adultPreset = SynaptixTheme(
    primarySurface: Color(0xFF2D2D2D),
    accentGlow: Color(0xFF80CBC4),
    useHighEnergyMotion: false,
    useSoftCorners: false,
    cardRadius: 12,
  );

  @override
  SynaptixTheme copyWith({
    Color? primarySurface,
    Color? accentGlow,
    bool? useHighEnergyMotion,
    bool? useSoftCorners,
    double? cardRadius,
  }) {
    return SynaptixTheme(
      primarySurface: primarySurface ?? this.primarySurface,
      accentGlow: accentGlow ?? this.accentGlow,
      useHighEnergyMotion: useHighEnergyMotion ?? this.useHighEnergyMotion,
      useSoftCorners: useSoftCorners ?? this.useSoftCorners,
      cardRadius: cardRadius ?? this.cardRadius,
    );
  }

  @override
  SynaptixTheme lerp(SynaptixTheme? other, double t) {
    if (other == null) return this;
    return SynaptixTheme(
      primarySurface: Color.lerp(primarySurface, other.primarySurface, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      useHighEnergyMotion:
          t < 0.5 ? useHighEnergyMotion : other.useHighEnergyMotion,
      useSoftCorners: t < 0.5 ? useSoftCorners : other.useSoftCorners,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
    );
  }
}
