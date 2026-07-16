import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/core/services/guest_api_gate.dart';
import 'package:synaptix/core/services/guest_session_controller.dart';
import 'package:synaptix/game/providers/core_providers.dart';

/// Reactive guest flag for UI (banner, etc.). Kept in sync with [GuestApiGate].
final isGuestSessionProvider = StateProvider<bool>((ref) {
  return GuestApiGate.isGuestSession;
});

/// App-wide guest session controller (API gate flags, warn toast, leave wipe).
final guestSessionControllerProvider = Provider<GuestSessionController>((ref) {
  final controller = GuestSessionController(
    serviceManager: ref.watch(serviceManagerProvider),
    onGuestFlagChanged: (isGuest) {
      ref.read(isGuestSessionProvider.notifier).state = isGuest;
    },
  );
  ref.onDispose(controller.dispose);
  return controller;
});
