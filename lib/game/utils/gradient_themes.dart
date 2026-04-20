import 'package:flutter/material.dart';

/// Gradient theme utilities for MainMenuScreen
/// Provides age-group specific gradients and color schemes
class GradientThemes {
  /// Get gradient for rewards banner based on age group
  static LinearGradient getRewardGradient(String ageGroup) {
    switch (ageGroup) {
      case 'kids':
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'teens':
        return const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'adults':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  /// Get gradient for greeting toast based on age group
  static LinearGradient getGreetingGradient(String ageGroup) {
    switch (ageGroup) {
      case 'kids':
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'teens':
        return const LinearGradient(
          colors: [Color(0xCB769CFD), Color(0x863575FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'adults':
        return const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  /// Modern gradient for primary actions
  static LinearGradient get primaryActionGradient => const LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Modern gradient for secondary actions
  static LinearGradient get secondaryActionGradient => const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFFEC4899)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Success gradient (green)
  static LinearGradient get successGradient => const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Warning gradient (amber)
  static LinearGradient get warningGradient => const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Error gradient (red)
  static LinearGradient get errorGradient => const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Get gradient colors list for age group
  static List<Color> getAgeGroupColors(String ageGroup) {
    switch (ageGroup) {
      case 'kids':
        return [const Color(0xFFFF6B6B), const Color(0xFFFF8E53)];
      case 'teens':
        return [const Color(0xFF4ECDC4), const Color(0xFF44A08D)];
      case 'adults':
        return [const Color(0xFF667eea), const Color(0xFF764ba2)];
      default:
        return [const Color(0xFF6366F1), const Color(0xFF8B5CF6)];
    }
  }

  /// Create custom gradient from colors
  static LinearGradient custom(List<Color> colors,
      {AlignmentGeometry begin = Alignment.topLeft,
      AlignmentGeometry end = Alignment.bottomRight}) {
    return LinearGradient(
      colors: colors,
      begin: begin,
      end: end,
    );
  }
}
