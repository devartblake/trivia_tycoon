import 'package:flutter/material.dart';
import 'performance_line_chart.dart';

/// Component for selecting chart metric and time range
class ChartSelector extends StatelessWidget {
  final PerformanceMetric selectedMetric;
  final TimeRange selectedTimeRange;
  final ValueChanged<PerformanceMetric> onMetricChanged;
  final ValueChanged<TimeRange> onTimeRangeChanged;

  const ChartSelector({
    super.key,
    required this.selectedMetric,
    required this.selectedTimeRange,
    required this.onMetricChanged,
    required this.onTimeRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Metric selector
        _buildMetricSelector(context),
        const SizedBox(height: 16),

        // Time range selector
        _buildTimeRangeSelector(context),
      ],
    );
  }

  /// Build metric selection chips
  Widget _buildMetricSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Metric',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            _buildMetricChip(
              context,
              'Accuracy',
              PerformanceMetric.accuracy,
            ),
            _buildMetricChip(
              context,
              'XP Earned',
              PerformanceMetric.xpEarned,
            ),
            _buildMetricChip(
              context,
              'Questions',
              PerformanceMetric.questionsAnswered,
            ),
          ],
        ),
      ],
    );
  }

  /// Build single metric chip
  Widget _buildMetricChip(
    BuildContext context,
    String label,
    PerformanceMetric metric,
  ) {
    final isSelected = selectedMetric == metric;

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          onMetricChanged(metric);
        }
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).primaryColor.withValues(alpha: 0.2),
      labelStyle: TextStyle(
        color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
      ),
    );
  }

  /// Build time range selection buttons
  Widget _buildTimeRangeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Time Range',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildTimeRangeButton(context, '24h', TimeRange.hours24),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimeRangeButton(context, '7d', TimeRange.days7),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildTimeRangeButton(context, '30d', TimeRange.days30),
            ),
          ],
        ),
      ],
    );
  }

  /// Build single time range button
  Widget _buildTimeRangeButton(
    BuildContext context,
    String label,
    TimeRange range,
  ) {
    final isSelected = selectedTimeRange == range;

    return Material(
      child: InkWell(
        onTap: () => onTimeRangeChanged(range),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? null
                : Border.all(color: Colors.grey[300]!),
          ),
          child: Center(
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected ? Colors.white : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Time range enum
enum TimeRange {
  hours24,
  days7,
  days30,
}

extension TimeRangeExtension on TimeRange {
  int get days {
    switch (this) {
      case TimeRange.hours24:
        return 1;
      case TimeRange.days7:
        return 7;
      case TimeRange.days30:
        return 30;
    }
  }

  String get label {
    switch (this) {
      case TimeRange.hours24:
        return 'Last 24 Hours';
      case TimeRange.days7:
        return 'Last 7 Days';
      case TimeRange.days30:
        return 'Last 30 Days';
    }
  }
}
