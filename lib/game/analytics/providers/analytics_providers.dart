import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/manager/service_manager.dart';
import '../services/analytics_service.dart';
import '../models/mission_analytics_entry.dart';
import '../models/engagement_entry.dart';
import '../models/retention_entry.dart';
import '../../../core/services/settings/app_settings.dart';

/// Provide the AnalyticsService instance
final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return ServiceManager.instance.analyticsService;
});

/// Raw mock JSON fetchers (non-aggregated)
final missionAnalyticsRawProvider = FutureProvider<List<MissionAnalyticsEntry>>((ref) async {
  final service = ref.read(analyticsServiceProvider);
  return await service.fetchMissionAnalytics();
});

final engagementAnalyticsRawProvider = FutureProvider<List<EngagementEntry>>((ref) async {
  final service = ref.read(analyticsServiceProvider);
  return await service.fetchEngagementAnalytics();
});

final retentionAnalyticsRawProvider = FutureProvider<List<RetentionEntry>>((ref) async {
  final service = ref.read(analyticsServiceProvider);
  return await service.fetchRetentionAnalytics();
});

// ============ SPIN & EARN ANALYTICS PROVIDERS ============

/// Spin statistics provider
final spinStatisticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  return await AppSettings.getSpinStatistics();
});

/// Spin history provider
final spinHistoryProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return await AppSettings.getSpinHistory();
});

/// Daily spin metrics provider
final dailySpinMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final todayCount = await AppSettings.getTodaySpinCount();
  final weeklyCount = await AppSettings.getWeeklySpinCount();
  final totalSpins = await AppSettings.getTotalLifetimeSpins();
  final dailyLimit = await AppSettings.getDailySpinLimit();
  final spinsRemaining = await AppSettings.getRemainingSpinsToday();
  final rewardPoints = await AppSettings.getSpinRewardPoints();

  return {
    'todayCount': todayCount,
    'weeklyCount': weeklyCount,
    'totalSpins': totalSpins,
    'dailyLimit': dailyLimit,
    'spinsRemaining': spinsRemaining,
    'rewardPoints': rewardPoints,
    'utilizationRate': dailyLimit > 0 ? (todayCount / dailyLimit * 100) : 0.0,
  };
});

/// Spin engagement rate provider
final spinEngagementRateProvider = FutureProvider<double>((ref) async {
  final todayCount = await AppSettings.getTodaySpinCount();
  final dailyLimit = await AppSettings.getDailySpinLimit();

  if (dailyLimit == 0) return 0.0;
  return (todayCount / dailyLimit) * 100;
});

/// Recent spins provider (last 10)
final recentSpinsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final history = await AppSettings.getSpinHistory();
  return history.take(10).toList();
});

/// Reward distribution provider
final rewardDistributionProvider = FutureProvider<Map<String, int>>((ref) async {
  final stats = await AppSettings.getSpinStatistics();
  final rewardCounts = stats['rewardCounts'] as Map<String, dynamic>?;

  if (rewardCounts == null) return {};

  return Map<String, int>.from(
      rewardCounts.map((key, value) => MapEntry(key, value as int))
  );
});

/// Spin trend data provider (for charts)
final spinTrendDataProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final history = await AppSettings.getSpinHistory();

  // Group by date
  final Map<String, Map<String, dynamic>> dateGroups = {};

  for (var spin in history) {
    final timestamp = spin['timestamp'];
    if (timestamp == null) continue;

    try {
      final date = timestamp is DateTime
          ? timestamp
          : DateTime.parse(timestamp.toString());
      final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

      if (!dateGroups.containsKey(dateKey)) {
        dateGroups[dateKey] = {
          'date': dateKey,
          'spinCount': 0,
          'totalRewards': 0,
        };
      }

      dateGroups[dateKey]!['spinCount'] = (dateGroups[dateKey]!['spinCount'] as int) + 1;
      dateGroups[dateKey]!['totalRewards'] =
          (dateGroups[dateKey]!['totalRewards'] as int) + (spin['rewardValue'] as int? ?? 0);
    } catch (e) {
      // Skip invalid entries
      continue;
    }
  }

  final sortedData = dateGroups.values.toList()
    ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

  return sortedData.take(30).toList(); // Last 30 days
});

/// Best spin rewards provider
final bestSpinRewardsProvider = FutureProvider<List<Map<String, dynamic>>>((ref) async {
  final history = await AppSettings.getSpinHistory();

  final sorted = List<Map<String, dynamic>>.from(history)
    ..sort((a, b) =>
    ((b['rewardValue'] as int? ?? 0).compareTo(a['rewardValue'] as int? ?? 0))
    );

  return sorted.take(5).toList();
});

/// Spin performance metrics provider
final spinPerformanceMetricsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final stats = await AppSettings.getSpinStatistics();
  final dailyMetrics = await ref.watch(dailySpinMetricsProvider.future);

  final totalSpins = stats['totalSpins'] ?? 0;
  final totalRewards = stats['totalRewardsEarned'] ?? 0;
  final bestReward = stats['bestReward'] ?? 0;

  return {
    'totalSpins': totalSpins,
    'totalRewards': totalRewards,
    'bestReward': bestReward,
    'averageReward': totalSpins > 0 ? (totalRewards / totalSpins).round() : 0,
    'todayUtilization': dailyMetrics['utilizationRate'],
    'weeklyAverage': dailyMetrics['weeklyCount'] > 0
        ? (dailyMetrics['weeklyCount'] / 7).round()
        : 0,
  };
});

/// Combined spin analytics provider
final spinAnalyticsSummaryProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final stats = await ref.watch(spinStatisticsProvider.future);
  final dailyMetrics = await ref.watch(dailySpinMetricsProvider.future);
  final distribution = await ref.watch(rewardDistributionProvider.future);
  final performance = await ref.watch(spinPerformanceMetricsProvider.future);

  return {
    'statistics': stats,
    'dailyMetrics': dailyMetrics,
    'rewardDistribution': distribution,
    'performance': performance,
  };
});