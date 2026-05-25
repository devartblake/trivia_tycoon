import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/leaderboard_entry.dart';

// ---------------------------------------------------------------------------
// Helper — builds a minimal but valid JSON map for LeaderboardEntry.fromJson
// ---------------------------------------------------------------------------

Map<String, dynamic> _baseJson({
  int userId = 1,
  String playerName = 'Alice',
  int score = 500,
  int rank = 1,
  int tier = 3,
  int tierRank = 5,
  bool isPromotionEligible = true,
  bool isRewardEligible = false,
  int wins = 10,
  String country = 'Nigeria',
  String state = 'Lagos',
  String countryCode = 'NG',
  int level = 7,
  String badges = 'gold',
  double xpProgress = 0.75,
  String timeframe = 'weekly',
  String avatar = 'avatar_1',
  String lastActive = '2025-01-15T10:00:00.000Z',
  String timestamp = '2025-01-15T09:00:00.000Z',
  String gender = 'female',
  String ageGroup = 'adults',
  String joinedDate = '2024-06-01T00:00:00.000Z',
  int streak = 7,
  double accuracy = 0.85,
  String favoriteCategory = 'science',
  String title = 'Scholar',
  String status = 'online',
  String device = 'mobile',
  String language = 'en',
  double sessionLength = 12.5,
  String lastQuestionCategory = 'math',
  List<String>? interests,
  bool emailVerified = true,
  String accountStatus = 'active',
  String timezone = 'UTC',
  List<String>? powerUps,
  String lastDeviceType = 'mobile',
  String preferredNotificationMethod = 'push',
  String subscriptionStatus = 'premium',
  double averageAnswerTime = 4.3,
  bool isBot = false,
  double accountAgeDays = 228.0,
  double engagementScore = 0.92,
}) {
  return {
    'user_id': userId,
    'playerName': playerName,
    'score': score,
    'rank': rank,
    'tier': tier,
    'tierRank': tierRank,
    'isPromotionEligible': isPromotionEligible,
    'isRewardEligible': isRewardEligible,
    'wins': wins,
    'country': country,
    'state': state,
    'countryCode': countryCode,
    'level': level,
    'badges': badges,
    'xpProgress': xpProgress,
    'timeframe': timeframe,
    'avatar': avatar,
    'last_active': lastActive,
    'timestamp': timestamp,
    'gender': gender,
    'ageGroup': ageGroup,
    'joinedDate': joinedDate,
    'streak': streak,
    'accuracy': accuracy,
    'favoriteCategory': favoriteCategory,
    'title': title,
    'status': status,
    'device': device,
    'language': language,
    'sessionLength': sessionLength,
    'lastQuestionCategory': lastQuestionCategory,
    'interests': interests ?? ['trivia', 'coding'],
    'emailVerified': emailVerified,
    'accountStatus': accountStatus,
    'timezone': timezone,
    'powerUps': powerUps ?? ['hint', 'skip'],
    'lastDeviceType': lastDeviceType,
    'preferredNotificationMethod': preferredNotificationMethod,
    'subscriptionStatus': subscriptionStatus,
    'averageAnswerTime': averageAnswerTime,
    'isBot': isBot,
    'accountAgeDays': accountAgeDays,
    'engagementScore': engagementScore,
  };
}

/// Builds a fully populated LeaderboardEntry for copyWith tests.
LeaderboardEntry _entry({
  int userId = 42,
  String playerName = 'Bob',
  int score = 800,
  int rank = 2,
  int tier = 5,
  int tierRank = 10,
}) {
  return LeaderboardEntry(
    userId: userId,
    playerName: playerName,
    score: score,
    rank: rank,
    tier: tier,
    tierRank: tierRank,
    isPromotionEligible: false,
    isRewardEligible: true,
    wins: 20,
    country: 'Kenya',
    state: 'Nairobi',
    countryCode: 'KE',
    level: 12,
    badges: 'platinum',
    xpProgress: 0.5,
    timeframe: 'global',
    avatar: 'avatar_2',
    lastActive: DateTime(2025, 2, 1),
    timestamp: DateTime(2025, 2, 1, 8),
    gender: 'male',
    ageGroup: 'teens',
    joinedDate: DateTime(2024, 1, 1),
    streak: 15,
    accuracy: 0.9,
    favoriteCategory: 'history',
    title: 'Champion',
    status: 'offline',
    device: 'tablet',
    language: 'sw',
    sessionLength: 20.0,
    lastQuestionCategory: 'geography',
    interests: const ['sports', 'music'],
    emailVerified: false,
    accountStatus: 'active',
    timezone: 'Africa/Nairobi',
    powerUps: const ['double_xp'],
    lastDeviceType: 'tablet',
    preferredNotificationMethod: 'email',
    subscriptionStatus: 'free',
    averageAnswerTime: 6.1,
    isBot: false,
    accountAgeDays: 400.0,
    engagementScore: 0.75,
  );
}

