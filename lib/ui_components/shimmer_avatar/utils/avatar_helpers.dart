import 'dart:io';
import 'package:flutter/material.dart';

/// Avatar helper utilities
class AvatarHelpers {
  /// Get modern gradient border colors
  static List<Color> getGradientBorderColors() {
    return [
      const Color(0xFF6366F1),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
    ];
  }

  /// Get modern shadow for avatar
  static List<BoxShadow> getModernShadow({
    Color? color,
    double blurRadius = 12,
    double spreadRadius = 0,
    Offset offset = const Offset(0, 4),
  }) {
    final shadowColor = color ?? Colors.black.withOpacity(0.15);
    return [
      BoxShadow(
        color: shadowColor,
        blurRadius: blurRadius,
        spreadRadius: spreadRadius,
        offset: offset,
      ),
      BoxShadow(
        color: shadowColor.withOpacity(0.1),
        blurRadius: blurRadius * 1.5,
        spreadRadius: spreadRadius,
        offset: Offset(offset.dx, offset.dy + 2),
      ),
    ];
  }

  /// Get gradient shadow colors for glow effect
  static List<BoxShadow> getGradientGlow({
    List<Color>? colors,
    double blurRadius = 20,
  }) {
    final glowColors = colors ?? getGradientBorderColors();
    return [
      BoxShadow(
        color: glowColors.first.withOpacity(0.3),
        blurRadius: blurRadius,
        spreadRadius: -2,
        offset: const Offset(-2, -2),
      ),
      BoxShadow(
        color: glowColors.last.withOpacity(0.3),
        blurRadius: blurRadius,
        spreadRadius: -2,
        offset: const Offset(2, 2),
      ),
    ];
  }

  /// Calculate responsive sizes based on radius
  static double getBadgeSize(double radius) => radius * 0.4;
  static double getStatusSize(double radius) => radius * 0.35;
  static double getBorderWidth(double radius) => radius * 0.08;

  /// Check if image path is valid
  static bool isValidImagePath(String? path) {
    if (path == null || path.isEmpty) return false;
    return path.startsWith('assets/') ||
        path.startsWith('http') ||
        File(path).existsSync();
  }
}
