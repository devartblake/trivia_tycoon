import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/analytics/models/engagement_entry.dart';

void main() {
  // -------------------------------------------------------------------------
  // fromJson
  // -------------------------------------------------------------------------

  group('EngagementEntry.fromJson', () {
    test('parses all fields', () {
      final e = EngagementEntry.fromJson({
        'date': '2026-05-11T00:00:00.000Z',
        'activeUsers': 500,
        'averageSessionLength': 12,
        'sessionsPerUser': 3,
      });
      expect(e.activeUsers, 500);
      expect(e.averageSessionLength, 12);
      expect(e.sessionsPerUser, 3);
      expect(e.date, DateTime.utc(2026, 5, 11));
    });

    test('activeUsers defaults to 0 when absent', () {
      final e = EngagementEntry.fromJson({
        'date': '2026-01-01T00:00:00.000Z',
        'averageSessionLength': 5,
        'sessionsPerUser': 2,
      });
      expect(e.activeUsers, 0);
    });

    test('averageSessionLength defaults to 0 when absent', () {
      final e = EngagementEntry.fromJson({
        'date': '2026-01-01T00:00:00.000Z',
        'activeUsers': 100,
        'sessionsPerUser': 2,
      });
      expect(e.averageSessionLength, 0);
    });

    test('sessionsPerUser defaults to 0 when absent', () {
      final e = EngagementEntry.fromJson({
        'date': '2026-01-01T00:00:00.000Z',
        'activeUsers': 100,
        'averageSessionLength': 5,
      });
      expect(e.sessionsPerUser, 0);
    });
  });

  // -------------------------------------------------------------------------
  // toJson
  // -------------------------------------------------------------------------

  group('EngagementEntry.toJson', () {
    test('serialises all four fields', () {
      final e = EngagementEntry(
        date: DateTime.utc(2026, 3, 15),
        activeUsers: 200,
        averageSessionLength: 8,
        sessionsPerUser: 4,
      );
      final json = e.toJson();
      expect(json['activeUsers'], 200);
      expect(json['averageSessionLength'], 8);
      expect(json['sessionsPerUser'], 4);
      expect(json['date'], isA<String>());
    });

    test('round-trip preserves all values', () {
      final original = EngagementEntry(
        date: DateTime.utc(2026, 4, 20),
        activeUsers: 999,
        averageSessionLength: 15,
        sessionsPerUser: 6,
      );
      final restored = EngagementEntry.fromJson(original.toJson());
      expect(restored.activeUsers, original.activeUsers);
      expect(restored.averageSessionLength, original.averageSessionLength);
      expect(restored.sessionsPerUser, original.sessionsPerUser);
      expect(restored.date, original.date);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  group('EngagementEntry.copyWith', () {
    test('updates activeUsers only', () {
      final e = EngagementEntry(
        date: DateTime.utc(2026, 1, 1),
        activeUsers: 100,
        averageSessionLength: 5,
        sessionsPerUser: 2,
      );
      final updated = e.copyWith(activeUsers: 999);
      expect(updated.activeUsers, 999);
      expect(updated.averageSessionLength, 5);
      expect(updated.sessionsPerUser, 2);
    });

    test('with no args returns equivalent entry', () {
      final e = EngagementEntry(
        date: DateTime.utc(2026, 1, 1),
        activeUsers: 50,
        averageSessionLength: 10,
        sessionsPerUser: 3,
      );
      final copy = e.copyWith();
      expect(copy.activeUsers, e.activeUsers);
      expect(copy.date, e.date);
    });
  });

  // -------------------------------------------------------------------------
  // Computed: day and sessions
  // -------------------------------------------------------------------------

  group('EngagementEntry computed properties', () {
    // 2026-05-11 is a Monday (weekday=1); _weekdayShort: (1-1)%7=0 → 'Mon'
    test('day returns Mon for Monday', () {
      final e = EngagementEntry(
        date: DateTime(2026, 5, 11),
        activeUsers: 1,
        averageSessionLength: 1,
        sessionsPerUser: 1,
      );
      expect(e.day, 'Mon');
    });

    // 2026-05-12 is a Tuesday (weekday=2); (2-1)%7=1 → 'Tue'
    test('day returns Tue for Tuesday', () {
      final e = EngagementEntry(
        date: DateTime(2026, 5, 12),
        activeUsers: 1,
        averageSessionLength: 1,
        sessionsPerUser: 1,
      );
      expect(e.day, 'Tue');
    });

    // 2026-05-17 is a Sunday (weekday=7); (7-1)%7=6 → 'Sun'
    test('day returns Sun for Sunday', () {
      final e = EngagementEntry(
        date: DateTime(2026, 5, 17),
        activeUsers: 1,
        averageSessionLength: 1,
        sessionsPerUser: 1,
      );
      expect(e.day, 'Sun');
    });

    test('sessions = activeUsers * sessionsPerUser', () {
      final e = EngagementEntry(
        date: DateTime.utc(2026, 1, 1),
        activeUsers: 200,
        averageSessionLength: 10,
        sessionsPerUser: 5,
      );
      expect(e.sessions, 1000);
    });

    test('sessions is 0 when sessionsPerUser is 0', () {
      final e = EngagementEntry(
        date: DateTime.utc(2026, 1, 1),
        activeUsers: 500,
        averageSessionLength: 10,
        sessionsPerUser: 0,
      );
      expect(e.sessions, 0);
    });
  });
}
