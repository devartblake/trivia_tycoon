import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_api_error.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_balance_model.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_fund_prize_pool_request.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_fund_prize_pool_result.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_history_item.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_history_response.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_link_wallet_request.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_link_wallet_result.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_network.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_prize_pool_model.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_stake_request.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_stake_result.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_staking_model.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_transaction_kind.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_transaction_status.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_withdraw_request.dart';
import 'package:trivia_tycoon/core/models/crypto/crypto_withdraw_result.dart';
import 'package:trivia_tycoon/core/services/api_service.dart';

void main() {
  // -------------------------------------------------------------------------
  // CryptoTransactionKind enum
  // -------------------------------------------------------------------------

  group('CryptoTransactionKind', () {
    test('has 7 values', () {
      expect(CryptoTransactionKind.values.length, 7);
    });

    test('fromApiValue returns correct kind for each api value', () {
      expect(CryptoTransactionKind.fromApiValue('crypto-wallet-link'),
          CryptoTransactionKind.walletLink);
      expect(CryptoTransactionKind.fromApiValue('crypto-withdraw-request'),
          CryptoTransactionKind.withdrawRequest);
      expect(CryptoTransactionKind.fromApiValue('crypto-stake-lock'),
          CryptoTransactionKind.stakeLock);
      expect(CryptoTransactionKind.fromApiValue('crypto-stake-unlock'),
          CryptoTransactionKind.stakeUnlock);
      expect(CryptoTransactionKind.fromApiValue('crypto-prize-pool-fund'),
          CryptoTransactionKind.prizePoolFund);
      expect(CryptoTransactionKind.fromApiValue('crypto-prize-pool-payout'),
          CryptoTransactionKind.prizePoolPayout);
    });

    test('fromApiValue returns unknown for unrecognized value', () {
      expect(CryptoTransactionKind.fromApiValue('garbage'),
          CryptoTransactionKind.unknown);
    });

    test('fromApiValue returns unknown for null', () {
      expect(CryptoTransactionKind.fromApiValue(null),
          CryptoTransactionKind.unknown);
    });

    test('fromApiValue returns unknown for empty string', () {
      expect(CryptoTransactionKind.fromApiValue(''),
          CryptoTransactionKind.unknown);
    });

    test('fromApiValue is case-insensitive', () {
      expect(CryptoTransactionKind.fromApiValue('CRYPTO-WALLET-LINK'),
          CryptoTransactionKind.walletLink);
    });

    test('all values have non-empty displayLabel', () {
      for (final k in CryptoTransactionKind.values) {
        expect(k.displayLabel.isNotEmpty, isTrue,
            reason: '${k.name} has empty displayLabel');
      }
    });

    test('all values have a direction', () {
      expect(CryptoTransactionKind.walletLink.direction,
          CryptoTransactionDirection.neutral);
      expect(CryptoTransactionKind.withdrawRequest.direction,
          CryptoTransactionDirection.negative);
      expect(CryptoTransactionKind.stakeUnlock.direction,
          CryptoTransactionDirection.positive);
    });
  });

  // -------------------------------------------------------------------------
  // CryptoTransactionDirection enum
  // -------------------------------------------------------------------------

  group('CryptoTransactionDirection', () {
    test('has 3 values', () {
      expect(CryptoTransactionDirection.values.length, 3);
    });

    test('contains positive, negative, neutral', () {
      expect(
          CryptoTransactionDirection.values,
          containsAll([
            CryptoTransactionDirection.positive,
            CryptoTransactionDirection.negative,
            CryptoTransactionDirection.neutral,
          ]));
    });
  });

  // -------------------------------------------------------------------------
  // CryptoNetwork enum
  // -------------------------------------------------------------------------

  group('CryptoNetwork', () {
    test('has 4 values', () {
      expect(CryptoNetwork.values.length, 4);
    });

    test('fromKey returns correct network for known key', () {
      expect(CryptoNetwork.fromKey('solana'), CryptoNetwork.solana);
      expect(CryptoNetwork.fromKey('xrp'), CryptoNetwork.xrp);
      expect(CryptoNetwork.fromKey('snx'), CryptoNetwork.snx);
      expect(CryptoNetwork.fromKey('shib'), CryptoNetwork.shib);
    });

    test('fromKey defaults to solana for unknown key', () {
      expect(CryptoNetwork.fromKey('unknown'), CryptoNetwork.solana);
    });

    test('tryParse returns null for null input', () {
      expect(CryptoNetwork.tryParse(null), isNull);
    });

    test('tryParse returns null for empty string', () {
      expect(CryptoNetwork.tryParse(''), isNull);
    });

    test('tryParse returns null for unknown key', () {
      expect(CryptoNetwork.tryParse('bitcoin'), isNull);
    });

    test('tryParse returns correct network for known key', () {
      expect(CryptoNetwork.tryParse('xrp'), CryptoNetwork.xrp);
    });

    test('tryParse is case-insensitive', () {
      expect(CryptoNetwork.tryParse('SOLANA'), CryptoNetwork.solana);
    });

    test('isPhaseOne is true for solana and xrp', () {
      expect(CryptoNetwork.solana.isPhaseOne, isTrue);
      expect(CryptoNetwork.xrp.isPhaseOne, isTrue);
    });

    test('isPhaseOne is false for snx and shib', () {
      expect(CryptoNetwork.snx.isPhaseOne, isFalse);
      expect(CryptoNetwork.shib.isPhaseOne, isFalse);
    });

    test('phaseOneNetworks returns exactly 2 networks', () {
      expect(CryptoNetwork.phaseOneNetworks().length, 2);
    });

    test('phaseOneNetworks contains solana and xrp', () {
      final networks = CryptoNetwork.phaseOneNetworks();
      expect(networks, containsAll([CryptoNetwork.solana, CryptoNetwork.xrp]));
    });

    test('all values have non-empty symbol', () {
      for (final n in CryptoNetwork.values) {
        expect(n.symbol.isNotEmpty, isTrue);
      }
    });

    test('all values have non-empty displayName', () {
      for (final n in CryptoNetwork.values) {
        expect(n.displayName.isNotEmpty, isTrue);
      }
    });
  });

  // -------------------------------------------------------------------------
  // CryptoTransactionStatus enum
  // -------------------------------------------------------------------------

  group('CryptoTransactionStatus', () {
    test('has 5 values', () {
      expect(CryptoTransactionStatus.values.length, 5);
    });

    test('fromApiValue returns correct status', () {
      expect(CryptoTransactionStatus.fromApiValue('Pending'),
          CryptoTransactionStatus.pending);
      expect(CryptoTransactionStatus.fromApiValue('Applied'),
          CryptoTransactionStatus.applied);
      expect(CryptoTransactionStatus.fromApiValue('Failed'),
          CryptoTransactionStatus.failed);
      expect(CryptoTransactionStatus.fromApiValue('Reversed'),
          CryptoTransactionStatus.reversed);
    });

    test('fromApiValue returns unknown for unrecognized value', () {
      expect(CryptoTransactionStatus.fromApiValue('garbage'),
          CryptoTransactionStatus.unknown);
    });

    test('fromApiValue returns unknown for null', () {
      expect(CryptoTransactionStatus.fromApiValue(null),
          CryptoTransactionStatus.unknown);
    });

    test('fromApiValue is case-insensitive', () {
      expect(CryptoTransactionStatus.fromApiValue('pending'),
          CryptoTransactionStatus.pending);
    });

    test('isPending is true for pending status', () {
      expect(CryptoTransactionStatus.pending.isPending, isTrue);
    });

    test('isPending is false for non-pending statuses', () {
      expect(CryptoTransactionStatus.applied.isPending, isFalse);
      expect(CryptoTransactionStatus.failed.isPending, isFalse);
      expect(CryptoTransactionStatus.unknown.isPending, isFalse);
    });

    test('all values have non-empty displayLabel', () {
      for (final s in CryptoTransactionStatus.values) {
        expect(s.displayLabel.isNotEmpty, isTrue);
      }
    });
  });

  // -------------------------------------------------------------------------
  // CryptoHistoryItem
  // -------------------------------------------------------------------------

  group('CryptoHistoryItem', () {
    test('fromJson parses required fields', () {
      final item = CryptoHistoryItem.fromJson({
        'transactionId': 'tx-1',
        'kind': 'crypto-stake-lock',
        'unitsDelta': -100,
        'status': 'Applied',
      });
      expect(item.transactionId, 'tx-1');
      expect(item.kind, CryptoTransactionKind.stakeLock);
      expect(item.unitsDelta, -100);
      expect(item.status, CryptoTransactionStatus.applied);
    });

    test('fromJson uses defaults for missing optional fields', () {
      final item = CryptoHistoryItem.fromJson({
        'transactionId': 'tx-2',
        'kind': 'unknown',
        'unitsDelta': 0,
        'status': 'Unknown',
      });
      expect(item.receiptRef, isNull);
      expect(item.createdAtUtc, isNull);
      expect(item.completedAtUtc, isNull);
    });

    test('fromJson parses dates correctly', () {
      final item = CryptoHistoryItem.fromJson({
        'transactionId': 'tx-3',
        'kind': 'unknown',
        'unitsDelta': 0,
        'status': 'Applied',
        'createdAtUtc': '2026-01-01T00:00:00.000Z',
        'completedAtUtc': '2026-01-02T00:00:00.000Z',
      });
      expect(item.createdAtUtc, isNotNull);
      expect(item.completedAtUtc, isNotNull);
    });

    test('toJson round-trip preserves transactionId', () {
      final item = CryptoHistoryItem.fromJson({
        'transactionId': 'round-trip',
        'kind': 'crypto-wallet-link',
        'unitsDelta': 50,
        'status': 'Pending',
      });
      final json = item.toJson();
      final restored = CryptoHistoryItem.fromJson(json);
      expect(restored.transactionId, 'round-trip');
      expect(restored.kind, CryptoTransactionKind.walletLink);
      expect(restored.unitsDelta, 50);
      expect(restored.status, CryptoTransactionStatus.pending);
    });

    test('isPending delegates to status.isPending', () {
      final pending = CryptoHistoryItem.fromJson({
        'transactionId': 'p',
        'kind': 'unknown',
        'unitsDelta': 0,
        'status': 'Pending',
      });
      final applied = CryptoHistoryItem.fromJson({
        'transactionId': 'a',
        'kind': 'unknown',
        'unitsDelta': 0,
        'status': 'Applied',
      });
      expect(pending.isPending, isTrue);
      expect(applied.isPending, isFalse);
    });
  });

  // -------------------------------------------------------------------------
  // CryptoHistoryResponse
  // -------------------------------------------------------------------------

  group('CryptoHistoryResponse', () {
    test('fromJson parses page/pageSize/total', () {
      final r = CryptoHistoryResponse.fromJson({
        'page': 2,
        'pageSize': 10,
        'total': 25,
        'items': [],
      });
      expect(r.page, 2);
      expect(r.pageSize, 10);
      expect(r.total, 25);
    });

    test('fromJson uses defaults for missing fields', () {
      final r = CryptoHistoryResponse.fromJson({'items': []});
      expect(r.page, 1);
      expect(r.items, isEmpty);
    });

    test('totalPages: ceil(total / pageSize)', () {
      final r = CryptoHistoryResponse.fromJson({
        'page': 1,
        'pageSize': 10,
        'total': 25,
        'items': [],
      });
      expect(r.totalPages, 3);
    });

    test('totalPages is 1 when pageSize is 0', () {
      const r =
          CryptoHistoryResponse(page: 1, pageSize: 0, total: 5, items: []);
      expect(r.totalPages, 1);
    });

    test('hasPendingItems is false when all items applied', () {
      final r = CryptoHistoryResponse.fromJson({
        'page': 1,
        'pageSize': 1,
        'total': 1,
        'items': [
          {
            'transactionId': 'x',
            'kind': 'unknown',
            'unitsDelta': 0,
            'status': 'Applied'
          }
        ],
      });
      expect(r.hasPendingItems, isFalse);
    });

    test('hasPendingItems is true when any item is pending', () {
      final r = CryptoHistoryResponse.fromJson({
        'page': 1,
        'pageSize': 2,
        'total': 2,
        'items': [
          {
            'transactionId': 'x',
            'kind': 'unknown',
            'unitsDelta': 0,
            'status': 'Applied'
          },
          {
            'transactionId': 'y',
            'kind': 'unknown',
            'unitsDelta': 0,
            'status': 'Pending'
          },
        ],
      });
      expect(r.hasPendingItems, isTrue);
    });

    test('toJson round-trip preserves page and total', () {
      const r =
          CryptoHistoryResponse(page: 3, pageSize: 5, total: 15, items: []);
      final json = r.toJson();
      final restored = CryptoHistoryResponse.fromJson(json);
      expect(restored.page, 3);
      expect(restored.total, 15);
    });
  });

  // -------------------------------------------------------------------------
  // CryptoBalanceModel
  // -------------------------------------------------------------------------

  group('CryptoBalanceModel', () {
    test('fromJson parses all fields', () {
      final m = CryptoBalanceModel.fromJson({
        'playerId': 'player-1',
        'units': 500,
        'unitType': 'GOLD',
      });
      expect(m.playerId, 'player-1');
      expect(m.units, 500);
      expect(m.unitType, 'GOLD');
    });

    test('fromJson uses defaults for missing fields', () {
      final m = CryptoBalanceModel.fromJson({});
      expect(m.playerId, '');
      expect(m.units, 0);
      expect(m.unitType, 'CRYPTO_UNITS');
    });

    test('toJson round-trip preserves all fields', () {
      const m = CryptoBalanceModel(
          playerId: 'p', units: 100, unitType: 'CRYPTO_UNITS');
      final json = m.toJson();
      final restored = CryptoBalanceModel.fromJson(json);
      expect(restored.playerId, 'p');
      expect(restored.units, 100);
      expect(restored.unitType, 'CRYPTO_UNITS');
    });
  });

  // -------------------------------------------------------------------------
  // CryptoApiException
  // -------------------------------------------------------------------------

  group('CryptoApiException', () {
    test('holds code and message', () {
      const ex =
          CryptoApiException(code: 'CRYPTO_DISABLED', message: 'disabled');
      expect(ex.code, 'CRYPTO_DISABLED');
      expect(ex.message, 'disabled');
    });

    test('statusCode is null by default', () {
      const ex = CryptoApiException(code: 'ERR', message: 'msg');
      expect(ex.statusCode, isNull);
    });

    test('details defaults to empty map', () {
      const ex = CryptoApiException(code: 'ERR', message: 'msg');
      expect(ex.details, isEmpty);
    });

    test('isCryptoDisabled is true for CRYPTO_DISABLED code', () {
      const ex = CryptoApiException(code: 'CRYPTO_DISABLED', message: '');
      expect(ex.isCryptoDisabled, isTrue);
    });

    test('isValidationError is true for VALIDATION_ERROR code', () {
      const ex = CryptoApiException(code: 'VALIDATION_ERROR', message: '');
      expect(ex.isValidationError, isTrue);
    });

    test('isMinWithdrawal is true for MIN_WITHDRAWAL code', () {
      const ex = CryptoApiException(code: 'MIN_WITHDRAWAL', message: '');
      expect(ex.isMinWithdrawal, isTrue);
    });

    test('isWalletNotLinked is true for WALLET_NOT_LINKED code', () {
      const ex = CryptoApiException(code: 'WALLET_NOT_LINKED', message: '');
      expect(ex.isWalletNotLinked, isTrue);
    });

    test('isInsufficientBalance is true for INSUFFICIENT_CRYPTO_BALANCE code',
        () {
      const ex =
          CryptoApiException(code: 'INSUFFICIENT_CRYPTO_BALANCE', message: '');
      expect(ex.isInsufficientBalance, isTrue);
    });

    test(
        'isInsufficientStakedBalance is true for INSUFFICIENT_STAKED_BALANCE code',
        () {
      const ex =
          CryptoApiException(code: 'INSUFFICIENT_STAKED_BALANCE', message: '');
      expect(ex.isInsufficientStakedBalance, isTrue);
    });

    test('getters are false for unrelated code', () {
      const ex = CryptoApiException(code: 'OTHER', message: '');
      expect(ex.isCryptoDisabled, isFalse);
      expect(ex.isValidationError, isFalse);
      expect(ex.isMinWithdrawal, isFalse);
      expect(ex.isWalletNotLinked, isFalse);
    });

    test('toString includes code and message', () {
      const ex =
          CryptoApiException(code: 'ERR_CODE', message: 'bad thing happened');
      final str = ex.toString();
      expect(str, contains('ERR_CODE'));
      expect(str, contains('bad thing happened'));
    });

    test('toString includes statusCode when provided', () {
      const ex =
          CryptoApiException(code: 'ERR', message: 'msg', statusCode: 400);
      expect(ex.toString(), contains('400'));
    });

    test('fromApiRequestException maps fields correctly', () {
      final apiEx = ApiRequestException(
        'API failed',
        statusCode: 404,
        errorCode: 'WALLET_NOT_LINKED',
      );
      final cryptoEx = CryptoApiException.fromApiRequestException(apiEx);
      expect(cryptoEx.code, 'WALLET_NOT_LINKED');
      expect(cryptoEx.message, 'API failed');
      expect(cryptoEx.statusCode, 404);
    });

    test('fromApiRequestException uses default code when errorCode is null',
        () {
      final apiEx = ApiRequestException('fail', statusCode: 500);
      final cryptoEx = CryptoApiException.fromApiRequestException(apiEx);
      expect(cryptoEx.code, 'CRYPTO_REQUEST_FAILED');
    });
  });

  // -------------------------------------------------------------------------
  // CryptoLinkWalletRequest
  // -------------------------------------------------------------------------

  group('CryptoLinkWalletRequest', () {
    test('toJson includes all required fields', () {
      const req = CryptoLinkWalletRequest(
          playerId: 'p1',
          walletAddress: 'wallet-addr',
          network: CryptoNetwork.xrp);
      final json = req.toJson();
      expect(json['playerId'], 'p1');
      expect(json['walletAddress'], 'wallet-addr');
      expect(json['network'], 'xrp');
    });

    test('default network is solana', () {
      const req =
          CryptoLinkWalletRequest(playerId: 'p2', walletAddress: 'addr');
      expect(req.network, CryptoNetwork.solana);
    });
  });

  // -------------------------------------------------------------------------
  // CryptoLinkWalletResult
  // -------------------------------------------------------------------------

  group('CryptoLinkWalletResult', () {
    test('fromJson parses all fields', () {
      final r = CryptoLinkWalletResult.fromJson({
        'playerId': 'p1',
        'walletAddress': 'addr',
        'network': 'xrp',
        'transactionId': 'tx-link',
        'status': 'Pending',
      });
      expect(r.playerId, 'p1');
      expect(r.walletAddress, 'addr');
      expect(r.network, CryptoNetwork.xrp);
      expect(r.transactionId, 'tx-link');
      expect(r.status, 'Pending');
    });

    test('fromJson defaults network to solana for unknown key', () {
      final r = CryptoLinkWalletResult.fromJson({
        'playerId': '',
        'walletAddress': '',
        'network': 'unknown-net',
        'transactionId': '',
        'status': '',
      });
      expect(r.network, CryptoNetwork.solana);
    });
  });

  // -------------------------------------------------------------------------
  // CryptoWithdrawRequest
  // -------------------------------------------------------------------------

  group('CryptoWithdrawRequest', () {
    test('toJson includes required fields', () {
      const req = CryptoWithdrawRequest(
          playerId: 'p1', units: 200, toWalletAddress: 'dst-addr');
      final json = req.toJson();
      expect(json['playerId'], 'p1');
      expect(json['units'], 200);
      expect(json['toWalletAddress'], 'dst-addr');
      expect(json['network'], 'solana');
    });
  });

  // -------------------------------------------------------------------------
  // CryptoWithdrawResult
  // -------------------------------------------------------------------------

  group('CryptoWithdrawResult', () {
    test('fromJson parses all fields', () {
      final r = CryptoWithdrawResult.fromJson({
        'transactionId': 'w-tx',
        'status': 'Applied',
        'units': 150,
        'network': 'xrp',
      });
      expect(r.transactionId, 'w-tx');
      expect(r.status, 'Applied');
      expect(r.units, 150);
      expect(r.network, CryptoNetwork.xrp);
    });
  });

  // -------------------------------------------------------------------------
  // CryptoStakeRequest
  // -------------------------------------------------------------------------

  group('CryptoStakeRequest', () {
    test('toJson includes playerId and units', () {
      const req = CryptoStakeRequest(playerId: 'p1', units: 300);
      final json = req.toJson();
      expect(json['playerId'], 'p1');
      expect(json['units'], 300);
    });

    test('toJson excludes stakeId when null', () {
      const req = CryptoStakeRequest(playerId: 'p1', units: 100);
      final json = req.toJson();
      expect(json.containsKey('stakeId'), isFalse);
    });

    test('toJson includes stakeId when non-empty', () {
      const req =
          CryptoStakeRequest(playerId: 'p1', units: 100, stakeId: 'stake-123');
      final json = req.toJson();
      expect(json['stakeId'], 'stake-123');
    });
  });

  // -------------------------------------------------------------------------
  // CryptoStakeResult
  // -------------------------------------------------------------------------

  group('CryptoStakeResult', () {
    test('fromJson parses all fields', () {
      final r = CryptoStakeResult.fromJson({
        'transactionId': 's-tx',
        'playerId': 'p1',
        'units': 100,
        'currentStakedUnits': 500,
        'status': 'Applied',
      });
      expect(r.transactionId, 's-tx');
      expect(r.playerId, 'p1');
      expect(r.units, 100);
      expect(r.currentStakedUnits, 500);
      expect(r.status, 'Applied');
    });

    test('fromJson uses defaults for missing numeric fields', () {
      final r = CryptoStakeResult.fromJson({
        'transactionId': '',
        'playerId': '',
        'status': '',
      });
      expect(r.units, 0);
      expect(r.currentStakedUnits, 0);
    });
  });

  // -------------------------------------------------------------------------
  // CryptoStakingModel
  // -------------------------------------------------------------------------

  group('CryptoStakingModel', () {
    test('fromJson parses all fields', () {
      final m = CryptoStakingModel.fromJson({
        'playerId': 'p1',
        'availableUnits': 400,
        'stakedUnits': 100,
        'unitType': 'CRYPTO_UNITS',
      });
      expect(m.playerId, 'p1');
      expect(m.availableUnits, 400);
      expect(m.stakedUnits, 100);
      expect(m.unitType, 'CRYPTO_UNITS');
    });

    test('fromJson defaults unitType to CRYPTO_UNITS', () {
      final m = CryptoStakingModel.fromJson({
        'playerId': '',
        'availableUnits': 0,
        'stakedUnits': 0,
      });
      expect(m.unitType, 'CRYPTO_UNITS');
    });

    test('toJson round-trip preserves all fields', () {
      const m = CryptoStakingModel(
          playerId: 'p',
          availableUnits: 50,
          stakedUnits: 10,
          unitType: 'CRYPTO_UNITS');
      final json = m.toJson();
      final restored = CryptoStakingModel.fromJson(json);
      expect(restored.playerId, 'p');
      expect(restored.availableUnits, 50);
      expect(restored.stakedUnits, 10);
    });
  });

  // -------------------------------------------------------------------------
  // CryptoPrizePoolModel
  // -------------------------------------------------------------------------

  group('CryptoPrizePoolModel', () {
    test('fromJson parses all fields', () {
      final m = CryptoPrizePoolModel.fromJson({
        'poolId': 'pool-1',
        'units': 1000,
        'unitType': 'CRYPTO_UNITS',
      });
      expect(m.poolId, 'pool-1');
      expect(m.units, 1000);
    });

    test('fromJson defaults poolId to "global"', () {
      final m = CryptoPrizePoolModel.fromJson({'units': 0, 'unitType': 'X'});
      expect(m.poolId, 'global');
    });

    test('fromJson defaults unitType to CRYPTO_UNITS', () {
      final m = CryptoPrizePoolModel.fromJson({'poolId': 'p', 'units': 0});
      expect(m.unitType, 'CRYPTO_UNITS');
    });
  });

  // -------------------------------------------------------------------------
  // CryptoFundPrizePoolRequest
  // -------------------------------------------------------------------------

  group('CryptoFundPrizePoolRequest', () {
    test('toJson includes playerId and units', () {
      const req = CryptoFundPrizePoolRequest(playerId: 'p1', units: 500);
      final json = req.toJson();
      expect(json['playerId'], 'p1');
      expect(json['units'], 500);
    });

    test('toJson excludes poolId when null', () {
      const req = CryptoFundPrizePoolRequest(playerId: 'p1', units: 100);
      final json = req.toJson();
      expect(json.containsKey('poolId'), isFalse);
    });

    test('toJson includes poolId when non-empty', () {
      const req = CryptoFundPrizePoolRequest(
          playerId: 'p1', units: 100, poolId: 'pool-abc');
      final json = req.toJson();
      expect(json['poolId'], 'pool-abc');
    });
  });

  // -------------------------------------------------------------------------
  // CryptoFundPrizePoolResult
  // -------------------------------------------------------------------------

  group('CryptoFundPrizePoolResult', () {
    test('fromJson parses all fields', () {
      final r = CryptoFundPrizePoolResult.fromJson({
        'transactionId': 'fp-tx',
        'poolId': 'pool-2',
        'unitsFunded': 200,
        'poolUnits': 1200,
        'status': 'Applied',
      });
      expect(r.transactionId, 'fp-tx');
      expect(r.poolId, 'pool-2');
      expect(r.unitsFunded, 200);
      expect(r.poolUnits, 1200);
      expect(r.status, 'Applied');
    });

    test('fromJson defaults poolId to "global" when missing', () {
      final r = CryptoFundPrizePoolResult.fromJson({
        'transactionId': '',
        'unitsFunded': 0,
        'poolUnits': 0,
        'status': '',
      });
      expect(r.poolId, 'global');
    });
  });
}
