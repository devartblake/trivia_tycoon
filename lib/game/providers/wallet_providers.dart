import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/wallet_service.dart';

final walletServiceProvider = Provider<WalletService>((ref) => WalletService());

final playerCoinsProvider = StateProvider<int>((ref) {
  final wallet = ref.read(walletServiceProvider);
  return wallet.coins;
});

final playerGemsProvider = StateProvider<int>((ref) {
  final wallet = ref.read(walletServiceProvider);
  return wallet.gems;
});

void incrementCoins(WidgetRef ref, int amount) {
  final wallet = ref.read(walletServiceProvider);
  wallet.addCoins(amount);
  ref.read(playerCoinsProvider.notifier).state = wallet.coins;
}

void incrementGems(WidgetRef ref, int amount) {
  final wallet = ref.read(walletServiceProvider);
  wallet.addGems(amount);
  ref.read(playerGemsProvider.notifier).state = wallet.gems;
}
