import 'package:flutter/material.dart';

enum MissionType { daily, weekly }

class Mission {
  final String title;
  final int progress;
  final int total;
  final int reward;
  final IconData icon;
  final String badge;
  final MissionType type;

  Mission({
    required this.title,
    required this.progress,
    required this.total,
    required this.reward,
    required this.icon,
    required this.badge,
    required this.type,
  });

  bool get isCompleted => progress >= total;
}
