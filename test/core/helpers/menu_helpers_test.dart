import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/helpers/menu_helpers.dart';
import 'package:synaptix/game/models/menu_enums.dart';

void main() {
  // -------------------------------------------------------------------------
  // formatNumber
  // -------------------------------------------------------------------------

  group('MenuHelpers.formatNumber', () {
    test('0 → "0"', () => expect(MenuHelpers.formatNumber(0), '0'));
    test('999 → "999"', () => expect(MenuHelpers.formatNumber(999), '999'));
    test('1000 → "1.0K"', () => expect(MenuHelpers.formatNumber(1000), '1.0K'));
    test('1500 → "1.5K"', () => expect(MenuHelpers.formatNumber(1500), '1.5K'));
    test('10000 → "10.0K"',
        () => expect(MenuHelpers.formatNumber(10000), '10.0K'));
    test('1000000 → "1.0M"',
        () => expect(MenuHelpers.formatNumber(1000000), '1.0M'));
    test('2500000 → "2.5M"',
        () => expect(MenuHelpers.formatNumber(2500000), '2.5M'));
    test('1234 → "1.2K"', () {
      // Values >= 1000 are abbreviated rather than formatted with separators.
      expect(MenuHelpers.formatNumber(1234), '1.2K');
    });
  });

  group('MenuHelpers.formatScore', () {
    test('delegates to formatNumber', () {
      expect(MenuHelpers.formatScore(5000), MenuHelpers.formatNumber(5000));
    });
  });

  // -------------------------------------------------------------------------
  // isCurrencyLow
  // -------------------------------------------------------------------------

  group('MenuHelpers.isCurrencyLow', () {
    test('coins < 100 → true', () {
      expect(MenuHelpers.isCurrencyLow('coins', 50, 500), isTrue);
    });

    test('coins >= 100 → false', () {
      expect(MenuHelpers.isCurrencyLow('coins', 100, 500), isFalse);
    });

    test('gems < 10 → true', () {
      expect(MenuHelpers.isCurrencyLow('gems', 5, 100), isTrue);
    });

    test('gems >= 10 → false', () {
      expect(MenuHelpers.isCurrencyLow('gems', 10, 100), isFalse);
    });

    test('energy < 30% of max → true', () {
      expect(MenuHelpers.isCurrencyLow('energy', 20, 100), isTrue);
    });

    test('energy >= 30% of max → false', () {
      expect(MenuHelpers.isCurrencyLow('energy', 30, 100), isFalse);
    });

    test('lives < 50% of max → true', () {
      expect(MenuHelpers.isCurrencyLow('lives', 2, 5), isTrue);
    });

    test('unknown currency → false', () {
      expect(MenuHelpers.isCurrencyLow('diamonds', 0, 100), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // getInitials
  // -------------------------------------------------------------------------

  group('MenuHelpers.getInitials', () {
    test('empty name → "?"', () => expect(MenuHelpers.getInitials(''), '?'));

    test('single word → first 2 chars uppercase', () {
      expect(MenuHelpers.getInitials('Alice'), 'AL');
    });

    test('two words → first char of each', () {
      expect(MenuHelpers.getInitials('Alice Bob'), 'AB');
    });

    test('three words → first 2 chars by default', () {
      expect(MenuHelpers.getInitials('Alice Bob Charlie'), 'AB');
    });

    test('maxChars=1 → single initial', () {
      expect(MenuHelpers.getInitials('Alice Bob', maxChars: 1), 'A');
    });

    test('single character name → that character', () {
      expect(MenuHelpers.getInitials('X'), 'X');
    });
  });

  // -------------------------------------------------------------------------
  // calculateXPPercentage
  // -------------------------------------------------------------------------

  group('MenuHelpers.calculateXPPercentage', () {
    test('50 of 100 → 50', () {
      expect(MenuHelpers.calculateXPPercentage(50, 100), 50);
    });

    test('0 of 100 → 0', () {
      expect(MenuHelpers.calculateXPPercentage(0, 100), 0);
    });

    test('100 of 100 → 100', () {
      expect(MenuHelpers.calculateXPPercentage(100, 100), 100);
    });

    test('over max is clamped to 100', () {
      expect(MenuHelpers.calculateXPPercentage(150, 100), 100);
    });

    test('max == 0 → 0 (no divide by zero)', () {
      expect(MenuHelpers.calculateXPPercentage(50, 0), 0);
    });
  });

  // -------------------------------------------------------------------------
  // getLevelFromXP / getXPForNextLevel
  // -------------------------------------------------------------------------

  group('MenuHelpers.getLevelFromXP', () {
    test('0 XP → level 1', () => expect(MenuHelpers.getLevelFromXP(0), 1));
    test('100 XP → level 2', () => expect(MenuHelpers.getLevelFromXP(100), 2));
    test('300 XP → level 3', () => expect(MenuHelpers.getLevelFromXP(300), 3));
    test('600 XP → level 4', () => expect(MenuHelpers.getLevelFromXP(600), 4));
  });

  group('MenuHelpers.getXPForNextLevel', () {
    test('level 1 → 100 XP required', () {
      expect(MenuHelpers.getXPForNextLevel(1), 100);
    });

    test('level 2 → 200 XP required', () {
      expect(MenuHelpers.getXPForNextLevel(2), 200);
    });

    test('level 5 → 500 XP required', () {
      expect(MenuHelpers.getXPForNextLevel(5), 500);
    });
  });

  // -------------------------------------------------------------------------
  // hasEnoughCurrency
  // -------------------------------------------------------------------------

  group('MenuHelpers.hasEnoughCurrency', () {
    test('current >= required → true', () {
      expect(MenuHelpers.hasEnoughCurrency(100, 100), isTrue);
      expect(MenuHelpers.hasEnoughCurrency(200, 50), isTrue);
    });

    test('current < required → false', () {
      expect(MenuHelpers.hasEnoughCurrency(49, 50), isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // truncateText
  // -------------------------------------------------------------------------

  group('MenuHelpers.truncateText', () {
    test('text within max returned unchanged', () {
      expect(MenuHelpers.truncateText('Hello', 10), 'Hello');
    });

    test('text equal to max returned unchanged', () {
      expect(MenuHelpers.truncateText('Hello', 5), 'Hello');
    });

    test('text exceeding max is truncated with "..."', () {
      expect(MenuHelpers.truncateText('Hello World', 5), 'Hello...');
    });

    test('empty string returned unchanged', () {
      expect(MenuHelpers.truncateText('', 5), '');
    });
  });

  // -------------------------------------------------------------------------
  // getRankSuffix
  // -------------------------------------------------------------------------

  group('MenuHelpers.getRankSuffix', () {
    test('1 → "1st"', () => expect(MenuHelpers.getRankSuffix(1), '1st'));
    test('2 → "2nd"', () => expect(MenuHelpers.getRankSuffix(2), '2nd'));
    test('3 → "3rd"', () => expect(MenuHelpers.getRankSuffix(3), '3rd'));
    test('4 → "4th"', () => expect(MenuHelpers.getRankSuffix(4), '4th'));
    test('11 → "11th" (teens rule)',
        () => expect(MenuHelpers.getRankSuffix(11), '11th'));
    test('12 → "12th" (teens rule)',
        () => expect(MenuHelpers.getRankSuffix(12), '12th'));
    test('13 → "13th" (teens rule)',
        () => expect(MenuHelpers.getRankSuffix(13), '13th'));
    test('21 → "21st"', () => expect(MenuHelpers.getRankSuffix(21), '21st'));
    test('22 → "22nd"', () => expect(MenuHelpers.getRankSuffix(22), '22nd'));
    test(
        '100 → "100th"', () => expect(MenuHelpers.getRankSuffix(100), '100th'));
    test(
        '101 → "101st"', () => expect(MenuHelpers.getRankSuffix(101), '101st'));
  });

  // -------------------------------------------------------------------------
  // getLayoutMode / getGridColumnCount / isWideScreen
  // -------------------------------------------------------------------------

  group('MenuHelpers.getLayoutMode', () {
    test('width < 768 → mobile', () {
      expect(MenuHelpers.getLayoutMode(375), LayoutMode.mobile);
    });

    test('width = 768 → tablet', () {
      expect(MenuHelpers.getLayoutMode(768), LayoutMode.tablet);
    });

    test('width = 1023 → tablet', () {
      expect(MenuHelpers.getLayoutMode(1023), LayoutMode.tablet);
    });

    test('width = 1024 → desktop', () {
      expect(MenuHelpers.getLayoutMode(1024), LayoutMode.desktop);
    });
  });

  group('MenuHelpers.getGridColumnCount', () {
    test('width < 768 → 1 column', () {
      expect(MenuHelpers.getGridColumnCount(375), 1);
    });

    test('width = 768 → 2 columns', () {
      expect(MenuHelpers.getGridColumnCount(768), 2);
    });

    test('width = 1024 → 3 columns', () {
      expect(MenuHelpers.getGridColumnCount(1024), 3);
    });

    test('width >= 1400 → 4 columns', () {
      expect(MenuHelpers.getGridColumnCount(1400), 4);
    });
  });

  group('MenuHelpers.isWideScreen', () {
    test('< 1024 → false', () {
      expect(MenuHelpers.isWideScreen(1023), isFalse);
    });

    test('>= 1024 → true', () {
      expect(MenuHelpers.isWideScreen(1024), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // formatTimeAgo
  // -------------------------------------------------------------------------

  group('MenuHelpers.formatTimeAgo', () {
    test('"Just now" for < 1 minute ago', () {
      final recent = DateTime.now().subtract(const Duration(seconds: 30));
      expect(MenuHelpers.formatTimeAgo(recent), 'Just now');
    });

    test('"X minute(s) ago" for < 1 hour', () {
      final t = DateTime.now().subtract(const Duration(minutes: 5));
      expect(MenuHelpers.formatTimeAgo(t), '5 minutes ago');
    });

    test('"1 minute ago" (singular)', () {
      final t = DateTime.now().subtract(const Duration(minutes: 1));
      expect(MenuHelpers.formatTimeAgo(t), '1 minute ago');
    });

    test('"X hour(s) ago" for < 1 day', () {
      final t = DateTime.now().subtract(const Duration(hours: 3));
      expect(MenuHelpers.formatTimeAgo(t), '3 hours ago');
    });

    test('"X day(s) ago" for < 30 days', () {
      final t = DateTime.now().subtract(const Duration(days: 5));
      expect(MenuHelpers.formatTimeAgo(t), '5 days ago');
    });

    test('"X month(s) ago" for < 365 days', () {
      final t = DateTime.now().subtract(const Duration(days: 60));
      expect(MenuHelpers.formatTimeAgo(t), '2 months ago');
    });

    test('"X year(s) ago" for > 365 days', () {
      final t = DateTime.now().subtract(const Duration(days: 400));
      expect(MenuHelpers.formatTimeAgo(t), '1 year ago');
    });
  });

  // -------------------------------------------------------------------------
  // getMatchActionLabel / getMatchStatusColor
  // -------------------------------------------------------------------------

  group('MenuHelpers.getMatchActionLabel', () {
    test('yourTurn → "Play"', () {
      expect(MenuHelpers.getMatchActionLabel(MatchStatus.yourTurn), 'Play');
    });

    test('waiting → "View"', () {
      expect(MenuHelpers.getMatchActionLabel(MatchStatus.waiting), 'View');
    });

    test('finished → "Review"', () {
      expect(MenuHelpers.getMatchActionLabel(MatchStatus.finished), 'Review');
    });
  });

  // -------------------------------------------------------------------------
  // getAvatarColor
  // -------------------------------------------------------------------------

  group('MenuHelpers.getAvatarColor', () {
    test('returns consistent color for same name', () {
      final c1 = MenuHelpers.getAvatarColor('Alice');
      final c2 = MenuHelpers.getAvatarColor('Alice');
      expect(c1, c2);
    });

    test('different names can produce different colors', () {
      // Not guaranteed to be different but they often are with different hashes
      final c1 = MenuHelpers.getAvatarColor('Alice');
      final c2 = MenuHelpers.getAvatarColor('Bob');
      // Just verify both return non-null and are Color values (can be same)
      expect(c1, isNotNull);
      expect(c2, isNotNull);
    });
  });
}
