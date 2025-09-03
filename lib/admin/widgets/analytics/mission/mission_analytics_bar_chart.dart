import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../game/analytics/models/mission_analytics_entry.dart';
import '../../../../game/providers/mission_filters_provider.dart';

class MissionAnalyticsBarChart extends ConsumerWidget {
  final List<MissionAnalyticsEntry> missions;
  final List<String> days;
  final List<int> completedData;
  final List<int> swappedData;

  const MissionAnalyticsBarChart({
    super.key,
    required this.missions,
    required this.days,
    required this.completedData,
    required this.swappedData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(missionFiltersProvider);

    final filtered = _filterMissions(missions, filters.timeframe);

    return BarChart(
      BarChartData(
        barGroups: List.generate(filtered.length, (index) {
          final e = filtered[index];
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(toY: e.missionsCompleted.toDouble(), color: Colors.blue),
              BarChartRodData(toY: e.missionsSwapped.toDouble(), color: Colors.orange),
            ],
          );
        }),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) => Text('${value.toInt()}'),
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true),
          ),
        ),
      ),
    );
  }

  List<MissionAnalyticsEntry> _filterMissions(List<MissionAnalyticsEntry> missions, String timeframe) {
    if (timeframe == 'Monthly') {
      return missions.take(30).toList();
    } else if (timeframe == 'Weekly') {
      return missions.take(7).toList();
    } else {
      return missions.take(7).toList();
    }
  }
}
