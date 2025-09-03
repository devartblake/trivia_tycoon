import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/controllers/coin_balance_notifier.dart';
import '../../core/services/settings/general_key_value_storage_service.dart';
import '../models/power_up.dart';

class PowerUpController extends StateNotifier<PowerUp?> {
  final Ref ref;

  PowerUpController(this.ref) : super(null);

  static const _equippedKey = 'equipped_power_up';
  static const _activationTimeKey = 'active_power_up_timestamp';

  GeneralKeyValueStorageService get _storage => ref.read(generalKeyValueStorageProvider);

  /// Returns the activation time of the currently equipped power-up (if any)
  Future<DateTime?> get activationTimestamp async {
    final timestamp = await _storage.getString(_activationTimeKey);
    return timestamp != null ? DateTime.tryParse(timestamp) : null;
  }

  /// Call on app start or screen load to restore equipped power-up
  Future<void> restoreFromStorage(List<PowerUp> availablePowerUps) async {
    final savedId = await _storage.getString(_equippedKey);
    final timestamp = await _storage.getString(_activationTimeKey);

    if (savedId == null || timestamp == null) {
      state = null;
      return;
    }

    final match = availablePowerUps.firstWhere(
          (p) => p.id == savedId,
      orElse: () => PowerUp.none(),
    );

    final startTime = DateTime.tryParse(timestamp);
    final isValid = startTime != null &&
        DateTime.now().isBefore(startTime.add(Duration(seconds: match.duration ?? 0)));

    if (match.id != PowerUp.none().id && isValid) {
      state = match;
    } else {
      await clearEquippedPowerUp();
    }
  }

  /// Attempts to use the power-up.
  /// Returns true if it was equipped successfully (i.e., not already active).
  Future<bool> usePowerUp(PowerUp powerUp) async {
    if (state?.id == powerUp.id) return false; // Already active
    await activate(powerUp);
    return true;
  }

  /// ✅ Equip and activate a power-up with timestamp.
  Future<void> activate(PowerUp powerUp) async {
    state = powerUp;
    await _storage.setString(_equippedKey, powerUp.id);
    await _storage.setString(_activationTimeKey, DateTime.now().toIso8601String());
  }

  /// ✅ Clear equipped power-up and remove its activation timestamp.
  Future<void> clearEquippedPowerUp() async {
    state = null;
    await _storage.remove(_equippedKey);
    await _storage.remove(_activationTimeKey);
  }

  /// ✅ Load a previously equipped power-up by ID from Hive.
  Future<void> loadEquipped(List<PowerUp> availablePowerUps) async {
    final savedId = await _storage.getString(_equippedKey);
    if (savedId != null) {
      final match = availablePowerUps.firstWhere(
            (p) => p.id == savedId,
        orElse: () => PowerUp.none(),
      );
      if (match.id != PowerUp.none().id) state = match;
    }
  }

  /// ✅ Equip a power-up by its ID directly.
  Future<void> equipById(String id, List<PowerUp> availablePowerUps) async {
    final match = availablePowerUps.firstWhere(
          (p) => p.id == id,
      orElse: () => PowerUp.none(),
    );
    if (match.id != PowerUp.none().id) {
      await activate(match);
    }
  }

  /// ✅ Check if the given power-up is currently equipped.
  bool isEquipped(String id) => state?.id == id;

  /// ✅ Check if the equipped power-up is expired based on duration.
  Future<bool> isExpired() async {
    if (state == null) return true;

    final timestamp = await _storage.getString(_activationTimeKey);
    if (timestamp == null) return true;

    final startTime = DateTime.tryParse(timestamp);
    if (startTime == null) return true;

    final duration = Duration(seconds: state!.duration ?? 0);
    return DateTime.now().isAfter(startTime.add(duration));
  }

  /// ✅ Return the remaining active time of the equipped power-up.
  Future<Duration> getRemainingTime() async {
    final timestamp = await _storage.getString(_activationTimeKey);
    if (timestamp == null) return Duration.zero;

    final start = DateTime.tryParse(timestamp);
    if (start == null) return Duration.zero;

    final end = start.add(Duration(seconds: state?.duration ?? 0));
    return end.difference(DateTime.now()).isNegative ? Duration.zero : end.difference(DateTime.now());
  }

  /// ✅ Automatically unequipped if expired.
  Future<void> checkAndClearIfExpired() async {
    if (await isExpired()) {
      await clearEquippedPowerUp();
    }
  }
}