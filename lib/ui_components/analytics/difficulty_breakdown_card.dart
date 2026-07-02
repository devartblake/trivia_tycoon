import 'package:flutter/material.dart';

/// Card showing performance breakdown by difficulty level
class DifficultyBreakdownCard extends StatelessWidget {
  final dynamic categoryPerformance;

  const DifficultyBreakdownCard({
    super.key,
    required this.categoryPerformance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Difficulty Breakdown',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            _buildDifficultyRow(context, 'Easy', 15, 12, Colors.green),
            const SizedBox(height: 12),
            _buildDifficultyRow(context, 'Medium', 12, 8, Colors.orange),
            const SizedBox(height: 12),
            _buildDifficultyRow(context, 'Hard', 8, 4, Colors.red),
            const SizedBox(height: 12),
            _buildDifficultyRow(context, 'Expert', 5, 2, Colors.purple),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyRow(
    BuildContext context,
    String difficulty,
    int total,
    int correct,
    Color color,
  ) {
    final accuracy = (correct / total * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              difficulty,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
            Text(
              '$correct/$total ($accuracy%)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(
          value: correct / total,
          minHeight: 6,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }
}
