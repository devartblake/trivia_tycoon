import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../game/repositories/question_result_repository.dart';
import '../../game/providers/question_analytics_provider.dart';
import 'performance_line_chart.dart';
import 'chart_selector.dart';

/// Provider for performance chart data with real data
final performanceChartDataProvider =
    FutureProvider.family<List<PerformanceDataPoint>, TimeRange>((ref, timeRange) {
  final repository = ref.watch(questionResultRepositoryProvider);
  return _fetchPerformanceData(repository, timeRange);
});

/// Provider for selected metric
final selectedMetricProvider =
    StateProvider<PerformanceMetric>((ref) => PerformanceMetric.accuracy);

/// Provider for selected time range
final selectedTimeRangeProvider =
    StateProvider<TimeRange>((ref) => TimeRange.hours24);

/// Combined provider for chart display
final performanceChartDisplayProvider =
    FutureProvider<List<PerformanceDataPoint>>((ref) {
  final timeRange = ref.watch(selectedTimeRangeProvider);
  return ref.watch(performanceChartDataProvider(timeRange).future);
});

/// Fetch performance data from repository with aggregation by time period
Future<List<PerformanceDataPoint>> _fetchPerformanceData(
  QuestionResultRepository repository,
  TimeRange timeRange,
) async {
  try {
    // Get recent results within time range
    final hoursAgo = timeRange.days * 24;
    final results = repository.getRecentResults(hoursAgo: hoursAgo);

    // If no real data, return empty list (screen handles this gracefully)
    if (results.isEmpty) {
      return [];
    }

    // Aggregate data by time period
    final dataPoints = <PerformanceDataPoint>[];

    if (timeRange == TimeRange.hours24) {
      // Group by hour - (totalQuestions, correctQuestions, totalXP)
      final hourlyData = <int, (int, int, int)>{};

      for (final result in results) {
        final hour = result.answeredAt.hour;
        if (!hourlyData.containsKey(hour)) {
          hourlyData[hour] = (0, 0, 0);
        }

        final data = hourlyData[hour]!;
        hourlyData[hour] = (
          data.$1 + 1,
          data.$2 + (result.isCorrect ? 1 : 0),
          data.$3 + result.xpEarned,
        );
      }

      // Create data points for each hour
      final now = DateTime.now();
      for (int i = 0; i < 24; i++) {
        final hour = i;
        final timestamp = now.subtract(Duration(hours: 23 - i));

        if (hourlyData.containsKey(hour)) {
          final data = hourlyData[hour]!;
          final totalQ = data.$1;
          final correctQ = data.$2;
          final totalXp = data.$3;
          final accuracy =
              totalQ > 0 ? (correctQ / totalQ * 100).clamp(0.0, 100.0) : 0.0;

          dataPoints.add(
            PerformanceDataPoint(
              timestamp: timestamp,
              accuracy: accuracy,
              xpEarned: totalXp,
              questionsAnswered: totalQ,
            ),
          );
        } else {
          // Add empty point for hours with no data
          dataPoints.add(
            PerformanceDataPoint(
              timestamp: timestamp,
              accuracy: 0.0,
              xpEarned: 0,
              questionsAnswered: 0,
            ),
          );
        }
      }
    } else if (timeRange == TimeRange.days7) {
      // Group by day - (totalQuestions, correctQuestions, totalXP)
      final dailyData = <int, (int, int, int)>{};

      for (final result in results) {
        final dayOfWeek = result.answeredAt.weekday;
        if (!dailyData.containsKey(dayOfWeek)) {
          dailyData[dayOfWeek] = (0, 0, 0);
        }

        final data = dailyData[dayOfWeek]!;
        dailyData[dayOfWeek] = (
          data.$1 + 1,
          data.$2 + (result.isCorrect ? 1 : 0),
          data.$3 + result.xpEarned,
        );
      }

      // Create data points for last 7 days
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final dayOffset = 6 - i;
        final timestamp = now.subtract(Duration(days: dayOffset));
        final dayOfWeek = timestamp.weekday;

        if (dailyData.containsKey(dayOfWeek)) {
          final data = dailyData[dayOfWeek]!;
          final totalQ = data.$1;
          final correctQ = data.$2;
          final totalXp = data.$3;
          final accuracy =
              totalQ > 0 ? (correctQ / totalQ * 100).clamp(0.0, 100.0) : 0.0;

          dataPoints.add(
            PerformanceDataPoint(
              timestamp: timestamp,
              accuracy: accuracy,
              xpEarned: totalXp,
              questionsAnswered: totalQ,
            ),
          );
        } else {
          dataPoints.add(
            PerformanceDataPoint(
              timestamp: timestamp,
              accuracy: 0.0,
              xpEarned: 0,
              questionsAnswered: 0,
            ),
          );
        }
      }
    } else {
      // Group by day for 30 days - (totalQuestions, correctQuestions, totalXP)
      final dailyData = <DateTime, (int, int, int)>{};

      for (final result in results) {
        final day = DateTime(
          result.answeredAt.year,
          result.answeredAt.month,
          result.answeredAt.day,
        );

        if (!dailyData.containsKey(day)) {
          dailyData[day] = (0, 0, 0);
        }

        final data = dailyData[day]!;
        dailyData[day] = (
          data.$1 + 1,
          data.$2 + (result.isCorrect ? 1 : 0),
          data.$3 + result.xpEarned,
        );
      }

      // Create data points for last 30 days
      final now = DateTime.now();
      for (int i = 0; i < 30; i++) {
        final dayOffset = 29 - i;
        final timestamp = now.subtract(Duration(days: dayOffset));
        final day = DateTime(timestamp.year, timestamp.month, timestamp.day);

        if (dailyData.containsKey(day)) {
          final data = dailyData[day]!;
          final totalQ = data.$1;
          final correctQ = data.$2;
          final totalXp = data.$3;
          final accuracy =
              totalQ > 0 ? (correctQ / totalQ * 100).clamp(0.0, 100.0) : 0.0;

          dataPoints.add(
            PerformanceDataPoint(
              timestamp: timestamp,
              accuracy: accuracy,
              xpEarned: totalXp,
              questionsAnswered: totalQ,
            ),
          );
        } else {
          dataPoints.add(
            PerformanceDataPoint(
              timestamp: timestamp,
              accuracy: 0.0,
              xpEarned: 0,
              questionsAnswered: 0,
            ),
          );
        }
      }
    }

    return dataPoints;
  } catch (e) {
    // Fallback to empty data on error
    print('Error fetching performance data: $e');
    return [];
  }
}
