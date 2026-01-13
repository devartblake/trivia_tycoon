import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

/// Provider for power-up countdown timer
final powerUpTimeProvider = StateNotifierProvider<PowerUpTimeNotifier, int?>((ref) {
  return PowerUpTimeNotifier(ref);
});

/// Notifier that manages power-up countdown timer
class PowerUpTimeNotifier extends StateNotifier<int?> {
  final Ref ref;
  Timer? _timer;

  PowerUpTimeNotifier(this.ref) : super(null);

  /// Start countdown timer
  void start(int seconds) {
    _timer?.cancel();
    state = seconds;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state == null || state! <= 1) {
        timer.cancel();
        state = null;

        // Clear equipped power-up after time expires
        ref.read(equippedPowerUpProvider.notifier).clearEquippedPowerUp();
      } else {
        state = state! - 1;
      }
    });
  }

  /// Stop timer and clear state
  void stop() {
    _timer?.cancel();
    state = null;
  }

  /// Check if timer is currently active
  bool get isActive => state != null && state! > 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}