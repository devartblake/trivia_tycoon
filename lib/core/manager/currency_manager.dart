import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../game/models/currency_type.dart';
import '../../game/utils/balance_change_effect.dart';

final currencyManagerProvider = Provider<CurrencyManager>((ref) {
  return CurrencyManager(ref);
});

class CurrencyManager {
  final Ref ref;

  // Enhanced state tracking
  DateTime? _lastSaveTime;
  Map<String, int> _transactionHistory = {};
  bool _isPaused = false;

  CurrencyManager(this.ref) {
    _loadCurrencyState();
  }

  /// Load saved currency state
  Future<void> _loadCurrencyState() async {
    try {
      final historyStr = await AppSettings.getString('transaction_history');
      if (historyStr != null && historyStr.isNotEmpty) { // Check for null first
        // Parse the string safely - you may need to adjust this parsing logic
        // depending on how you're storing the transaction history
        try {
          // If stored as JSON string
          _transactionHistory = Map<String, int>.from(json.decode(historyStr));
        } catch (parseError) {
          debugPrint('Failed to parse transaction history: $parseError');
          _transactionHistory = {};
        }
      }

      final lastSaveStr = await AppSettings.getString('currency_last_save');
      if (lastSaveStr != null && lastSaveStr.isNotEmpty) { // Check for null first
        _lastSaveTime = DateTime.parse(lastSaveStr);
      }
    } catch (e) {
      debugPrint('Failed to load currency state: $e');
      // Initialize with defaults on error
      _transactionHistory = {};
      _lastSaveTime = null;
    }
  }

  StateNotifierProvider<CurrencyNotifier, int> getProvider(CurrencyType type) {
    switch (type) {
      case CurrencyType.coins:
        return _coinProvider;
      case CurrencyType.diamonds:
        return _diamondProvider;
    }
  }

  int getBalance(CurrencyType type) => ref.watch(getProvider(type));
  CurrencyNotifier getNotifier(CurrencyType type) =>
      ref.read(getProvider(type).notifier);

  Future<void> transfer(CurrencyType from, CurrencyType to, int amount) async {
    if (_isPaused) return;

    final fromNotifier = getNotifier(from);
    final toNotifier = getNotifier(to);
    if (fromNotifier.canAfford(amount)) {
      await fromNotifier.deduct(amount);
      await toNotifier.addValue(amount);

      // Track transaction
      await _recordTransaction('transfer_${from.name}_to_${to.name}', amount);
    }
  }

  Future<void> earnFromAction(
      String actionId, {
        required CurrencyType type,
        int amount = 100,
      }) async {
    if (_isPaused) return;

    final notifier = getNotifier(type);
    await notifier.addValue(amount);
    BalanceChangeEffect.trigger(type); // Optional visual/sound effect

    // Track earning
    await _recordTransaction('earn_${actionId}_${type.name}', amount);
  }

  /// Record transaction for statistics
  Future<void> _recordTransaction(String transactionType, int amount) async {
    try {
      _transactionHistory[transactionType] = (_transactionHistory[transactionType] ?? 0) + amount;
      await AppSettings.setString('transaction_history', _transactionHistory.toString());
    } catch (e) {
      debugPrint('Failed to record transaction: $e');
    }
  }

  /// LIFECYCLE METHOD: Save currency state when app backgrounded
  /// Called by AppLifecycleObserver when app goes to background
  Future<void> saveCurrencyState() async {
    try {
      // Force save all currency notifiers
      await ref.read(_coinProvider.notifier).forceSave();
      await ref.read(_diamondProvider.notifier).forceSave();

      // Save transaction history
      await AppSettings.setString('transaction_history', _transactionHistory.toString());
      await AppSettings.setString('currency_last_save', DateTime.now().toIso8601String());

      // Create state snapshot
      final stateSnapshot = {
        'coinBalance': getBalance(CurrencyType.coins),
        'diamondBalance': getBalance(CurrencyType.diamonds),
        'transactionHistory': _transactionHistory,
        'timestamp': DateTime.now().toIso8601String(),
      };

      await AppSettings.setString('currency_state_snapshot', stateSnapshot.toString());
      _lastSaveTime = DateTime.now();

      debugPrint('Currency state saved successfully');
    } catch (e) {
      debugPrint('Failed to save currency state: $e');
    }
  }

