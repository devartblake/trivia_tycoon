import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../game/providers/arcade_providers.dart'
    show rewardReactorServiceProvider;
import '../controllers/reactor_notifier.dart';

export '../controllers/reactor_notifier.dart' show ReactorPhase, ReactorState;

final reactorProvider =
    StateNotifierProvider.autoDispose<ReactorNotifier, ReactorState>((ref) {
  return ReactorNotifier(ref.read(rewardReactorServiceProvider));
});

final reactorPhaseProvider = Provider.autoDispose<ReactorPhase>((ref) =>
    ref.watch(reactorProvider).phase);

final reactorCooldownProvider = Provider.autoDispose<DateTime?>((ref) =>
    ref.watch(reactorProvider).cooldownUntil);
