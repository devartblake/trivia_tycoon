import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/providers/question_analytics_provider.dart';
import '../../ui_components/analytics/performance_summary_card.dart';
import '../../ui_components/analytics/categories_card.dart';
import '../../ui_components/analytics/trending_card.dart';

/// Main player analytics dashboard screen
class PlayerAnalyticsDashboard extends ConsumerWidget {
  const PlayerAnalyticsDashboard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch all analytics providers
    final performanceSummary = ref.watch(performanceSummaryProvider);
    final trendingPerformance = ref.watch(trendingPerformanceProvider);
    final weakCategories = ref.watch(weakCategoriesProvider);
    final strongCategories = ref.watch(strongCategoriesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(performanceSummaryProvider),
            tooltip: 'Refresh data',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Performance Summary Card
              PerformanceSummaryCard(
                summary: performanceSummary,
              ),
              const SizedBox(height: 20),

              // Trending Performance Card
              TrendingPerformanceCard(
                trending: trendingPerformance,
              ),
              const SizedBox(height: 20),

              // Categories Performance
              Text(
                'Category Breakdown',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              _CategoryPerformanceSection(
                performanceSummary: performanceSummary,
              ),
              const SizedBox(height: 20),

              // Weak Categories
              WeakCategoriesCard(
                categories: weakCategories,
                onCategoryTap: (category) => _navigateToCategoryDetail(
                  context,
                  category,
                ),
              ),
              const SizedBox(height: 20),

              // Strong Categories
              StrongCategoriesCard(
                categories: strongCategories,
                onCategoryTap: (category) => _navigateToCategoryDetail(
                  context,
                  category,
                ),
              ),
              const SizedBox(height: 20),

              // Quick Tips Section
              _QuickTipsSection(
                weakCategoriesCount: weakCategories.length,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToCategoryDetail(BuildContext context, String category) {
    context.push(
      '/analytics/category/$category',
      extra: category,
    );
  }
}

/// Section showing category performance breakdown
class _CategoryPerformanceSection extends ConsumerWidget {
  final dynamic performanceSummary;

  const _CategoryPerformanceSection({
    required this.performanceSummary,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get all category data
    // For now, we'll show a message that data is loading
    // In a real implementation, we'd fetch all categories

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance by Category',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Category data will appear after answering more questions.',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14,
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

/// Quick tips based on performance
class _QuickTipsSection extends StatelessWidget {
  final int weakCategoriesCount;

  const _QuickTipsSection({required this.weakCategoriesCount});

  @override
  Widget build(BuildContext context) {
    List<String> tips = [];

    if (weakCategoriesCount > 0) {
      tips.add('Focus on improving your weak categories first');
      tips.add(
          'Practice $weakCategoriesCount category/categories where accuracy is low');
    }

    tips.addAll([
      'Try to maintain an accuracy above 75%',
      'Longer answer times may indicate difficult questions',
    ]);

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
                const SizedBox(width: 8),
                Text(
                  'Tips for Improvement',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade900,
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
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tip,
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
