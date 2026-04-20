import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart'
    hide analyticsServiceProvider;
import '../../game/analytics/providers/analytics_providers.dart';
import 'synaptix_mode.dart';
import 'synaptix_mode_notifier.dart';

/// Provider for the active [SynaptixMode].
///
/// Initialized with the user's age-group-derived mode at bootstrap.
/// Widgets can read the mode via `ref.watch(synaptixModeProvider)`.
final synaptixModeProvider =
    StateNotifierProvider<SynaptixModeNotifier, SynaptixMode>((ref) {
  final profileService = ref.read(playerProfileServiceProvider);
  final notifier = SynaptixModeNotifier(profileService);
  try {
    notifier.setAnalyticsService(ref.read(analyticsServiceProvider));
  } catch (_) {
    // Analytics may not be available during early bootstrap
  }
  return notifier;
});
