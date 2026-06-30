import 'package:flutter/material.dart';
import '../../game/services/question_analytics_service.dart';

/// Card displaying trending performance
class TrendingPerformanceCard extends StatelessWidget {
  final TrendingSummary trending;

  const TrendingPerformanceCard({
    super.key,
    required this.trending,
  });

  @override
  Widget build(BuildContext context) {
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
                  'Last ${trending.period}',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                _TrendIndicator(trending: trending.trending),
              ],
            ),
            const SizedBox(height: 24),
            // Main Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TrendStatColumn(
                  label: 'Questions',
                  value: trending.questionsAnswered.toString(),
                  icon: Icons.quiz,
                  color: Colors.blue,
                ),
                _TrendStatColumn(
                  label: 'Correct',
                  value: trending.correctAnswered.toString(),
                  icon: Icons.check_circle,
                  color: Colors.green,
                ),
                _TrendStatColumn(
                  label: 'Accuracy',
                  value: '${trending.accuracyPercent}%',
                  icon: Icons.percent,
                  color: Colors.amber,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Visualization
            Column(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: trending.questionsAnswered > 0
                        ? (trending.correctAnswered / trending.questionsAnswered)
                        : 0,
                    minHeight: 12,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation(
                      _getAccuracyColor(trending.accuracyPercent),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Success Rate',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccuracyColor(String? accuracyPercent) {
    if (accuracyPercent == null) return Colors.grey;
    final accuracy = double.parse(accuracyPercent);
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.amber;
    return Colors.red;
  }
}

class _TrendIndicator extends StatelessWidget {
  final String trending; // 'up', 'down', 'neutral'

  const _TrendIndicator({required this.trending});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getTrendColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getTrendColor().withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getTrendIcon(),
            color: _getTrendColor(),
            size: 18,
          ),
          const SizedBox(width: 4),
          Text(
            _getTrendLabel(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _getTrendColor(),
            ),
          ),
        ],
      ),
    );
  }

  Color _getTrendColor() {
    switch (trending) {
      case 'up':
        return Colors.green;
      case 'down':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getTrendIcon() {
    switch (trending) {
      case 'up':
        return Icons.trending_up;
      case 'down':
        return Icons.trending_down;
      default:
        return Icons.trending_flat;
    }
  }

  String _getTrendLabel() {
    switch (trending) {
      case 'up':
        return 'Excellent';
      case 'down':
        return 'Needs Work';
      default:
        return 'Average';
    }
  }
}

class _TrendStatColumn extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _TrendStatColumn({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
}
