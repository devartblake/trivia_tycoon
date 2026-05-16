import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/utils/tier_assigner.dart';
import 'package:trivia_tycoon/game/utils/referral_code_gen.dart';
import 'package:trivia_tycoon/game/utils/qr_payload.dart';
import 'package:trivia_tycoon/game/utils/date_formatter.dart';
import 'package:trivia_tycoon/game/utils/greeting_utils.dart';
import 'package:trivia_tycoon/game/models/leaderboard_entry.dart';

LeaderboardEntry _entry({required int userId, required int score}) =>
    LeaderboardEntry(
      userId: userId,
      playerName: 'Player $userId',
      score: score,
      rank: 0,
      tier: 0,
      tierRank: 0,
      isPromotionEligible: false,
      isRewardEligible: false,
      wins: 0,
      country: '',
      state: '',
      countryCode: '',
      level: 1,
      badges: '',
      xpProgress: 0.0,
      timeframe: 'global',
      avatar: '',
      lastActive: DateTime(2026),
      timestamp: DateTime(2026),
      gender: '',
      ageGroup: '',
      joinedDate: DateTime(2026),
      streak: 0,
      accuracy: 0.0,
      favoriteCategory: '',
      title: '',
      status: 'active',
      device: '',
      language: '',
      sessionLength: 0.0,
      lastQuestionCategory: '',
      interests: const [],
      emailVerified: false,
      accountStatus: 'active',
      timezone: 'UTC',
      powerUps: const [],
      lastDeviceType: '',
      preferredNotificationMethod: 'push',
      subscriptionStatus: 'free',
      averageAnswerTime: 0.0,
      isBot: false,
      accountAgeDays: 0.0,
      engagementScore: 0.0,
    );

