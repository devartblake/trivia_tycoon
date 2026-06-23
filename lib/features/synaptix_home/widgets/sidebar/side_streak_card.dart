import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../layout/synaptix_panel.dart';

class SideStreakCard extends StatelessWidget {
  final SynaptixHomePlayer player;

  const SideStreakCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: SynaptixHomeTheme.orange,
            size: 42,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WIN STREAK',
                style: TextStyle(color: SynaptixHomeTheme.muted, fontSize: 12),
              ),
              Text(
                '${player.streak}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Best: ${player.bestStreak}',
                style: const TextStyle(
                  color: SynaptixHomeTheme.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
