import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/settings/general_key_value_storage_service.dart';

class EnergyState {
  final int current;
  final int max;
  final DateTime? lastRefillTime;
  final Duration refillInterval;

  const EnergyState({
    required this.current,
    required this.max,
    this.lastRefillTime,
    this.refillInterval = const Duration(minutes: 30),
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

class LivesState {
  final int current;
  final int max;
  final DateTime? lastRefillTime;
  final Duration refillInterval;

  const LivesState({
    required this.current,
    required this.max,
    this.lastRefillTime,
    this.refillInterval = const Duration(hours: 2),
  });

  LivesState copyWith({
    int? current,
    int? max,
    DateTime? lastRefillTime,
    Duration? refillInterval,
  }) {
    return LivesState(
      current: current ?? this.current,
      max: max ?? this.max,
      lastRefillTime: lastRefillTime ?? this.lastRefillTime,
      refillInterval: refillInterval ?? this.refillInterval,
    );
  }
}

// --- Notifiers ---

class EnergyNotifier extends StateNotifier<EnergyState> {
  final GeneralKeyValueStorageService _storage;
  Timer? _refillTimer;

  EnergyNotifier(this._storage) : super(const EnergyState(current: 45, max: 50)) {
    _loadEnergyState();
    _startRefillTimer();
  }

  Future<void> _loadEnergyState() async {
    final current = await _storage.getInt('energy_current');
    final max = await _storage.getInt('energy_max');
    final lastRefillString = await _storage.getString('energy_last_refill');
    final lastRefill = lastRefillString != null ? DateTime.parse(lastRefillString) : null;

    state = state.copyWith(
      current: current,
      max: max,
      lastRefillTime: lastRefill,
    );

    _checkForAutoRefill();
  }

  Future<void> _saveEnergyState() async {
    await _storage.setInt('energy_current', state.current);
    await _storage.setInt('energy_max', state.max);
    if (state.lastRefillTime != null) {
      await _storage.setString('energy_last_refill', state.lastRefillTime!.toIso8601String());
    }
  }

  void _checkForAutoRefill() {
    if (state.lastRefillTime == null) return;

    final now = DateTime.now();
    final timeSinceRefill = now.difference(state.lastRefillTime!);
    final refillsEarned = timeSinceRefill.inMinutes ~/ state.refillInterval.inMinutes;

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

  void useEnergy(int amount) {
    if (state.current >= amount) {
      state = state.copyWith(current: state.current - amount);
      _saveEnergyState();
    }
  }

  void addEnergy(int amount) {
    final newCurrent = (state.current + amount).clamp(0, state.max);
    state = state.copyWith(current: newCurrent);
    _saveEnergyState();
  }

  @override
  void dispose() {
    _refillTimer?.cancel();
    super.dispose();
  }
}

class LivesNotifier extends StateNotifier<LivesState> {
  final GeneralKeyValueStorageService _storage;
  Timer? _refillTimer;

  LivesNotifier(this._storage) : super(const LivesState(current: 3, max: 5)) {
    _loadLivesState();
    _startRefillTimer();
  }

  Future<void> _loadLivesState() async {
    final current = await _storage.getInt('lives_current') ?? 3;
    final max = await _storage.getInt('lives_max') ?? 5;
    final lastRefillString = await _storage.getString('lives_last_refill');
    final lastRefill = lastRefillString != null ? DateTime.parse(lastRefillString) : null;

    state = state.copyWith(
      current: current,
      max: max,
      lastRefillTime: lastRefill,
    );

    _checkForAutoRefill();
  }

  Future<void> _saveLivesState() async {
    await _storage.setInt('lives_current', state.current);
    await _storage.setInt('lives_max', state.max);
    if (state.lastRefillTime != null) {
      await _storage.setString('lives_last_refill', state.lastRefillTime!.toIso8601String());
    }
  }

  void _checkForAutoRefill() {
    if (state.lastRefillTime == null) return;

    final now = DateTime.now();
    final timeSinceRefill = now.difference(state.lastRefillTime!);
    final refillsEarned = timeSinceRefill.inHours ~/ state.refillInterval.inHours;

    if (refillsEarned > 0) {
      final newCurrent = (state.current + refillsEarned).clamp(0, state.max);
      state = state.copyWith(
        current: newCurrent,
        lastRefillTime: now,
      );
      _saveLivesState();
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
        _saveLivesState();
      }
    });
  }

  void useLives(int amount) {
    if (state.current >= amount) {
      state = state.copyWith(current: state.current - amount);
      _saveLivesState();
    }
  }

  void addLives(int amount) {
    final newCurrent = (state.current + amount).clamp(0, state.max);
    state = state.copyWith(current: newCurrent);
    _saveLivesState();
  }

  @override
  void dispose() {
    _refillTimer?.cancel();
    super.dispose();
  }
}