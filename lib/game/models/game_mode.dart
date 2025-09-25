
import 'package:flutter/material.dart';

enum GameMode {
  classic,
  topicExplorer,
  survival,
  arena,
  teams,
  daily,
}

class GameModeInfo {
  final String title;
  final String description;
  final IconData icon;
  final Gradient gradient;
  final List<String> rules;
  final List<String> tips;
  final Map<String, String> features;
  final String difficulty;
  final String duration;
  final String? navigationRoute;

  const GameModeInfo({
    required this.title,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.rules,
    required this.tips,
    required this.features,
    required this.difficulty,
    required this.duration,
    this.navigationRoute,
  });
}