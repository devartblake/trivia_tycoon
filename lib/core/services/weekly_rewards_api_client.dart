import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:synaptix/core/manager/log_manager.dart';

/// API client for weekly reward system
class WeeklyRewardsApiClient {
  final http.Client _httpClient;
  final bool _ownsHttpClient;
  final String _baseUrl;

  WeeklyRewardsApiClient({
    http.Client? httpClient,
    String? baseUrl,
  })  : _httpClient = httpClient ?? http.Client(),
        _ownsHttpClient = httpClient == null,
        _baseUrl = _normalizeBaseUrl(baseUrl ?? defaultBaseUrl);

  static const String defaultBaseUrl = 'https://api.synaptixplay.com/api/v1';
  static const String _rewardsPath = '/rewards';

  static String _normalizeBaseUrl(String baseUrl) {
    return baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
  }

  /// Get the weekly reward schedule (7-day progression)
  Future<List<WeeklyRewardDay>> getWeeklySchedule() async {
    try {
      final uri = Uri.parse('$_baseUrl$_rewardsPath/weekly-schedule');

      LogManager.debug('[WeeklyRewardsApiClient] GET $uri');

      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> scheduleList =
            data is List ? data : (data['schedule'] ?? []);

        final schedule = scheduleList
            .map((json) =>
                WeeklyRewardDay.fromJson(json as Map<String, dynamic>))
            .toList();

        LogManager.debug(
          '[WeeklyRewardsApiClient] Loaded weekly schedule: ${schedule.length} days',
        );
        return schedule;
      } else {
        throw WeeklyRewardsException(
          message: 'Failed to fetch weekly schedule',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      LogManager.error(
        '[WeeklyRewardsApiClient] Error fetching weekly schedule: $e',
        source: 'WeeklyRewardsApiClient.getWeeklySchedule',
        error: e,
      );
      rethrow;
    }
  }

  /// Get player's current weekly streak status
  Future<WeeklyStreakStatus> getWeeklyStreak(String userId) async {
    try {
      if (userId.isEmpty || userId == 'current') {
        LogManager.debug(
          '[WeeklyRewardsApiClient] Missing user ID, using default weekly streak',
        );
        return _defaultWeeklyStreak();
      }

      final uri = Uri.parse('$_baseUrl$_rewardsPath/weekly-streak/$userId');

      LogManager.debug('[WeeklyRewardsApiClient] GET $uri');

      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final streak = WeeklyStreakStatus.fromJson(data);
        LogManager.debug(
          '[WeeklyRewardsApiClient] Weekly streak: ${streak.currentDay}/7, days claimed: ${streak.daysClaimedCount}',
        );
        return streak;
      } else if (response.statusCode == 401) {
        throw WeeklyRewardsException(
          message: 'Unauthorized - user not logged in',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 404) {
        // No streak yet, return default
        return _defaultWeeklyStreak();
      } else {
        throw WeeklyRewardsException(
          message: 'Failed to fetch weekly streak',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      LogManager.error(
        '[WeeklyRewardsApiClient] Error fetching weekly streak: $e',
        source: 'WeeklyRewardsApiClient.getWeeklyStreak',
        error: e,
      );
      rethrow;
    }
  }

  /// Claim weekly reward for current day
  Future<WeeklyRewardClaimResult> claimWeeklyReward({int day = 1}) async {
    try {
      final uri = Uri.parse('$_baseUrl$_rewardsPath/weekly/claim');

      LogManager.debug('[WeeklyRewardsApiClient] POST $uri day=$day');

      final response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'day': day}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = WeeklyRewardClaimResult.fromJson(data);
        LogManager.debug(
          '[WeeklyRewardsApiClient] Weekly reward claimed: Day ${result.dayNumber}',
        );
        return result;
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        // Already claimed this day
        throw AlreadyClaimedException('Weekly reward already claimed today');
      } else if (response.statusCode == 401) {
        throw WeeklyRewardsException(
          message: 'Unauthorized - user not logged in',
          statusCode: response.statusCode,
        );
      } else {
        throw WeeklyRewardsException(
          message: 'Failed to claim weekly reward',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      LogManager.error(
        '[WeeklyRewardsApiClient] Error claiming weekly reward: $e',
        source: 'WeeklyRewardsApiClient.claimWeeklyReward',
        error: e,
      );
      rethrow;
    }
  }

  /// Calculate next week reset time (Sunday midnight UTC)
  static DateTime _getNextWeekReset(DateTime now) {
    // Sunday = 7 in DateTime.weekday
    final daysUntilSunday = (7 - now.weekday) % 7;
    final daysToAdd = daysUntilSunday == 0 ? 7 : daysUntilSunday;
    return DateTime.utc(now.year, now.month, now.day)
        .add(Duration(days: daysToAdd));
  }

  static WeeklyStreakStatus _defaultWeeklyStreak() {
    final now = DateTime.now();
    return WeeklyStreakStatus(
      currentDay: 1,
      daysClaimedCount: 0,
      daysClaimedDates: [],
      streakStartDate: now,
      weekResetDate: _getNextWeekReset(now),
    );
  }

  /// Close the HTTP client
  void close() {
    if (_ownsHttpClient) {
      _httpClient.close();
    }
  }
}

/// Single day in weekly reward schedule
class WeeklyRewardDay {
  final int day; // 1-7
  final String type; // 'coins' or 'gems'
  final int coinsAmount;
  final int gemsAmount;
  final String displayName;
  final bool? claimed;

  WeeklyRewardDay({
    required this.day,
    required this.type,
    required this.coinsAmount,
    required this.gemsAmount,
    required this.displayName,
    this.claimed,
  });

  factory WeeklyRewardDay.fromJson(Map<String, dynamic> json) {
    return WeeklyRewardDay(
      day: json['day'] ?? 1,
      type:
          json['type'] ?? json['rewardType'] ?? json['reward_type'] ?? 'coins',
      coinsAmount: json['coinsAmount'] ?? json['coins_amount'] ?? 0,
      gemsAmount: json['gemsAmount'] ?? json['gems_amount'] ?? 0,
      displayName: json['displayName'] ??
          json['display_name'] ??
          json['displayLabel'] ??
          json['display_label'] ??
          'Day ${json['day']}',
      claimed: json['claimed'],
    );
  }

  Map<String, dynamic> toJson() => {
        'day': day,
        'type': type,
        'coinsAmount': coinsAmount,
        'gemsAmount': gemsAmount,
        'displayName': displayName,
        'claimed': claimed,
      };

  /// Check if this day has coins
  bool get hasCoins => coinsAmount > 0;

  /// Check if this day has gems
  bool get hasGems => gemsAmount > 0;
}

/// Player's weekly streak status
class WeeklyStreakStatus {
  final int currentDay; // 1-7, which day are they on
  final int daysClaimedCount; // How many days claimed this week
  final List<DateTime> daysClaimedDates; // Dates of claimed days
  final DateTime streakStartDate; // When current streak started
  final DateTime weekResetDate; // When week resets

  WeeklyStreakStatus({
    required this.currentDay,
    required this.daysClaimedCount,
    required this.daysClaimedDates,
    required this.streakStartDate,
    required this.weekResetDate,
  });

  factory WeeklyStreakStatus.fromJson(Map<String, dynamic> json) {
    final datesJson =
        json['daysClaimedDates'] ?? json['days_claimed_dates'] ?? [];
    final claimedDaysJson = json['claimedDays'] ?? json['claimed_days'] ?? [];

    final cycleStartRaw = json['cycleStart'] ?? json['cycle_start'];
    final fallbackStart = DateTime.now();
    final cycleStart = cycleStartRaw != null
        ? DateTime.parse(cycleStartRaw.toString())
        : fallbackStart;

    final dates = datesJson is List && datesJson.isNotEmpty
        ? datesJson.map((d) => DateTime.parse(d.toString())).toList()
        : claimedDaysJson is List
            ? claimedDaysJson
                .map((day) => cycleStart.add(Duration(days: (day as int) - 1)))
                .toList()
            : <DateTime>[];

    return WeeklyStreakStatus(
      currentDay: json['currentDay'] ?? json['current_day'] ?? 1,
      daysClaimedCount: json['daysClaimedCount'] ??
          json['days_claimed_count'] ??
          dates.length,
      daysClaimedDates: dates,
      streakStartDate: DateTime.parse(
        json['streakStartDate'] ??
            json['streak_start_date'] ??
            cycleStart.toIso8601String(),
      ),
      weekResetDate: DateTime.parse(
        json['weekResetDate'] ??
            json['week_reset_date'] ??
            cycleStart.add(const Duration(days: 7)).toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'currentDay': currentDay,
        'daysClaimedCount': daysClaimedCount,
        'daysClaimedDates':
            daysClaimedDates.map((d) => d.toIso8601String()).toList(),
        'streakStartDate': streakStartDate.toIso8601String(),
        'weekResetDate': weekResetDate.toIso8601String(),
      };

  /// Check if a specific day has been claimed
  bool isDayClaimed(int day) => daysClaimedDates.isNotEmpty;

  /// Days remaining until week reset
  int get daysUntilReset {
    final remaining = weekResetDate.difference(DateTime.now());
    return remaining.inDays;
  }
}

/// Result of claiming a weekly reward
class WeeklyRewardClaimResult {
  final int dayNumber;
  final int coinsAwarded;
  final int gemsAwarded;
  final int newTotalCoins;
  final int newTotalGems;
  final int currentStreak;
  final DateTime nextClaimDate;

  WeeklyRewardClaimResult({
    required this.dayNumber,
    required this.coinsAwarded,
    required this.gemsAwarded,
    required this.newTotalCoins,
    required this.newTotalGems,
    required this.currentStreak,
    required this.nextClaimDate,
  });

  factory WeeklyRewardClaimResult.fromJson(Map<String, dynamic> json) {
    final updatedStreak = json['updatedStreak'] ?? json['updated_streak'];
    final updatedStreakMap =
        updatedStreak is Map ? Map<String, dynamic>.from(updatedStreak) : null;

    return WeeklyRewardClaimResult(
      dayNumber: json['dayNumber'] ?? json['day_number'] ?? json['day'] ?? 1,
      coinsAwarded: json['coinsAwarded'] ??
          json['coins_awarded'] ??
          json['coinsGranted'] ??
          json['coins_granted'] ??
          0,
      gemsAwarded: json['gemsAwarded'] ??
          json['gems_awarded'] ??
          json['gemsGranted'] ??
          json['gems_granted'] ??
          0,
      newTotalCoins: json['newTotalCoins'] ??
          json['new_total_coins'] ??
          json['newBalance'] ??
          json['new_balance'] ??
          0,
      newTotalGems: json['newTotalGems'] ?? json['new_total_gems'] ?? 0,
      currentStreak: json['currentStreak'] ??
          json['current_streak'] ??
          updatedStreakMap?['currentDay'] ??
          1,
      nextClaimDate: DateTime.parse(
        json['nextClaimDate'] ??
            json['next_claim_date'] ??
            DateTime.now().add(const Duration(days: 1)).toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'dayNumber': dayNumber,
        'coinsAwarded': coinsAwarded,
        'gemsAwarded': gemsAwarded,
        'newTotalCoins': newTotalCoins,
        'newTotalGems': newTotalGems,
        'currentStreak': currentStreak,
        'nextClaimDate': nextClaimDate.toIso8601String(),
      };
}

/// Exception for weekly rewards operations
class WeeklyRewardsException implements Exception {
  final String message;
  final int statusCode;

  WeeklyRewardsException({
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() => 'WeeklyRewardsException: $message (status: $statusCode)';
}

/// Exception when reward already claimed
class AlreadyClaimedException implements Exception {
  final String message;

  AlreadyClaimedException(this.message);

  @override
  String toString() => 'AlreadyClaimedException: $message';
}
