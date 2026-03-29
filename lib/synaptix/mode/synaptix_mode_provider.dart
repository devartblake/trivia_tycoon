import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'synaptix_mode.dart';
import 'synaptix_mode_notifier.dart';

/// Provider for the active [SynaptixMode].
///
/// Initialized with the user's age-group-derived mode at bootstrap.
/// Widgets can read the mode via `ref.watch(synaptixModeProvider)`.
final synaptixModeProvider =
    StateNotifierProvider<SynaptixModeNotifier, SynaptixMode>((ref) {
  final profileService = ref.read(playerProfileServiceProvider);
  return SynaptixModeNotifier(profileService);
});