void main() {
  // -------------------------------------------------------------------------
  // TierAssigner
  // -------------------------------------------------------------------------

  group('TierAssigner', () {
    test('empty list returns empty result', () {
      expect(TierAssigner.assignTiers([]), isEmpty);
    });

    test('single entry gets rank=1, tier=10, tierRank=1', () {
      final result = TierAssigner.assignTiers([_entry(userId: 1, score: 100)]);
      expect(result.length, 1);
      expect(result.first.rank, 1);
      expect(result.first.tier, 10);
      expect(result.first.tierRank, 1);
    });

    test('two entries sorted by score descending, higher score gets rank 1',
        () {
      final result = TierAssigner.assignTiers([
        _entry(userId: 1, score: 50),
        _entry(userId: 2, score: 200),
      ]);
      expect(result.first.userId, 2);
      expect(result.first.rank, 1);
      expect(result.last.rank, 2);
    });

    test('rank 1 gets tier 10 and tierRank 1', () {
      final result = TierAssigner.assignTiers([_entry(userId: 1, score: 1000)]);
      expect(result.first.tier, 10);
      expect(result.first.tierRank, 1);
    });

    test('rank 101 gets tier 9 and tierRank 1', () {
      final entries =
          List.generate(101, (i) => _entry(userId: i, score: 1000 - i));
      final result = TierAssigner.assignTiers(entries);
      expect(result[100].rank, 101);
      expect(result[100].tier, 9);
      expect(result[100].tierRank, 1);
    });

    test('rank 1001 gets tier 0', () {
      final entries =
          List.generate(1001, (i) => _entry(userId: i, score: 1001 - i));
      final result = TierAssigner.assignTiers(entries);
      expect(result[1000].rank, 1001);
      expect(result[1000].tier, 0);
    });

    test('isPromotionEligible is true for all 25 top-tier entries', () {
      final entries =
          List.generate(25, (i) => _entry(userId: i, score: 1000 - i));
      final result = TierAssigner.assignTiers(entries);
      for (final e in result) {
        expect(e.isPromotionEligible, isTrue,
            reason:
                'rank ${e.rank} (tierRank ${e.tierRank}) should be promotable');
      }
    });

    test('isPromotionEligible is false for tierRank 26', () {
      final entries =
          List.generate(26, (i) => _entry(userId: i, score: 1000 - i));
      final result = TierAssigner.assignTiers(entries);
      expect(result[25].isPromotionEligible, isFalse);
    });

    test('isRewardEligible is true for all 20 top-tier entries', () {
      final entries =
          List.generate(20, (i) => _entry(userId: i, score: 1000 - i));
      final result = TierAssigner.assignTiers(entries);
      for (final e in result) {
        expect(e.isRewardEligible, isTrue);
      }
    });

    test('isRewardEligible is false for tierRank 21', () {
      final entries =
          List.generate(21, (i) => _entry(userId: i, score: 1000 - i));
      final result = TierAssigner.assignTiers(entries);
      expect(result[20].isRewardEligible, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // ReferralCodeGen
  // -------------------------------------------------------------------------

  group('ReferralCodeGen', () {
    test('generate() returns a String starting with "RC"', () {
      expect(ReferralCodeGen.generate(), startsWith('RC'));
    });

    test('generate() returns 10 chars total (RC + 8 default)', () {
      expect(ReferralCodeGen.generate().length, 10);
    });

    test('suffix chars are all from Crockford base32 alphabet', () {
      const alphabet = '0123456789ABCDEFGHJKMNPQRSTVWXYZ';
      final suffix = ReferralCodeGen.generate().substring(2);
      for (final ch in suffix.split('')) {
        expect(alphabet.contains(ch), isTrue,
            reason: 'char "$ch" not in Crockford alphabet');
      }
    });

    test('generate(length: 4) returns 6 chars (RC + 4)', () {
      expect(ReferralCodeGen.generate(length: 4).length, 6);
    });

    test('two consecutive calls return different codes', () {
      final a = ReferralCodeGen.generate();
      final b = ReferralCodeGen.generate();
      expect(a, isNot(equals(b)));
    });
  });

  // -------------------------------------------------------------------------
  // QrPayload
  // -------------------------------------------------------------------------

  group('QrPayload', () {
    test('result starts with tt://invite?', () {
      final uri = QrPayload.buildUri(
          code: 'RCABCD', ownerUserId: 'u1', issuedAtUnix: 0);
      expect(uri, startsWith('tt://invite?'));
    });

    test('result contains v=1', () {
      final uri = QrPayload.buildUri(
          code: 'RCABCD', ownerUserId: 'u1', issuedAtUnix: 0);
      expect(uri, contains('v=1'));
    });

    test('result contains rc= with the code value', () {
      final uri = QrPayload.buildUri(
          code: 'RCTEST', ownerUserId: 'u1', issuedAtUnix: 0);
      expect(uri, contains('rc=RCTEST'));
    });

    test('result contains uid= with ownerUserId', () {
      final uri = QrPayload.buildUri(
          code: 'RCABCD', ownerUserId: 'user123', issuedAtUnix: 0);
      expect(uri, contains('uid=user123'));
    });

    test('result contains ts= with the unix timestamp', () {
      final uri = QrPayload.buildUri(
          code: 'RCABCD', ownerUserId: 'u1', issuedAtUnix: 1234567890);
      expect(uri, contains('ts=1234567890'));
    });

    test('without signature: result does not contain sig=', () {
      final uri = QrPayload.buildUri(
          code: 'RCABCD', ownerUserId: 'u1', issuedAtUnix: 0);
      expect(uri, isNot(contains('sig=')));
    });

    test('with signature: result includes sig= parameter', () {
      final uri = QrPayload.buildUri(
          code: 'RCABCD',
          ownerUserId: 'u1',
          issuedAtUnix: 0,
          signature: 'abc123');
      expect(uri, contains('sig=abc123'));
    });
  });

  // -------------------------------------------------------------------------
  // DateFormatter
  // -------------------------------------------------------------------------

  group('DateFormatter', () {
    test('formatDateTime returns "Today ..." for the current date', () {
      final result = DateFormatter.formatDateTime(DateTime.now());
      expect(result, startsWith('Today'));
    });

    test('formatDateTime returns M/D format for yesterday', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final result = DateFormatter.formatDateTime(yesterday);
      expect(result, isNot(startsWith('Today')));
      expect(result, contains('/'));
    });

    test('formatDuration formats 1h 30m 5s as "1:30:05"', () {
      expect(
        DateFormatter.formatDuration(
            const Duration(hours: 1, minutes: 30, seconds: 5)),
        '1:30:05',
      );
    });

    test('formatDuration formats zero duration as "0:00:00"', () {
      expect(DateFormatter.formatDuration(Duration.zero), '0:00:00');
    });

    test('formatRelative returns "just now" for 30 seconds ago', () {
      final past = DateTime.now().subtract(const Duration(seconds: 30));
      expect(DateFormatter.formatRelative(past), 'just now');
    });

    test('formatRelative returns "5 minutes ago" for 5 minutes ago', () {
      final past = DateTime.now().subtract(const Duration(minutes: 5));
      expect(DateFormatter.formatRelative(past), '5 minutes ago');
    });

    test('formatRelative uses singular "minute" for 1 minute ago', () {
      final past = DateTime.now().subtract(const Duration(minutes: 1));
      expect(DateFormatter.formatRelative(past), '1 minute ago');
    });

    test('formatRelative returns "2 hours ago" for 2 hours ago', () {
      final past = DateTime.now().subtract(const Duration(hours: 2));
      expect(DateFormatter.formatRelative(past), '2 hours ago');
    });

    test('formatRelative returns "3 days ago" for 3 days ago', () {
      final past = DateTime.now().subtract(const Duration(days: 3));
      expect(DateFormatter.formatRelative(past), '3 days ago');
    });

    test('formatRelative returns "in 2 minutes" for a future time', () {
      final future = DateTime.now().add(const Duration(minutes: 2));
      expect(DateFormatter.formatRelative(future), 'in 2 minutes');
    });
  });

  // -------------------------------------------------------------------------
  // GreetingUtils
  // -------------------------------------------------------------------------

  group('GreetingUtils', () {
    test('getGreeting(0) returns "Good Morning"', () {
      expect(GreetingUtils.getGreeting(0), 'Good Morning');
    });

    test('getGreeting(6) returns "Good Morning"', () {
      expect(GreetingUtils.getGreeting(6), 'Good Morning');
    });

    test('getGreeting(11) returns "Good Morning"', () {
      expect(GreetingUtils.getGreeting(11), 'Good Morning');
    });

    test('getGreeting(12) returns "Good Afternoon"', () {
      expect(GreetingUtils.getGreeting(12), 'Good Afternoon');
    });

    test('getGreeting(16) returns "Good Afternoon"', () {
      expect(GreetingUtils.getGreeting(16), 'Good Afternoon');
    });

    test('getGreeting(17) returns "Good Evening"', () {
      expect(GreetingUtils.getGreeting(17), 'Good Evening');
    });

    test('getGreeting(23) returns "Good Evening"', () {
      expect(GreetingUtils.getGreeting(23), 'Good Evening');
    });

    test('getPersonalizedGreeting includes the user name', () {
      expect(GreetingUtils.getPersonalizedGreeting('Alice'), contains('Alice'));
    });

    test('getPersonalizedGreeting includes "Good"', () {
      expect(GreetingUtils.getPersonalizedGreeting('Bob'), contains('Good'));
    });

    test('getMotivationalMessage returns non-empty string', () {
      expect(GreetingUtils.getMotivationalMessage(), isNotEmpty);
    });

    test('getTimePeriodEmoji returns non-empty string', () {
      expect(GreetingUtils.getTimePeriodEmoji(), isNotEmpty);
    });

    test('getTimePeriod returns one of the four expected period strings', () {
      const valid = {'morning', 'afternoon', 'evening', 'night'};
      expect(valid.contains(GreetingUtils.getTimePeriod()), isTrue);
    });

    test('exactly one of isMorning/isAfternoon/isEvening/isNight is true', () {
      final flags = [
        GreetingUtils.isMorning,
        GreetingUtils.isAfternoon,
        GreetingUtils.isEvening,
        GreetingUtils.isNight,
      ];
      expect(flags.where((f) => f).length, 1);
    });
  });
}
