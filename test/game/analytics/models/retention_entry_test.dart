import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/analytics/models/retention_entry.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

RetentionEntry _entry({
  DateTime? date,
  int day1 = 80,
  int day7 = 55,
  int day30 = 30,
}) =>
    RetentionEntry(
      date: date ?? DateTime.utc(2026, 1, 1),
      day1Retention: day1,
      day7Retention: day7,
      day30Retention: day30,
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  // -------------------------------------------------------------------------
  // fromJson
  // -------------------------------------------------------------------------

  group('RetentionEntry.fromJson', () {
    test('parses all fields', () {
      final e = RetentionEntry.fromJson({
        'date': '2026-04-01T00:00:00.000Z',
        'day1Retention': 75,
        'day7Retention': 50,
        'day30Retention': 25,
      });
      expect(e.date, DateTime.utc(2026, 4, 1));
      expect(e.day1Retention, 75);
      expect(e.day7Retention, 50);
      expect(e.day30Retention, 25);
    });

    test('day1Retention defaults to 0 when absent', () {
      final e = RetentionEntry.fromJson({
        'date': '2026-01-01T00:00:00.000Z',
        'day7Retention': 40,
        'day30Retention': 20,
      });
      expect(e.day1Retention, 0);
    });

    test('day7Retention defaults to 0 when absent', () {
      final e = RetentionEntry.fromJson({
        'date': '2026-01-01T00:00:00.000Z',
        'day1Retention': 80,
        'day30Retention': 20,
      });
      expect(e.day7Retention, 0);
    });

    test('day30Retention defaults to 0 when absent', () {
      final e = RetentionEntry.fromJson({
        'date': '2026-01-01T00:00:00.000Z',
        'day1Retention': 80,
        'day7Retention': 40,
      });
      expect(e.day30Retention, 0);
    });
  });

  // -------------------------------------------------------------------------
  // toJson
  // -------------------------------------------------------------------------

  group('RetentionEntry.toJson', () {
    test('serialises all four fields', () {
      final e = _entry(day1: 90, day7: 60, day30: 35);
      final json = e.toJson();
      expect(json['day1Retention'], 90);
      expect(json['day7Retention'], 60);
      expect(json['day30Retention'], 35);
      expect(json['date'], isA<String>());
    });

    test('round-trip preserves all values', () {
      final original =
          _entry(date: DateTime.utc(2026, 7, 4), day1: 70, day7: 45, day30: 22);
      final restored = RetentionEntry.fromJson(original.toJson());
      expect(restored.date, original.date);
      expect(restored.day1Retention, original.day1Retention);
      expect(restored.day7Retention, original.day7Retention);
      expect(restored.day30Retention, original.day30Retention);
    });
  });

  // -------------------------------------------------------------------------
  // copyWith
  // -------------------------------------------------------------------------

  group('RetentionEntry.copyWith', () {
    test('updates day1Retention only', () {
      final original = _entry();
      final updated = original.copyWith(day1Retention: 95);
      expect(updated.day1Retention, 95);
      expect(updated.day7Retention, original.day7Retention);
      expect(updated.day30Retention, original.day30Retention);
    });

    test('with no args returns equivalent entry', () {
      final original = _entry();
      final copy = original.copyWith();
      expect(copy.day1Retention, original.day1Retention);
      expect(copy.day7Retention, original.day7Retention);
      expect(copy.day30Retention, original.day30Retention);
    });
  });

  // -------------------------------------------------------------------------
  // Computed: retentionPercentage and day
  // -------------------------------------------------------------------------

  group('RetentionEntry computed properties', () {
    test('retentionPercentage equals day1Retention as double', () {
      expect(_entry(day1: 72).retentionPercentage, 72.0);
    });

    test('retentionPercentage is 0.0 when day1Retention is 0', () {
      expect(_entry(day1: 0).retentionPercentage, 0.0);
    });

    // Correct weekday labels should map directly from Monday..Sunday
    // to ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].
    test('day maps Monday to Mon', () {
      final e = _entry(date: DateTime(2026, 5, 11)); // Monday
      expect(e.day, 'Mon');
    });

    test('day maps Saturday to Sat', () {
      final e = _entry(date: DateTime(2026, 5, 16)); // Saturday
      expect(e.day, 'Sat');
    });

    test('day maps Sunday to Sun', () {
      final e = _entry(date: DateTime(2026, 5, 17)); // Sunday
      expect(e.day, 'Sun');
    });
  });
}
