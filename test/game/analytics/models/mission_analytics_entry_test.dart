import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/analytics/models/mission_analytics_entry.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

MissionAnalyticsEntry _entry({
  DateTime? date,
  int missionsCompleted = 10,
  int missionsSwapped = 2,
  int xpEarned = 500,
  String userType = 'free',
}) =>
    MissionAnalyticsEntry(
      date: date ?? DateTime.utc(2026, 1, 1),
      missionsCompleted: missionsCompleted,
      missionsSwapped: missionsSwapped,
      xpEarned: xpEarned,
      userType: userType,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // fromJson
  // -------------------------------------------------------------------------

  group('MissionAnalyticsEntry.fromJson', () {
    test('parses all fields', () {
      final e = MissionAnalyticsEntry.fromJson({
        'date': '2026-03-15T00:00:00.000Z',
        'missionsCompleted': 20,
        'missionsSwapped': 5,
        'xpEarned': 1200,
        'userType': 'premium',
      });
      expect(e.date, DateTime.utc(2026, 3, 15));
      expect(e.missionsCompleted, 20);
      expect(e.missionsSwapped, 5);
      expect(e.xpEarned, 1200);
      expect(e.userType, 'premium');
    });

    test('missionsCompleted defaults to 0 when absent', () {
      final e = MissionAnalyticsEntry.fromJson({
        'date': '2026-01-01T00:00:00.000Z',
        'missionsSwapped': 1,
        'xpEarned': 100,
        'userType': 'free',
      });
      expect(e.missionsCompleted, 0);
    });

    test('missionsSwapped defaults to 0 when absent', () {
      final e = MissionAnalyticsEntry.fromJson({
        'date': '2026-01-01T00:00:00.000Z',
        'missionsCompleted': 5,
        'xpEarned': 100,
        'userType': 'free',
      });
      expect(e.missionsSwapped, 0);
    });

    test('xpEarned defaults to 0 when absent', () {
      final e = MissionAnalyticsEntry.fromJson({
        'date': '2026-01-01T00:00:00.000Z',
        'missionsCompleted': 5,
        'missionsSwapped': 1,
        'userType': 'free',
      });
      expect(e.xpEarned, 0);
    });

    test('userType defaults to "free" when absent', () {
      final e = MissionAnalyticsEntry.fromJson({
        'date': '2026-01-01T00:00:00.000Z',
        'missionsCompleted': 3,
        'missionsSwapped': 0,
        'xpEarned': 50,
      });
      expect(e.userType, 'free');
    });
  });

  // -------------------------------------------------------------------------
  // toJson
  // -------------------------------------------------------------------------

  group('MissionAnalyticsEntry.toJson', () {
    test('serialises all five fields', () {
      final e = _entry(missionsCompleted: 7, missionsSwapped: 1, xpEarned: 300, userType: 'premium');
      final json = e.toJson();
      expect(json['missionsCompleted'], 7);
      expect(json['missionsSwapped'], 1);
      expect(json['xpEarned'], 300);
      expect(json['userType'], 'premium');
      expect(json['date'], isA<String>());
    });

    test('round-trip preserves all values', () {
      final original = _entry(
        date: DateTime.utc(2026, 6, 10),
        missionsCompleted: 15,
        missionsSwapped: 4,
        xpEarned: 800,
        userType: 'premium',
      );
      final restored = MissionAnalyticsEntry.fromJson(original.toJson());
      expect(restored.date, original.date);
      expect(restored.missionsCompleted, original.missionsCompleted);
      expect(restored.missionsSwapped, original.missionsSwapped);
      expect(restored.xpEarned, original.xpEarned);
      expect(restored.userType, original.userType);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  group('MissionAnalyticsEntry.copyWith', () {
    test('updates missionsCompleted only', () {
      final original = _entry();
      final updated = original.copyWith(missionsCompleted: 99);
      expect(updated.missionsCompleted, 99);
      expect(updated.missionsSwapped, original.missionsSwapped);
      expect(updated.xpEarned, original.xpEarned);
      expect(updated.userType, original.userType);
    });

    test('updates xpEarned and userType', () {
      final original = _entry();
      final updated = original.copyWith(xpEarned: 9999, userType: 'premium');
      expect(updated.xpEarned, 9999);
      expect(updated.userType, 'premium');
      expect(updated.missionsCompleted, original.missionsCompleted);
    });

    test('with no args returns equivalent entry', () {
      final original = _entry();
      final copy = original.copyWith();
      expect(copy.missionsCompleted, original.missionsCompleted);
      expect(copy.missionsSwapped, original.missionsSwapped);
      expect(copy.xpEarned, original.xpEarned);
      expect(copy.userType, original.userType);
      expect(copy.date, original.date);
    });
  });
}
