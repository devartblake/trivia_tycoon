import 'package:flutter/material.dart';
import 'performance_line_chart.dart';
import 'chart_selector.dart';

/// Screen displaying performance charts with selector
class PerformanceChartScreen extends StatefulWidget {
  final String? title;

  const PerformanceChartScreen({
    super.key,
    this.title = 'Performance Trends',
  });

  @override
  State<PerformanceChartScreen> createState() => _PerformanceChartScreenState();
}

class _PerformanceChartScreenState extends State<PerformanceChartScreen> {
  late PerformanceMetric selectedMetric;
  late TimeRange selectedTimeRange;

  @override
  void initState() {
    super.initState();
    selectedMetric = PerformanceMetric.accuracy;
    selectedTimeRange = TimeRange.hours24;
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _generateMockData(selectedTimeRange);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          if (widget.title != null) ...[
            Text(
              widget.title!,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 24),
          ],

          // Chart selector
          ChartSelector(
            selectedMetric: selectedMetric,
            selectedTimeRange: selectedTimeRange,
            onMetricChanged: (metric) {
              setState(() => selectedMetric = metric);
            },
            onTimeRangeChanged: (range) {
              setState(() => selectedTimeRange = range);
            },
          ),
          const SizedBox(height: 24),

          // Chart
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: PerformanceLineChart(
                data: chartData,
                metric: selectedMetric,
                lineColor: _getMetricColor(selectedMetric),
                showGrid: true,
                showLegend: true,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Stats section
          _buildStatsSection(context, chartData),
        ],
      ),
    );
  }

  /// Build stats section showing summary
  Widget _buildStatsSection(
    BuildContext context,
    List<PerformanceDataPoint> data,
  ) {
    if (data.isEmpty) return const SizedBox.shrink();

    final values = data
        .map((p) => selectedMetric == PerformanceMetric.accuracy
            ? p.accuracy
            : selectedMetric == PerformanceMetric.xpEarned
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
            _buildStatCard(context, 'Average', _formatValue(avg)),
            _buildStatCard(context, 'Peak', _formatValue(max)),
            _buildStatCard(context, 'Low', _formatValue(min)),
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
                    color: _getMetricColor(selectedMetric),
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
  String _formatValue(double value) {
    switch (selectedMetric) {
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

  /// Generate mock data for selected time range
  List<PerformanceDataPoint> _generateMockData(TimeRange timeRange) {
    final now = DateTime.now();
    final data = <PerformanceDataPoint>[];

    final dataPoints = timeRange == TimeRange.hours24
        ? 24
        : timeRange == TimeRange.days7
            ? 7
            : 30;

    for (int i = 0; i < dataPoints; i++) {
      final timestamp = timeRange == TimeRange.hours24
          ? now.subtract(Duration(hours: dataPoints - 1 - i))
          : now.subtract(Duration(days: dataPoints - 1 - i));

      // Generate realistic trending data
      final baseAccuracy = 70.0 + (i % 3) * 5.0;
      final accuracy = (baseAccuracy + (i % 2 == 0 ? 5 : -3)).clamp(0.0, 100.0);

      final xpEarned = 150 + (i * 10) + ((i % 5) * 20);
      final questionsAnswered = 8 + (i % 4);

      data.add(
        PerformanceDataPoint(
          timestamp: timestamp,
          accuracy: accuracy,
          xpEarned: xpEarned,
          questionsAnswered: questionsAnswered,
        ),
      );
    }

    return data;
  }
}
