import 'package:flutter/material.dart';

class TycoonToastThemeManager {
  /// Gets the gradient for a given theme event string
  static LinearGradient getGradientForEvent(String themeEvent) {
    switch (themeEvent.toLowerCase()) {
      case 'spring':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF9A9E),
            Color(0xFFFECAE8),
            Color(0xFFA8E6CF),
          ],
          stops: [0.0, 0.5, 1.0],
        );

      case 'summer':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD89B),
            Color(0xFF19547B),
          ],
        );

      case 'autumn':
      case 'fall':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFD66D75),
            Color(0xFFE29587),
            Color(0xFFFFB347),
          ],
          stops: [0.0, 0.6, 1.0],
        );

      case 'winter':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF74B9FF),
            Color(0xFF0984E3),
            Color(0xFF6C5CE7),
          ],
          stops: [0.0, 0.7, 1.0],
        );

      case 'halloween':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8E44AD),
            Color(0xFFE67E22),
            Color(0xFF2C3E50),
          ],
          stops: [0.0, 0.5, 1.0],
        );

      case 'holiday':
      case 'christmas':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE74C3C),
            Color(0xFF27AE60),
            Color(0xFFFFD700),
          ],
          stops: [0.0, 0.6, 1.0],
        );

      case 'neon':
      case 'cyberpunk':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00F5FF),
            Color(0xFF8A2BE2),
            Color(0xFFFF1493),
          ],
          stops: [0.0, 0.5, 1.0],
        );

      case 'sunset':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF7B7B),
            Color(0xFFFF8E53),
            Color(0xFFFF6B35),
          ],
        );

      case 'ocean':
      case 'aqua':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF667EEA),
            Color(0xFF764BA2),
          ],
        );

      case 'forest':
      case 'nature':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF11998E),
            Color(0xFF38EF7D),
          ],
        );

      case 'galaxy':
      case 'space':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF4CA1AF),
            Color(0xFF8E44AD),
          ],
          stops: [0.0, 0.5, 1.0],
        );

      case 'fire':
      case 'flame':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF4B1F),
            Color(0xFFFF9068),
          ],
        );

      case 'ice':
      case 'frost':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE0EAFC),
            Color(0xFFCFDEF3),
          ],
        );

      case 'royal':
      case 'luxury':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8E2DE2),
            Color(0xFF4A00E0),
          ],
        );

      case 'pastel':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFB6C1),
            Color(0xFFFFF0F5),
            Color(0xFFE6E6FA),
          ],
          stops: [0.0, 0.5, 1.0],
        );

      case 'dark':
      case 'night':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF34495E),
          ],
        );

      case 'rainbow':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6B6B),
            Color(0xFFFFE66D),
            Color(0xFF4ECDC4),
            Color(0xFF45B7D1),
            Color(0xFF96CEB4),
            Color(0xFFDDA0DD),
          ],
          stops: [0.0, 0.2, 0.4, 0.6, 0.8, 1.0],
        );

      case 'reward':
      case 'gold':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFA500),
            Color(0xFFFF6347),
          ],
          stops: [0.0, 0.6, 1.0],
        );

      case 'success':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00B894),
            Color(0xFF00CEC9),
          ],
        );

      case 'error':
      case 'danger':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFE17055),
            Color(0xFFD63031),
          ],
        );

      case 'warning':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFDCB6E),
            Color(0xFFE17055),
          ],
        );

      case 'info':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF74B9FF),
            Color(0xFF0984E3),
          ],
        );

      default:
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF636E72),
            Color(0xFF2D3436),
          ],
        );
    }
  }

  /// Gets predefined theme colors for specific reward types
  static LinearGradient getRewardTheme(String rewardType) {
    switch (rewardType.toLowerCase()) {
      case 'coins':
      case 'money':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFFD700),
            Color(0xFFFFA500),
          ],
        );

      case 'gems':
      case 'diamonds':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF74B9FF),
            Color(0xFF0984E3),
            Color(0xFF6C5CE7),
          ],
          stops: [0.0, 0.5, 1.0],
        );

      case 'spins':
      case 'casino':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF8E44AD),
            Color(0xFF9B59B6),
            Color(0xFFE91E63),
          ],
          stops: [0.0, 0.6, 1.0],
        );

      case 'boost':
      case 'power':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFFFF6348),
            Color(0xFFFF7675),
          ],
        );

      case 'mystery':
      case 'unknown':
        return LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2D3436),
            Color(0xFF636E72),
            Color(0xFF8E44AD),
          ],
          stops: [0.0, 0.7, 1.0],
        );

      default:
        return getGradientForEvent('reward');
    }
  }

  /// Gets a theme based on the current time of day
  static LinearGradient getTimeBasedTheme() {
    final hour = DateTime.now().hour;

    if (hour >= 6 && hour < 12) {
      // Morning
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFD89B),
          Color(0xFFFFADB0),
        ],
      );
    } else if (hour >= 12 && hour < 17) {
      // Afternoon
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF74B9FF),
          Color(0xFF0984E3),
        ],
      );
    } else if (hour >= 17 && hour < 20) {
      // Evening
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFF7B7B),
          Color(0xFFFF8E53),
        ],
      );
    } else {
      // Night
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF2C3E50),
          Color(0xFF4CA1AF),
        ],
      );
    }
  }

  /// Gets a seasonal theme based on current date
  static LinearGradient getSeasonalTheme() {
    final month = DateTime.now().month;

    if (month >= 3 && month <= 5) {
      return getGradientForEvent('spring');
    } else if (month >= 6 && month <= 8) {
      return getGradientForEvent('summer');
    } else if (month >= 9 && month <= 11) {
      return getGradientForEvent('autumn');
    } else {
      return getGradientForEvent('winter');
    }
  }

  /// Gets available theme names for UI selection
  static List<String> getAvailableThemes() {
    return [
      'spring', 'summer', 'autumn', 'winter',
      'halloween', 'holiday', 'neon', 'sunset',
      'ocean', 'forest', 'galaxy', 'fire',
      'ice', 'royal', 'pastel', 'dark',
      'rainbow', 'reward', 'success', 'error',
      'warning', 'info'
    ];
  }
}