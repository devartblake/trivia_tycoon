import 'package:flutter/material.dart';
import '../../game/models/menu_enums.dart';

/// Menu helper utilities
class MenuHelpers {
  /// Format number with K/M suffixes
  static String formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  /// Format score display
  static String formatScore(int score) {
    return formatNumber(score);
  }

  /// Check if currency is low
  static bool isCurrencyLow(String currencyType, int current, int max) {
    switch (currencyType.toLowerCase()) {
      case 'coins':
        return current < 100;
      case 'gems':
        return current < 10;
      case 'energy':
        return current < max * 0.3;
      case 'lives':
        return current < max * 0.5;
      default:
        return false;
    }
  }

  /// Get avatar color based on name hash
  static Color getAvatarColor(String name) {
    final colors = [
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Amber
      const Color(0xFF10B981), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
      const Color(0xFFEF4444), // Red
      const Color(0xFF06B6D4), // Cyan
      const Color(0xFFF97316), // Orange
    ];

    final index = name.hashCode.abs() % colors.length;
    return colors[index];
  }

  /// Get initials from name
  static String getInitials(String name, {int maxChars = 2}) {
    if (name.isEmpty) return '?';

    final parts = name.trim().split(' ');
    if (parts.length == 1) {
      return name.substring(0, maxChars.clamp(1, name.length)).toUpperCase();
    }

    return parts
        .take(maxChars)
        .map((part) => part.isNotEmpty ? part[0] : '')
        .join('')
        .toUpperCase();
  }

  /// Calculate XP progress percentage
  static int calculateXPPercentage(int current, int max) {
    if (max == 0) return 0;
    return ((current / max) * 100).clamp(0, 100).toInt();
  }

  /// Get level from XP
  static int getLevelFromXP(int totalXP) {
    // Example: Each level requires 100 * level XP
    // Level 1: 0-100, Level 2: 100-300, Level 3: 300-600, etc.
    int level = 1;
    int requiredXP = 100;
    int accumulatedXP = 0;

    while (accumulatedXP + requiredXP <= totalXP) {
      accumulatedXP += requiredXP;
      level++;
      requiredXP = 100 * level;
    }

    return level;
  }

  /// Get XP required for next level
  static int getXPForNextLevel(int currentLevel) {
    return 100 * currentLevel;
  }

  /// Check if user has enough currency
  static bool hasEnoughCurrency(int current, int required) {
    return current >= required;
  }

  /// Format time ago
  static String formatTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 365) {
      final years = (difference.inDays / 365).floor();
      return '$years year${years > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 30) {
      final months = (difference.inDays / 30).floor();
      return '$months month${months > 1 ? 's' : ''} ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Get match status color
  static Color getMatchStatusColor(MatchStatus status) {
    switch (status) {
      case MatchStatus.yourTurn:
        return const Color(0xFFEF4444); // Red
      case MatchStatus.waiting:
        return const Color(0xFF94A3B8); // Gray
      case MatchStatus.similarStats:
        return const Color(0xFF6366F1); // Blue
      case MatchStatus.fastPlayer:
        return const Color(0xFF10B981); // Green
      case MatchStatus.finished:
        return const Color(0xFF64748B); // Dark gray
    }
  }

  /// Get action button for match status
  static String getMatchActionLabel(MatchStatus status) {
    switch (status) {
      case MatchStatus.yourTurn:
        return 'Play';
      case MatchStatus.waiting:
        return 'View';
      case MatchStatus.similarStats:
      case MatchStatus.fastPlayer:
        return 'Start';
      case MatchStatus.finished:
        return 'Review';
    }
  }

  /// Truncate text with ellipsis
  static String truncateText(String text, int maxLength) {
    if (text.length <= maxLength) return text;
    return '${text.substring(0, maxLength)}...';
  }

  /// Get rank suffix (1st, 2nd, 3rd, etc.)
  static String getRankSuffix(int rank) {
    if (rank % 100 >= 11 && rank % 100 <= 13) {
      return '${rank}th';
    }
    switch (rank % 10) {
      case 1:
        return '${rank}st';
      case 2:
        return '${rank}nd';
      case 3:
        return '${rank}rd';
      default:
        return '${rank}th';
    }
  }

  /// Check if premium feature is accessible
  static bool canAccessPremiumFeature(bool isPremium) {
    return isPremium;
  }

  /// Get energy regeneration time
  static String getEnergyRegenTime(int currentEnergy, int maxEnergy) {
    if (currentEnergy >= maxEnergy) {
      return 'Full';
    }
    final remaining = maxEnergy - currentEnergy;
    final minutes = remaining * 5; // Assuming 5 min per energy
    if (minutes < 60) {
      return '${minutes}m';
    }
    final hours = (minutes / 60).floor();
    final mins = minutes % 60;
    return '${hours}h ${mins}m';
  }

  /// Get layout mode from width
  static LayoutMode getLayoutMode(double width) {
    if (width >= 1024) {
      return LayoutMode.desktop;
    } else if (width >= 768) {
      return LayoutMode.tablet;
    } else {
      return LayoutMode.mobile;
    }
  }

  /// Check if screen is wide
  static bool isWideScreen(double width) {
    return width >= 1024;
  }

  /// Get grid column count based on width
  static int getGridColumnCount(double width) {
    if (width >= 1400) return 4;
    if (width >= 1024) return 3;
    if (width >= 768) return 2;
    return 1;
  }
}
