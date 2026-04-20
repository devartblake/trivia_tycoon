import 'analytics_service.dart';
import '../../../core/services/settings/app_settings.dart';

extension SpinAnalytics on AnalyticsService {
  /// Track when user completes a spin
  Future<void> trackSpinCompleted({
    required String rewardType,
    required int rewardValue,
    required int spinsRemaining,
    required double rewardPoints,
  }) async {
    await trackEvent('spin_completed', {
      'reward_type': rewardType,
      'reward_value': rewardValue,
      'spins_remaining': spinsRemaining,
      'reward_points': rewardPoints,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Update spin statistics in AppSettings
    await _updateSpinStatisticsInSettings(
      rewardType: rewardType,
      rewardValue: rewardValue,
    );
  }

  /// Private helper to update spin statistics in AppSettings
  Future<void> _updateSpinStatisticsInSettings({
    required String rewardType,
    required int rewardValue,
  }) async {
    final stats = await AppSettings.getSpinStatistics();

    // Update total spins
    stats['totalSpins'] = (stats['totalSpins'] ?? 0) + 1;

    // Update reward type counts
    final rewardCounts = Map<String, int>.from(stats['rewardCounts'] ?? {});
    rewardCounts[rewardType] = (rewardCounts[rewardType] ?? 0) + 1;
    stats['rewardCounts'] = rewardCounts;

    // Update total rewards earned
    stats['totalRewardsEarned'] =
        (stats['totalRewardsEarned'] ?? 0) + rewardValue;

    // Update best reward
    if (rewardValue > (stats['bestReward'] ?? 0)) {
      stats['bestReward'] = rewardValue;
      stats['bestRewardType'] = rewardType;
    }

    await AppSettings.saveSpinStatistics(stats);
  }

  /// Track spin wheel opened
  Future<void> trackSpinWheelOpened({
    required int spinsRemaining,
    required double rewardPoints,
    String? source,
  }) async {
    await trackEvent('spin_wheel_opened', {
      'spins_remaining': spinsRemaining,
      'reward_points': rewardPoints,
      'source': source ?? 'unknown',
    });
  }

  /// Track when user runs out of spins
  Future<void> trackNoSpinsAvailable({
    required int dailyLimit,
    required int todayCount,
  }) async {
    await trackEvent('no_spins_available', {
      'daily_limit': dailyLimit,
      'today_count': todayCount,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track reward milestone reached
  Future<void> trackRewardMilestone({
    required String milestoneType,
    required double pointValue,
    required String rewardDescription,
  }) async {
    await trackEvent('reward_milestone_reached', {
      'milestone_type': milestoneType,
      'point_value': pointValue,
      'reward_description': rewardDescription,
    });
  }

  /// Track spin settings changed
  Future<void> trackSpinSettingChanged({
    required String settingName,
    required bool newValue,
  }) async {
    await trackEvent('spin_setting_changed', {
      'setting_name': settingName,
      'new_value': newValue,
    });
  }

  /// Track bonus spin activated
  Future<void> trackBonusSpinActivated({
    required double multiplier,
    required DateTime expiryTime,
  }) async {
    await trackEvent('bonus_spin_activated', {
      'multiplier': multiplier,
      'expiry_time': expiryTime.toIso8601String(),
    });
  }

  /// Track daily/weekly reset
  Future<void> trackSpinReset({
    required String resetType, // 'daily' or 'weekly'
    required DateTime resetTime,
  }) async {
    await trackEvent('spin_reset', {
      'reset_type': resetType,
      'reset_time': resetTime.toIso8601String(),
    });
  }

  /// Track when a spin results in a specific reward tier
  Future<void> trackRewardTierReceived({
    required String tier, // 'common', 'uncommon', 'rare', 'jackpot'
    required String rewardType,
    required int rewardValue,
  }) async {
    await trackEvent('reward_tier_received', {
      'tier': tier,
      'reward_type': rewardType,
      'reward_value': rewardValue,
    });
  }

  /// Track spin streak (consecutive days)
  Future<void> trackSpinStreak({
    required int streakDays,
    required bool isNewRecord,
  }) async {
    await trackEvent('spin_streak', {
      'streak_days': streakDays,
      'is_new_record': isNewRecord,
    });
  }

  /// Track when user views spin history
  Future<void> trackSpinHistoryViewed({
    required int historyCount,
  }) async {
    await trackEvent('spin_history_viewed', {
      'history_count': historyCount,
    });
  }

  /// Track when user claims a reward
  Future<void> trackRewardClaimed({
    required String rewardType,
    required int rewardValue,
    required double pointsSpent,
  }) async {
    await trackEvent('reward_claimed', {
      'reward_type': rewardType,
      'reward_value': rewardValue,
      'points_spent': pointsSpent,
    });
  }

  /// Track spin session metrics
  Future<void> trackSpinSession({
    required int spinsInSession,
    required int totalRewardsEarned,
    required Duration sessionDuration,
  }) async {
    await trackEvent('spin_session', {
      'spins_in_session': spinsInSession,
      'total_rewards_earned': totalRewardsEarned,
      'session_duration_seconds': sessionDuration.inSeconds,
    });
  }

  /// Track when user shares spin results
  Future<void> trackSpinResultShared({
    required String rewardType,
    required int rewardValue,
    required String shareMethod, // 'social', 'message', etc.
  }) async {
    await trackEvent('spin_result_shared', {
      'reward_type': rewardType,
      'reward_value': rewardValue,
      'share_method': shareMethod,
    });
  }

  /// Track premium spin usage (if applicable)
  Future<void> trackPremiumSpinUsed({
    required String premiumType, // 'bonus', 'purchased', etc.
    required int cost,
  }) async {
    await trackEvent('premium_spin_used', {
      'premium_type': premiumType,
      'cost': cost,
    });
  }

  /// Track spin wheel customization
  Future<void> trackSpinWheelCustomized({
    required String customizationType, // 'theme', 'animation', etc.
    required String value,
  }) async {
    await trackEvent('spin_wheel_customized', {
      'customization_type': customizationType,
      'value': value,
    });
  }

  /// Batch update spin statistics (for efficiency)
  Future<void> batchUpdateSpinStats({
    required List<Map<String, dynamic>> spinResults,
  }) async {
    final stats = await AppSettings.getSpinStatistics();

    int totalSpinsAdded = 0;
    int totalRewardsAdded = 0;
    int maxReward = stats['bestReward'] ?? 0;
    String? bestRewardType = stats['bestRewardType'];

    final rewardCounts = Map<String, int>.from(stats['rewardCounts'] ?? {});

    for (var result in spinResults) {
      final rewardType = result['rewardType'] as String;
      final rewardValue = result['rewardValue'] as int;

      totalSpinsAdded++;
      totalRewardsAdded += rewardValue;

      rewardCounts[rewardType] = (rewardCounts[rewardType] ?? 0) + 1;

      if (rewardValue > maxReward) {
        maxReward = rewardValue;
        bestRewardType = rewardType;
      }
    }

    stats['totalSpins'] = (stats['totalSpins'] ?? 0) + totalSpinsAdded;
    stats['totalRewardsEarned'] =
        (stats['totalRewardsEarned'] ?? 0) + totalRewardsAdded;
    stats['rewardCounts'] = rewardCounts;
    stats['bestReward'] = maxReward;
    if (bestRewardType != null) {
      stats['bestRewardType'] = bestRewardType;
    }

    await AppSettings.saveSpinStatistics(stats);

    // Track the batch update event
    await trackEvent('spin_stats_batch_updated', {
      'spins_added': totalSpinsAdded,
      'rewards_added': totalRewardsAdded,
    });
  }

  /// Get comprehensive spin analytics
  Future<Map<String, dynamic>> getSpinAnalytics() async {
    final stats = await AppSettings.getSpinStatistics();
    final history = await AppSettings.getSpinHistory();
    final todayCount = await AppSettings.getTodaySpinCount();
    final weeklyCount = await AppSettings.getWeeklySpinCount();
    final totalSpins = await AppSettings.getTotalLifetimeSpins();

    return {
      'statistics': stats,
      'recent_history': history.take(10).toList(),
      'today_count': todayCount,
      'weekly_count': weeklyCount,
      'total_spins': totalSpins,
      'generated_at': DateTime.now().toIso8601String(),
    };
  }
}
