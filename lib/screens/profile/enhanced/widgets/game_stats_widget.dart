import 'package:flutter/material.dart';

class GameStatsWidget extends StatelessWidget {
  final String userId;

  const GameStatsWidget({
    Key? key,
    required this.userId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.bar_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Game Statistics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _buildStatRow(context, 'Total Games', '342', Icons.games),
            const SizedBox(height: 12),
            _buildStatRow(context, 'Win Rate', '68%', Icons.trending_up,
                color: Colors.green),
            const SizedBox(height: 12),
            _buildStatRow(context, 'Average Score', '825', Icons.stars),
            const SizedBox(height: 12),
            _buildStatRow(context, 'Best Category', 'Science', Icons.science),
            const SizedBox(height: 20),
            _buildCategoryBreakdown(context),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Row(
      children: [
        Icon(icon,
            size: 20, color: color ?? Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }

  Widget _buildCategoryBreakdown(BuildContext context) {
    final categories = [
      {'name': 'Science', 'score': 920, 'percentage': 0.92},
      {'name': 'History', 'score': 850, 'percentage': 0.85},
      {'name': 'Sports', 'score': 780, 'percentage': 0.78},
      {'name': 'Movies', 'score': 810, 'percentage': 0.81},
      {'name': 'Music', 'score': 760, 'percentage': 0.76},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category Performance',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        ...categories.map((category) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category['name'] as String,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      Text(
                        '${category['score']}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  LinearProgressIndicator(
                    value: category['percentage'] as double,
                    backgroundColor:
                        Theme.of(context).colorScheme.surfaceContainerHighest,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ],
              ),
            )),
      ],
    );
  }
}
