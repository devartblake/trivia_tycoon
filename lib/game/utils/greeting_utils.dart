import 'package:flutter/material.dart';

/// Greeting utilities for time-based greetings
class GreetingUtils {
  /// Get time-based greeting text
  static String getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  /// Get greeting icon based on time
  static IconData getGreetingIcon(int hour) {
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_sunny_outlined;
    return Icons.nightlight_round;
  }

  /// Get current greeting text
  static String get currentGreeting {
    final hour = DateTime.now().hour;
    return getGreeting(hour);
  }

  /// Get current greeting icon
  static IconData get currentGreetingIcon {
    final hour = DateTime.now().hour;
    return getGreetingIcon(hour);
  }

  /// Get greeting with user name
  static String getPersonalizedGreeting(String userName) {
    return '${currentGreeting}, $userName!';
  }

  /// Get time period (morning, afternoon, evening, night)
  static String getTimePeriod() {
    final hour = DateTime.now().hour;
    if (hour < 6) return 'night';
    if (hour < 12) return 'morning';
    if (hour < 17) return 'afternoon';
    if (hour < 21) return 'evening';
    return 'night';
  }

  /// Check if it's morning
  static bool get isMorning {
    final hour = DateTime.now().hour;
    return hour >= 6 && hour < 12;
  }

  /// Check if it's afternoon
  static bool get isAfternoon {
    final hour = DateTime.now().hour;
    return hour >= 12 && hour < 17;
  }

  /// Check if it's evening
  static bool get isEvening {
    final hour = DateTime.now().hour;
    return hour >= 17 && hour < 21;
  }

  /// Check if it's night
  static bool get isNight {
    final hour = DateTime.now().hour;
    return hour >= 21 || hour < 6;
  }

  /// Get motivational message based on time
  static String getMotivationalMessage() {
    final period = getTimePeriod();
    switch (period) {
      case 'morning':
        return 'Start your day with a challenge!';
      case 'afternoon':
        return 'Keep the momentum going!';
      case 'evening':
        return 'Wind down with some trivia!';
      case 'night':
        return 'One more round before bed?';
      default:
        return 'Ready to play?';
    }
  }

  /// Get emoji for time period
  static String getTimePeriodEmoji() {
    final period = getTimePeriod();
    switch (period) {
      case 'morning':
        return '🌅';
      case 'afternoon':
        return '☀️';
      case 'evening':
        return '🌇';
      case 'night':
        return '🌙';
      default:
        return '⭐';
    }
  }
}
