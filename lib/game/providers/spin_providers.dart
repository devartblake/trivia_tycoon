import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui_components/spin_wheel/services/spin_tracker.dart';

/// Live spin statistics. Invalidate via [ref.invalidate] after each spin
/// so all watching widgets (reward_screen, spin_earn_screen) rebuild.
final spinStatisticsProvider =
    FutureProvider.autoDispose<SpinStatistics>((ref) async {
  return EnhancedSpinTracker.getStatistics();
});
