import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_balance_model.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_fund_prize_pool_request.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_fund_prize_pool_result.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_history_response.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_link_wallet_request.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_link_wallet_result.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_network.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_prize_pool_model.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_stake_request.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_stake_result.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_staking_model.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_withdraw_request.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_withdraw_result.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/crypto/crypto_service.dart';
import 'package:trivia_tycoon/game/providers/crypto_providers.dart';
import 'package:trivia_tycoon/game/providers/profile_providers.dart';

void main() {
  group('crypto providers', () {
    test('link wallet invalidates balance, staking, and history providers',
        () async {
      final service = _FakeCryptoService();
      final container = ProviderContainer(
        overrides: [
          cryptoServiceProvider.overrideWithValue(service),
          currentUserIdProvider.overrideWith((ref) async => 'player-1'),
        ],
      );
      addTearDown(container.dispose);

      final firstBalance =
          await container.read(cryptoBalanceProvider('player-1').future);
      await container.read(cryptoStakingProvider('player-1').future);
      await container.read(currentUserCryptoHistoryProvider.future);

      expect(firstBalance.units, 100);
      expect(service.balanceCalls, 1);
      expect(service.stakingCalls, 1);
      expect(service.historyCalls, 1);

      await container.read(linkWalletProvider)(
            const CryptoLinkWalletRequest(
              playerId: 'player-1',
              walletAddress: '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
            ),
          );

      final refreshedBalance =
          await container.read(cryptoBalanceProvider('player-1').future);
      await container.read(cryptoStakingProvider('player-1').future);
      await container.read(currentUserCryptoHistoryProvider.future);

      expect(refreshedBalance.units, 200);
      expect(service.balanceCalls, 2);
      expect(service.stakingCalls, 2);
      expect(service.historyCalls, 2);
    });

    test('fund prize pool invalidates player crypto and prize pool providers',
        () async {
      final service = _FakeCryptoService();
      final container = ProviderContainer(
        overrides: [
          cryptoServiceProvider.overrideWithValue(service),
          currentUserIdProvider.overrideWith((ref) async => 'player-1'),
          currentCryptoPrizePoolIdProvider.overrideWith((ref) => 'global'),
        ],
      );
      addTearDown(container.dispose);

      final firstPool =
          await container.read(cryptoPrizePoolProvider('global').future);
      await container.read(cryptoBalanceProvider('player-1').future);

      expect(firstPool.units, 1000);
      expect(service.prizePoolCalls, 1);
      expect(service.balanceCalls, 1);

      await container.read(fundPrizePoolProvider)(
            const CryptoFundPrizePoolRequest(
              playerId: 'player-1',
              units: 50,
              poolId: 'global',
            ),
          );

      final refreshedPool =
          await container.read(cryptoPrizePoolProvider('global').future);
      final refreshedBalance =
          await container.read(cryptoBalanceProvider('player-1').future);

      expect(refreshedPool.units, 1050);
      expect(refreshedBalance.units, 200);
      expect(service.prizePoolCalls, 2);
      expect(service.balanceCalls, 2);
    });
  });
}

class _FakeCryptoService extends CryptoService {
  _FakeCryptoService()
      : super(
          apiService: ApiService(
            baseUrl: 'https://example.test',
            initializeCache: false,
          ),
        );

  int balanceCalls = 0;
  int stakingCalls = 0;
  int historyCalls = 0;
  int prizePoolCalls = 0;

  @override
  Future<CryptoBalanceModel> getBalance(String playerId) async {
    balanceCalls += 1;
    return CryptoBalanceModel(
      playerId: playerId,
      units: balanceCalls * 100,
      unitType: 'CRYPTO_UNITS',
    );
  }

  @override
  Future<CryptoHistoryResponse> getHistory(
    String playerId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    historyCalls += 1;
    return CryptoHistoryResponse(
      page: page,
      pageSize: pageSize,
      total: 0,
      items: const [],
    );
  }

  @override
  Future<CryptoStakingModel> getStakingPosition(String playerId) async {
    stakingCalls += 1;
    return CryptoStakingModel(
      playerId: playerId,
      availableUnits: 50,
      stakedUnits: stakingCalls * 10,
      unitType: 'CRYPTO_UNITS',
    );
  }

  @override
  Future<CryptoPrizePoolModel> getPrizePool(String poolId) async {
    prizePoolCalls += 1;
    return CryptoPrizePoolModel(
      poolId: poolId,
      units: 950 + (prizePoolCalls * 50),
      unitType: 'CRYPTO_UNITS',
    );
  }

  @override
  Future<CryptoLinkWalletResult> linkWallet(
    CryptoLinkWalletRequest request,
  ) async {
    return CryptoLinkWalletResult(
      playerId: request.playerId,
      walletAddress: request.walletAddress,
      network: CryptoNetwork.solana,
      transactionId: 'link-1',
      status: 'linked',
    );
  }

  @override
  Future<CryptoWithdrawResult> withdraw(CryptoWithdrawRequest request) async {
    return CryptoWithdrawResult(
      transactionId: 'withdraw-1',
      status: 'pending',
      units: request.units,
      network: request.network,
    );
  }

  @override
  Future<CryptoStakeResult> stake(CryptoStakeRequest request) async {
    return CryptoStakeResult(
      transactionId: 'stake-1',
      playerId: request.playerId,
      units: request.units,
      currentStakedUnits: request.units,
      status: 'staked',
    );
  }

  @override
  Future<CryptoStakeResult> unstake(CryptoStakeRequest request) async {
    return CryptoStakeResult(
      transactionId: 'unstake-1',
      playerId: request.playerId,
      units: request.units,
      currentStakedUnits: 0,
      status: 'unstaked',
    );
  }

  @override
  Future<CryptoFundPrizePoolResult> fundPrizePool(
    CryptoFundPrizePoolRequest request,
  ) async {
    return CryptoFundPrizePoolResult(
      transactionId: 'fund-1',
      poolId: request.poolId ?? 'global',
      unitsFunded: request.units,
      poolUnits: 1050,
      status: 'funded',
    );
  }
}
