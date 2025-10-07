import 'package:flutter/material.dart';

enum ChallengeType { daily, weekly, special }

class Challenge {
  final String id;
  final ChallengeType type;
  final String title;
  final String description;
  final String rewardSummary;
  final IconData icon;
  final double progress;
  final bool completed;

  const Challenge({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.rewardSummary,
    required this.icon,
    required this.progress,
    required this.completed,
  });

  Challenge copyWith({
    double? progress,
    bool? completed,
  }) {
    return Challenge(
      id: id,
      type: type,
      title: title,
      description: description,
      rewardSummary: rewardSummary,
      icon: icon,
      progress: progress ?? this.progress,
      completed: completed ?? this.completed,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'description': description,
      'rewardSummary': rewardSummary,
      'progress': progress,
      'completed': completed,
    };
  }

  factory Challenge.fromJson(Map<String, dynamic> json) {
    return Challenge(
      id: json['id'],
      type: ChallengeType.values.byName(json['type']),
      title: json['title'],
      description: json['description'],
      rewardSummary: json['rewardSummary'],
      icon: Icons.flash_on_rounded, // Default, should be mapped
      progress: json['progress'],
      completed: json['completed'],
    );
  }
}

class ChallengeBundle {
  final List<Challenge> challenges;
  final DateTime refreshTime;

  const ChallengeBundle({
    required this.challenges,
    required this.refreshTime,
  });

  ChallengeBundle copyWith({
    List<Challenge>? challenges,
    DateTime? refreshTime,
  }) {
    return ChallengeBundle(
      challenges: challenges ?? this.challenges,
      refreshTime: refreshTime ?? this.refreshTime,
    );
  }
}
