import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';

final powerUpTimeProvider = StateNotifierProvider<PowerUpTimeNotifier, int?>((ref) {
  return PowerUpTimeNotifier(ref);
});

class PowerUpTimeNotifier extends StateNotifier<int?> {
  final Ref ref;
  Timer? _timer;

  PowerUpTimeNotifier(this.ref) : super(null);

  final powerUpTimeProvider = StreamProvider<int?>((ref) {
    final powerUp = ref.watch(equippedPowerUpProvider);
    if (powerUp == null) return const Stream.empty();

    final endTime = DateTime.now().add(Duration(seconds: powerUp.duration!));
    return Stream.periodic(const Duration(seconds: 1), (_) {
      final remaining = endTime.difference(DateTime.now()).inSeconds;
      return remaining > 0 ? remaining : 0;
    }).takeWhile((remaining) => remaining > 0);
  });


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

  void stop() {
    _timer?.cancel();
    state = null;
  }

  bool get isActive => state != null && state! > 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
