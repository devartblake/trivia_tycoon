import 'package:flutter/material.dart';
import '../../game/services/question_analytics_service.dart';

/// Card displaying overall performance statistics
class PerformanceSummaryCard extends StatelessWidget {
  final PerformanceSummary summary;

  const PerformanceSummaryCard({
    super.key,
    required this.summary,
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
            Text(
              'Overall Performance',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            // Stats Grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              children: [
                _StatTile(
                  icon: Icons.quiz,
                  label: 'Questions',
                  value: summary.totalQuestions.toString(),
                  color: Colors.blue,
                ),
                _StatTile(
                  icon: Icons.check_circle,
                  label: 'Accuracy',
                  value: '${summary.accuracy.toStringAsFixed(1)}%',
                  color: Colors.green,
                ),
                _StatTile(
                  icon: Icons.star,
                  label: 'Total XP',
                  value: summary.totalXP.toString(),
                  color: Colors.amber,
                ),
                _StatTile(
                  icon: Icons.attach_money,
                  label: 'Coins',
                  value: summary.totalCoins.toString(),
                  color: Colors.orange,
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Breakdown
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _BreakdownStat(
                  label: 'Correct',
                  value: summary.correctQuestions,
                  color: Colors.green,
                  total: summary.totalQuestions,
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.grey.shade300,
                ),
                _BreakdownStat(
                  label: 'Incorrect',
                  value: summary.incorrectQuestions,
                  color: Colors.red,
                  total: summary.totalQuestions,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Avg. Time: ${summary.averageTimeSeconds}s',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _BreakdownStat extends StatelessWidget {
  final String label;
  final int value;
  final Color color;
  final int total;

  const _BreakdownStat({
    required this.label,
    required this.value,
    required this.color,
    required this.total,
  });

  double get percentage => total > 0 ? (value / total * 100) : 0;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
