import 'package:flutter/material.dart';
import '../../game/models/skill_progression_model.dart';

/// Visual XP progress bar for a skill
class SkillProgressBar extends StatelessWidget {
  final SkillNode skill;
  final Color? color;

  const SkillProgressBar({
    super.key,
    required this.skill,
    this.color,
  });

  /// Get progress color
  Color _getProgressColor() {
    if (color != null) return color!;
    if (skill.isMastered) return Colors.amber;
    if (skill.level > 0) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    if (skill.level == 0) {
      return const SizedBox.shrink();
    }

    final progressColor = _getProgressColor();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Level and progress percentage
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level ${skill.level}/10',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: progressColor,
                  ),
            ),
            Text(
              '${(skill.progressPercent * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Progress bar
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: skill.progressPercent,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(progressColor),
          ),
        ),
        const SizedBox(height: 4),

        // XP text
        Text(
          '${skill.currentXp} / ${skill.totalXpRequired} XP',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }
}
