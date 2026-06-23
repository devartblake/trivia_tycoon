import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';

class AchievementTile extends StatelessWidget {
  final SynaptixAchievement achievement;

  const AchievementTile({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(achievement.icon, color: SynaptixHomeTheme.gold, size: 34),
        const SizedBox(height: 8),
        Text(
          achievement.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          achievement.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: SynaptixHomeTheme.muted, fontSize: 11),
        ),
      ],
    );
  }
}
