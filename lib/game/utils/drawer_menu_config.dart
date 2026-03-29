import 'package:flutter/material.dart';
import '../models/drawer_menu_data.dart';

/// Configuration for drawer menu items
class DrawerMenuConfig {
  /// Main navigation menu items with gradient styling
  static List<GradientMenuItem> get mainMenuItems => [
    const GradientMenuItem(
      icon: Icons.home_rounded,
      title: 'Home',
      route: '/',
      gradient: LinearGradient(
        colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
      ),
    ),
    const GradientMenuItem(
      icon: Icons.message_rounded,
      title: 'Messages',
      route: '/messages',
      gradient: LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      ),
    ),
    const GradientMenuItem(
      icon: Icons.quiz_rounded,
      title: 'Quiz',
      route: '/quiz',
      gradient: LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
      ),
    ),
    const GradientMenuItem(
      icon: Icons.games_rounded,
      title: 'Labs Challenges',
      route: '/mini-games',
      gradient: LinearGradient(
        colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
      ),
    ),
    const GradientMenuItem(
      icon: Icons.psychology_rounded,
      title: 'Pathways',
      route: '/skills',
      gradient: LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      ),
    ),
    const GradientMenuItem(
      icon: Icons.gamepad_rounded,
      title: 'Multiplayer',
      route: '/multiplayer',
      gradient: LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
      ),
    ),
    const GradientMenuItem(
      icon: Icons.leaderboard_rounded,
      title: 'Arena',
      route: '/leaderboard',
      gradient: LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      ),
    ),
  ];

  /// Additional feature menu items
  static List<SimpleMenuItem> get moreMenuItems => [
    const SimpleMenuItem(
      icon: Icons.telegram_rounded,
      title: 'Missions',
      route: '/missions',
      color: Color(0x9670FF1B),
    ),
  ];

  /// Bottom utility menu items
  static List<SimpleMenuItem> get bottomMenuItems => [
    const SimpleMenuItem(
      icon: Icons.admin_panel_settings_rounded,
      title: 'Administrator',
      route: '/admin',
      color: Color(0xFFEF4444),
    ),
    const SimpleMenuItem(
      icon: Icons.settings_rounded,
      title: 'Settings',
      route: '/settings',
      color: Color(0xFF64748B),
    ),
    const SimpleMenuItem(
      icon: Icons.help_outline_rounded,
      title: 'Help & Feedback',
      route: '/help',
      color: Color(0xFFF59E0B),
    ),
    const SimpleMenuItem(
      icon: Icons.report_rounded,
      title: 'Report',
      route: '/report',
      color: Color(0xFF8B5CF6),
    ),
  ];

  /// Header gradient colors
  static const LinearGradient headerGradient = LinearGradient(
    colors: [
      Color(0xFF6366F1),
      Color(0xFF8B5CF6),
      Color(0xFFA855F7),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Background gradient colors
  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [
      Color(0xFFF8FAFF),
      Color(0xFFFFFFFF),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  /// Logout button gradient
  static const LinearGradient logoutGradient = LinearGradient(
    colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
  );
}
