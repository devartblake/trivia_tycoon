import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/game/services/rewards_api_service.dart';

// Stub that throws on any API call to keep tests network-free.
class _StubApiService extends ApiService {
  _StubApiService()
      : super(baseUrl: 'http://stub.invalid', initializeCache: false);

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    throw UnimplementedError('stub');
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? headers,
    Duration? timeout,
  }) async {
    throw UnimplementedError('stub');
  }

  @override
  Future<List<Map<String, dynamic>>> getList(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    Duration? timeout,
  }) async {
    throw UnimplementedError('stub');
  }
}

void main() {
  // -------------------------------------------------------------------------
  // DailyRewardConfigModel
  // -------------------------------------------------------------------------

  group('DailyRewardConfigModel', () {
    test('fromJson parses all fields', () {
      final m = DailyRewardConfigModel.fromJson({
        'rewardType': 'gems',
        'coinsAmount': 200,
        'displayName': 'Gem Box',
        'iconName': 'gem_box',
      });
      expect(m.rewardType, 'gems');
      expect(m.coinsAmount, 200);
      expect(m.displayName, 'Gem Box');
      expect(m.iconName, 'gem_box');
    });

    test('fromJson uses default rewardType when missing', () {
      final m = DailyRewardConfigModel.fromJson({
        'coinsAmount': 100,
        'displayName': 'Box',
        'iconName': 'box',
      });
      expect(m.rewardType, 'coins');
    });

    test('fromJson uses default coinsAmount of 100 when missing', () {
      final m = DailyRewardConfigModel.fromJson({
        'rewardType': 'coins',
        'displayName': 'Box',
        'iconName': 'box',
      });
      expect(m.coinsAmount, 100);
    });

    test('fromJson uses default displayName when missing', () {
      final m = DailyRewardConfigModel.fromJson({
        'rewardType': 'coins',
        'coinsAmount': 50,
        'iconName': 'box',
      });
      expect(m.displayName, 'Daily Mystery Box');
    });

    test('fromJson uses default iconName "daily_box" when missing', () {
      final m = DailyRewardConfigModel.fromJson({
        'rewardType': 'coins',
        'coinsAmount': 50,
        'displayName': 'Box',
      });
      expect(m.iconName, 'daily_box');
    });

    test('fromJson with all defaults applied', () {
      final m = DailyRewardConfigModel.fromJson({});
      expect(m.rewardType, 'coins');
      expect(m.coinsAmount, 100);
      expect(m.displayName, 'Daily Mystery Box');
      expect(m.iconName, 'daily_box');
    });
  });

  // -------------------------------------------------------------------------
  // DailyRewardStatusModel
  // -------------------------------------------------------------------------

  group('DailyRewardStatusModel', () {
    test('holds isClaimAvailable and optional nextAvailableAtUtc', () {
      const m = DailyRewardStatusModel(isClaimAvailable: true);
      expect(m.isClaimAvailable, isTrue);
      expect(m.nextAvailableAtUtc, isNull);
    });

    test('stores nextAvailableAtUtc when provided', () {
      final dt = DateTime(2026, 1, 2);
      final m = DailyRewardStatusModel(
        isClaimAvailable: false,
        nextAvailableAtUtc: dt,
      );
      expect(m.isClaimAvailable, isFalse);
      expect(m.nextAvailableAtUtc, dt);
    });
  });

  // -------------------------------------------------------------------------
  // DailyRewardClaimModel
  // -------------------------------------------------------------------------

  group('DailyRewardClaimModel', () {
    test('fromJson parses all fields', () {
      final m = DailyRewardClaimModel.fromJson({
        'success': true,
        'coinsGranted': 150,
        'newBalance': 1500,
        'message': 'Claim successful',
        'nextClaimAt': '2026-01-02T12:00:00.000Z',
      });
      expect(m.success, isTrue);
      expect(m.coinsGranted, 150);
      expect(m.newBalance, 1500);
      expect(m.message, 'Claim successful');
      expect(m.nextClaimAt, isNotNull);
    });

    test('fromJson success is false when not true', () {
      final m = DailyRewardClaimModel.fromJson({
        'success': false,
        'coinsGranted': 0,
        'newBalance': 0,
        'message': 'Already claimed',
      });
      expect(m.success, isFalse);
    });

    test('fromJson uses defaults for missing numeric fields', () {
      final m = DailyRewardClaimModel.fromJson({
        'success': false,
        'message': 'err',
      });
      expect(m.coinsGranted, 0);
      expect(m.newBalance, 0);
    });

    test('fromJson nextClaimAt is null when missing', () {
      final m = DailyRewardClaimModel.fromJson({
        'success': true,
        'coinsGranted': 100,
        'newBalance': 1000,
        'message': 'ok',
      });
      expect(m.nextClaimAt, isNull);
    });

    test('fromJson nextClaimAt parsed from ISO string', () {
      final m = DailyRewardClaimModel.fromJson({
        'success': true,
        'coinsGranted': 100,
        'newBalance': 1000,
        'message': 'ok',
        'nextClaimAt': '2026-06-15T08:00:00.000Z',
      });
      expect(m.nextClaimAt, isA<DateTime>());
      expect(m.nextClaimAt!.year, 2026);
    });
  });

  // -------------------------------------------------------------------------
  // WeeklyRewardDayModel
  // -------------------------------------------------------------------------

  group('WeeklyRewardDayModel', () {
    test('fromJson parses all fields', () {
      final m = WeeklyRewardDayModel.fromJson({
        'day': 3,
        'rewardType': 'gems',
        'coinsAmount': 0,
        'gemsAmount': 5,
        'displayLabel': 'Day 3',
      });
      expect(m.day, 3);
      expect(m.rewardType, 'gems');
      expect(m.coinsAmount, 0);
      expect(m.gemsAmount, 5);
      expect(m.displayLabel, 'Day 3');
    });

    test('fromJson uses defaults for missing fields', () {
      final m = WeeklyRewardDayModel.fromJson({});
      expect(m.day, 1);
      expect(m.rewardType, 'coins');
      expect(m.coinsAmount, 0);
      expect(m.gemsAmount, 0);
      expect(m.displayLabel, '');
    });

    test('amountLabel shows coins when only coinsAmount > 0', () {
      final m = WeeklyRewardDayModel.fromJson({
        'day': 1,
        'rewardType': 'coins',
        'coinsAmount': 100,
        'gemsAmount': 0,
        'displayLabel': '',
      });
      expect(m.amountLabel, '100');
    });

    test('amountLabel shows gems when only gemsAmount > 0', () {
      final m = WeeklyRewardDayModel.fromJson({
        'day': 1,
        'rewardType': 'gems',
        'coinsAmount': 0,
        'gemsAmount': 5,
        'displayLabel': '',
      });
      expect(m.amountLabel, '5');
    });

    test('amountLabel shows combined when both > 0', () {
      final m = WeeklyRewardDayModel.fromJson({
        'day': 7,
        'rewardType': 'combo',
        'coinsAmount': 200,
        'gemsAmount': 10,
        'displayLabel': '',
      });
      expect(m.amountLabel, '200 + 10');
    });

    test('amountLabel is "1" when both amounts are 0', () {
      final m = WeeklyRewardDayModel.fromJson({
        'day': 1,
        'rewardType': 'custom',
        'coinsAmount': 0,
        'gemsAmount': 0,
        'displayLabel': '',
      });
      expect(m.amountLabel, '1');
    });
  });

  // -------------------------------------------------------------------------
  // WeeklyStreakDataModel
  // -------------------------------------------------------------------------

  group('WeeklyStreakDataModel', () {
    test('fromJson parses basic fields', () {
      final m = WeeklyStreakDataModel.fromJson({
        'currentDay': 4,
        'cycleStart': '2026-01-01',
        'claimedDays': [1, 2, 3],
        'schedule': [],
      });
      expect(m.currentDay, 4);
      expect(m.cycleStart, '2026-01-01');
      expect(m.claimedDays, [1, 2, 3]);
      expect(m.schedule, isEmpty);
    });

    test('fromJson uses defaults for missing fields', () {
      final m = WeeklyStreakDataModel.fromJson({});
      expect(m.currentDay, 1);
      expect(m.cycleStart, '');
      expect(m.claimedDays, isEmpty);
      expect(m.schedule, isEmpty);
    });

    test('fromJson parses schedule list', () {
      final m = WeeklyStreakDataModel.fromJson({
        'currentDay': 1,
        'cycleStart': '',
        'claimedDays': [],
        'schedule': [
          {
            'day': 1,
            'rewardType': 'coins',
            'coinsAmount': 100,
            'gemsAmount': 0,
            'displayLabel': 'Day 1',
          },
        ],
      });
      expect(m.schedule.length, 1);
      expect(m.schedule.first.day, 1);
    });
  });

  // -------------------------------------------------------------------------
  // WeeklyClaimResultModel
  // -------------------------------------------------------------------------

  group('WeeklyClaimResultModel', () {
    test('fromJson parses all fields', () {
      final m = WeeklyClaimResultModel.fromJson({
        'success': true,
        'day': 5,
        'coinsGranted': 300,
        'gemsGranted': 2,
        'newBalance': 3000,
        'message': 'Day 5 claimed',
        'updatedStreak': {
          'currentDay': 5,
          'cycleStart': '2026-01-01',
          'claimedDays': [1, 2, 3, 4, 5],
          'schedule': [],
        },
      });
      expect(m.success, isTrue);
      expect(m.day, 5);
      expect(m.coinsGranted, 300);
      expect(m.gemsGranted, 2);
      expect(m.newBalance, 3000);
      expect(m.message, 'Day 5 claimed');
      expect(m.updatedStreak.currentDay, 5);
    });

    test('fromJson uses defaults for missing numeric fields', () {
      final m = WeeklyClaimResultModel.fromJson({
        'success': false,
        'message': '',
        'updatedStreak': {},
      });
      expect(m.day, 1);
      expect(m.coinsGranted, 0);
      expect(m.gemsGranted, 0);
      expect(m.newBalance, 0);
    });
  });

  // -------------------------------------------------------------------------
  // RewardsApiService (stub — verifies error propagation)
  // -------------------------------------------------------------------------

  group('RewardsApiService (stub)', () {
    late RewardsApiService svc;

    setUp(() {
      svc = RewardsApiService(_StubApiService());
    });

    test('getDailyConfig propagates error from stub', () async {
      await expectLater(svc.getDailyConfig(), throwsA(isA<UnimplementedError>()));
    });

    test('getDailyStatus propagates error from stub', () async {
      await expectLater(
        svc.getDailyStatus('player1'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('claimDailyReward propagates error from stub', () async {
      await expectLater(
        svc.claimDailyReward(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('getWeeklySchedule propagates error from stub', () async {
      await expectLater(
        svc.getWeeklySchedule(),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('getWeeklyStreak propagates error from stub', () async {
      await expectLater(
        svc.getWeeklyStreak('player1'),
        throwsA(isA<UnimplementedError>()),
      );
    });

    test('claimWeeklyReward propagates error from stub', () async {
      await expectLater(
        svc.claimWeeklyReward(3),
        throwsA(isA<UnimplementedError>()),
      );
    });
  });
}
