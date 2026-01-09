import 'package:flutter/material.dart';
import '../domain/arcade_difficulty.dart';
import '../domain/arcade_game_definition.dart';
import '../domain/arcade_game_id.dart';
import '../ui/screens/arcade_game_shell.dart';
import '../ui/screens/arcade_stub_game_screen.dart';

class ArcadeRegistry {
  const ArcadeRegistry();

  List<ArcadeGameDefinition> get games => [
    const ArcadeGameDefinition(
      id: ArcadeGameId.patternSprint,
      title: 'Pattern Sprint',
      subtitle: 'Fill the missing pattern under time pressure.',
      icon: Icons.auto_awesome,
      supportedDifficulties: [
        ArcadeDifficulty.easy,
        ArcadeDifficulty.normal,
        ArcadeDifficulty.hard,
      ],
      builder: _buildStub,
    ),
    const ArcadeGameDefinition(
      id: ArcadeGameId.memoryFlip,
      title: 'Memory Flip',
      subtitle: 'Match pairs quickly with minimal mistakes.',
      icon: Icons.grid_view_rounded,
      supportedDifficulties: [
        ArcadeDifficulty.easy,
        ArcadeDifficulty.normal,
        ArcadeDifficulty.hard,
      ],
      builder: _buildStub,
    ),
    ArcadeGameDefinition(
      id: ArcadeGameId.quickMathRush,
      title: 'Quick Math Rush',
      subtitle: 'Answer fast, build streaks, climb difficulty.',
      icon: Icons.calculate_rounded,
      supportedDifficulties: const [
        ArcadeDifficulty.easy,
        ArcadeDifficulty.normal,
        ArcadeDifficulty.hard,
        ArcadeDifficulty.insane,
      ],
      builder: _buildStub,
    ),
  ];

  /// Temporary placeholder game screen used until we implement each game.
  static Widget _buildStub(BuildContext context, ArcadeDifficulty difficulty) {
    return const ArcadeStubGameScreen();
  }
}
