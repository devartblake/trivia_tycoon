import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/extensions/datetime_extensions.dart';

void main() {
  // -------------------------------------------------------------------------
  // RelativeTime extension
  // -------------------------------------------------------------------------

  group('RelativeTime.relativeTime — "just now"', () {
    test('returns "just now" for 0 seconds ago', () {
      final dt = DateTime.now();
      expect(dt.relativeTime, 'just now');
    });

    test('returns "just now" for 30 seconds ago', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 30));
      expect(dt.relativeTime, 'just now');
    });

    test('returns "just now" for 59 seconds ago', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 59));
      expect(dt.relativeTime, 'just now');
    });
  });

  group('RelativeTime.relativeTime — minutes', () {
    test('returns "1 min ago" for exactly 60 seconds ago', () {
      final dt = DateTime.now().subtract(const Duration(seconds: 60));
      expect(dt.relativeTime, '1 min ago');
    });

    test('returns "5 min ago" for 5 minutes ago', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 5));
      expect(dt.relativeTime, '5 min ago');
    });

    test('returns "59 min ago" for 59 minutes ago', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 59));
      expect(dt.relativeTime, '59 min ago');
    });
  });

  group('RelativeTime.relativeTime — hours', () {
    test('returns "1 hrs ago" for exactly 60 minutes ago', () {
      final dt = DateTime.now().subtract(const Duration(minutes: 60));
      expect(dt.relativeTime, '1 hrs ago');
    });

    test('returns "3 hrs ago" for 3 hours ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 3));
      expect(dt.relativeTime, '3 hrs ago');
    });

    test('returns "23 hrs ago" for 23 hours ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 23));
      expect(dt.relativeTime, '23 hrs ago');
    });
  });

  group('RelativeTime.relativeTime — days', () {
    test('returns "1 days ago" for exactly 24 hours ago', () {
      final dt = DateTime.now().subtract(const Duration(hours: 24));
      expect(dt.relativeTime, '1 days ago');
    });

    test('returns "7 days ago" for 7 days ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 7));
      expect(dt.relativeTime, '7 days ago');
    });

    test('returns "30 days ago" for 30 days ago', () {
      final dt = DateTime.now().subtract(const Duration(days: 30));
      expect(dt.relativeTime, '30 days ago');
    });
  });
}
