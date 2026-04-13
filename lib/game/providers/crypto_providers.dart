library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/crypto/crypto_balance_model.dart';
import '../../core/models/crypto/crypto_fund_prize_pool_request.dart';
import '../../core/models/crypto/crypto_fund_prize_pool_result.dart';
import '../../core/models/crypto/crypto_history_response.dart';
import '../../core/models/crypto/crypto_link_wallet_request.dart';
import '../../core/models/crypto/crypto_link_wallet_result.dart';
import '../../core/models/crypto/crypto_prize_pool_model.dart';
import '../../core/models/crypto/crypto_stake_request.dart';
import '../../core/models/crypto/crypto_stake_result.dart';
import '../../core/models/crypto/crypto_staking_model.dart';
import '../../core/models/crypto/crypto_withdraw_request.dart';
import '../../core/models/crypto/crypto_withdraw_result.dart';
import '../../core/services/crypto/crypto_service.dart';
import 'core_providers.dart';
import 'profile_providers.dart';

class CryptoHistoryQuery {
  const CryptoHistoryQuery({
    this.page = 1,
    this.pageSize = 20,
  });

  final int page;
  final int pageSize;

  CryptoHistoryQuery copyWith({
    int? page,
    int? pageSize,
  }) {
    return CryptoHistoryQuery(
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is CryptoHistoryQuery &&
        other.page == page &&
        other.pageSize == pageSize;
  }

  @override
  int get hashCode => Object.hash(page, pageSize);
}

final cryptoServiceProvider = Provider<CryptoService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return CryptoService(apiService: apiService);
});

final currentUserCryptoHistoryQueryProvider =
    StateProvider<CryptoHistoryQuery>((ref) {
  return const CryptoHistoryQuery();
});

final currentCryptoPrizePoolIdProvider = StateProvider<String>((ref) {
  return 'global';
});

final cryptoBalanceProvider =
    FutureProvider.family<CryptoBalanceModel, String>((ref, playerId) async {
  final service = ref.watch(cryptoServiceProvider);
  return service.getBalance(playerId);
});

final currentUserCryptoBalanceProvider =
    FutureProvider<CryptoBalanceModel>((ref) async {
  final playerId = await ref.watch(currentUserIdProvider.future);
  return ref.watch(cryptoServiceProvider).getBalance(playerId);
});

final cryptoStakingProvider =
    FutureProvider.family<CryptoStakingModel, String>((ref, playerId) async {
  final service = ref.watch(cryptoServiceProvider);
  return service.getStakingPosition(playerId);
});

final currentUserCryptoStakingProvider =
    FutureProvider<CryptoStakingModel>((ref) async {
  final playerId = await ref.watch(currentUserIdProvider.future);
  return ref.watch(cryptoServiceProvider).getStakingPosition(playerId);
});

final currentUserCryptoHistoryProvider =
    FutureProvider<CryptoHistoryResponse>((ref) async {
  final playerId = await ref.watch(currentUserIdProvider.future);
  final query = ref.watch(currentUserCryptoHistoryQueryProvider);
  return ref.watch(cryptoServiceProvider).getHistory(
        playerId,
        page: query.page,
        pageSize: query.pageSize,
      );
});

final cryptoHistoryProvider =
    FutureProvider.family<CryptoHistoryResponse, ({String playerId, CryptoHistoryQuery query})>(
  (ref, args) async {
    final service = ref.watch(cryptoServiceProvider);
    return service.getHistory(
      args.playerId,
      page: args.query.page,
      pageSize: args.query.pageSize,
    );
  },
);

final cryptoPrizePoolProvider =
    FutureProvider.family<CryptoPrizePoolModel, String>((ref, poolId) async {
  final service = ref.watch(cryptoServiceProvider);
  return service.getPrizePool(poolId);
});

final currentCryptoPrizePoolProvider =
    FutureProvider<CryptoPrizePoolModel>((ref) async {
  final poolId = ref.watch(currentCryptoPrizePoolIdProvider);
  return ref.watch(cryptoServiceProvider).getPrizePool(poolId);
});

final linkWalletProvider =
    Provider<Future<CryptoLinkWalletResult> Function(CryptoLinkWalletRequest)>(
  (ref) {
    return (request) async {
      final result = await ref.read(cryptoServiceProvider).linkWallet(request);
      _invalidatePlayerCryptoProviders(ref, request.playerId);
      return result;
    };
  },
);

final withdrawCryptoProvider =
    Provider<Future<CryptoWithdrawResult> Function(CryptoWithdrawRequest)>(
  (ref) {
    return (request) async {
      final result = await ref.read(cryptoServiceProvider).withdraw(request);
      _invalidatePlayerCryptoProviders(ref, request.playerId);
      return result;
    };
  },
);

final stakeCryptoProvider =
    Provider<Future<CryptoStakeResult> Function(CryptoStakeRequest)>((ref) {
  return (request) async {
    final result = await ref.read(cryptoServiceProvider).stake(request);
    _invalidatePlayerCryptoProviders(ref, request.playerId);
    return result;
  };
});

final unstakeCryptoProvider =
    Provider<Future<CryptoStakeResult> Function(CryptoStakeRequest)>((ref) {
  return (request) async {
    final result = await ref.read(cryptoServiceProvider).unstake(request);
    _invalidatePlayerCryptoProviders(ref, request.playerId);
    return result;
  };
});

final fundPrizePoolProvider = Provider<
    Future<CryptoFundPrizePoolResult> Function(CryptoFundPrizePoolRequest)>(
  (ref) {
    return (request) async {
      final result = await ref.read(cryptoServiceProvider).fundPrizePool(request);
      _invalidatePlayerCryptoProviders(ref, request.playerId);
      final poolId = request.poolId == null || request.poolId!.isEmpty
          ? 'global'
          : request.poolId!;
      ref.invalidate(cryptoPrizePoolProvider(poolId));
      ref.invalidate(currentCryptoPrizePoolProvider);
      return result;
    };
  },
);

void _invalidatePlayerCryptoProviders(Ref ref, String playerId) {
  ref.invalidate(cryptoBalanceProvider(playerId));
  ref.invalidate(cryptoStakingProvider(playerId));
  ref.invalidate(currentUserCryptoBalanceProvider);
  ref.invalidate(currentUserCryptoStakingProvider);
  ref.invalidate(currentUserCryptoHistoryProvider);
}
