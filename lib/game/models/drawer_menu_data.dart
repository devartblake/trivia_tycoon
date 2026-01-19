import 'package:flutter/material.dart';

/// Menu item data for gradient-styled menu items
class GradientMenuItem {
  final IconData icon;
  final String title;
  final String route;
  final LinearGradient gradient;

  const GradientMenuItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.gradient,
  });

  factory GradientMenuItem.fromMap(Map<String, dynamic> map) {
    return GradientMenuItem(
      icon: map['icon'] as IconData,
      title: map['title'] as String,
      route: map['route'] as String,
      gradient: map['gradient'] as LinearGradient,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'icon': icon,
      'title': title,
      'route': route,
      'gradient': gradient,
    };
  }
}

/// Menu item data for simple-styled menu items
class SimpleMenuItem {
  final IconData icon;
  final String title;
  final String route;
  final Color color;

  const SimpleMenuItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.color,
  });

  factory SimpleMenuItem.fromMap(Map<String, dynamic> map) {
    return SimpleMenuItem(
      icon: map['icon'] as IconData,
      title: map['title'] as String,
      route: map['route'] as String,
      color: map['color'] as Color,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'icon': icon,
      'title': title,
      'route': route,
      'color': color,
    };
  }
}

/// Profile stats data for drawer header
class ProfileStats {
  final int level;
  final int currentXP;
  final bool isPremium;

  const ProfileStats({
    required this.level,
    required this.currentXP,
    required this.isPremium,
  });

  factory ProfileStats.fromMap(Map<String, dynamic> map) {
    return ProfileStats(
      level: map['level'] as int? ?? 1,
      currentXP: map['currentXP'] as int? ?? 0,
      isPremium: map['isPremium'] as bool? ?? false,
    );
  }
}
