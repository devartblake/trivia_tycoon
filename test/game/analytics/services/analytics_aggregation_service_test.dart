import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/analytics/models/engagement_entry.dart';
import 'package:synaptix/game/analytics/models/mission_analytics_entry.dart';
import 'package:synaptix/game/analytics/models/retention_entry.dart';
import 'package:synaptix/game/analytics/services/analytics_aggregation_service.dart';
import 'package:synaptix/game/providers/timeline_filter_provider.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MissionAnalyticsEntry _mission({
  required DateTime date,
  int completed = 5,
  int swapped = 1,
  int xp = 100,
  String userType = 'free',
}) =>
    MissionAnalyticsEntry(
      date: date,
      missionsCompleted: completed,
      missionsSwapped: swapped,
      xpEarned: xp,
      userType: userType,
    );

EngagementEntry _engagement({
  required DateTime date,
  int activeUsers = 100,
  int avgSession = 10,
  int sessionsPerUser = 3,
}) =>
    EngagementEntry(
      date: date,
      activeUsers: activeUsers,
      averageSessionLength: avgSession,
      sessionsPerUser: sessionsPerUser,
    );

RetentionEntry _retention({
  required DateTime date,
  int day1 = 80,
  int day7 = 60,
  int day30 = 40,
}) =>
    RetentionEntry(
      date: date,
      day1Retention: day1,
      day7Retention: day7,
      day30Retention: day30,
    );

