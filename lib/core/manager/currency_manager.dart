import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../game/models/currency_type.dart';
import '../../game/utils/balance_change_effect.dart';

final currencyManagerProvider = Provider<CurrencyManager>((ref) {
  return CurrencyManager(ref);
});

class CurrencyManager {
  final Ref ref;

  CurrencyManager(this.ref);

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
    final fromNotifier = getNotifier(from);
    final toNotifier = getNotifier(to);
    if (fromNotifier.canAfford(amount)) {
      await fromNotifier.deduct(amount);
      await toNotifier.add(amount);
    }
  }

  Future<void> earnFromAction(
    String actionId, {
    required CurrencyType type,
    int amount = 100,
  }) async {
    final notifier = getNotifier(type);
    await notifier.add(amount);
    BalanceChangeEffect.trigger(type); // Optional visual/sound effect
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

  Future<void> add(int amount) async {
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
}
