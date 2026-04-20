import 'package:flutter/material.dart';
import '../domain/arcade_difficulty.dart';
import '../domain/arcade_game_definition.dart';
import '../domain/arcade_game_id.dart';
import '../games/memory_flip/memory_flip_screen.dart';
import '../games/pattern_sprint/pattern_sprint_screen.dart';
import '../games/quick_math/quick_math_screen.dart';

class ArcadeRegistry {
  const ArcadeRegistry();

  List<ArcadeGameDefinition> get games => [
        ArcadeGameDefinition(
          id: ArcadeGameId.patternSprint,
          title: 'Pattern Sprint',
          subtitle: 'Fill the missing pattern under time pressure.',
          icon: Icons.auto_awesome,
          supportedDifficulties: const [
            ArcadeDifficulty.easy,
            ArcadeDifficulty.normal,
            ArcadeDifficulty.hard,
          ],
          builder: (context, difficulty) =>
              PatternSprintScreen(difficulty: difficulty),
        ),
        ArcadeGameDefinition(
          id: ArcadeGameId.memoryFlip,
          title: 'Memory Flip',
          subtitle: 'Match pairs quickly with minimal mistakes.',
          icon: Icons.grid_view_rounded,
          supportedDifficulties: const [
            ArcadeDifficulty.easy,
            ArcadeDifficulty.normal,
            ArcadeDifficulty.hard,
          ],
          builder: (context, difficulty) =>
              MemoryFlipScreen(difficulty: difficulty),
        ),
        ArcadeGameDefinition(
          id: ArcadeGameId.quickMathRush,
          title: 'Quick Math Rush',
          subtitle: 'Answer fast, build streaks, climb difficulty.',
          icon: Icons.calculate_rounded,
          supportedDifficulties: [
            ArcadeDifficulty.easy,
            ArcadeDifficulty.normal,
            ArcadeDifficulty.hard,
            ArcadeDifficulty.insane,
          ],
          builder: (context, difficulty) =>
              QuickMathRushScreen(difficulty: difficulty),
        ),
      ];
}
