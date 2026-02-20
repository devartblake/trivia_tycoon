import 'package:flutter/material.dart';
import 'package:trivia_tycoon/screens/question/widgets/stats/stat_item.dart';

class StatsOverviewCard extends StatelessWidget {
  final Map<String, dynamic> stats;

  const StatsOverviewCard({super.key, required this.stats});

  @override
  Widget build(BuildContext context) {
    final summary = stats['summary'] as Map<String, dynamic>? ?? {};
    final totalQuestions = summary['totalQuestions'] ?? 0;
    final totalDatasets = summary['totalDatasets'] ?? 0;
    final categoryCounts = summary['categoryCounts'] as Map<String, int>? ?? {};
    final categories = categoryCounts.length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quiz Database',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: StatItem(
                  title: 'Total Questions',
                  value: _formatNumber(totalQuestions),
                  icon: Icons.quiz,
                  color: Colors.blue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatItem(
                  title: 'Categories',
                  value: categories.toString(),
                  icon: Icons.category,
                  color: Colors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: StatItem(
                  title: 'Datasets',
                  value: totalDatasets.toString(),
                  icon: Icons.library_books,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}k';
    }
    return number.toString();
  }
}