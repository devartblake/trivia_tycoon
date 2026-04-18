import 'package:flutter/material.dart';

import '../../../core/dto/learning_dto.dart';

class ModuleCard extends StatelessWidget {
  final ModuleDto module;
  final VoidCallback onTap;

  const ModuleCard({super.key, required this.module, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = module.difficultyColour;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withOpacity(0.6), width: 1.5),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      module.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (module.isCompleted)
                    Icon(Icons.check_circle, color: Colors.green, size: 20),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                module.description,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _DifficultyBadge(
                    label: module.difficultyText,
                    color: color,
                  ),
                  const SizedBox(width: 8),
                  _InfoChip(
                    icon: Icons.menu_book_outlined,
                    label: '${module.lessonCount} lessons',
                  ),
                  const Spacer(),
                  _InfoChip(
                    icon: Icons.star_outline,
                    label: '+${module.rewardXp} XP',
                  ),
                  const SizedBox(width: 6),
                  _InfoChip(
                    icon: Icons.monetization_on_outlined,
                    label: '+${module.rewardCoins}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _DifficultyBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey.shade600),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}
