import '../../models/crypto/crypto_api_error.dart';
import '../../models/crypto/crypto_balance_model.dart';
import '../../models/crypto/crypto_fund_prize_pool_request.dart';
import '../../models/crypto/crypto_fund_prize_pool_result.dart';
import '../../models/crypto/crypto_history_response.dart';
import '../../models/crypto/crypto_link_wallet_request.dart';
import '../../models/crypto/crypto_link_wallet_result.dart';
import '../../models/crypto/crypto_prize_pool_model.dart';
import '../../models/crypto/crypto_stake_request.dart';
import '../../models/crypto/crypto_stake_result.dart';
import '../../models/crypto/crypto_staking_model.dart';
import '../../models/crypto/crypto_withdraw_request.dart';
import '../../models/crypto/crypto_withdraw_result.dart';
import '../api_service.dart';

class CryptoService {
  const CryptoService({
    required this.apiService,
  });

  final ApiService apiService;

  Future<CryptoBalanceModel> getBalance(String playerId) async {
    try {
      final response = await apiService.get('/crypto/balance/$playerId');
      return CryptoBalanceModel.fromJson(response);
    } on ApiRequestException catch (error) {
      throw CryptoApiException.fromApiRequestException(error);
    }
  }

  Future<CryptoHistoryResponse> getHistory(
    String playerId, {
    int page = 1,
    int pageSize = 20,
  }) async {
    try {
      final response = await apiService.get(
        '/crypto/history/$playerId',
        queryParameters: {
          'page': page,
          'pageSize': pageSize,
        },
      );
      return CryptoHistoryResponse.fromJson(response);
    } on ApiRequestException catch (error) {
      throw CryptoApiException.fromApiRequestException(error);
    }
  }

  Future<CryptoLinkWalletResult> linkWallet(
    CryptoLinkWalletRequest request,
  ) async {
    try {
      final response = await apiService.post(
        '/crypto/link-wallet',
        body: request.toJson(),
      );
      return CryptoLinkWalletResult.fromJson(response);
    } on ApiRequestException catch (error) {
      throw CryptoApiException.fromApiRequestException(error);
    }
  }

  Future<CryptoWithdrawResult> withdraw(CryptoWithdrawRequest request) async {
    try {
      final response = await apiService.post(
        '/crypto/withdraw',
        body: request.toJson(),
      );
      return CryptoWithdrawResult.fromJson(response);
    } on ApiRequestException catch (error) {
      throw CryptoApiException.fromApiRequestException(error);
    }
  }

  Future<CryptoStakeResult> stake(CryptoStakeRequest request) async {
    return _submitStakeRequest('/crypto/stake', request);
  }

  Future<CryptoStakeResult> unstake(CryptoStakeRequest request) async {
    return _submitStakeRequest('/crypto/unstake', request);
  }

  Future<CryptoStakingModel> getStakingPosition(String playerId) async {
    try {
      final response = await apiService.get('/crypto/staking/$playerId');
      return CryptoStakingModel.fromJson(response);
    } on ApiRequestException catch (error) {
      throw CryptoApiException.fromApiRequestException(error);
    }
  }

  Future<CryptoFundPrizePoolResult> fundPrizePool(
    CryptoFundPrizePoolRequest request,
  ) async {
    try {
      final response = await apiService.post(
        '/crypto/prize-pool/fund',
        body: request.toJson(),
      );
      return CryptoFundPrizePoolResult.fromJson(response);
    } on ApiRequestException catch (error) {
      throw CryptoApiException.fromApiRequestException(error);
    }
  }

  Future<CryptoPrizePoolModel> getPrizePool(String poolId) async {
    try {
      final response = await apiService.get('/crypto/prize-pool/$poolId');
      return CryptoPrizePoolModel.fromJson(response);
    } on ApiRequestException catch (error) {
      throw CryptoApiException.fromApiRequestException(error);
    }
  }

  Future<CryptoStakeResult> _submitStakeRequest(
    String path,
    CryptoStakeRequest request,
  ) async {
    try {
      final response = await apiService.post(path, body: request.toJson());
      return CryptoStakeResult.fromJson(response);
    } on ApiRequestException catch (error) {
      throw CryptoApiException.fromApiRequestException(error);
    }
  }
}
