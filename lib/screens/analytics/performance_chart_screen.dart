import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui_components/analytics/performance_line_chart.dart';
import '../../ui_components/analytics/chart_selector.dart';
import '../../ui_components/analytics/performance_chart_provider.dart';

/// Screen displaying performance charts with Riverpod integration
class PerformanceChartScreen extends ConsumerWidget {
  final String? title;

  const PerformanceChartScreen({
    super.key,
    this.title = 'Performance Trends',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final metric = ref.watch(selectedMetricProvider);
    final timeRange = ref.watch(selectedTimeRangeProvider);
    final chartDataAsync = ref.watch(performanceChartDisplayProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
          ],

          // Chart selector
          ChartSelector(
            selectedMetric: metric,
            selectedTimeRange: timeRange,
            onMetricChanged: (newMetric) {
              ref.read(selectedMetricProvider.notifier).state = newMetric;
            },
            onTimeRangeChanged: (newRange) {
              ref.read(selectedTimeRangeProvider.notifier).state = newRange;
            },
          ),
          const SizedBox(height: 24),

          // Chart with loading/error states
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: chartDataAsync.when(
                data: (data) => PerformanceLineChart(
                  data: data,
                  metric: metric,
                  lineColor: _getMetricColor(metric),
                  showGrid: true,
                  showLegend: true,
                ),
                loading: () => _buildLoadingState(context),
                error: (error, stack) => _buildErrorState(context, error),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats section
          chartDataAsync.when(
            data: (data) => _buildStatsSection(context, data, metric),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  /// Build loading state
  Widget _buildLoadingState(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading performance data...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build error state
  Widget _buildErrorState(BuildContext context, Object error) {
    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Failed to load performance data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[500],
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build stats section showing summary
  Widget _buildStatsSection(
    BuildContext context,
    List<PerformanceDataPoint> data,
    PerformanceMetric metric,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    final values = data
        .map((p) => metric == PerformanceMetric.accuracy
            ? p.accuracy
            : metric == PerformanceMetric.xpEarned
                ? p.xpEarned.toDouble()
                : p.questionsAnswered.toDouble())
        .toList();

    final avg = values.isNotEmpty
        ? values.reduce((a, b) => a + b) / values.length
        : 0.0;
    final max =
        values.isNotEmpty ? values.reduce((a, b) => a > b ? a : b) : 0.0;
    final min =
        values.isNotEmpty ? values.reduce((a, b) => a < b ? a : b) : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Summary Statistics',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatCard(context, 'Average', _formatValue(avg, metric)),
            _buildStatCard(context, 'Peak', _formatValue(max, metric)),
            _buildStatCard(context, 'Low', _formatValue(min, metric)),
          ],
        ),
      ],
    );
  }

  /// Build stat card
  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
  ) {
    return Card(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format value based on metric
  String _formatValue(double value, PerformanceMetric metric) {
    switch (metric) {
      case PerformanceMetric.accuracy:
        return '${value.toStringAsFixed(1)}%';
      case PerformanceMetric.xpEarned:
        if (value >= 1000) {
          return '${(value / 1000).toStringAsFixed(1)}k';
        }
        return value.toInt().toString();
      case PerformanceMetric.questionsAnswered:
        return value.toInt().toString();
    }
  }

  /// Get color for metric
  Color _getMetricColor(PerformanceMetric metric) {
    switch (metric) {
      case PerformanceMetric.accuracy:
        return Colors.blue;
      case PerformanceMetric.xpEarned:
        return Colors.green;
      case PerformanceMetric.questionsAnswered:
        return Colors.purple;
    }
  }
}
