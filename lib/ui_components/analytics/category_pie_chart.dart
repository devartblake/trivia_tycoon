import 'package:flutter/material.dart';
import '../../game/services/question_analytics_service.dart';

/// Pie chart showing category performance breakdown
class CategoryPieChart extends StatelessWidget {
  final List<CategoryPerformance> categories;
  final void Function(String)? onCategoryTap;

  const CategoryPieChart({
    super.key,
    required this.categories,
    this.onCategoryTap,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text(
              'No category data available',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
        ),
      );
    }

    // Sort by total questions (descending) and take top 5
    final topCategories = [...categories]
      ..sort((a, b) => b.totalQuestions.compareTo(a.totalQuestions))
      ..take(5)
      .toList();

    final colors = _generateColors(topCategories.length);

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
            const SizedBox(height: 20),
            // Legend with bars
            ...topCategories.asMap().entries.map((entry) {
              final index = entry.key;
              final category = entry.value;
              final color = colors[index];
              final accuracy = category.accuracy;

              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: GestureDetector(
                  onTap: () => onCategoryTap?.call(category.category),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    category.category,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${accuracy.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _getAccuracyColor(accuracy),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Accuracy bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: accuracy / 100,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation(
                            _getAccuracyColor(accuracy),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${category.correctQuestions}/${category.totalQuestions} correct',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Color _getAccuracyColor(double accuracy) {
    if (accuracy >= 80) return Colors.green;
    if (accuracy >= 60) return Colors.amber;
    return Colors.red;
  }

  List<Color> _generateColors(int count) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.purple,
      Colors.teal,
      Colors.indigo,
      Colors.cyan,
    ];
    return colors.take(count).toList();
  }
}
