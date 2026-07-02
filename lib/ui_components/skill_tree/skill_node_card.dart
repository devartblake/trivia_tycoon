import 'package:flutter/material.dart';
import '../../game/models/skill_progression_model.dart';

/// Card displaying a single skill node in the skill tree
class SkillNodeCard extends StatelessWidget {
  final SkillNode skill;
  final VoidCallback onTap;
  final bool isSelected;

  const SkillNodeCard({
    super.key,
    required this.skill,
    required this.onTap,
    this.isSelected = false,
  });

  /// Get card color based on skill state
  Color _getCardColor() {
    if (skill.isMastered) {
      return Colors.amber;
    }
    if (skill.level > 0) {
      return Colors.blue;
    }
    return Colors.grey;
  }

  /// Get icon based on skill state
  IconData _getIcon() {
    if (skill.level == 0) {
      return Icons.lock;
    }
    if (skill.isMastered) {
      return Icons.star;
    }
    return Icons.check_circle;
  }

  /// Get icon color
  Color _getIconColor() {
    return _getCardColor();
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _getCardColor();
    final backgroundColor = cardColor.withValues(alpha: 0.1);
    final borderColor = isSelected ? cardColor : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 4 : 2,
        color: backgroundColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                _getIcon(),
                size: 32,
                color: _getIconColor(),
              ),
              const SizedBox(height: 8),

              // Skill name
              Text(
                skill.name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),

              // Level indicator (if unlocked)
              if (skill.level > 0) ...[
                const SizedBox(height: 6),
                Text(
                  'Level ${skill.level}/10',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: cardColor,
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],

              // Locked indicator
              if (skill.level == 0) ...[
                const SizedBox(height: 6),
                Text(
                  'LOCKED',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
