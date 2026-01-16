import 'package:flutter/material.dart';

/// Theme configuration for ProfileAvatar widgets
///
/// Provides default styling for all descendant [ProfileAvatar] widgets.
/// This follows Material Design 3 theming patterns and allows for
/// consistent avatar styling across the application.
class ProfileAvatarTheme extends InheritedWidget {
  const ProfileAvatarTheme({
    super.key,
    required super.child,
    this.initialTextStyle,
    this.decoration,
    this.statusIndicatorSize,
    this.badgeSize,
    this.badgeDecoration,
    this.animationDuration,
    this.animationCurve,
    this.shimmerBaseColor,
    this.shimmerHighlightColor,
    this.defaultGradient,
    this.glowEnabled,
    this.glowColor,
    this.glowRadius,
  });

  /// Text style for avatar initials
  final TextStyle? initialTextStyle;

  /// Default decoration for avatars
  final BoxDecoration? decoration;

  /// Default status indicator size
  final double? statusIndicatorSize;

  /// Default badge size
  final double? badgeSize;

  /// Default badge decoration
  final BoxDecoration? badgeDecoration;

  /// Default animation duration
  final Duration? animationDuration;

  /// Default animation curve
  final Curve? animationCurve;

  /// Shimmer effect base color
  final Color? shimmerBaseColor;

  /// Shimmer effect highlight color
  final Color? shimmerHighlightColor;

  /// Default gradient for avatars
  final Gradient? defaultGradient;

  /// Whether to enable glow effect by default
  final bool? glowEnabled;

  /// Default glow color
  final Color? glowColor;

  /// Default glow radius
  final double? glowRadius;

  /// Retrieves the nearest [ProfileAvatarTheme] ancestor
  static ProfileAvatarTheme? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ProfileAvatarTheme>();
  }

  /// Creates a theme with Material 3 defaults
  ///
  /// Uses the provided [colorScheme] to generate appropriate colors
  /// for avatars that match the app's overall theme.
  static ProfileAvatarTheme material3({
    required Widget child,
    required ColorScheme colorScheme,
    TextStyle? textStyle,
    double statusIndicatorSize = 12.0,
    double badgeSize = 16.0,
    Duration animationDuration = const Duration(milliseconds: 300),
    Curve animationCurve = Curves.easeInOut,
  }) {
    return ProfileAvatarTheme(
      initialTextStyle: textStyle ??
          TextStyle(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimaryContainer,
            letterSpacing: 0.5,
          ),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.primaryContainer,
            colorScheme.secondaryContainer,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      statusIndicatorSize: statusIndicatorSize,
      badgeSize: badgeSize,
      badgeDecoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.error,
        border: Border.all(
          color: colorScheme.surface,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withOpacity(0.2),
            blurRadius: 4,
          ),
        ],
      ),
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      shimmerBaseColor: colorScheme.surfaceContainerHighest,
      shimmerHighlightColor: colorScheme.surface,
      defaultGradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.primary,
          colorScheme.secondary,
        ],
      ),
      child: child,
    );
  }

  /// Creates a theme with custom gradient
  static ProfileAvatarTheme gradient({
    required Widget child,
    required List<Color> colors,
    AlignmentGeometry begin = Alignment.topLeft,
    AlignmentGeometry end = Alignment.bottomRight,
    TextStyle? textStyle,
  }) {
    return ProfileAvatarTheme(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: begin,
          end: end,
          colors: colors,
        ),
      ),
      initialTextStyle: textStyle,
      child: child,
    );
  }

  @override
  bool updateShouldNotify(ProfileAvatarTheme oldWidget) {
    return initialTextStyle != oldWidget.initialTextStyle ||
        decoration != oldWidget.decoration ||
        statusIndicatorSize != oldWidget.statusIndicatorSize ||
        badgeSize != oldWidget.badgeSize ||
        badgeDecoration != oldWidget.badgeDecoration ||
        animationDuration != oldWidget.animationDuration ||
        animationCurve != oldWidget.animationCurve ||
        shimmerBaseColor != oldWidget.shimmerBaseColor ||
        shimmerHighlightColor != oldWidget.shimmerHighlightColor ||
        defaultGradient != oldWidget.defaultGradient ||
        glowEnabled != oldWidget.glowEnabled ||
        glowColor != oldWidget.glowColor ||
        glowRadius != oldWidget.glowRadius;
  }
}