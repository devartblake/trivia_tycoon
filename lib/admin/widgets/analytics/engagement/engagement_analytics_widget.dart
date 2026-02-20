import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../game/analytics/models/engagement_entry.dart';
import '../../../../game/providers/mission_filters_provider.dart';

class EngagementAnalyticsChart extends ConsumerWidget {
  final List<EngagementEntry> entries;

  const EngagementAnalyticsChart({super.key, required this.entries});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(missionFiltersProvider);
    final filtered = entries.take(filters.timeframe == 'Monthly' ? 30 : 7).toList();

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
                color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.people,
                size: 48,
                color: Color(0xFFF59E0B),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No engagement data available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data will appear as users engage',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    final maxEngagement = filtered.map((e) => e.sessionsPerUser).reduce((a, b) => a > b ? a : b).toDouble();
    final minEngagement = filtered.map((e) => e.sessionsPerUser).reduce((a, b) => a < b ? a : b).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stats Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFF59E0B), Color(0xFFFBBF24)],
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Current',
                  filtered.first.sessionsPerUser.toStringAsFixed(1),
                  Icons.today,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              Expanded(
                child: _buildStatItem(
                  'Average',
                  (filtered.map((e) => e.sessionsPerUser).reduce((a, b) => a + b) / filtered.length).toStringAsFixed(1),
                  Icons.trending_up,
                ),
              ),
              Container(width: 1, height: 40, color: Colors.white30),
              Expanded(
                child: _buildStatItem(
                  'Peak',
                  maxEngagement.toStringAsFixed(1),
                  Icons.star,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Chart
        SizedBox(
          height: 250,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxEngagement / 5).clamp(1, double.infinity),
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey[200]!,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() >= 0 && value.toInt() < filtered.length) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _getLabel(value.toInt(), filters.timeframe),
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
                          value.toStringAsFixed(1),
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
              borderData: FlBorderData(
                show: true,
                border: Border(
                  left: BorderSide(color: Colors.grey[300]!, width: 1),
                  bottom: BorderSide(color: Colors.grey[300]!, width: 1),
                ),
              ),
              minY: (minEngagement - 1).clamp(0, double.infinity),
              maxY: maxEngagement + 2,
              lineBarsData: [
                LineChartBarData(
                  spots: filtered
                      .asMap()
                      .entries
                      .map((e) => FlSpot(
                    e.key.toDouble(),
                    e.value.sessionsPerUser.toDouble(),
                  ))
                      .toList(),
                  isCurved: true,
                  color: const Color(0xFFF59E0B),
                  barWidth: 3,
                  isStrokeCapRound: true,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) {
                      return FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2,
                        strokeColor: const Color(0xFFF59E0B),
                      );
                    },
                  ),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFFF59E0B).withValues(alpha: 0.3),
                        const Color(0xFFF59E0B).withValues(alpha: 0.05),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ],
              lineTouchData: LineTouchData(
                enabled: true,
                touchTooltipData: LineTouchTooltipData(
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((spot) {
                      return LineTooltipItem(
                        '${spot.y.toStringAsFixed(1)} sessions',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      );
                    }).toList();
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white, size: 20),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
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
