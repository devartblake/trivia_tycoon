import 'package:flutter/material.dart';

/// Match data model
class MatchData {
  final String name;
  final String? score;
  final String status;
  final String? avatarUrl;

  const MatchData({
    required this.name,
    this.score,
    required this.status,
    this.avatarUrl,
  });

  factory MatchData.fromJson(Map<String, dynamic> json) {
    return MatchData(
      name: json['name'] as String,
      score: json['score'] as String?,
      status: json['status'] as String,
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'score': score,
      'status': status,
      'avatarUrl': avatarUrl,
    };
  }
}

/// Action button data model
class ActionData {
  final String label;
  final IconData icon;
  final String route;
  final String description;
  final int? badge;
  final LinearGradient gradient;

  const ActionData({
    required this.label,
    required this.icon,
    required this.route,
    required this.description,
    this.badge,
    required this.gradient,
  });
}

/// Currency data model
class CurrencyData {
  final String name;
  final int value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final bool isLow;

  const CurrencyData({
    required this.name,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    this.isLow = false,
  });
}

/// Journey progress data model
class JourneyData {
  final int currentXP;
  final int maxXP;
  final int level;
  final String? nextReward;

  const JourneyData({
    required this.currentXP,
    required this.maxXP,
    required this.level,
    this.nextReward,
  });

  double get progress => (currentXP / maxXP).clamp(0.0, 1.0);
  int get percentage => (progress * 100).toInt();
}

/// Recently played game data
class RecentGameData {
  final String title;
  final String? category;
  final int? score;
  final DateTime playedAt;
  final String? imageUrl;

  const RecentGameData({
    required this.title,
    this.category,
    this.score,
    required this.playedAt,
    this.imageUrl,
  });
}

/// User profile summary for menu
class MenuProfileData {
  final String name;
  final String? avatarUrl;
  final int level;
  final int rank;
  final int coins;
  final int gems;
  final int energy;
  final int maxEnergy;
  final int lives;
  final int maxLives;
  final bool isPremium;

  const MenuProfileData({
    required this.name,
    this.avatarUrl,
    required this.level,
    required this.rank,
    required this.coins,
    required this.gems,
    required this.energy,
    required this.maxEnergy,
    required this.lives,
    required this.maxLives,
    this.isPremium = false,
  });
}
