import 'dart:ui';
import 'package:flutter/material.dart';
import '../mode/synaptix_mode.dart';
import '../../game/models/skill_tree_graph.dart';

enum SynaptixHapticIntensity { soft, standard, energetic }
enum SynaptixSoundStyle { bouncy, digital, minimalist }

/// Mapping of semantic icon roles to specific IconData.
class IconProfile {
  final IconData success;
  final IconData challenge;
  final IconData settings;
  final IconData profile;
  final IconData leaderboard;
  final IconData quiz;
  final IconData powerUp;
  final IconData alert;

  const IconProfile({
    required this.success,
    required this.challenge,
    required this.settings,
    required this.profile,
    required this.leaderboard,
    required this.quiz,
    required this.powerUp,
    required this.alert,
  });

  static IconProfile lerp(IconProfile? a, IconProfile? b, double t) {
    // Icons don't lerp, so we just switch at the threshold.
    return t < 0.5 ? (a ?? teenIcons) : (b ?? teenIcons);
  }

  static const kidsIcons = IconProfile(
    success: Icons.star_rounded,
    challenge: Icons.workspace_premium_rounded,
    settings: Icons.settings_suggest_rounded,
    profile: Icons.face_rounded,
    leaderboard: Icons.emoji_events_rounded,
    quiz: Icons.lightbulb_rounded,
    powerUp: Icons.bolt_rounded,
    alert: Icons.notification_important_rounded,
  );

  static const teenIcons = IconProfile(
    success: Icons.check_circle_outline,
    challenge: Icons.military_tech_outlined,
    settings: Icons.tune_rounded,
    profile: Icons.account_circle_outlined,
    leaderboard: Icons.query_stats_rounded,
    quiz: Icons.psychology_outlined,
    powerUp: Icons.flash_on_rounded,
    alert: Icons.error_outline_rounded,
  );

