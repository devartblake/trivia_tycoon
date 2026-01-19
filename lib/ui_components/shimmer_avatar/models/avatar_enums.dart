import 'package:flutter/material.dart';

/// Avatar online status
enum AvatarStatus {
  online,
  offline,
  away,
  busy,
}

/// Avatar badge type
enum AvatarBadgeType {
  none,
  level,
  notification,
  premium,
}

/// Extension methods for AvatarStatus
extension AvatarStatusExtension on AvatarStatus {
  /// Get the color for the status
  Color getColor() {
    switch (this) {
      case AvatarStatus.online:
        return const Color(0xFF10B981); // Modern green
      case AvatarStatus.offline:
        return const Color(0xFF9CA3AF); // Gray
      case AvatarStatus.away:
        return const Color(0xFFF59E0B); // Amber
      case AvatarStatus.busy:
        return const Color(0xFFEF4444); // Red
    }
  }

  /// Get the gradient colors for status
  List<Color> getGradientColors() {
    switch (this) {
      case AvatarStatus.online:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case AvatarStatus.offline:
        return [const Color(0xFF9CA3AF), const Color(0xFF6B7280)];
      case AvatarStatus.away:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case AvatarStatus.busy:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
    }
  }

  /// Get icon for the status (if applicable)
  IconData? getIcon() {
    switch (this) {
      case AvatarStatus.away:
        return Icons.schedule_rounded;
      case AvatarStatus.busy:
        return Icons.do_not_disturb_rounded;
      default:
        return null;
    }
  }

  /// Get label for the status
  String getLabel() {
    switch (this) {
      case AvatarStatus.online:
        return 'Online';
      case AvatarStatus.offline:
        return 'Offline';
      case AvatarStatus.away:
        return 'Away';
      case AvatarStatus.busy:
        return 'Busy';
    }
  }
}

/// Extension methods for AvatarBadgeType
extension AvatarBadgeTypeExtension on AvatarBadgeType {
  /// Get gradient colors for badge
  List<Color> getGradientColors() {
    switch (this) {
      case AvatarBadgeType.level:
        return [const Color(0xFF3B82F6), const Color(0xFF6366F1)];
      case AvatarBadgeType.notification:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      case AvatarBadgeType.premium:
        return [const Color(0xFFFBBF24), const Color(0xFFF59E0B)];
      case AvatarBadgeType.none:
        return [const Color(0xFF9CA3AF), const Color(0xFF6B7280)];
    }
  }

  /// Get icon for badge type
  IconData? getIcon() {
    switch (this) {
      case AvatarBadgeType.premium:
        return Icons.star_rounded;
      default:
        return null;
    }
  }

  /// Get default content color
  Color getContentColor() {
    return Colors.white;
  }
}
