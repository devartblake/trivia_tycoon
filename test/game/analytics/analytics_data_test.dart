import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/analytics/models/analytics_data.dart';
import 'package:trivia_tycoon/game/analytics/models/engagement_entry.dart';
import 'package:trivia_tycoon/game/analytics/models/mission_analytics_entry.dart';
import 'package:trivia_tycoon/game/analytics/models/retention_entry.dart';

void main() {
  // -------------------------------------------------------------------------
  // AnalyticsData — construction with empty lists
  // -------------------------------------------------------------------------

  group('AnalyticsData — empty lists', () {
    test('missions field is accessible and empty', () {
      final data = AnalyticsData(
        missions: [],
        engagements: [],
        retentions: [],
      );
      expect(data.missions, isEmpty);
    });

    test('engagements field is accessible and empty', () {
      final data = AnalyticsData(
        missions: [],
        engagements: [],
        retentions: [],
      );
      expect(data.engagements, isEmpty);
    });

    test('retentions field is accessible and empty', () {
      final data = AnalyticsData(
        missions: [],
        engagements: [],
        retentions: [],
      );
      expect(data.retentions, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // AnalyticsData — identity preservation (same list reference)
  // -------------------------------------------------------------------------

  group('AnalyticsData — list identity', () {
    test('missions stores the exact list passed in', () {
      final missions = <MissionAnalyticsEntry>[];
      final data =
          AnalyticsData(missions: missions, engagements: [], retentions: []);
      expect(data.missions, same(missions));
    });

    test('engagements stores the exact list passed in', () {
      final engagements = <EngagementEntry>[];
      final data =
          AnalyticsData(missions: [], engagements: engagements, retentions: []);
      expect(data.engagements, same(engagements));
    });

    test('retentions stores the exact list passed in', () {
      final retentions = <RetentionEntry>[];
      final data =
          AnalyticsData(missions: [], engagements: [], retentions: retentions);
      expect(data.retentions, same(retentions));
    });
  });

  // -------------------------------------------------------------------------
  // AnalyticsData — non-empty lists
  // -------------------------------------------------------------------------

  group('AnalyticsData — non-empty lists', () {
    final date = DateTime(2024, 6, 1);

    test('missions preserves all elements', () {
      final m = MissionAnalyticsEntry(
        date: date,
        missionsCompleted: 5,
        missionsSwapped: 2,
        xpEarned: 100,
        userType: 'free',
      );
      final data =
          AnalyticsData(missions: [m], engagements: [], retentions: []);
      expect(data.missions.length, 1);
      expect(data.missions.first.missionsCompleted, 5);
    });

    test('engagements preserves all elements', () {
      final e = EngagementEntry(
        date: date,
        activeUsers: 50,
        averageSessionLength: 15,
        sessionsPerUser: 3,
      );
      final data =
          AnalyticsData(missions: [], engagements: [e], retentions: []);
      expect(data.engagements.length, 1);
      expect(data.engagements.first.activeUsers, 50);
    });

    test('retentions preserves all elements', () {
      final r = RetentionEntry(
        date: date,
        day1Retention: 80,
        day7Retention: 60,
        day30Retention: 40,
      );
      final data =
          AnalyticsData(missions: [], engagements: [], retentions: [r]);
      expect(data.retentions.length, 1);
      expect(data.retentions.first.day1Retention, 80);
    });

    test('multiple items preserved in order', () {
      final dates = [DateTime(2024, 1, 1), DateTime(2024, 1, 2)];
      final retentions = dates
          .map((d) => RetentionEntry(
                date: d,
                day1Retention: 70,
                day7Retention: 50,
                day30Retention: 30,
              ))
          .toList();
      final data =
          AnalyticsData(missions: [], engagements: [], retentions: retentions);
      expect(data.retentions.length, 2);
      expect(data.retentions[0].date, dates[0]);
      expect(data.retentions[1].date, dates[1]);
    });
  });
}
