import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../synaptix/theme/synaptix_theme_extension.dart';

/// Enum for selectable metrics
enum PerformanceMetric {
  accuracy,
  xpEarned,
  questionsAnswered,
}

/// Line chart showing 24-hour performance trending
class PerformanceLineChart extends StatefulWidget {
  final List<PerformanceDataPoint> data;
  final String title;
  final PerformanceMetric metric;
  final bool showGrid;
  final bool showLegend;
  final Color? lineColor;
  final double? maxValue;

  const PerformanceLineChart({
    super.key,
    required this.data,
    this.title = 'Performance Trend',
    this.metric = PerformanceMetric.accuracy,
    this.showGrid = true,
    this.showLegend = true,
    this.lineColor,
    this.maxValue,
  });

  @override
  State<PerformanceLineChart> createState() => _PerformanceLineChartState();
}

class _PerformanceLineChartState extends State<PerformanceLineChart> {
  int? touchedIndex;

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        if (widget.title.isNotEmpty) ...[
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
        ],

        // Chart
        SizedBox(
          height: 300,
          child: _buildChart(context),
        ),
        const SizedBox(height: 16),

        // Legend
        if (widget.showLegend) _buildLegend(context),
      ],
    );
  }

  /// Build the line chart
  Widget _buildChart(BuildContext context) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final lineColor = widget.lineColor ??
        synaptix?.chartPalette.first ??
        Theme.of(context).primaryColor;
    final spots = _convertDataToSpots();

    if (spots.isEmpty) {
      return _buildEmptyState(context);
    }

    final maxY = widget.maxValue ?? _calculateMaxValue();

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: widget.showGrid,
          drawHorizontalLine: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey[200],
              strokeWidth: 1,
            );
          },
        ),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              getTitlesWidget: (value, meta) {
                return _buildBottomTitle(value, meta);
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                return _buildLeftTitle(value, meta);
              },
            ),
          ),
        ),
        borderData: FlBorderData(
          show: true,
          border: Border(
            left: BorderSide(color: Colors.grey[300]!, width: 1),
            bottom: BorderSide(color: Colors.grey[300]!, width: 1),
          ),
        ),
        minX: 0,
        maxX: (spots.length - 1).toDouble(),
        minY: 0,
        maxY: maxY,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: lineColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) {
                final isSelected = touchedIndex == index;
                return FlDotCirclePainter(
                  radius: isSelected ? 6 : 4,
                  color: lineColor,
                  strokeWidth: isSelected ? 2 : 1,
                  strokeColor: isSelected
                      ? Colors.white
                      : lineColor.withValues(alpha: 0.5),
                );
              },
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                colors: [
                  lineColor.withValues(alpha: 0.3),
                  lineColor.withValues(alpha: 0.0),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
        lineTouchData: LineTouchData(
          handleBuiltInTouches: true,
          touchCallback: (FlTouchEvent event, LineTouchResponse? response) {
            if (event is FlTapUpEvent || event is FlPanEndEvent) {
              setState(() {
                touchedIndex = null;
              });
            } else {
              setState(() {
                touchedIndex = response?.lineBarSpots?.first.x.toInt();
              });
            }
          },
          mouseCursorResolver: (event, response) {
            return response == null || response.lineBarSpots == null
                ? MouseCursor.defer
                : SystemMouseCursors.click;
          },
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes
                .map(
                  (index) => TouchedSpotIndicatorData(
                    FlLine(
                      color: Colors.grey[300],
                      strokeWidth: 4,
                    ),
                    FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) =>
                          FlDotCirclePainter(
                        radius: 8,
                        color: barData.color ?? Colors.blue,
                        strokeWidth: 2,
                        strokeColor: Colors.white,
                      ),
                    ),
                  ),
                )
                .toList();
          },
        ),
      ),
    );
  }

  /// Convert data points to chart spots
  List<FlSpot> _convertDataToSpots() {
    return widget.data.asMap().entries.map((entry) {
      final value = _extractMetricValue(entry.value);
      return FlSpot(entry.key.toDouble(), value);
    }).toList();
  }

  /// Extract metric value from data point
  double _extractMetricValue(PerformanceDataPoint point) {
    switch (widget.metric) {
      case PerformanceMetric.accuracy:
        return point.accuracy;
      case PerformanceMetric.xpEarned:
        return point.xpEarned.toDouble();
      case PerformanceMetric.questionsAnswered:
        return point.questionsAnswered.toDouble();
    }
  }

  /// Calculate max Y value for chart
  double _calculateMaxValue() {
    if (widget.data.isEmpty) return 100;

    final values = widget.data.map(_extractMetricValue).toList();
    final max = values.reduce((a, b) => a > b ? a : b);

    // Round up to next 10%
    return ((max + 10) / 10).ceil() * 10.toDouble();
  }

  /// Build bottom axis title
  Widget _buildBottomTitle(double value, TitleMeta meta) {
    if (value == 0 || value == (widget.data.length - 1).toDouble()) {
      return Text(
        _formatTimeLabel(value.toInt()),
        style: TextStyle(
          color: Colors.grey[600],
          fontSize: 12,
        ),
      );
    }
    return const SizedBox.shrink();
  }

  /// Build left axis title
  Widget _buildLeftTitle(double value, TitleMeta meta) {
    return Text(
      _formatYAxisLabel(value),
      style: TextStyle(
        color: Colors.grey[600],
        fontSize: 10,
      ),
    );
  }

  /// Format time labels
  String _formatTimeLabel(int index) {
    final hour = (index % 24).toString().padLeft(2, '0');
    return '$hour:00';
  }

  /// Format Y-axis labels
  String _formatYAxisLabel(double value) {
    switch (widget.metric) {
      case PerformanceMetric.accuracy:
        return '${value.toInt()}%';
      case PerformanceMetric.xpEarned:
        if (value >= 1000) {
          return '${(value / 1000).toStringAsFixed(1)}k';
        }
        return value.toInt().toString();
      case PerformanceMetric.questionsAnswered:
        return value.toInt().toString();
    }
  }

  /// Build legend
  Widget _buildLegend(BuildContext context) {
    final color = widget.lineColor ?? Theme.of(context).primaryColor;
    final metricName = _getMetricName();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 3,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            metricName,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: Colors.grey[700],
                ),
          ),
        ],
      ),
    );
  }

  /// Get metric display name
  String _getMetricName() {
    switch (widget.metric) {
      case PerformanceMetric.accuracy:
        return 'Accuracy Trend (last 24 hours)';
      case PerformanceMetric.xpEarned:
        return 'XP Earned Trend (last 24 hours)';
      case PerformanceMetric.questionsAnswered:
        return 'Questions Answered Trend (last 24 hours)';
    }
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No data available',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ],
      ),
    );
  }
}

/// Data point for performance chart
class PerformanceDataPoint {
  final DateTime timestamp;
  final double accuracy; // 0-100
  final int xpEarned;
  final int questionsAnswered;

  PerformanceDataPoint({
    required this.timestamp,
    required this.accuracy,
    required this.xpEarned,
    required this.questionsAnswered,
  });
}
