import 'package:flutter/material.dart';
import '../../core/services/tier_api_client.dart';

/// Progress bar showing advancement to next tier
class TierProgressBar extends StatelessWidget {
  final PlayerTierProgress progress;

  const TierProgressBar({
    super.key,
    required this.progress,
  });

  @override
  Widget build(BuildContext context) {
    if (progress.isMaxTier) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'You\'ve reached the maximum tier!',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.amber.shade700,
              ),
            ),
          ),
        ),
      );
    }

    final nextTier = progress.nextTier!;
    final progressPercent = progress.progressPercentage / 100;

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Progress to Next Tier',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  nextTier.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progressPercent,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(
                  _getProgressColor(progressPercent),
                ),
              ),
            ),
            const SizedBox(height: 12),
            // XP details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'XP Progress',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${progress.xpInCurrentTier} / ${progress.xpNeededForNextTier}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Completion',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      '${progress.progressPercentage}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: _getProgressColor(progressPercent),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Estimated time (simplified)
            _EstimatedTimeDisplay(
              xpRemaining: progress.xpNeededForNextTier - progress.xpInCurrentTier,
            ),
          ],
        ),
      ),
    );
  }

  Color _getProgressColor(double progressValue) {
    if (progressValue >= 0.75) return Colors.green;
    if (progressValue >= 0.5) return Colors.amber;
    if (progressValue >= 0.25) return Colors.orange;
    return Colors.blue;
  }
}

class _EstimatedTimeDisplay extends StatelessWidget {
  final int xpRemaining;

  const _EstimatedTimeDisplay({required this.xpRemaining});

  @override
  Widget build(BuildContext context) {
    // Assume ~100 XP per quiz on average
    final estimatedQuizzes = (xpRemaining / 100).ceil();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.blue.shade200,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.schedule,
            size: 18,
            color: Colors.blue.shade600,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Estimated: ~$estimatedQuizzes more quizzes',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue.shade700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
