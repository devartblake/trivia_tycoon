import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../components/synaptix_progress_bar.dart';
import '../layout/synaptix_panel.dart';
import '../tiles/achievement_tile.dart';

class ProgressionCard extends StatelessWidget {
  final SynaptixHomePlayer player;
  final List<SynaptixAchievement> achievements;

  const ProgressionCard({
    super.key,
    required this.player,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      minHeight: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR PROGRESSION',
            style: TextStyle(
              color: SynaptixHomeTheme.purple,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _LevelBadge(level: player.level),
              const SizedBox(width: 14),
              Expanded(child: SynaptixProgressBar(value: player.xpProgress)),
              const SizedBox(width: 14),
              Text(
                '${player.currentXp} / ${player.targetXp} XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'RECENT ACHIEVEMENTS',
            style: TextStyle(
              color: SynaptixHomeTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 420;
              final tiles = [
                for (final achievement in achievements)
                  AchievementTile(achievement: achievement),
              ];
              if (stack) {
                return Column(
                  children: [
                    for (final tile in tiles) ...[
                      tile,
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (final tile in tiles) Expanded(child: tile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SynaptixHomeTheme.panelAlt,
        border: Border.all(color: SynaptixHomeTheme.purple),
      ),
      child: Center(
        child: Text(
          '$level',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
