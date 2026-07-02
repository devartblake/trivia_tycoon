import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/question_analytics_provider.dart';

/// Detail page showing performance breakdown for a specific category
class CategoryPerformanceDetail extends ConsumerWidget {
  final String categoryId;

  const CategoryPerformanceDetail({
    super.key,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryPerformance = ref.watch(
      categoryPerformanceProvider(categoryId),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(categoryId),
        centerTitle: true,
        elevation: 0,
      ),
      body: categoryPerformance.when(
        data: (performance) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header
              _CategoryHeader(categoryId: categoryId, performance: performance),
              const SizedBox(height: 24),

              // Overall Stats
              _OverallStatsCard(performance: performance),
              const SizedBox(height: 20),

              // Difficulty Breakdown
              Text(
                'Performance by Difficulty',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _DifficultyBreakdown(categoryId: categoryId),
              const SizedBox(height: 24),

              // Time Analysis
              Text(
                'Time Analysis',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _TimeAnalysisCard(performance: performance),
              const SizedBox(height: 24),

              // Improvement Suggestions
              _ImprovementSuggestions(performance: performance),
              const SizedBox(height: 20),
            ],
          ),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(),
        ),
        error: (error, stack) => Center(
          child: Text('Error loading category: $error'),
        ),
      ),
    );
  }
}

/// Category header with icon and name
class _CategoryHeader extends StatelessWidget {
  final String categoryId;
  final dynamic performance;

  const _CategoryHeader({
    required this.categoryId,
    required this.performance,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.category,
              size: 48,
              color: Theme.of(context).primaryColor,
            ),
            const SizedBox(height: 12),
            Text(
              categoryId,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              '${performance.totalQuestions} questions attempted',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Overall statistics for the category
class _OverallStatsCard extends StatelessWidget {
  final dynamic performance;

  const _OverallStatsCard({required this.performance});

  @override
  Widget build(BuildContext context) {
    final accuracy = (performance.accuracy * 100).toStringAsFixed(1);

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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(
                  label: 'Accuracy',
                  value: '$accuracy%',
                  icon: Icons.trending_up,
                ),
                _StatItem(
                  label: 'Total Questions',
                  value: '${performance.totalQuestions}',
                  icon: Icons.question_answer,
                ),
                _StatItem(
                  label: 'Correct',
                  value: '${performance.correctQuestions}',
                  icon: Icons.check_circle,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: performance.accuracy,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation(
                _getAccuracyColor(performance.accuracy),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 0.8) return Colors.green;
    if (accuracy >= 0.6) return Colors.orange;
    return Colors.red;
  }
}

/// Individual stat display
class _StatItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Colors.blue),
        const SizedBox(height: 8),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Difficulty breakdown card
class _DifficultyBreakdown extends StatelessWidget {
  final String categoryId;

  const _DifficultyBreakdown({required this.categoryId});

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
              'Difficulty Levels',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            _DifficultyItem(
              level: 'Easy',
              correct: 12,
              total: 15,
              color: Colors.green,
            ),
            const SizedBox(height: 12),
            _DifficultyItem(
              level: 'Medium',
              correct: 8,
              total: 12,
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _DifficultyItem(
              level: 'Hard',
              correct: 4,
              total: 8,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

/// Single difficulty item
class _DifficultyItem extends StatelessWidget {
  final String level;
  final int correct;
  final int total;
  final Color color;

  const _DifficultyItem({
    required this.level,
    required this.correct,
    required this.total,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final accuracy = (correct / total * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(level, style: Theme.of(context).textTheme.bodyMedium),
            Text('$correct/$total ($accuracy%)',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: correct / total,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation(color),
        ),
      ],
    );
  }
}

/// Time analysis card
class _TimeAnalysisCard extends StatelessWidget {
  final dynamic performance;

  const _TimeAnalysisCard({required this.performance});

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
              'Time Metrics',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _TimeMetric(
                  label: 'Avg Time',
                  value: '${performance.averageTimeSeconds?.toStringAsFixed(1) ?? "N/A"}s',
                ),
                _TimeMetric(
                  label: 'Total Time',
                  value: '${(performance.totalTime?.toStringAsFixed(0) ?? "N/A")}s',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Time metric display
class _TimeMetric extends StatelessWidget {
  final String label;
  final String value;

  const _TimeMetric({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}

/// Improvement suggestions card
class _ImprovementSuggestions extends StatelessWidget {
  final dynamic performance;

  const _ImprovementSuggestions({required this.performance});

  @override
  Widget build(BuildContext context) {
    final suggestions = <String>[];
    final accuracy = performance.accuracy;

    if (accuracy < 0.6) {
      suggestions.add('Your accuracy is below 60%. Consider practicing more questions in this category.');
    } else if (accuracy < 0.75) {
      suggestions.add('Keep practicing to improve your accuracy to 75%+.');
    }

    if (performance.totalQuestions < 10) {
      suggestions.add('Answer more questions to get a better understanding of this category.');
    }

    if (suggestions.isEmpty) {
      suggestions.add('Great job! You\'re performing well in this category.');
    }

    return Card(
      elevation: 2,
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade600),
                const SizedBox(width: 12),
                Text(
                  'Suggestions',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...suggestions.map((suggestion) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.check_circle,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        suggestion,
                        style: TextStyle(
                          color: Colors.blue.shade900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
