import '../../core/services/api_service.dart';
import '../../ui_components/spin_wheel/models/spin_system_models.dart';
import '../../ui_components/spin_wheel/services/spin_tracker.dart';
import '../models/reward_step_models.dart';

class DailyRewardConfigModel {
  final String rewardType;
  final int coinsAmount;
  final String displayName;
  final String iconName;

  const DailyRewardConfigModel({
    required this.rewardType,
    required this.coinsAmount,
    required this.displayName,
    required this.iconName,
  });

  factory DailyRewardConfigModel.fromJson(Map<String, dynamic> json) {
    return DailyRewardConfigModel(
      rewardType: (json['rewardType'] ?? 'coins').toString(),
      coinsAmount: (json['coinsAmount'] as num? ?? 100).toInt(),
      displayName: (json['displayName'] ?? 'Daily Mystery Box').toString(),
      iconName: (json['iconName'] ?? 'daily_box').toString(),
    );
  }
}

class DailyRewardStatusModel {
  final bool isClaimAvailable;
  final DateTime? nextAvailableAtUtc;

  const DailyRewardStatusModel({
    required this.isClaimAvailable,
    this.nextAvailableAtUtc,
  });
}

class DailyRewardClaimModel {
  final bool success;
  final int coinsGranted;
  final int newBalance;
  final String message;
  final DateTime? nextClaimAt;

  const DailyRewardClaimModel({
    required this.success,
    required this.coinsGranted,
    required this.newBalance,
    required this.message,
    this.nextClaimAt,
  });

  factory DailyRewardClaimModel.fromJson(Map<String, dynamic> json) {
    return DailyRewardClaimModel(
      success: json['success'] == true,
      coinsGranted: (json['coinsGranted'] as num? ?? 0).toInt(),
      newBalance: (json['newBalance'] as num? ?? 0).toInt(),
      message: (json['message'] ?? '').toString(),
      nextClaimAt: _parseDate(json['nextClaimAt']),
    );
  }
}

class WeeklyRewardDayModel {
  final int day;
  final String rewardType;
  final int coinsAmount;
  final int gemsAmount;
  final String displayLabel;

  const WeeklyRewardDayModel({
    required this.day,
    required this.rewardType,
    required this.coinsAmount,
    required this.gemsAmount,
    required this.displayLabel,
  });

  factory WeeklyRewardDayModel.fromJson(Map<String, dynamic> json) {
    return WeeklyRewardDayModel(
      day: (json['day'] as num? ?? 1).toInt(),
      rewardType: (json['rewardType'] ?? 'coins').toString(),
      coinsAmount: (json['coinsAmount'] as num? ?? 0).toInt(),
      gemsAmount: (json['gemsAmount'] as num? ?? 0).toInt(),
      displayLabel: (json['displayLabel'] ?? '').toString(),
    );
  }

  String get amountLabel {
    if (coinsAmount > 0 && gemsAmount > 0) return '$coinsAmount + $gemsAmount';
    if (coinsAmount > 0) return coinsAmount.toString();
    if (gemsAmount > 0) return gemsAmount.toString();
    return '1';
  }
}

class WeeklyStreakDataModel {
  final int currentDay;
  final String cycleStart;
  final List<int> claimedDays;
  final List<WeeklyRewardDayModel> schedule;

  const WeeklyStreakDataModel({
    required this.currentDay,
    required this.cycleStart,
    required this.claimedDays,
    required this.schedule,
  });

  factory WeeklyStreakDataModel.fromJson(Map<String, dynamic> json) {
    final rawSchedule = json['schedule'];
    return WeeklyStreakDataModel(
      currentDay: (json['currentDay'] as num? ?? 1).toInt(),
      cycleStart: (json['cycleStart'] ?? '').toString(),
      claimedDays: (json['claimedDays'] as List? ?? const [])
          .map((e) => (e as num).toInt())
          .toList(growable: false),
      schedule: rawSchedule is List
          ? rawSchedule
              .whereType<Map>()
              .map((e) => WeeklyRewardDayModel.fromJson(
                    Map<String, dynamic>.from(e),
                  ))
              .toList(growable: false)
          : const [],
    );
  }
}

class WeeklyClaimResultModel {
  final bool success;
  final int day;
  final int coinsGranted;
  final int gemsGranted;
  final int newBalance;
  final String message;
  final WeeklyStreakDataModel updatedStreak;

  const WeeklyClaimResultModel({
    required this.success,
    required this.day,
    required this.coinsGranted,
    required this.gemsGranted,
    required this.newBalance,
    required this.message,
    required this.updatedStreak,
  });

  factory WeeklyClaimResultModel.fromJson(Map<String, dynamic> json) {
    return WeeklyClaimResultModel(
      success: json['success'] == true,
      day: (json['day'] as num? ?? 1).toInt(),
      coinsGranted: (json['coinsGranted'] as num? ?? 0).toInt(),
      gemsGranted: (json['gemsGranted'] as num? ?? 0).toInt(),
      newBalance: (json['newBalance'] as num? ?? 0).toInt(),
      message: (json['message'] ?? '').toString(),
      updatedStreak: WeeklyStreakDataModel.fromJson(
        Map<String, dynamic>.from(json['updatedStreak'] as Map? ?? const {}),
      ),
    );
  }
}

