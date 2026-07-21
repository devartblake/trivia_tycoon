import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui_components/spin_wheel/services/spin_tracker.dart';
import 'reward_backend_providers.dart';

/// Live spin statistics. Invalidate via [ref.invalidate] after each spin
/// so all watching widgets (reward_screen, spin_earn_screen) rebuild.
final spinStatisticsProvider =
    FutureProvider.autoDispose<SpinStatistics>((ref) async {
  try {
    return await ref.watch(serverSpinStatisticsProvider.future);
  } catch (_) {
    return EnhancedSpinTracker.getStatistics();
  }
});

/// Centralized notifier for spin availability and cooldown state
class SpinStateNotifier extends AutoDisposeAsyncNotifier<SpinStatistics> {
  @override
  Future<SpinStatistics> build() async {
    return ref.watch(spinStatisticsProvider.future);
  }

  /// Manually refresh availability
  Future<void> refresh() async {
    ref.invalidate(spinStatisticsProvider);
  }
}

final spinStateNotifierProvider =
    AsyncNotifierProvider.autoDispose<SpinStateNotifier, SpinStatistics>(() {
  return SpinStateNotifier();
});
