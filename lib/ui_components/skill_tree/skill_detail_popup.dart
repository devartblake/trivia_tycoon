import 'package:flutter/material.dart';
import '../../game/models/skill_progression_model.dart';

/// Dialog displaying full details about a skill
class SkillDetailPopup extends StatelessWidget {
  final SkillNode skill;
  final VoidCallback onClose;

  const SkillDetailPopup({
    super.key,
    required this.skill,
    required this.onClose,
  });

  /// Get color based on skill state
  Color _getSkillColor() {
    if (skill.isMastered) return Colors.amber;
    if (skill.level > 0) return Colors.blue;
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    final skillColor = _getSkillColor();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        skill.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: skillColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Chip(
                        label: Text(
                          skill.category,
                          style: const TextStyle(fontSize: 12),
                        ),
                        backgroundColor: skillColor.withValues(alpha: 0.2),
                        labelStyle: TextStyle(color: skillColor),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: onClose,
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Progress section (if unlocked)
            if (skill.level > 0) ...[
              _buildProgressSection(context, skillColor),
              const SizedBox(height: 16),
            ],

            // Status section
            _buildStatusSection(context, skillColor),
            const SizedBox(height: 16),

            // Description
            if (skill.description != null && skill.description!.isNotEmpty) ...[
              Text(
                'Description',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                skill.description!,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
            ],

            // Prerequisites
            if (skill.prerequisites.isNotEmpty) ...[
              Text(
                'Requirements',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              ...skill.prerequisites.map((prereq) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 18,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 8),
                      Text(
                        prereq,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Locked message
            if (skill.level == 0) ...[
              Container(
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
                ),
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.lock, size: 20, color: Colors.orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Complete the requirements above to unlock this skill',
                        style: TextStyle(color: Colors.orange[700], fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Timeline (if available)
            if (skill.unlockedAt != null || skill.masteredAt != null) ...[
              _buildTimelineSection(context),
              const SizedBox(height: 16),
            ],

            // Close button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onClose,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build progress section
  Widget _buildProgressSection(BuildContext context, Color skillColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progress',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Level ${skill.level}/10',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            Text(
              '${(skill.progressPercent * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: skill.progressPercent,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation(skillColor),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${skill.currentXp} / ${skill.totalXpRequired} XP',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey[600],
              ),
        ),
      ],
    );
  }

  /// Build status section
  Widget _buildStatusSection(BuildContext context, Color skillColor) {
    String statusText;
    Color statusColor;

    if (skill.isMastered) {
      statusText = '⭐ MASTERED';
      statusColor = Colors.amber;
    } else if (skill.level > 0) {
      statusText = '✓ UNLOCKED';
      statusColor = Colors.blue;
    } else {
      statusText = '🔒 LOCKED';
      statusColor = Colors.grey;
    }

    return Container(
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        children: [
          Text(
            statusText,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Spacer(),
          if (skill.unlockedAt != null)
            Text(
              'Unlocked ${_formatDate(skill.unlockedAt!)}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
        ],
      ),
    );
  }

  /// Build timeline section
  Widget _buildTimelineSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Timeline',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        if (skill.unlockedAt != null)
          _buildTimelineItem(
            context,
            'Unlocked',
            _formatDate(skill.unlockedAt!),
            Icons.check_circle,
            Colors.blue,
          ),
        if (skill.masteredAt != null)
          _buildTimelineItem(
            context,
            'Mastered',
            _formatDate(skill.masteredAt!),
            Icons.star,
            Colors.amber,
          ),
      ],
    );
  }

  /// Build single timeline item
  Widget _buildTimelineItem(
    BuildContext context,
    String label,
    String date,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
          ),
          const Spacer(),
          Text(
            date,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()} weeks ago';
    } else {
      return '${(difference.inDays / 30).floor()} months ago';
    }
  }
}