class RewardsApiService {
  final ApiService _api;

  const RewardsApiService(this._api);

  Future<DailyRewardConfigModel> getDailyConfig() async {
    final json = await _api.get('/rewards/daily-config');
    return DailyRewardConfigModel.fromJson(json);
  }

  Future<DailyRewardStatusModel> getDailyStatus(String playerId) async {
    final json = await _api.get('/store/rewards/$playerId');
    final cards = json['cards'];
    if (cards is List) {
      for (final card in cards.whereType<Map>()) {
        final item = Map<String, dynamic>.from(card);
        if ((item['rewardId'] ?? '').toString() == 'daily-checkin') {
          return DailyRewardStatusModel(
            isClaimAvailable: item['isClaimAvailable'] == true,
            nextAvailableAtUtc: _parseDate(item['nextAvailableAtUtc']),
          );
        }
      }
    }
    return const DailyRewardStatusModel(isClaimAvailable: true);
  }

  Future<DailyRewardClaimModel> claimDailyReward() async {
    final json = await _api.post('/rewards/daily/claim', body: const {});
    return DailyRewardClaimModel.fromJson(json);
  }

  Future<List<WeeklyRewardDayModel>> getWeeklySchedule() async {
    final list = await _api.getList('/rewards/weekly-schedule');
    return list.map(WeeklyRewardDayModel.fromJson).toList(growable: false);
  }

  Future<WeeklyStreakDataModel> getWeeklyStreak(String playerId) async {
    final json = await _api.get('/rewards/weekly-streak/$playerId');
    return WeeklyStreakDataModel.fromJson(json);
  }

  Future<WeeklyClaimResultModel> claimWeeklyReward(int day) async {
    final json = await _api.post('/rewards/weekly/claim', body: {'day': day});
    return WeeklyClaimResultModel.fromJson(json);
  }

  Future<SpinStatistics> getSpinStats(String playerId) async {
    final json = await _api.get('/spins/stats/$playerId');
    final dailyCount =
        _intFromAny(json, const ['dailyCount', 'todayCount', 'today_count']);
    final dailyLimit = _intFromAny(
      json,
      const [
        'dailyLimit',
        'daily_limit',
        'maxSpinsPerDay',
        'max_spins_per_day'
      ],
      fallback: 5,
    );
    final remaining = _intFromAny(
      json,
      const [
        'remainingToday',
        'remaining_today',
        'spinsRemaining',
        'spins_remaining'
      ],
      fallback: dailyLimit - dailyCount,
    );
    return SpinStatistics(
      dailyCount: dailyCount,
      weeklyCount: _intFromAny(json, const ['weeklyCount', 'weekly_count']),
      totalSpins: _intFromAny(
        json,
        const [
          'totalCount',
          'totalSpins',
          'total_spins',
          'total_lifetime_spins'
        ],
      ),
      maxSpinsPerDay: dailyLimit,
      timeUntilNextSpin: Duration.zero,
      canSpin:
          _boolFromAny(json, const ['canSpin', 'can_spin']) ?? remaining > 0,
      cooldownDuration: Duration.zero,
      spinsRemainingToday: remaining.clamp(0, dailyLimit),
    );
  }

  Future<List<SpinResult>> getSpinHistory(
    String playerId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    final list = await _api.getList(
      '/spins/history/$playerId',
      queryParameters: {'page': page, 'pageSize': pageSize},
    );
    return list.map((json) {
      final rewardType = (json['rewardType'] ?? 'coins').toString();
      final amount = (json['amount'] as num? ?? 0).toInt();
      return SpinResult(
        id: (json['spinId'] ?? '').toString(),
        label: '$amount $rewardType',
        reward: amount,
        rewardType: rewardType,
        timestamp: _parseDate(json['claimedAt']) ?? DateTime.now(),
      );
    }).toList(growable: false);
  }

  Future<List<RewardStep>> getSpinRewardSteps() async {
    final list = await _api.getList('/rewards/spin-reward-steps');
    return list.map((json) {
      final type = _rewardType(json['rewardType']);
      return RewardStep(
        pointValue: (json['pointValue'] as num? ?? 0).toDouble(),
        icon: type.defaultIcon,
        backgroundColor: type.defaultColor,
        quantity: (json['quantity'] as num? ?? 1).toInt(),
        description: (json['description'] ?? type.displayName).toString(),
        type: type,
      );
    }).toList(growable: false);
  }
}

int _intFromAny(
  Map<String, dynamic> json,
  List<String> keys, {
  int fallback = 0,
}) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value.toInt();
    if (value is String) {
      final parsed = num.tryParse(value);
      if (parsed != null) return parsed.toInt();
    }
  }
  return fallback;
}

bool? _boolFromAny(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    if (value is String) {
      final normalized = value.toLowerCase();
      if (normalized == 'true') return true;
      if (normalized == 'false') return false;
    }
  }
  return null;
}

RewardType _rewardType(Object? value) {
  final normalized = (value ?? '').toString().toLowerCase();
  switch (normalized) {
    case 'gems':
    case 'diamonds':
      return RewardType.gems;
    case 'coins':
      return RewardType.coins;
    default:
      return RewardType.custom;
  }
}

DateTime? _parseDate(Object? value) {
  if (value == null) return null;
  return DateTime.tryParse(value.toString());
}
