import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/providers/question_analytics_provider.dart';
import '../../game/services/question_analytics_service.dart';

/// Detailed performance breakdown for a specific category
class CategoryPerformanceDetailPage extends ConsumerWidget {
  final String category;

  const CategoryPerformanceDetailPage({
    super.key,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsService = ref.watch(questionAnalyticsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(category),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header Card
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style:
                            Theme.of(context).textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 16),
                      _CategoryStats(
                        analyticsService: analyticsService,
                        category: category,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Performance by Difficulty
              _DifficultyBreakdown(
                analyticsService: analyticsService,
                category: category,
              ),
              const SizedBox(height: 20),

              // Time Analysis
              _TimeAnalysis(
                analyticsService: analyticsService,
                category: category,
              ),
              const SizedBox(height: 20),

              // Improvement Tips
              _ImprovementTips(
                analyticsService: analyticsService,
                category: category,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// Category statistics display
class _CategoryStats extends ConsumerWidget {
  final QuestionAnalyticsService analyticsService;
  final String category;

  const _CategoryStats({
    required this.analyticsService,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performance = analyticsService.getCategoryPerformance(category);

    if (performance.totalQuestions == 0) {
      return Center(
        child: Text(
          'No data available for this category yet.',
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _StatCard(
          label: 'Total Questions',
          value: performance.totalQuestions.toString(),
          icon: Icons.quiz,
          color: Colors.blue,
        ),
        _StatCard(
          label: 'Accuracy',
          value: '${performance.accuracy.toStringAsFixed(1)}%',
          icon: Icons.check_circle,
          color: _getAccuracyColor(performance.accuracy),
        ),
        _StatCard(
          label: 'Correct',
          value: performance.correctQuestions.toString(),
          icon: Icons.done,
          color: Colors.green,
        ),
        _StatCard(
          label: 'Total XP',
          value: performance.totalXP.toString(),
          icon: Icons.star,
          color: Colors.amber,
        ),
      ],
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.amber;
    return Colors.red;
  }
}

/// Displays breakdown by difficulty level
class _DifficultyBreakdown extends ConsumerWidget {
  final QuestionAnalyticsService analyticsService;
  final String category;

  const _DifficultyBreakdown({
    required this.analyticsService,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance by Difficulty',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Track your performance across different difficulty levels',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation(Colors.blue.shade400),
            ),
          ],
        ),
      ),
    );
  }
}

/// Time analysis for the category
class _TimeAnalysis extends ConsumerWidget {
  final QuestionAnalyticsService analyticsService;
  final String category;

  const _TimeAnalysis({
    required this.analyticsService,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Time Analysis',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _TimeStatColumn(
                  label: 'Avg Time',
                  value: 'N/A',
                  unit: 'seconds',
                ),
                _TimeStatColumn(
                  label: 'Fastest',
                  value: 'N/A',
                  unit: 'seconds',
                ),
                _TimeStatColumn(
                  label: 'Slowest',
                  value: 'N/A',
                  unit: 'seconds',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Time data will be available after answering more questions',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Improvement tips based on category performance
class _ImprovementTips extends ConsumerWidget {
  final QuestionAnalyticsService analyticsService;
  final String category;

  const _ImprovementTips({
    required this.analyticsService,
    required this.category,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final performance = analyticsService.getCategoryPerformance(category);

    final tips = <String>[];

    if (performance.accuracy < 60) {
      tips.add('Focus on understanding the fundamentals in this category');
      tips.add('Try starting with easier difficulty questions');
    } else if (performance.accuracy < 80) {
      tips.add('You\'re doing well! Push for 80%+ accuracy');
      tips.add('Review incorrect answers to identify patterns');
    } else {
      tips.add(
          'Excellent performance! Consider challenging yourself with harder questions');
      tips.add('Maintain this level by practicing regularly');
    }

    return Card(
      elevation: 2,
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber.shade600),
                const SizedBox(width: 8),
                Text(
                  'Improvement Tips',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade900,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...tips.map((tip) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Icon(
                        Icons.check_circle,
                        size: 16,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: Colors.green.shade900,
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

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
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
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _TimeStatColumn extends StatelessWidget {
  final String label;
  final String value;
  final String unit;

  const _TimeStatColumn({
    required this.label,
    required this.value,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          unit,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }
}
