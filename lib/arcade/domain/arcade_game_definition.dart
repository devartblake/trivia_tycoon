import 'package:flutter/material.dart';
import 'arcade_difficulty.dart';
import 'arcade_game_id.dart';

typedef ArcadeGameBuilder = Widget Function(
    BuildContext context,
    ArcadeDifficulty difficulty,
    );

class ArcadeGameDefinition {
  final ArcadeGameId id;
  final String title;
  final String subtitle;
  final IconData icon;

  final List<ArcadeDifficulty> supportedDifficulties;

  /// Builds the game screen/widget for the selected difficulty.
  final ArcadeGameBuilder builder;

  const ArcadeGameDefinition({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.supportedDifficulties,
    required this.builder,
  });
}
