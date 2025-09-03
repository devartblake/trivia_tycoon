import '../../providers/timeline_filter_provider.dart';
import '../models/engagement_entry.dart';
import '../models/mission_analytics_entry.dart';
import '../models/retention_entry.dart';

enum AnalyticsTimeframe { daily, weekly, monthly }

class AnalyticsAggregationService {
  /// Aggregates mission analytics based on timeframe
  static List<MissionAnalyticsEntry> aggregateMissionsBy(
      AnalyticsTimeframe timeframe,
      List<MissionAnalyticsEntry> rawData,
      ) {
    final Map<String, MissionAnalyticsEntry> aggregated = {};

    for (var entry in rawData) {
      final bucket = _getBucketKey(entry.date, timeframe);

      aggregated.update(
        bucket,
            (existing) => existing.copyWith(
          missionsCompleted: existing.missionsCompleted + entry.missionsCompleted,
          missionsSwapped: existing.missionsSwapped + entry.missionsSwapped,
          xpEarned: existing.xpEarned + entry.xpEarned,
        ),
        ifAbsent: () => entry,
      );
    }

    return aggregated.values.toList();
  }

  /// Aggregates engagement analytics based on timeframe
  static List<EngagementEntry> aggregateEngagementBy(
      AnalyticsTimeframe timeframe,
      List<EngagementEntry> rawData,
      ) {
    final Map<String, EngagementEntry> aggregated = {};

    for (var entry in rawData) {
      final bucket = _getBucketKey(entry.date, timeframe);

      aggregated.update(
        bucket,
            (existing) => existing.copyWith(
          activeUsers: existing.activeUsers + entry.activeUsers,
          averageSessionLength: ((existing.averageSessionLength + entry.averageSessionLength) ~/ 2),
          sessionsPerUser: ((existing.sessionsPerUser + entry.sessionsPerUser) ~/ 2),
        ),
        ifAbsent: () => entry,
      );
    }

    return aggregated.values.toList();
  }

  /// Aggregates retention analytics based on timeframe
  static List<RetentionEntry> aggregateRetentionBy(
      AnalyticsTimeframe timeframe,
      List<RetentionEntry> rawData,
      ) {
    final Map<String, RetentionEntry> aggregated = {};

    for (var entry in rawData) {
      final bucket = _getBucketKey(entry.date, timeframe);

      aggregated.update(
        bucket,
            (existing) => existing.copyWith(
          day1Retention: (existing.day1Retention + entry.day1Retention) ~/ 2,
          day7Retention: (existing.day7Retention + entry.day7Retention) ~/ 2,
          day30Retention: (existing.day30Retention + entry.day30Retention) ~/ 2,
        ),
        ifAbsent: () => entry,
      );
    }

    return aggregated.values.toList();
  }

  /// Helper to filter by timeline range
  static List<MissionAnalyticsEntry> filterByTimeline(
      List<MissionAnalyticsEntry> missions,
      TimelineRange range,
      ) {
    final now = DateTime.now();
    return missions.where((m) {
      final diff = now.difference(m.date).inDays;
      switch (range) {
        case TimelineRange.last7Days:
          return diff <= 7;
        case TimelineRange.last14Days:
          return diff <= 14;
        case TimelineRange.last30Days:
          return diff <= 30;
        case TimelineRange.last90Days:
          return diff <= 90;
      }
    }).toList();
  }

  /// Helper to format dates into daily, weekly, or monthly buckets
  static String _getBucketKey(DateTime date, AnalyticsTimeframe timeframe) {
    switch (timeframe) {
      case AnalyticsTimeframe.daily:
        return '${date.year}-${date.month}-${date.day}';
      case AnalyticsTimeframe.weekly:
        return '${date.year}-W${_weekOfYear(date)}';
      case AnalyticsTimeframe.monthly:
        return '${date.year}-${date.month}';
    }
  }

  /// Week number calculation
  static int _weekOfYear(DateTime date) {
    final firstDay = DateTime(date.year, 1, 1);
    final diff = date.difference(firstDay);
    return (diff.inDays / 7).ceil();
  }

  static List<MissionAnalyticsEntry> aggregateMissions(
      List<MissionAnalyticsEntry> missions,
      AnalyticsTimeframe timeframe,
      TimelineRange timeline,
      String userType,
      ) {
    final now = DateTime.now();

    final filtered = missions.where((m) {
      final diff = now.difference(m.date).inDays;
      final userTypeMatch = userType == 'all'
          || (userType == 'premium' && m.userType == 'premium')
          || (userType == 'free' && m.userType == 'free');

      bool timelineMatch;
      switch (timeline) {
        case TimelineRange.last7Days:
          timelineMatch = diff <= 7;
          break;
        case TimelineRange.last14Days:
          timelineMatch = diff <= 14;
          break;
        case TimelineRange.last30Days:
          timelineMatch = diff <= 30;
          break;
        case TimelineRange.last90Days:
          timelineMatch = diff <= 90;
          break;
      }

      return userTypeMatch && timelineMatch;
    }).toList();

    return aggregateMissionsBy(timeframe, filtered);
  }

  static List<EngagementEntry> aggregateEngagements(
      List<EngagementEntry> entries,
      TimelineRange timeline,
      ) {
    final now = DateTime.now();

    final filtered = entries.where((e) {
      final diff = now.difference(e.date).inDays;
      switch (timeline) {
        case TimelineRange.last7Days:
          return diff <= 7;
        case TimelineRange.last14Days:
          return diff <= 14;
        case TimelineRange.last30Days:
          return diff <= 30;
        case TimelineRange.last90Days:
          return diff <= 90;
      }
    }).toList();

    return filtered;
  }

  static List<RetentionEntry> aggregateRetention(
      List<RetentionEntry> entries,
      TimelineRange timeline,
      ) {
    final now = DateTime.now();

    final filtered = entries.where((e) {
      final diff = now.difference(e.date).inDays;
      switch (timeline) {
        case TimelineRange.last7Days:
          return diff <= 7;
        case TimelineRange.last14Days:
          return diff <= 14;
        case TimelineRange.last30Days:
          return diff <= 30;
        case TimelineRange.last90Days:
          return diff <= 90;
      }
    }).toList();

    return filtered;
  }

  static AnalyticsTimeframe parseTimeframe(String timeframe) {
    switch (timeframe.toLowerCase()) {
      case 'weekly':
        return AnalyticsTimeframe.weekly;
      case 'monthly':
        return AnalyticsTimeframe.monthly;
      case 'daily':
      default:
        return AnalyticsTimeframe.daily;
    }
  }
}
