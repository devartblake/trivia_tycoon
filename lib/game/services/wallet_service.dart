import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class WalletService {
  static const _boxName = 'wallet_data';

  int _coins = 0;
  int _gems = 0;

  int get coins => _coins;
  int get gems => _gems;

  /// Initialize the wallet from Hive-persisted data.
  Future<void> init() async {
    try {
      final box = await _getBox();
      _coins = box.get('coins', defaultValue: 0);
      _gems = box.get('gems', defaultValue: 0);
    } catch (e) {
      LogManager.debug('[WalletService] Init error: $e');
    }
  }

  Future<Box> _getBox() async {
    if (Hive.isBoxOpen(_boxName)) {
      return Hive.box(_boxName);
    }
    return await Hive.openBox(_boxName);
  }

  void addCoins(int amount) {
    if (amount <= 0) return;
    _coins += amount;
    _persist();
  }

  void addGems(int amount) {
    if (amount <= 0) return;
    _gems += amount;
    _persist();
  }

  Future<void> setBalances({
    required int coins,
    required int gems,
  }) async {
    _coins = coins < 0 ? 0 : coins;
    _gems = gems < 0 ? 0 : gems;
    await _persist();
  }

  bool spendCoins(int amount) {
    if (amount <= 0) return true;
    if (_coins < amount) return false;
    _coins -= amount;
    _persist();
    return true;
  }

  bool spendGems(int amount) {
    if (amount <= 0) return true;
    if (_gems < amount) return false;
    _gems -= amount;
    _persist();
    return true;
  }

  Future<void> _persist() async {
    try {
      final box = await _getBox();
      await box.put('coins', _coins);
      await box.put('gems', _gems);
    } catch (e) {
      LogManager.debug('[WalletService] Persist error: $e');
    }
  }
}
