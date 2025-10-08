import 'package:trivia_tycoon/ui_components/spin_wheel/models/spin_system_models.dart';
import 'analytics_service.dart';

/// Dedicated tracker for Spin & Earn analytics
class SpinAnalyticsTracker {
  final AnalyticsService analytics;

  SpinAnalyticsTracker(this.analytics);

  /// Track complete spin session
  Future<void> trackSpinSession({
    required int spinsCompleted,
    required List<WheelSegment> results,
    required Duration sessionDuration,
  }) async {
    int totalRewards = results.fold(0, (sum, segment) => sum + segment.reward);

    await analytics.trackEvent('spin_session_complete', {
      'spins_completed': spinsCompleted,
      'total_rewards': totalRewards,
      'session_duration_seconds': sessionDuration.inSeconds,
      'average_reward': spinsCompleted > 0 ? totalRewards / spinsCompleted : 0,
      'unique_rewards': results.map((e) => e.label).toSet().length,
    });

    // Track best reward in session
    if (results.isNotEmpty) {
      final bestReward = results.reduce((a, b) =>
      a.reward > b.reward ? a : b
      );

      await analytics.trackEvent('session_best_reward', {
        'reward_type': bestReward.label,
        'reward_value': bestReward.reward,
      });
    }
  }

  /// Track user engagement patterns
  Future<void> trackEngagementPattern({
    required List<DateTime> spinTimestamps,
  }) async {
    if (spinTimestamps.length < 2) return;

    final intervals = <Duration>[];
    for (int i = 1; i < spinTimestamps.length; i++) {
      intervals.add(spinTimestamps[i].difference(spinTimestamps[i - 1]));
    }

    final avgInterval = intervals.fold<Duration>(
      Duration.zero,
          (sum, interval) => sum + interval,
    ) ~/ intervals.length;

    await analytics.trackEvent('spin_engagement_pattern', {
      'total_spins': spinTimestamps.length,
      'average_interval_seconds': avgInterval.inSeconds,
      'min_interval_seconds': intervals.map((e) => e.inSeconds).reduce((a, b) => a < b ? a : b),
      'max_interval_seconds': intervals.map((e) => e.inSeconds).reduce((a, b) => a > b ? a : b),
    });
  }

  /// Track reward distribution preferences
  Future<void> trackRewardPreferences({
    required Map<String, int> rewardCounts,
  }) async {
    final totalSpins = rewardCounts.values.fold(0, (sum, count) => sum + count);
    final preferences = <String, double>{};

    rewardCounts.forEach((reward, count) {
      preferences[reward] = (count / totalSpins) * 100;
    });

    await analytics.trackEvent('reward_preferences', {
      'total_spins': totalSpins,
      'reward_distribution': preferences,
      'most_common_reward': rewardCounts.entries
          .reduce((a, b) => a.value > b.value ? a : b)
          .key,
    });
  }

  /// Track daily spin completion rate
  Future<void> trackDailyCompletionRate({
    required int spinsCompleted,
    required int dailyLimit,
  }) async {
    final completionRate = (spinsCompleted / dailyLimit * 100).round();

    await analytics.trackEvent('daily_spin_completion', {
      'spins_completed': spinsCompleted,
      'daily_limit': dailyLimit,
      'completion_rate': completionRate,
      'missed_spins': dailyLimit - spinsCompleted,
    });
  }

  /// Track spin streak (consecutive days)
  Future<void> trackSpinStreak({
    required int currentStreak,
    required int bestStreak,
    required bool isNewRecord,
  }) async {
    await analytics.trackEvent('spin_streak_updated', {
      'current_streak': currentStreak,
      'best_streak': bestStreak,
      'is_new_record': isNewRecord,
      'streak_milestone': _getStreakMilestone(currentStreak),
    });
  }

  String _getStreakMilestone(int streak) {
    if (streak >= 30) return '30_day_master';
    if (streak >= 14) return '2_week_champion';
    if (streak >= 7) return '1_week_warrior';
    if (streak >= 3) return '3_day_starter';
    return 'building_streak';
  }

  /// Track time of day preferences
  Future<void> trackTimePreferences({
    required List<DateTime> spinTimestamps,
  }) async {
    final hourCounts = <int, int>{};

    for (var timestamp in spinTimestamps) {
      final hour = timestamp.hour;
      hourCounts[hour] = (hourCounts[hour] ?? 0) + 1;
    }

    final mostActiveHour = hourCounts.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    await analytics.trackEvent('spin_time_preferences', {
      'most_active_hour': mostActiveHour,
      'hour_distribution': hourCounts,
      'morning_spins': _countSpinsByTimeOfDay(hourCounts, 6, 12),
      'afternoon_spins': _countSpinsByTimeOfDay(hourCounts, 12, 18),
      'evening_spins': _countSpinsByTimeOfDay(hourCounts, 18, 24),
      'night_spins': _countSpinsByTimeOfDay(hourCounts, 0, 6),
    });
  }

  int _countSpinsByTimeOfDay(Map<int, int> hourCounts, int startHour, int endHour) {
    int count = 0;
    for (int hour = startHour; hour < endHour; hour++) {
      count += hourCounts[hour] ?? 0;
    }
    return count;
  }
}
