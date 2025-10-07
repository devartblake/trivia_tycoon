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

    if (filtered.isEmpty) {
      return Container(
        height: 300,
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.bar_chart,
                size: 48,
                color: Color(0xFF3B82F6),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No data available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start completing missions to see data',
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
          ],
        ),
        const SizedBox(height: 16),

        // Chart
        SizedBox(
          height: 280,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: _getMaxValue(filtered) * 1.2,
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    final label = rodIndex == 0 ? 'Completed' : 'Swapped';
                    return BarTooltipItem(
                      '$label: ${rod.toY.toInt()}',
                      const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    );
                  },
                ),
              ),
              barGroups: List.generate(filtered.length, (index) {
                final e = filtered[index];
                return BarChartGroupData(
                  x: index,
                  barRods: [
                    BarChartRodData(
                      toY: e.missionsCompleted.toDouble(),
                      color: const Color(0xFF10B981),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF10B981), Color(0xFF059669)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                    BarChartRodData(
                      toY: e.missionsSwapped.toDouble(),
                      color: const Color(0xFFF59E0B),
                      width: 16,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(4),
                      ),
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                      ),
                    ),
                  ],
                  barsSpace: 8,
                );
              }),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < filtered.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _getBottomLabel(value.toInt(), filters.timeframe),
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        );
                      }
                      return const Text('');
                    },
                    reservedSize: 30,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _getMaxValue(filtered) / 5,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 1),
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
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
            gradient: LinearGradient(
              colors: [
                color,
                color == const Color(0xFF10B981)
                    ? const Color(0xFF059669)
                    : const Color(0xFFF97316),
              ],
            ),
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

  double _getMaxValue(List<MissionAnalyticsEntry> filtered) {
    double max = 0;
    for (var entry in filtered) {
      if (entry.missionsCompleted > max) max = entry.missionsCompleted.toDouble();
      if (entry.missionsSwapped > max) max = entry.missionsSwapped.toDouble();
    }
    return max > 0 ? max : 10;
  }

  String _getBottomLabel(int index, String timeframe) {
    switch (timeframe) {
      case 'Weekly':
        return 'W${index + 1}';
      case 'Monthly':
        return 'M${index + 1}';
      default:
        return 'D${index + 1}';
    }
  }

  List<MissionAnalyticsEntry> _filterMissions(
      List<MissionAnalyticsEntry> missions, String timeframe) {
    if (timeframe == 'Monthly') {
      return missions.take(30).toList();
    } else if (timeframe == 'Weekly') {
      return missions.take(7).toList();
    } else {
      return missions.take(7).toList();
    }
  }
}
