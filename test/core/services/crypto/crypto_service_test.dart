import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_api_error.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_fund_prize_pool_request.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_link_wallet_request.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_network.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_stake_request.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_transaction_kind.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_transaction_status.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_withdraw_request.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';
import 'package:trivia_tycoon/core/services/crypto/crypto_service.dart';

void main() {
  late Directory tempDir;
  late Box authBox;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('crypto_service_test');
    Hive.init(tempDir.path);
  });

  setUp(() async {
    authBox = await Hive.openBox('auth_tokens');
    await authBox.put('auth_access_token', 'crypto-token');
  });

  tearDown(() async {
    await authBox.clear();
    await authBox.close();
    await Hive.deleteBoxFromDisk('auth_tokens');
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  test('getBalance parses canonical unit response', () async {
    final service = _buildService((options, handler) {
      if (options.path == '/crypto/balance/player-1') {
        expect(options.headers['Authorization'], 'Bearer crypto-token');
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'playerId': 'player-1',
              'units': 1250,
              'unitType': 'CRYPTO_UNITS',
            },
          ),
        );
        return;
      }
      handler.next(options);
    });

    final balance = await service.getBalance('player-1');

    expect(balance.playerId, 'player-1');
    expect(balance.units, 1250);
    expect(balance.unitType, 'CRYPTO_UNITS');
  });

  test('getHistory parses paginated history items', () async {
    final service = _buildService((options, handler) {
      if (options.path == '/crypto/history/player-1') {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'page': 1,
              'pageSize': 20,
              'total': 2,
              'items': [
                {
                  'transactionId': 'tx-1',
                  'kind': 'crypto-withdraw-request',
                  'unitsDelta': -100,
                  'status': 'Pending',
                  'receiptRef': 'wallet-1',
                  'createdAtUtc': '2026-04-12T14:00:00Z',
                  'completedAtUtc': null,
                },
                {
                  'transactionId': 'tx-2',
                  'kind': 'crypto-prize-pool-payout',
                  'unitsDelta': 500,
                  'status': 'Applied',
                  'receiptRef': 'weekly-tournament',
                  'createdAtUtc': '2026-04-11T20:00:00Z',
                  'completedAtUtc': '2026-04-11T20:00:01Z',
                },
              ],
            },
          ),
        );
        return;
      }
      handler.next(options);
    });

    final history = await service.getHistory('player-1');

    expect(history.total, 2);
    expect(history.hasPendingItems, isTrue);
    expect(history.items.first.kind, CryptoTransactionKind.withdrawRequest);
    expect(history.items.first.status, CryptoTransactionStatus.pending);
    expect(history.items.last.kind, CryptoTransactionKind.prizePoolPayout);
  });

  test('linkWallet serializes request and parses response', () async {
    final service = _buildService((options, handler) {
      if (options.path == '/crypto/link-wallet') {
        expect(options.data['playerId'], 'player-1');
        expect(
          options.data['walletAddress'],
          '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
        );
        expect(options.data['network'], 'solana');
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'playerId': 'player-1',
              'walletAddress': '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
              'network': 'solana',
              'transactionId': 'tx-link',
              'status': 'Applied',
            },
          ),
        );
        return;
      }
      handler.next(options);
    });

    final result = await service.linkWallet(
      const CryptoLinkWalletRequest(
        playerId: 'player-1',
        walletAddress: '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
      ),
    );

    expect(result.transactionId, 'tx-link');
    expect(result.network, CryptoNetwork.solana);
  });

  test('withdraw maps backend error envelope to CryptoApiException', () async {
    final service = _buildService((options, handler) {
      if (options.path == '/crypto/withdraw') {
        handler.reject(
          DioException(
            requestOptions: options,
            response: Response(
              requestOptions: options,
              statusCode: 409,
              data: {
                'error': {
                  'code': 'INSUFFICIENT_CRYPTO_BALANCE',
                  'message': 'Insufficient crypto balance.',
                  'details': {
                    'availableUnits': 50,
                    'requestedUnits': 100,
                  },
                },
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        );
        return;
      }
      handler.next(options);
    });

    expect(
      () => service.withdraw(
        const CryptoWithdrawRequest(
          playerId: 'player-1',
          units: 100,
          toWalletAddress: '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
        ),
      ),
      throwsA(
        isA<CryptoApiException>()
            .having((e) => e.code, 'code', 'INSUFFICIENT_CRYPTO_BALANCE')
            .having((e) => e.statusCode, 'statusCode', 409)
            .having((e) => e.details['availableUnits'], 'availableUnits', 50),
      ),
    );
  });

  test('stake and unstake parse current staked units', () async {
    final service = _buildService((options, handler) {
      if (options.path == '/crypto/stake' ||
          options.path == '/crypto/unstake') {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'transactionId':
                  options.path == '/crypto/stake' ? 'stake-tx' : 'unstake-tx',
              'playerId': 'player-1',
              'units': 200,
              'currentStakedUnits': options.path == '/crypto/stake' ? 350 : 150,
              'status': 'Applied',
            },
          ),
        );
        return;
      }
      handler.next(options);
    });

    final stakeResult = await service.stake(
      const CryptoStakeRequest(playerId: 'player-1', units: 200),
    );
    final unstakeResult = await service.unstake(
      const CryptoStakeRequest(playerId: 'player-1', units: 200),
    );

    expect(stakeResult.currentStakedUnits, 350);
    expect(unstakeResult.currentStakedUnits, 150);
  });

  test('getStakingPosition and prize pool endpoints parse responses', () async {
    final service = _buildService((options, handler) {
      if (options.path == '/crypto/staking/player-1') {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'playerId': 'player-1',
              'availableUnits': 1050,
              'stakedUnits': 350,
              'unitType': 'CRYPTO_UNITS',
            },
          ),
        );
        return;
      }

      if (options.path == '/crypto/prize-pool/global') {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'poolId': 'global',
              'units': 1800,
              'unitType': 'CRYPTO_UNITS',
            },
          ),
        );
        return;
      }

      if (options.path == '/crypto/prize-pool/fund') {
        handler.resolve(
          Response(
            requestOptions: options,
            statusCode: 200,
            data: {
              'transactionId': 'fund-tx',
              'poolId': 'global',
              'unitsFunded': 50,
              'poolUnits': 1800,
              'status': 'Applied',
            },
          ),
        );
        return;
      }

      handler.next(options);
    });

    final staking = await service.getStakingPosition('player-1');
    final pool = await service.getPrizePool('global');
    final fundResult = await service.fundPrizePool(
      const CryptoFundPrizePoolRequest(
        playerId: 'player-1',
        units: 50,
      ),
    );

    expect(staking.availableUnits, 1050);
    expect(staking.stakedUnits, 350);
    expect(pool.units, 1800);
    expect(fundResult.unitsFunded, 50);
  });
}

CryptoService _buildService(
  void Function(RequestOptions options, RequestInterceptorHandler handler)
      onRequest,
) {
  final dio = Dio(BaseOptions(baseUrl: 'https://example.test'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: onRequest,
    ),
  );

  return CryptoService(
    apiService: ApiService(
      baseUrl: 'https://example.test',
      dio: dio,
      initializeCache: false,
    ),
  );
}
