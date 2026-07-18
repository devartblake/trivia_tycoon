import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:synaptix/core/services/settings/general_key_value_storage_service.dart';

class CoinBalanceNotifier extends StateNotifier<int> {
  static const _key = 'coinBalance';
  final GeneralKeyValueStorageService storage;

  /// Completes once the persisted balance has been loaded into [state].
  /// Callers (and tests) can await this before mutating to avoid the initial
  /// async load clobbering an early write.
  late final Future<void> initialized;

  CoinBalanceNotifier(this.storage) : super(0) {
    initialized = _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final stored = await storage.getInt(_key);
    state = stored;
  }

  Future<void> add(int amount) async {
    state += amount;
    await storage.setInt(_key, state);
  }

  Future<void> deduct(int amount) async {
    if (state >= amount) {
      state -= amount;
      await storage.setInt(_key, state);
    }
  }

  bool canAfford(int amount) => state >= amount;

  Future<void> set(int amount) async {
    state = amount;
    await storage.setInt(_key, state);
  }

  Future<void> reset() => set(0);
}
