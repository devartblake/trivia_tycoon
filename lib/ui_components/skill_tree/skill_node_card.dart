import 'package:flutter/material.dart';
import 'package:synaptix/game/models/skill_progression_model.dart';
import 'package:synaptix/game/models/skill_tree_graph.dart' hide SkillNode;
import 'package:synaptix/core/theme/skill_category_colors.dart';

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
  Color _getCardColor(BuildContext context) {
    if (skill.level == 0) {
      return Colors.grey;
    }

    // Try to map category string to SkillCategory enum
    final category = _mapCategory(skill.category);
    return SkillCategoryColors.backgroundFor(context, category);
  }

  SkillCategory _mapCategory(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('math')) return SkillCategory.scholar;
    if (lower.contains('science')) return SkillCategory.xp;
    if (lower.contains('logic')) return SkillCategory.timer;
    return SkillCategory.general;
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
  Color _getIconColor(BuildContext context) {
    if (skill.level == 0) return Colors.grey.shade600;
    
    final category = _mapCategory(skill.category);
    return SkillCategoryColors.glowFor(context, category);
  }

  @override
  Widget build(BuildContext context) {
    final cardColor = _getCardColor(context);
    final backgroundColor = cardColor.withValues(alpha: 0.1);
    final borderColor = isSelected ? cardColor : Colors.transparent;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: isSelected ? 4 : 2,
        color: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: backgroundColor,
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              Icon(
                _getIcon(),
                size: 32,
                color: _getIconColor(context),
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
