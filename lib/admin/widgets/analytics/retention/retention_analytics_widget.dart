import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../game/analytics/models/retention_entry.dart';
import '../../../../game/providers/mission_filters_provider.dart';

class RetentionAnalyticsChart extends ConsumerWidget {
  final List<RetentionEntry> entries;

  const RetentionAnalyticsChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(missionFiltersProvider);
    final filtered = entries.take(filters.timeframe == 'Monthly' ? 30 : 7).toList();

    return AspectRatio(
      aspectRatio: 1.6,
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: filtered.asMap().entries.map((e) => FlSpot(e.key.toDouble(), e.value.retentionPercentage.toDouble())).toList(),
              color: Colors.green,
              isCurved: true,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }
}