  /// LIFECYCLE METHOD: Validate currency state when app resumes
  /// Called by AppLifecycleObserver when app resumes from background
  Future<void> validateCurrencyState() async {
    try {
      // Validate currency balances
      await _validateCurrencyIntegrity();

      // Resume normal operations
      _isPaused = false;

      debugPrint('Currency state validation completed');
    } catch (e) {
      debugPrint('Currency state validation failed: $e');
      await _resetCurrencyState();
    }
  }

  /// Validate currency integrity
  Future<void> _validateCurrencyIntegrity() async {
    try {
      bool needsRepair = false;

      // Validate coin balance
      final coinBalance = getBalance(CurrencyType.coins);
      if (coinBalance < 0) {
        await getNotifier(CurrencyType.coins).set(0);
        needsRepair = true;
      }

      // Validate diamond balance
      final diamondBalance = getBalance(CurrencyType.diamonds);
      if (diamondBalance < 0) {
        await getNotifier(CurrencyType.diamonds).set(0);
        needsRepair = true;
      }

      // Clean invalid transaction history
      _transactionHistory.removeWhere((key, value) => value < 0);

      if (needsRepair) {
        await AppSettings.setString('transaction_history', _transactionHistory.toString());
        debugPrint('Currency integrity restored');
      }
    } catch (e) {
      debugPrint('Failed to validate currency integrity: $e');
    }
  }

  /// Reset currency state
  Future<void> _resetCurrencyState() async {
    try {
      await getNotifier(CurrencyType.coins).reset();
      await getNotifier(CurrencyType.diamonds).reset();
      _transactionHistory.clear();
      _lastSaveTime = null;

      await AppSettings.setString('transaction_history', '');
      await AppSettings.setString('currency_last_save', '');

      debugPrint('Currency state reset to defaults');
    } catch (e) {
      debugPrint('Failed to reset currency state: $e');
    }
  }

  /// Pause currency operations
  void pauseCurrency() {
    _isPaused = true;
  }

  /// Resume currency operations
  void resumeCurrency() {
    _isPaused = false;
  }

  /// Get currency statistics
  Map<String, dynamic> getCurrencyStats() {
    return {
      'coinBalance': getBalance(CurrencyType.coins),
      'diamondBalance': getBalance(CurrencyType.diamonds),
      'transactionHistory': _transactionHistory,
      'isPaused': _isPaused,
      'lastSave': _lastSaveTime?.toIso8601String(),
    };
  }

  /// Export currency data for backup
  Map<String, dynamic> exportCurrencyData() {
    return {
      'coinBalance': getBalance(CurrencyType.coins),
      'diamondBalance': getBalance(CurrencyType.diamonds),
      'transactionHistory': _transactionHistory,
      'exported': DateTime.now().toIso8601String(),
    };
  }

  /// Import currency data from backup
  Future<void> importCurrencyData(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('coinBalance')) {
        await getNotifier(CurrencyType.coins).set(data['coinBalance']);
      }

      if (data.containsKey('diamondBalance')) {
        await getNotifier(CurrencyType.diamonds).set(data['diamondBalance']);
      }

      if (data.containsKey('transactionHistory')) {
        _transactionHistory = Map<String, int>.from(data['transactionHistory']);
        await AppSettings.setString('transaction_history', _transactionHistory.toString());
      }

      debugPrint('Currency data imported successfully');
    } catch (e) {
      debugPrint('Failed to import currency data: $e');
      rethrow;
    }
  }
}

final _coinProvider = StateNotifierProvider<CurrencyNotifier, int>((ref) {
  return CurrencyNotifier('coinBalance');
});

final _diamondProvider = StateNotifierProvider<CurrencyNotifier, int>((ref) {
  return CurrencyNotifier('diamondBalance');
});

class CurrencyNotifier extends StateNotifier<int> {
  final String hiveKey;

  CurrencyNotifier(this.hiveKey) : super(0) {
    _loadFromHive();
  }

  Future<void> _loadFromHive() async {
    final stored = await AppSettings.getInt(hiveKey) ?? 0;
    state = stored;
  }

  Future<void> addValue(int amount) async {
    state += amount;
    await AppSettings.setInt(hiveKey, state);
  }

  Future<void> deduct(int amount) async {
    state -= amount;
    await AppSettings.setInt(hiveKey, state);
  }

  Future<void> set(int value) async {
    state = value;
    await AppSettings.setInt(hiveKey, state);
  }

  bool canAfford(int amount) => state >= amount;

  Future<void> reset() async {
    state = 0;
    await AppSettings.setInt(hiveKey, state);
  }

  /// Force save current state (for lifecycle management)
  Future<void> forceSave() async {
    await AppSettings.setInt(hiveKey, state);
  }
}