void main() {
  // -------------------------------------------------------------------------
  // LeaderboardEntry.fromJson — basic parsing
  // -------------------------------------------------------------------------

  group('LeaderboardEntry.fromJson — scalar fields', () {
    test('parses userId from int', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(userId: 99));
      expect(entry.userId, 99);
    });

    test('parses userId from string (coercion)', () {
      final json = _baseJson();
      json['user_id'] = '77';
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.userId, 77);
    });

    test('parses playerName', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(playerName: 'Zara'));
      expect(entry.playerName, 'Zara');
    });

    test('parses score', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(score: 1200));
      expect(entry.score, 1200);
    });

    test('parses rank', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(rank: 5));
      expect(entry.rank, 5);
    });

    test('parses tier', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(tier: 7));
      expect(entry.tier, 7);
    });

    test('parses tierRank', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(tierRank: 42));
      expect(entry.tierRank, 42);
    });

    test('parses boolean flags', () {
      final entry = LeaderboardEntry.fromJson(
        _baseJson(isPromotionEligible: true, isRewardEligible: true),
      );
      expect(entry.isPromotionEligible, isTrue);
      expect(entry.isRewardEligible, isTrue);
    });

    test('parses wins and level', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(wins: 55, level: 10));
      expect(entry.wins, 55);
      expect(entry.level, 10);
    });

    test('parses country, state, countryCode', () {
      final entry = LeaderboardEntry.fromJson(
        _baseJson(country: 'Ghana', state: 'Accra', countryCode: 'GH'),
      );
      expect(entry.country, 'Ghana');
      expect(entry.state, 'Accra');
      expect(entry.countryCode, 'GH');
    });

    test('parses xpProgress as double', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(xpProgress: 0.6));
      expect(entry.xpProgress, closeTo(0.6, 0.001));
    });

    test('parses accuracy as double', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(accuracy: 0.92));
      expect(entry.accuracy, closeTo(0.92, 0.001));
    });

    test('parses sessionLength as double', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(sessionLength: 15.0));
      expect(entry.sessionLength, closeTo(15.0, 0.001));
    });

    test('parses emailVerified boolean', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(emailVerified: false));
      expect(entry.emailVerified, isFalse);
    });

    test('parses isBot flag', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(isBot: true));
      expect(entry.isBot, isTrue);
    });

    test('parses subscriptionStatus', () {
      final entry = LeaderboardEntry.fromJson(
        _baseJson(subscriptionStatus: 'premium'),
      );
      expect(entry.subscriptionStatus, 'premium');
    });

    test('parses averageAnswerTime', () {
      final entry = LeaderboardEntry.fromJson(
        _baseJson(averageAnswerTime: 3.7),
      );
      expect(entry.averageAnswerTime, closeTo(3.7, 0.001));
    });

    test('parses engagementScore', () {
      final entry = LeaderboardEntry.fromJson(_baseJson(engagementScore: 0.88));
      expect(entry.engagementScore, closeTo(0.88, 0.001));
    });
  });

  group('LeaderboardEntry.fromJson — DateTime fields', () {
    test('parses lastActive from ISO string', () {
      final entry = LeaderboardEntry.fromJson(
        _baseJson(lastActive: '2025-03-10T14:30:00.000Z'),
      );
      expect(entry.lastActive.year, 2025);
      expect(entry.lastActive.month, 3);
      expect(entry.lastActive.day, 10);
    });

    test('parses timestamp from ISO string', () {
      final entry = LeaderboardEntry.fromJson(
        _baseJson(timestamp: '2025-06-01T00:00:00.000Z'),
      );
      expect(entry.timestamp.year, 2025);
      expect(entry.timestamp.month, 6);
    });

    test('parses joinedDate from ISO string', () {
      final entry = LeaderboardEntry.fromJson(
        _baseJson(joinedDate: '2023-12-25T00:00:00.000Z'),
      );
      expect(entry.joinedDate.year, 2023);
      expect(entry.joinedDate.month, 12);
      expect(entry.joinedDate.day, 25);
    });
  });

  group('LeaderboardEntry.fromJson — list fields', () {
    test('parses interests list', () {
      final entry = LeaderboardEntry.fromJson(
        _baseJson(interests: ['gaming', 'reading', 'travel']),
      );
      expect(entry.interests, ['gaming', 'reading', 'travel']);
    });

    test('parses powerUps list', () {
      final entry = LeaderboardEntry.fromJson(
        _baseJson(powerUps: ['hint', 'shield']),
      );
      expect(entry.powerUps, ['hint', 'shield']);
    });

    test('interests defaults to empty list when absent', () {
      final json = _baseJson();
      json.remove('interests');
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.interests, isEmpty);
    });

    test('powerUps defaults to empty list when absent', () {
      final json = _baseJson();
      json.remove('powerUps');
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.powerUps, isEmpty);
    });
  });

  group('LeaderboardEntry.fromJson — default fallbacks', () {
    test('playerName defaults to "Unknown" when null', () {
      final json = _baseJson();
      json['playerName'] = null;
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.playerName, 'Unknown');
    });

    test('score defaults to 0 when absent', () {
      final json = _baseJson();
      json.remove('score');
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.score, 0);
    });

    test('tier defaults to 1 when absent', () {
      final json = _baseJson();
      json.remove('tier');
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.tier, 1);
    });

    test('accountStatus defaults to "active" when absent', () {
      final json = _baseJson();
      json.remove('accountStatus');
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.accountStatus, 'active');
    });

    test('timezone defaults to "UTC" when absent', () {
      final json = _baseJson();
      json.remove('timezone');
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.timezone, 'UTC');
    });

    test('subscriptionStatus defaults to "free" when absent', () {
      final json = _baseJson();
      json.remove('subscriptionStatus');
      final entry = LeaderboardEntry.fromJson(json);
      expect(entry.subscriptionStatus, 'free');
    });
  });

  // -------------------------------------------------------------------------
  // LeaderboardEntry.toJson
  // -------------------------------------------------------------------------

  group('LeaderboardEntry.toJson', () {
    test('serializes all scalar fields', () {
      final entry = _entry(userId: 5, playerName: 'Tess', score: 999);
      final json = entry.toJson();

      expect(json['user_Id'], 5);
      expect(json['playerName'], 'Tess');
      expect(json['score'], 999);
    });

    test('serializes DateTime fields as ISO strings', () {
      final entry = _entry();
      final json = entry.toJson();

      // lastActive was DateTime(2025, 2, 1)
      expect(json['lastActive'], contains('2025'));
      expect(json['timestamp'], contains('2025'));
      expect(json['joinedDate'], contains('2024'));
    });

    test('serializes boolean fields', () {
      final entry = _entry();
      final json = entry.toJson();
      expect(json['isPromotionEligible'], isFalse);
      expect(json['isRewardEligible'], isTrue);
      expect(json['emailVerified'], isFalse);
      expect(json['isBot'], isFalse);
    });

    test('serializes list fields', () {
      final entry = _entry();
      final json = entry.toJson();
      expect(json['interests'], ['sports', 'music']);
      expect(json['powerUps'], ['double_xp']);
    });

    test('serializes xpProgress and accuracy as doubles', () {
      final entry = _entry();
      final json = entry.toJson();
      expect(json['xpProgress'], closeTo(0.5, 0.001));
      expect(json['accuracy'], closeTo(0.9, 0.001));
    });
  });

  // -------------------------------------------------------------------------
  // LeaderboardEntry.copyWith
  // -------------------------------------------------------------------------

  group('LeaderboardEntry.copyWith', () {
    test('copies score', () {
      final updated = _entry(score: 800).copyWith(score: 1500);
      expect(updated.score, 1500);
    });

    test('copies rank', () {
      final updated = _entry(rank: 2).copyWith(rank: 1);
      expect(updated.rank, 1);
    });

    test('copies playerName', () {
      final updated = _entry().copyWith(playerName: 'NewName');
      expect(updated.playerName, 'NewName');
    });

    test('copies tier and tierRank', () {
      final updated =
          _entry(tier: 5, tierRank: 10).copyWith(tier: 8, tierRank: 2);
      expect(updated.tier, 8);
      expect(updated.tierRank, 2);
    });

    test('copies isPromotionEligible', () {
      final updated = _entry().copyWith(isPromotionEligible: true);
      expect(updated.isPromotionEligible, isTrue);
    });

    test('copies streak', () {
      final updated = _entry().copyWith(streak: 99);
      expect(updated.streak, 99);
    });

    test('copies subscriptionStatus', () {
      final updated = _entry().copyWith(subscriptionStatus: 'premium');
      expect(updated.subscriptionStatus, 'premium');
    });

    test('preserves all unchanged fields', () {
      final original = _entry(
        userId: 100,
        playerName: 'Original',
        score: 300,
        tier: 4,
      );
      final updated = original.copyWith(score: 999);

      // Fields NOT changed should stay the same
      expect(updated.userId, 100);
      expect(updated.playerName, 'Original');
      expect(updated.tier, 4);
      expect(updated.country, original.country);
      expect(updated.wins, original.wins);
      expect(updated.interests, original.interests);
    });
  });

  // -------------------------------------------------------------------------
  // fromJson → toJson round-trip — key sanity check
  // -------------------------------------------------------------------------

  group('LeaderboardEntry — fromJson → field access round-trip', () {
    test('all key scalar values survive the round-trip', () {
      final json = _baseJson(
        userId: 77,
        playerName: 'RoundTrip',
        score: 350,
        rank: 3,
        tier: 2,
        wins: 8,
        country: 'Egypt',
        level: 5,
      );
      final entry = LeaderboardEntry.fromJson(json);

      expect(entry.userId, 77);
      expect(entry.playerName, 'RoundTrip');
      expect(entry.score, 350);
      expect(entry.rank, 3);
      expect(entry.tier, 2);
      expect(entry.wins, 8);
      expect(entry.country, 'Egypt');
      expect(entry.level, 5);
    });
  });
}