  static const adultIcons = IconProfile(
    success: Icons.done_all_rounded,
    challenge: Icons.shield_outlined,
    settings: Icons.settings_applications_outlined,
    profile: Icons.person_outline_rounded,
    leaderboard: Icons.leaderboard_outlined,
    quiz: Icons.menu_book_outlined,
    powerUp: Icons.auto_awesome_outlined,
    alert: Icons.info_outline_rounded,
  );
}

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
  final Curve defaultCurve;
  final Curve snappyCurve;
  final LinearGradient mainBackgroundGradient;
  final Decoration glassOverlay;
  final String headlineFont;
  final String bodyFont;
  final IconProfile icons;
  final List<Color> chartPalette;
  final SynaptixHapticIntensity hapticIntensity;
  final double soundVolumeMultiplier;
  final SynaptixSoundStyle preferredSoundStyle;
  final bool useSoftCorners;
  final double cardRadius;

  const SynaptixTheme({
    required this.primarySurface,
    required this.accentGlow,
    required this.useHighEnergyMotion,
    required this.defaultCurve,
    required this.snappyCurve,
    required this.mainBackgroundGradient,
    required this.glassOverlay,
    required this.headlineFont,
    required this.bodyFont,
    required this.icons,
    required this.chartPalette,
    required this.hapticIntensity,
    required this.soundVolumeMultiplier,
    required this.preferredSoundStyle,
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
    defaultCurve: Curves.elasticOut,
    snappyCurve: Curves.bounceOut,
    mainBackgroundGradient: LinearGradient(
      colors: [Color(0xFFFFF9C4), Color(0xFFFFECB3)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glassOverlay: BoxDecoration(
      color: Color(0xCCFFFFFF),
      borderRadius: BorderRadius.all(Radius.circular(20)),
    ),
    headlineFont: 'OpenSans',
    bodyFont: 'OpenSans',
    icons: IconProfile.kidsIcons,
    chartPalette: [
      Color(0xFFFF5252), // Red
      Color(0xFF448AFF), // Blue
      Color(0xFF4CAF50), // Green
      Color(0xFFFFEB3B), // Yellow
    ],
    hapticIntensity: SynaptixHapticIntensity.energetic,
    soundVolumeMultiplier: 1.0,
    preferredSoundStyle: SynaptixSoundStyle.bouncy,
    useSoftCorners: true,
    cardRadius: 20,
  );

  /// Teen: dark navy, neon cyan accent, high-energy motion.
  static const teenPreset = SynaptixTheme(
    primarySurface: Color(0xFF0D1B2A),
    accentGlow: Color(0xFF00E5FF),
    useHighEnergyMotion: true,
    defaultCurve: Curves.easeOutBack,
    snappyCurve: Curves.easeOutCubic,
    mainBackgroundGradient: LinearGradient(
      colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glassOverlay: BoxDecoration(
      color: Color(0x3300E5FF),
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
    headlineFont: 'OpenSans',
    bodyFont: 'OpenSans',
    icons: IconProfile.teenIcons,
    chartPalette: [
      Color(0xFF00E5FF), // Neon Cyan
      Color(0xFFFF00E5), // Neon Pink
      Color(0xFFB0FF00), // Neon Lime
      Color(0xFF7000FF), // Neon Purple
    ],
    hapticIntensity: SynaptixHapticIntensity.standard,
    soundVolumeMultiplier: 0.9,
    preferredSoundStyle: SynaptixSoundStyle.digital,
    useSoftCorners: false,
    cardRadius: 14,
  );

  /// Adult: charcoal, muted teal accent, restrained motion.
  static const adultPreset = SynaptixTheme(
    primarySurface: Color(0xFF2D2D2D),
    accentGlow: Color(0xFF80CBC4),
    useHighEnergyMotion: false,
    defaultCurve: Curves.easeInOutCubic,
    snappyCurve: Curves.easeOutQuad,
    mainBackgroundGradient: LinearGradient(
      colors: [Color(0xFF2D2D2D), Color(0xFF1B1B1B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    glassOverlay: BoxDecoration(
      color: Color(0x1A80CBC4),
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
    headlineFont: 'Faustina',
    bodyFont: 'OpenSans',
    icons: IconProfile.adultIcons,
    chartPalette: [
      Color(0xFF455A64), // Blue Grey
      Color(0xFF80CBC4), // Muted Teal
      Color(0xFF90A4AE), // Muted Blue
      Color(0xFFB0BEC5), // Light Muted Blue
    ],
    hapticIntensity: SynaptixHapticIntensity.soft,
    soundVolumeMultiplier: 0.7,
    preferredSoundStyle: SynaptixSoundStyle.minimalist,
    useSoftCorners: false,
    cardRadius: 12,
  );

  @override
  SynaptixTheme copyWith({
    Color? primarySurface,
    Color? accentGlow,
    bool? useHighEnergyMotion,
    Curve? defaultCurve,
    Curve? snappyCurve,
    LinearGradient? mainBackgroundGradient,
    Decoration? glassOverlay,
    String? headlineFont,
    String? bodyFont,
    IconProfile? icons,
    List<Color>? chartPalette,
    SynaptixHapticIntensity? hapticIntensity,
    double? soundVolumeMultiplier,
    SynaptixSoundStyle? preferredSoundStyle,
    bool? useSoftCorners,
    double? cardRadius,
  }) {
    return SynaptixTheme(
      primarySurface: primarySurface ?? this.primarySurface,
      accentGlow: accentGlow ?? this.accentGlow,
      useHighEnergyMotion: useHighEnergyMotion ?? this.useHighEnergyMotion,
      defaultCurve: defaultCurve ?? this.defaultCurve,
      snappyCurve: snappyCurve ?? this.snappyCurve,
      mainBackgroundGradient:
          mainBackgroundGradient ?? this.mainBackgroundGradient,
      glassOverlay: glassOverlay ?? this.glassOverlay,
      headlineFont: headlineFont ?? this.headlineFont,
      bodyFont: bodyFont ?? this.bodyFont,
      icons: icons ?? this.icons,
      chartPalette: chartPalette ?? this.chartPalette,
      hapticIntensity: hapticIntensity ?? this.hapticIntensity,
      soundVolumeMultiplier:
          soundVolumeMultiplier ?? this.soundVolumeMultiplier,
      preferredSoundStyle: preferredSoundStyle ?? this.preferredSoundStyle,
      useSoftCorners: useSoftCorners ?? this.useSoftCorners,
      cardRadius: cardRadius ?? this.cardRadius,
    );
  }

  /// Resolve a category color based on the current mode's accent intensity.
  Color skillNodeColor(SkillCategory category) {
    // Base colors from the design system
    final baseColor = switch (category) {
      SkillCategory.scholar => const Color(0xFF3B5B8C),
      SkillCategory.strategist => const Color(0xFF8C3B5B),
      SkillCategory.xp => const Color(0xFF3B8C5B),
      SkillCategory.timer => const Color(0xFF5B3B8C),
      SkillCategory.combo => const Color(0xFF8C6B3B),
      SkillCategory.risk => const Color(0xFF8C3B3B),
      SkillCategory.luck => const Color(0xFF3B8C8C),
      SkillCategory.elite => const Color(0xFF5B5B3B),
      SkillCategory.stealth => const Color(0xFF3B3B5B),
      SkillCategory.combat => const Color(0xFF7C3B3B),
      SkillCategory.knowledge => const Color(0xFF3B5B7C),
      SkillCategory.wildcard => const Color(0xFF6B3B7C),
      SkillCategory.category => const Color(0xFF3B7C5B),
      _ => const Color(0xFF4A4A4A),
    };

    // Tint the base color slightly towards the accent glow of the mode
    return Color.lerp(baseColor, accentGlow, 0.15)!;
  }

  /// Resolve a surface-aware glass tint.
  Color glassColor({double opacity = 0.1}) {
    return Colors.white.withValues(alpha: opacity);
  }

  @override
  SynaptixTheme lerp(SynaptixTheme? other, double t) {
    if (other == null) return this;
    return SynaptixTheme(
      primarySurface: Color.lerp(primarySurface, other.primarySurface, t)!,
      accentGlow: Color.lerp(accentGlow, other.accentGlow, t)!,
      useHighEnergyMotion:
          t < 0.5 ? useHighEnergyMotion : other.useHighEnergyMotion,
      defaultCurve: t < 0.5 ? defaultCurve : other.defaultCurve,
      snappyCurve: t < 0.5 ? snappyCurve : other.snappyCurve,
      mainBackgroundGradient:
          LinearGradient.lerp(mainBackgroundGradient, other.mainBackgroundGradient, t)!,
      glassOverlay: Decoration.lerp(glassOverlay, other.glassOverlay, t)!,
      headlineFont: t < 0.5 ? headlineFont : other.headlineFont,
      bodyFont: t < 0.5 ? bodyFont : other.bodyFont,
      icons: IconProfile.lerp(icons, other.icons, t),
      chartPalette: t < 0.5 ? chartPalette : other.chartPalette,
      hapticIntensity: t < 0.5 ? hapticIntensity : other.hapticIntensity,
      soundVolumeMultiplier:
          lerpDouble(soundVolumeMultiplier, other.soundVolumeMultiplier, t)!,
      preferredSoundStyle:
          t < 0.5 ? preferredSoundStyle : other.preferredSoundStyle,
      useSoftCorners: t < 0.5 ? useSoftCorners : other.useSoftCorners,
      cardRadius: lerpDouble(cardRadius, other.cardRadius, t)!,
    );
  }
}