// Known fixed date — same day bucket
final _dayA = DateTime(2026, 1, 15);
final _dayB = DateTime(2026, 1, 20);

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // parseTimeframe
  // -------------------------------------------------------------------------

  group('AnalyticsAggregationService.parseTimeframe', () {
    test('"daily" → AnalyticsTimeframe.daily', () {
      expect(
        AnalyticsAggregationService.parseTimeframe('daily'),
        AnalyticsTimeframe.daily,
      );
    });

    test('"weekly" → AnalyticsTimeframe.weekly', () {
      expect(
        AnalyticsAggregationService.parseTimeframe('weekly'),
        AnalyticsTimeframe.weekly,
      );
    });

    test('"monthly" → AnalyticsTimeframe.monthly', () {
      expect(
        AnalyticsAggregationService.parseTimeframe('monthly'),
        AnalyticsTimeframe.monthly,
      );
    });

    test('unknown string defaults to daily', () {
      expect(
        AnalyticsAggregationService.parseTimeframe('unknown'),
        AnalyticsTimeframe.daily,
      );
    });

    test('empty string defaults to daily', () {
      expect(
        AnalyticsAggregationService.parseTimeframe(''),
        AnalyticsTimeframe.daily,
      );
    });

    test('case-insensitive: "WEEKLY" → weekly', () {
      expect(
        AnalyticsAggregationService.parseTimeframe('WEEKLY'),
        AnalyticsTimeframe.weekly,
      );
    });
  });

  // -------------------------------------------------------------------------
  // aggregateMissionsBy
  // -------------------------------------------------------------------------

  group('AnalyticsAggregationService.aggregateMissionsBy', () {
    test('empty input returns empty list', () {
      expect(
        AnalyticsAggregationService.aggregateMissionsBy(
            AnalyticsTimeframe.daily, []),
        isEmpty,
      );
    });

    test('single entry is returned unchanged', () {
      final entry = _mission(date: _dayA, completed: 3, swapped: 1, xp: 50);
      final result = AnalyticsAggregationService.aggregateMissionsBy(
          AnalyticsTimeframe.daily, [entry]);
      expect(result.length, 1);
      expect(result[0].missionsCompleted, 3);
    });

    test('two entries on same day are summed (daily)', () {
      final entries = [
        _mission(date: _dayA, completed: 4, swapped: 2, xp: 100),
        _mission(date: _dayA, completed: 6, swapped: 1, xp: 200),
      ];
      final result = AnalyticsAggregationService.aggregateMissionsBy(
          AnalyticsTimeframe.daily, entries);
      expect(result.length, 1);
      expect(result[0].missionsCompleted, 10);
      expect(result[0].missionsSwapped, 3);
      expect(result[0].xpEarned, 300);
    });

    test('entries on different days produce separate buckets (daily)', () {
      final entries = [
        _mission(date: _dayA, completed: 5),
        _mission(date: _dayB, completed: 7),
      ];
      final result = AnalyticsAggregationService.aggregateMissionsBy(
          AnalyticsTimeframe.daily, entries);
      expect(result.length, 2);
    });

    test('entries in same month are merged (monthly)', () {
      final jan5 = DateTime(2026, 1, 5);
      final jan20 = DateTime(2026, 1, 20);
      final entries = [
        _mission(date: jan5, completed: 10, xp: 500),
        _mission(date: jan20, completed: 5, xp: 250),
      ];
      final result = AnalyticsAggregationService.aggregateMissionsBy(
          AnalyticsTimeframe.monthly, entries);
      expect(result.length, 1);
      expect(result[0].missionsCompleted, 15);
      expect(result[0].xpEarned, 750);
    });

    test('entries in different months produce separate buckets (monthly)', () {
      final jan = DateTime(2026, 1, 10);
      final feb = DateTime(2026, 2, 10);
      final result = AnalyticsAggregationService.aggregateMissionsBy(
        AnalyticsTimeframe.monthly,
        [_mission(date: jan), _mission(date: feb)],
      );
      expect(result.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // aggregateEngagementBy
  // -------------------------------------------------------------------------

  group('AnalyticsAggregationService.aggregateEngagementBy', () {
    test('empty input returns empty list', () {
      expect(
        AnalyticsAggregationService.aggregateEngagementBy(
            AnalyticsTimeframe.daily, []),
        isEmpty,
      );
    });

    test('single entry returned unchanged', () {
      final entry = _engagement(date: _dayA, activeUsers: 200);
      final result = AnalyticsAggregationService.aggregateEngagementBy(
          AnalyticsTimeframe.daily, [entry]);
      expect(result[0].activeUsers, 200);
    });

    test(
        'two entries on same day: activeUsers summed, session averages taken (daily)',
        () {
      final entries = [
        _engagement(
            date: _dayA, activeUsers: 100, avgSession: 10, sessionsPerUser: 4),
        _engagement(
            date: _dayA, activeUsers: 200, avgSession: 20, sessionsPerUser: 6),
      ];
      final result = AnalyticsAggregationService.aggregateEngagementBy(
          AnalyticsTimeframe.daily, entries);
      expect(result.length, 1);
      expect(result[0].activeUsers, 300);
      // Integer average: (10+20)~/2 = 15
      expect(result[0].averageSessionLength, 15);
      // Integer average: (4+6)~/2 = 5
      expect(result[0].sessionsPerUser, 5);
    });

    test('entries on different days are separate (daily)', () {
      final result = AnalyticsAggregationService.aggregateEngagementBy(
        AnalyticsTimeframe.daily,
        [
          _engagement(date: _dayA, activeUsers: 100),
          _engagement(date: _dayB, activeUsers: 200),
        ],
      );
      expect(result.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // aggregateRetentionBy
  // -------------------------------------------------------------------------

  group('AnalyticsAggregationService.aggregateRetentionBy', () {
    test('empty input returns empty list', () {
      expect(
        AnalyticsAggregationService.aggregateRetentionBy(
            AnalyticsTimeframe.daily, []),
        isEmpty,
      );
    });

    test('single entry returned unchanged', () {
      final entry = _retention(date: _dayA, day1: 90);
      final result = AnalyticsAggregationService.aggregateRetentionBy(
          AnalyticsTimeframe.daily, [entry]);
      expect(result[0].day1Retention, 90);
    });

    test('two entries on same day produce integer averages (daily)', () {
      final entries = [
        _retention(date: _dayA, day1: 80, day7: 60, day30: 40),
        _retention(date: _dayA, day1: 60, day7: 40, day30: 20),
      ];
      final result = AnalyticsAggregationService.aggregateRetentionBy(
          AnalyticsTimeframe.daily, entries);
      expect(result.length, 1);
      // (80+60)~/2 = 70
      expect(result[0].day1Retention, 70);
      // (60+40)~/2 = 50
      expect(result[0].day7Retention, 50);
      // (40+20)~/2 = 30
      expect(result[0].day30Retention, 30);
    });
  });

  // -------------------------------------------------------------------------
  // filterByTimeline
  // -------------------------------------------------------------------------

  group('AnalyticsAggregationService.filterByTimeline', () {
    final now = DateTime.now();

    late MissionAnalyticsEntry within7;
    late MissionAnalyticsEntry within14;
    late MissionAnalyticsEntry within30;
    late MissionAnalyticsEntry within90;
    late MissionAnalyticsEntry beyond90;

    setUp(() {
      within7 = _mission(date: now.subtract(const Duration(days: 3)));
      within14 = _mission(date: now.subtract(const Duration(days: 10)));
      within30 = _mission(date: now.subtract(const Duration(days: 20)));
      within90 = _mission(date: now.subtract(const Duration(days: 45)));
      beyond90 = _mission(date: now.subtract(const Duration(days: 100)));
    });

    test('last7Days includes entry from 3 days ago', () {
      final result = AnalyticsAggregationService.filterByTimeline(
          [within7, within14], TimelineRange.last7Days);
      expect(result, contains(within7));
      expect(result, isNot(contains(within14)));
    });

    test('last14Days includes entries from ≤14 days ago', () {
      final result = AnalyticsAggregationService.filterByTimeline(
          [within7, within14, within30], TimelineRange.last14Days);
      expect(result, containsAll([within7, within14]));
      expect(result, isNot(contains(within30)));
    });

    test('last30Days includes entries from ≤30 days ago', () {
      final result = AnalyticsAggregationService.filterByTimeline(
          [within14, within30, within90], TimelineRange.last30Days);
      expect(result, containsAll([within14, within30]));
      expect(result, isNot(contains(within90)));
    });

    test('last90Days includes entries from ≤90 days ago', () {
      final result = AnalyticsAggregationService.filterByTimeline(
          [within30, within90, beyond90], TimelineRange.last90Days);
      expect(result, containsAll([within30, within90]));
      expect(result, isNot(contains(beyond90)));
    });

    test('empty input returns empty list', () {
      expect(
        AnalyticsAggregationService.filterByTimeline(
            [], TimelineRange.last7Days),
        isEmpty,
      );
    });
  });

  // -------------------------------------------------------------------------
  // aggregateMissions (combined filter + aggregate)
  // -------------------------------------------------------------------------

  group('AnalyticsAggregationService.aggregateMissions', () {
    final now = DateTime.now();
    final recent = now.subtract(const Duration(days: 5));
    final old = now.subtract(const Duration(days: 100));

    test('userType "all" includes both premium and free', () {
      final result = AnalyticsAggregationService.aggregateMissions(
        [
          _mission(date: recent, userType: 'premium', completed: 3),
          _mission(date: recent, userType: 'free', completed: 4),
        ],
        AnalyticsTimeframe.daily,
        TimelineRange.last7Days,
        'all',
      );
      // Both entries are on the same day and have the same bucket → merged
      expect(result.length, 1);
      expect(result[0].missionsCompleted, 7);
    });

    test('userType "premium" excludes free entries', () {
      final result = AnalyticsAggregationService.aggregateMissions(
        [
          _mission(date: recent, userType: 'premium', completed: 3),
          _mission(date: recent, userType: 'free', completed: 99),
        ],
        AnalyticsTimeframe.daily,
        TimelineRange.last7Days,
        'premium',
      );
      expect(result.length, 1);
      expect(result[0].missionsCompleted, 3);
    });

    test('userType "free" excludes premium entries', () {
      final result = AnalyticsAggregationService.aggregateMissions(
        [
          _mission(date: recent, userType: 'free', completed: 7),
          _mission(date: recent, userType: 'premium', completed: 99),
        ],
        AnalyticsTimeframe.daily,
        TimelineRange.last7Days,
        'free',
      );
      expect(result.length, 1);
      expect(result[0].missionsCompleted, 7);
    });

    test('old entries outside timeline are excluded', () {
      final result = AnalyticsAggregationService.aggregateMissions(
        [
          _mission(date: recent, completed: 5),
          _mission(date: old, completed: 99),
        ],
        AnalyticsTimeframe.daily,
        TimelineRange.last7Days,
        'all',
      );
      expect(result.length, 1);
      expect(result[0].missionsCompleted, 5);
    });
  });

  // -------------------------------------------------------------------------
  // aggregateEngagements (timeline filter only)
  // -------------------------------------------------------------------------

  group('AnalyticsAggregationService.aggregateEngagements', () {
    final now = DateTime.now();

    test('returns entries within the timeline range', () {
      final recent = _engagement(date: now.subtract(const Duration(days: 3)));
      final old = _engagement(date: now.subtract(const Duration(days: 50)));
      final result = AnalyticsAggregationService.aggregateEngagements(
          [recent, old], TimelineRange.last7Days);
      expect(result.length, 1);
    });

    test('returns all entries when all are within range', () {
      final a = _engagement(date: now.subtract(const Duration(days: 2)));
      final b = _engagement(date: now.subtract(const Duration(days: 5)));
      final result = AnalyticsAggregationService.aggregateEngagements(
          [a, b], TimelineRange.last7Days);
      expect(result.length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // aggregateRetention (timeline filter only)
  // -------------------------------------------------------------------------

  group('AnalyticsAggregationService.aggregateRetention', () {
    final now = DateTime.now();

    test('returns entries within the timeline range', () {
      final recent = _retention(date: now.subtract(const Duration(days: 5)));
      final old = _retention(date: now.subtract(const Duration(days: 50)));
      final result = AnalyticsAggregationService.aggregateRetention(
          [recent, old], TimelineRange.last7Days);
      expect(result.length, 1);
    });

    test('returns empty list when all entries are outside range', () {
      final old = _retention(date: now.subtract(const Duration(days: 200)));
      final result = AnalyticsAggregationService.aggregateRetention(
          [old], TimelineRange.last90Days);
      expect(result, isEmpty);
    });
  });
}
