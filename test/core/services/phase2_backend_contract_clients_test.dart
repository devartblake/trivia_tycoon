import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:synaptix/core/services/daily_bonus_api_client.dart';
import 'package:synaptix/core/services/tier_api_client.dart';
import 'package:synaptix/core/services/weekly_rewards_api_client.dart';

void main() {
  const baseUrl = 'https://example.test/api/v1';

  group('Phase 2 backend contract clients', () {
    test('TierApiClient parses backend progression DTOs and sends xpAmount',
        () async {
      final requests = <Uri>[];
      String? xpAwardBody;
      final httpClient = _StubHttpClient((request) {
        requests.add(request.url);

        if (request.url.path.endsWith('/progression/tiers')) {
          return http.Response(
            jsonEncode([
              _tier('bronze-rookie', 'Bronze Rookie', 1, 0, 500),
              _tier('silver-scholar', 'Silver Scholar', 2, 500, 1200),
            ]),
            200,
          );
        }

        if (request.url.path.endsWith('/progression/player/player-id')) {
          return http.Response(
            jsonEncode({
              'currentTierId': 'silver-scholar',
              'currentTierName': 'Silver Scholar',
              'currentLevel': 2,
              'currentXp': 750.0,
              'xpInCurrentTier': 250.0,
              'xpNeededForNextTier': 450.0,
              'progressPercentage': 35.0,
            }),
            200,
          );
        }

        if (request.url.path.endsWith('/progression/xp/award')) {
          xpAwardBody = request is http.Request ? request.body : null;
          return http.Response(
            jsonEncode({
              'xpAwarded': 100.0,
              'totalXp': 850.0,
              'newLevel': 2,
              'tierUpgraded': false,
            }),
            200,
          );
        }

        return http.Response('{}', 404);
      });

      final client = TierApiClient(httpClient: httpClient, baseUrl: baseUrl);

      final tiers = await client.getTierDefinitions();
      final progress = await client.getPlayerTierProgress('player-id');
      final award = await client.awardXp('player-id', 100, 'quiz_complete');

      expect(tiers, hasLength(2));
      expect(progress.currentTier.id, 'silver-scholar');
      expect(progress.currentXp, 750);
      expect(progress.progressPercentage, 35);
      expect(award.totalXp, 850);
      expect(jsonDecode(xpAwardBody!)['xpAmount'], 100);
      expect(
        requests.map((uri) => uri.path),
        containsAll([
          '/api/v1/progression/tiers',
          '/api/v1/progression/player/player-id',
          '/api/v1/progression/xp/award',
        ]),
      );
    });

    test('DailyBonusApiClient maps account rewards backend DTOs', () async {
      final httpClient = _StubHttpClient((request) {
        if (request.url.path.endsWith('/rewards/daily-config')) {
          return http.Response(
            jsonEncode({
              'rewardType': 'coins',
              'coinsAmount': 100,
              'displayName': 'Daily Mystery Box',
              'iconName': 'daily_box',
            }),
            200,
          );
        }

        if (request.url.path.endsWith('/account/rewards/status')) {
          return http.Response(
            jsonEncode({
              'canClaimDaily': false,
              'nextDailyClaimAt': '2026-07-04T00:00:00Z',
              'dailyCoins': 100,
              'currentWeeklyDay': 3,
              'weeklyClaimedDays': [1, 2],
              'weeklySchedule': [],
            }),
            200,
          );
        }

        if (request.url.path.endsWith('/account/rewards/claim')) {
          return http.Response(
            jsonEncode({
              'success': true,
              'coinsGranted': 100,
              'newBalance': 250,
              'message': 'Daily reward claimed.',
              'nextClaimAt': '2026-07-04T00:00:00Z',
            }),
            200,
          );
        }

        return http.Response('{}', 404);
      });

      final client =
          DailyBonusApiClient(httpClient: httpClient, baseUrl: baseUrl);

      final config = await client.getDailyConfig();
      final status = await client.getAccountRewardStatus();
      final claim = await client.claimDailyReward();

      expect(config.displayName, 'Daily Mystery Box');
      expect(status.claimedToday, isTrue);
      expect(status.currentStreak, 2);
      expect(status.coinsAmount, 100);
      expect(claim.coinsAwarded, 100);
      expect(claim.newTotalCoins, 250);
    });

    test('WeeklyRewardsApiClient maps weekly backend DTOs and claim day',
        () async {
      String? claimBody;
      final httpClient = _StubHttpClient((request) {
        if (request.url.path.endsWith('/rewards/weekly-schedule')) {
          return http.Response(
            jsonEncode([
              {
                'day': 1,
                'rewardType': 'coins',
                'coinsAmount': 100,
                'gemsAmount': 0,
                'displayLabel': 'Day 1 - 100 Credits',
              },
            ]),
            200,
          );
        }

        if (request.url.path.endsWith('/rewards/weekly-streak/player-id')) {
          return http.Response(
            jsonEncode({
              'currentDay': 3,
              'cycleStart': '2026-07-01',
              'claimedDays': [1, 2],
              'schedule': [],
            }),
            200,
          );
        }

        if (request.url.path.endsWith('/rewards/weekly/claim')) {
          claimBody = request is http.Request ? request.body : null;
          return http.Response(
            jsonEncode({
              'success': true,
              'day': 3,
              'coinsGranted': 200,
              'gemsGranted': 0,
              'newBalance': 450,
              'message': 'Day 3 reward claimed.',
              'updatedStreak': {
                'currentDay': 4,
                'cycleStart': '2026-07-01',
                'claimedDays': [1, 2, 3],
                'schedule': [],
              },
            }),
            200,
          );
        }

        return http.Response('{}', 404);
      });

      final client =
          WeeklyRewardsApiClient(httpClient: httpClient, baseUrl: baseUrl);

      final schedule = await client.getWeeklySchedule();
      final streak = await client.getWeeklyStreak('player-id');
      final claim = await client.claimWeeklyReward(day: streak.currentDay);

      expect(schedule.single.type, 'coins');
      expect(schedule.single.displayName, 'Day 1 - 100 Credits');
      expect(streak.currentDay, 3);
      expect(streak.daysClaimedCount, 2);
      expect(streak.weekResetDate.day, 8);
      expect(claim.dayNumber, 3);
      expect(claim.currentStreak, 4);
      expect(jsonDecode(claimBody!)['day'], 3);
    });
  });
}

Map<String, dynamic> _tier(
  String id,
  String name,
  int level,
  int minXp,
  int maxXp,
) {
  return {
    'id': id,
    'name': name,
    'level': level,
    'minXp': minXp,
    'maxXp': maxXp,
    'iconName': id.replaceAll('-', '_'),
    'rewards': {
      'badge': '${id}_badge',
      'coinsBonus': 100,
      'gemsBonus': 0,
    },
  };
}

class _StubHttpClient extends http.BaseClient {
  _StubHttpClient(this._handler);

  final FutureOr<http.Response> Function(http.BaseRequest request) _handler;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final response = await _handler(request);
    return http.StreamedResponse(
      Stream.value(response.bodyBytes),
      response.statusCode,
      headers: response.headers,
      request: request,
    );
  }
}
