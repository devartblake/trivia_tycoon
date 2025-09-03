import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../game/analytics/models/mission_analytics_entry.dart';
import '../../../../game/providers/mission_filters_provider.dart';

class MissionAnalyticsRadarChart extends ConsumerWidget {
  final List<MissionAnalyticsEntry> missions;
  final List<int> missionsCompleted;
  final List<int> missionsSwapped;
  final List<int> xpEarned;
  final String labelMode;

  const MissionAnalyticsRadarChart({
    super.key,
    required this.missions,
    required this.missionsCompleted,
    required this.missionsSwapped,
    required this.xpEarned,
    this.labelMode = 'Daily',
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(missionFiltersProvider);

    final List<MissionAnalyticsEntry> filtered = _filterMissions(missions, filters.timeframe);

    if (filtered.length < 3) {
      return const SizedBox(height: 200, child: Center(child: Text('Not enough data for radar chart.')));
    }

    return AspectRatio(
      aspectRatio: 1.3,
      child: RadarChart(
        RadarChartData(
          radarTouchData: RadarTouchData(enabled: true),
          dataSets: [
            RadarDataSet(
              dataEntries: filtered.map((e) => RadarEntry(value: e.missionsCompleted.toDouble())).toList(),
              borderColor: Colors.blue,
              fillColor: Colors.blue.withOpacity(0.4),
              entryRadius: 3,
            ),
            RadarDataSet(
              dataEntries: filtered.map((e) => RadarEntry(value: e.missionsSwapped.toDouble())).toList(),
              borderColor: Colors.orange,
              fillColor: Colors.orange.withOpacity(0.4),
              entryRadius: 3,
            ),
            RadarDataSet(
              dataEntries: filtered.map((e) => RadarEntry(value: e.xpEarned.toDouble())).toList(),
              borderColor: Colors.green,
              fillColor: Colors.green.withOpacity(0.4),
              entryRadius: 3,
            ),
          ],
          radarShape: RadarShape.polygon,
          titlePositionPercentageOffset: 0.2,
          getTitle: (index, angle) => RadarChartTitle(
            text: _getLabel(index, filters.timeframe),
            angle: angle,
          ),
          tickCount: 5,
          gridBorderData: const BorderSide(color: Colors.grey),
          tickBorderData: const BorderSide(color: Colors.grey),
        ),
      ),
    );
  }

  List<MissionAnalyticsEntry> _filterMissions(List<MissionAnalyticsEntry> missions, String timeframe) {
    if (timeframe == 'Weekly') {
      return missions.take(7).toList();
    } else if (timeframe == 'Monthly') {
      return missions.take(30).toList();
    } else {
      return missions.take(7).toList();
    }
  }

  String _getLabel(int index, String timeframe) {
    switch (timeframe) {
      case 'Weekly':
        return 'W${index + 1}';
      case 'Monthly':
        return 'M${index + 1}';
      default:
        return 'D${index + 1}';
    }
  }
}