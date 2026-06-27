import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/manager/log_manager.dart';

/// API client for daily bonus rewards
class DailyBonusApiClient {
  final http.Client _httpClient;

  DailyBonusApiClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  static const String _baseUrl = 'https://api.synaptixplay.com/api/v1';
  static const String _accountRewardsPath = '/account/rewards';
  static const String _rewardsPath = '/rewards';

  /// Get daily reward configuration
  Future<DailyRewardConfig> getDailyConfig() async {
    try {
      final uri = Uri.parse('$_baseUrl$_rewardsPath/daily-config');

      LogManager.debug('[DailyBonusApiClient] GET $uri');

      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final config = DailyRewardConfig.fromJson(data);
        LogManager.debug(
          '[DailyBonusApiClient] Loaded daily config: ${config.coinsAmount} coins',
        );
        return config;
      } else {
        throw DailyBonusException(
          message: 'Failed to fetch daily config',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      LogManager.error(
        '[DailyBonusApiClient] Error fetching daily config: $e',
        source: 'DailyBonusApiClient.getDailyConfig',
        error: e,
      );
      rethrow;
    }
  }

  /// Get account reward status (daily claim tracking)
  Future<AccountRewardStatus> getAccountRewardStatus() async {
    try {
      final uri = Uri.parse('$_baseUrl$_accountRewardsPath/status');

      LogManager.debug('[DailyBonusApiClient] GET $uri');

      final response = await _httpClient.get(uri);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = AccountRewardStatus.fromJson(data);
        LogManager.debug(
          '[DailyBonusApiClient] Account reward status: claimed=${"${status.claimedToday}"}, streak=${status.currentStreak}',
        );
        return status;
      } else if (response.statusCode == 401) {
        throw DailyBonusException(
          message: 'Unauthorized - user not logged in',
          statusCode: response.statusCode,
        );
      } else {
        throw DailyBonusException(
          message: 'Failed to fetch account reward status',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      LogManager.error(
        '[DailyBonusApiClient] Error fetching account reward status: $e',
        source: 'DailyBonusApiClient.getAccountRewardStatus',
        error: e,
      );
      rethrow;
    }
  }

  /// Claim daily reward
  Future<RewardClaimResult> claimDailyReward() async {
    try {
      final uri = Uri.parse('$_baseUrl$_accountRewardsPath/claim');

      LogManager.debug('[DailyBonusApiClient] POST $uri');

      final response = await _httpClient.post(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final result = RewardClaimResult.fromJson(data);
        LogManager.debug(
          '[DailyBonusApiClient] Daily reward claimed: ${result.coinsAwarded} coins',
        );
        return result;
      } else if (response.statusCode == 400) {
        // Already claimed today
        throw AlreadyClaimedException('Daily reward already claimed today');
      } else if (response.statusCode == 401) {
        throw DailyBonusException(
          message: 'Unauthorized - user not logged in',
          statusCode: response.statusCode,
        );
      } else {
        throw DailyBonusException(
          message: 'Failed to claim daily reward',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      LogManager.error(
        '[DailyBonusApiClient] Error claiming daily reward: $e',
        source: 'DailyBonusApiClient.claimDailyReward',
        error: e,
      );
      rethrow;
    }
  }

  /// Close the HTTP client
  void close() {
    _httpClient.close();
  }
}

/// Daily reward configuration
class DailyRewardConfig {
  final String rewardType; // 'coins' or 'gems'
  final int coinsAmount;
  final int? gemsAmount;
  final String displayName;
  final String iconName;

  DailyRewardConfig({
    required this.rewardType,
    required this.coinsAmount,
    this.gemsAmount,
    required this.displayName,
    required this.iconName,
  });

  factory DailyRewardConfig.fromJson(Map<String, dynamic> json) {
    return DailyRewardConfig(
      rewardType: json['rewardType'] ?? json['reward_type'] ?? 'coins',
      coinsAmount: json['coinsAmount'] ?? json['coins_amount'] ?? 100,
      gemsAmount: json['gemsAmount'] ?? json['gems_amount'],
      displayName: json['displayName'] ?? json['display_name'] ?? 'Daily Reward',
      iconName: json['iconName'] ?? json['icon_name'] ?? 'daily_box',
    );
  }

  Map<String, dynamic> toJson() => {
    'rewardType': rewardType,
    'coinsAmount': coinsAmount,
    'gemsAmount': gemsAmount,
    'displayName': displayName,
    'iconName': iconName,
  };
}

/// Account reward status
class AccountRewardStatus {
  final bool claimedToday;
  final DateTime? nextDailyClaimAt;
  final int currentStreak;
  final String rewardType;
  final int coinsAmount;
  final int? gemsAmount;

  AccountRewardStatus({
    required this.claimedToday,
    this.nextDailyClaimAt,
    required this.currentStreak,
    required this.rewardType,
    required this.coinsAmount,
    this.gemsAmount,
  });

  factory AccountRewardStatus.fromJson(Map<String, dynamic> json) {
    return AccountRewardStatus(
      claimedToday: json['claimedToday'] ?? json['claimed_today'] ?? false,
      nextDailyClaimAt: json['nextDailyClaimAt'] != null
          ? DateTime.parse(json['nextDailyClaimAt'] as String)
          : null,
      currentStreak: json['currentStreak'] ?? json['current_streak'] ?? 0,
      rewardType: json['rewardType'] ?? json['reward_type'] ?? 'coins',
      coinsAmount: json['coinsAmount'] ?? json['coins_amount'] ?? 100,
      gemsAmount: json['gemsAmount'] ?? json['gems_amount'],
    );
  }

  Map<String, dynamic> toJson() => {
    'claimedToday': claimedToday,
    'nextDailyClaimAt': nextDailyClaimAt?.toIso8601String(),
    'currentStreak': currentStreak,
    'rewardType': rewardType,
    'coinsAmount': coinsAmount,
    'gemsAmount': gemsAmount,
  };

  /// Time until next claim is available
  Duration? get timeUntilNextClaim {
    if (nextDailyClaimAt == null) return null;
    final remaining = nextDailyClaimAt!.difference(DateTime.now());
    return remaining.isNegative ? null : remaining;
  }
}

/// Result of claiming a reward
class RewardClaimResult {
  final int coinsAwarded;
  final int? gemsAwarded;
  final int newTotalCoins;
  final int newTotalGems;
  final int newStreak;

  RewardClaimResult({
    required this.coinsAwarded,
    this.gemsAwarded,
    required this.newTotalCoins,
    required this.newTotalGems,
    required this.newStreak,
  });

  factory RewardClaimResult.fromJson(Map<String, dynamic> json) {
    return RewardClaimResult(
      coinsAwarded: json['coinsAwarded'] ?? json['coins_awarded'] ?? 0,
      gemsAwarded: json['gemsAwarded'] ?? json['gems_awarded'],
      newTotalCoins: json['newTotalCoins'] ?? json['new_total_coins'] ?? 0,
      newTotalGems: json['newTotalGems'] ?? json['new_total_gems'] ?? 0,
      newStreak: json['newStreak'] ?? json['new_streak'] ?? 1,
    );
  }

  Map<String, dynamic> toJson() => {
    'coinsAwarded': coinsAwarded,
    'gemsAwarded': gemsAwarded,
    'newTotalCoins': newTotalCoins,
    'newTotalGems': newTotalGems,
    'newStreak': newStreak,
  };
}

/// Exception for daily bonus operations
class DailyBonusException implements Exception {
  final String message;
  final int statusCode;

  DailyBonusException({
    required this.message,
    required this.statusCode,
  });

  @override
  String toString() =>
      'DailyBonusException: $message (status: $statusCode)';
}

/// Exception when reward already claimed
class AlreadyClaimedException implements Exception {
  final String message;

  AlreadyClaimedException(this.message);

  @override
  String toString() => 'AlreadyClaimedException: $message';
}
