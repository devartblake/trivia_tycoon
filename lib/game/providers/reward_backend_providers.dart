import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../screens/rewards/presets/reward_step_presets.dart';
import '../../core/services/user_identity_resolver.dart';
import '../../ui_components/spin_wheel/models/spin_system_models.dart';
import '../../ui_components/spin_wheel/services/spin_tracker.dart';
import '../models/reward_step_models.dart';
import '../services/rewards_api_service.dart';
import 'core_providers.dart' show apiServiceProvider, serviceManagerProvider;
import 'learning_providers.dart' show currentPlayerIdProvider;

final rewardsApiServiceProvider = Provider<RewardsApiService>((ref) {
  return RewardsApiService(ref.watch(apiServiceProvider));
});

final dailyRewardConfigProvider =
    FutureProvider<DailyRewardConfigModel>((ref) async {
  return ref.watch(rewardsApiServiceProvider).getDailyConfig();
});

final dailyRewardStatusProvider =
    FutureProvider.autoDispose<DailyRewardStatusModel>((ref) async {
  final playerId = await ref.watch(currentPlayerIdProvider.future);
  if (playerId == null || playerId.isEmpty) {
    throw StateError('No authenticated player id available.');
  }
  return ref.watch(rewardsApiServiceProvider).getDailyStatus(playerId);
});

final weeklyRewardScheduleProvider =
    FutureProvider<List<WeeklyRewardDayModel>>((ref) async {
  return ref.watch(rewardsApiServiceProvider).getWeeklySchedule();
});

final weeklyStreakProvider =
    FutureProvider.autoDispose<WeeklyStreakDataModel>((ref) async {
  final playerId = await ref.watch(currentPlayerIdProvider.future);
  if (playerId == null || playerId.isEmpty) {
    throw StateError('No authenticated player id available.');
  }
  return ref.watch(rewardsApiServiceProvider).getWeeklyStreak(playerId);
});

final serverSpinStatisticsProvider =
    FutureProvider.autoDispose<SpinStatistics>((ref) async {
  final playerId = await UserIdentityResolver.resolveUserId(
    ref.watch(serviceManagerProvider),
  );
  return ref.watch(rewardsApiServiceProvider).getSpinStats(playerId);
});

final serverSpinHistoryProvider =
    FutureProvider.autoDispose<List<SpinResult>>((ref) async {
  final playerId = await UserIdentityResolver.resolveUserId(
    ref.watch(serviceManagerProvider),
  );
  return ref.watch(rewardsApiServiceProvider).getSpinHistory(playerId);
});

final spinRewardStepsProvider =
    FutureProvider.autoDispose<List<RewardStep>>((ref) async {
  try {
    final steps =
        await ref.watch(rewardsApiServiceProvider).getSpinRewardSteps();
    return steps.isEmpty ? RewardStepPresets.dailySpinRewards : steps;
  } catch (_) {
    return RewardStepPresets.dailySpinRewards;
  }
});
