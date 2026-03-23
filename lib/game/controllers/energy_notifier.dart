import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/settings/general_key_value_storage_service.dart';

// ---------------------------------------------------------------------------
// Energy configuration constants
// ---------------------------------------------------------------------------

/// Maximum energy a player can hold.
const int kEnergyMax = 20;

/// Energy refill interval: 1 energy every 10 minutes.
const Duration kEnergyRefillInterval = Duration(minutes: 10);

/// Energy cost for a casual match.
const int kEnergyCasualCost = 3;

/// Energy cost for a ranked match.
const int kEnergyRankedCost = 4;

/// Energy cost for practice mode (1; set to 0 for completely free).
const int kEnergyPracticeCost = 1;

// ---------------------------------------------------------------------------
// EnergyState
// ---------------------------------------------------------------------------

/// Immutable snapshot of the player's energy.
class EnergyState {
  final int current;
  final int max;
  final DateTime? lastRefillTime;
  final Duration refillInterval;

  const EnergyState({
    required this.current,
    required this.max,
    this.lastRefillTime,
    this.refillInterval = kEnergyRefillInterval,
  });

  EnergyState copyWith({
    int? current,
    int? max,
    DateTime? lastRefillTime,
    Duration? refillInterval,
  }) {
    return EnergyState(
      current: current ?? this.current,
      max: max ?? this.max,
      lastRefillTime: lastRefillTime ?? this.lastRefillTime,
      refillInterval: refillInterval ?? this.refillInterval,
    );
  }
}

// ---------------------------------------------------------------------------
// EnergyNotifier
// ---------------------------------------------------------------------------

/// Manages player energy.
///
/// Energy gates access to all match types:
///   - Casual match: [kEnergyCasualCost]
///   - Ranked match: [kEnergyRankedCost]
///   - Practice mode: [kEnergyPracticeCost]
///
/// Energy refills automatically at a rate of 1 unit per [kEnergyRefillInterval].
/// The maximum storable energy is [kEnergyMax].
class EnergyNotifier extends StateNotifier<EnergyState> {
  final GeneralKeyValueStorageService _storage;
  Timer? _refillTimer;

  EnergyNotifier(this._storage)
      : super(const EnergyState(current: kEnergyMax, max: kEnergyMax)) {
    _loadEnergyState();
    _startRefillTimer();
  }

  Future<void> _loadEnergyState() async {
    // Use generic `get` so we can distinguish null (not yet stored) from 0.
    final rawCurrent = await _storage.get('energy_current');
    final rawMax = await _storage.get('energy_max');
    final lastRefillString = await _storage.getString('energy_last_refill');
    final lastRefill =
        lastRefillString != null ? DateTime.tryParse(lastRefillString) : null;

    final storedCurrent = rawCurrent is int ? rawCurrent : null;
    final storedMax = rawMax is int ? rawMax : null;

    state = state.copyWith(
      current: storedCurrent ?? state.current,
      max: storedMax ?? state.max,
      lastRefillTime: lastRefill,
    );

    _checkForAutoRefill();
  }

  Future<void> _saveEnergyState() async {
    await _storage.setInt('energy_current', state.current);
    await _storage.setInt('energy_max', state.max);
    if (state.lastRefillTime != null) {
      await _storage.setString(
          'energy_last_refill', state.lastRefillTime!.toIso8601String());
    }
  }

  void _checkForAutoRefill() {
    if (state.lastRefillTime == null) return;

    final now = DateTime.now();
    final timeSinceRefill = now.difference(state.lastRefillTime!);
    final refillsEarned =
        timeSinceRefill.inMinutes ~/ state.refillInterval.inMinutes;

    if (refillsEarned > 0) {
      final newCurrent = (state.current + refillsEarned).clamp(0, state.max);
      state = state.copyWith(
        current: newCurrent,
        lastRefillTime: now,
      );
      _saveEnergyState();
    }
  }

  void _startRefillTimer() {
    _refillTimer?.cancel();
    _refillTimer = Timer.periodic(state.refillInterval, (_) {
      if (state.current < state.max) {
        state = state.copyWith(
          current: state.current + 1,
          lastRefillTime: DateTime.now(),
        );
        _saveEnergyState();
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Convenience getters — use these to gate match access in the UI.
  // ---------------------------------------------------------------------------

  /// Whether the player has enough energy for a casual match.
  bool get canPlayCasual => state.current >= kEnergyCasualCost;

  /// Whether the player has enough energy for a ranked match.
  bool get canPlayRanked => state.current >= kEnergyRankedCost;

  /// Whether the player has enough energy for practice mode.
  bool get canPlayPractice => state.current >= kEnergyPracticeCost;

  // ---------------------------------------------------------------------------
  // Energy consumption — call before starting a match.
  // ---------------------------------------------------------------------------

  /// Deduct the cost of a casual match. Returns `true` if successful.
  bool useCasualEnergy() => useEnergy(kEnergyCasualCost);

  /// Deduct the cost of a ranked match. Returns `true` if successful.
  bool useRankedEnergy() => useEnergy(kEnergyRankedCost);

  /// Deduct the cost of practice mode. Returns `true` if successful.
  bool usePracticeEnergy() => useEnergy(kEnergyPracticeCost);

  /// Deduct [amount] energy. Returns `true` if the player had enough energy.
  bool useEnergy(int amount) {
    if (state.current >= amount) {
      state = state.copyWith(current: state.current - amount);
      _saveEnergyState();
      return true;
    }
    return false;
  }

  /// Add [amount] energy, clamped to [EnergyState.max].
  void addEnergy(int amount) {
    final newCurrent = (state.current + amount).clamp(0, state.max);
    state = state.copyWith(current: newCurrent);
    _saveEnergyState();
  }

  /// Synchronise local state with authoritative server values.
  /// Called after a successful GET /mobile/economy/state response.
  void syncWithServer(int serverEnergy, int serverMax, Duration serverInterval) {
    state = state.copyWith(
      current: serverEnergy.clamp(0, serverMax),
      max: serverMax,
      refillInterval: serverInterval,
      lastRefillTime: DateTime.now(),
    );
    _saveEnergyState();
    _startRefillTimer(); // restart with potentially updated interval
  }

  @override
  void dispose() {
    _refillTimer?.cancel();
    super.dispose();
  }
}
