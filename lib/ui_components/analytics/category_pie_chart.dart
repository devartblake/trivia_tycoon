import 'package:flutter/material.dart';
import '../../game/services/question_analytics_service.dart';
import '../../synaptix/theme/synaptix_theme_extension.dart';
import 'neural_bloom_painter.dart';

/// Visualization showing category performance breakdown using the Neural Bloom system
class CategoryPieChart extends StatefulWidget {
  final List<CategoryPerformance> categories;
  final void Function(String)? onCategoryTap;

  const CategoryPieChart({
    super.key,
    required this.categories,
    this.onCategoryTap,
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.categories.isEmpty) {
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

    final accentColor =
        Theme.of(context).extension<SynaptixTheme>()?.accentGlow ??
            Theme.of(context).primaryColor;

    // Sort by total questions (descending) and take top 5-7 for the bloom
    final topCategories = ([...widget.categories]
          ..sort((a, b) => b.totalQuestions.compareTo(a.totalQuestions)))
        .take(7)
        .toList();

    final bloomData = _convertToBloomData(context, topCategories);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Neural Bloom',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your cognitive growth by category',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            const SizedBox(height: 24),
            // Bloom Visualization
            Center(
              child: AnimatedBuilder(
                animation: _animationController,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(280, 280),
                    painter: NeuralBloomPainter(
                      data: bloomData,
                      animationValue: _animationController.value,
                      accentColor: accentColor,
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            // Legend
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: topCategories.asMap().entries.map((entry) {
                final category = entry.value;
                final color = bloomData[entry.key].color;
                return _buildLegendItem(category.category, color);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  List<NeuralBloomData> _convertToBloomData(
      BuildContext context, List<CategoryPerformance> categories) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final palette = synaptix?.chartPalette ??
        [
          Colors.blue,
          Colors.green,
          Colors.orange,
          Colors.pink,
          Colors.purple,
          Colors.teal,
          Colors.cyan,
        ];

    return categories.asMap().entries.map((entry) {
      final index = entry.key;
      final category = entry.value;
      return NeuralBloomData(
        label: category.category,
        value: (category.accuracy / 100).clamp(0.1, 1.0),
        color: palette[index % palette.length],
      );
    }).toList();
  }
}
