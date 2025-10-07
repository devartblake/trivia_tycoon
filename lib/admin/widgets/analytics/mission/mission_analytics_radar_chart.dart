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
      return Container(
        height: 300,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.radar,
                size: 48,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Not enough data for radar chart',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'At least 3 data points required',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Legend
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _buildLegendItem('Completed', const Color(0xFF10B981)),
            _buildLegendItem('Swapped', const Color(0xFFF59E0B)),
            _buildLegendItem('XP Earned', const Color(0xFF6366F1)),
          ],
        ),
        const SizedBox(height: 16),

        // Chart
        AspectRatio(
          aspectRatio: 1.3,
          child: RadarChart(
            RadarChartData(
              radarTouchData: RadarTouchData(
                enabled: true,
                touchCallback: (FlTouchEvent event, response) {},
              ),
              dataSets: [
                RadarDataSet(
                  dataEntries: filtered
                      .map((e) => RadarEntry(value: e.missionsCompleted.toDouble()))
                      .toList(),
                  borderColor: const Color(0xFF10B981),
                  fillColor: const Color(0xFF10B981).withOpacity(0.2),
                  borderWidth: 2,
                  entryRadius: 4,
                ),
                RadarDataSet(
                  dataEntries: filtered
                      .map((e) => RadarEntry(value: e.missionsSwapped.toDouble()))
                      .toList(),
                  borderColor: const Color(0xFFF59E0B),
                  fillColor: const Color(0xFFF59E0B).withOpacity(0.2),
                  borderWidth: 2,
                  entryRadius: 4,
                ),
                RadarDataSet(
                  dataEntries: filtered
                      .map((e) => RadarEntry(value: e.xpEarned.toDouble()))
                      .toList(),
                  borderColor: const Color(0xFF6366F1),
                  fillColor: const Color(0xFF6366F1).withOpacity(0.2),
                  borderWidth: 2,
                  entryRadius: 4,
                ),
              ],
              radarShape: RadarShape.polygon,
              titlePositionPercentageOffset: 0.15,
              getTitle: (index, angle) => RadarChartTitle(
                text: _getLabel(index, filters.timeframe),
                angle: angle,
              ),
              tickCount: 5,
              gridBorderData: BorderSide(color: Colors.grey[300]!, width: 1),
              tickBorderData: BorderSide(color: Colors.grey[300]!, width: 1),
              radarBackgroundColor: Colors.transparent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  List<MissionAnalyticsEntry> _filterMissions(
      List<MissionAnalyticsEntry> missions, String timeframe) {
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
