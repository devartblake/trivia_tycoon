import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/core/models/crypto/crypto_balance_model.dart';
import 'package:synaptix/core/models/crypto/crypto_history_item.dart';
import 'package:synaptix/core/models/crypto/crypto_history_response.dart';
import 'package:synaptix/core/models/crypto/crypto_staking_model.dart';
import 'package:synaptix/core/models/crypto/crypto_transaction_kind.dart';
import 'package:synaptix/core/models/crypto/crypto_transaction_status.dart';
import 'package:synaptix/game/providers/crypto_providers.dart';
import 'package:synaptix/screens/store/crypto_wallet_screen.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

const _enabledFlags = CryptoFeatureFlags(
  surfacesEnabled: true,
  writesEnabled: true,
  enabledNetworkKeys: {'solana'},
);

const _disabledFlags = CryptoFeatureFlags(
  surfacesEnabled: false,
  writesEnabled: false,
  enabledNetworkKeys: {},
);

const _balance = CryptoBalanceModel(
  playerId: 'player-1',
  units: 1250,
  unitType: 'CRYPTO_UNITS',
);

const _staking = CryptoStakingModel(
  playerId: 'player-1',
  availableUnits: 700,
  stakedUnits: 300,
  unitType: 'CRYPTO_UNITS',
);

const _emptyHistory = CryptoHistoryResponse(
  page: 1,
  pageSize: 20,
  total: 0,
  items: [],
);

CryptoHistoryResponse _linkedHistory({bool pendingWithdrawal = false}) {
  return CryptoHistoryResponse(
    page: 1,
    pageSize: 20,
    total: pendingWithdrawal ? 2 : 1,
    items: [
      const CryptoHistoryItem(
        transactionId: 'link-1',
        kind: CryptoTransactionKind.walletLink,
        unitsDelta: 0,
        status: CryptoTransactionStatus.applied,
        receiptRef: '7EcDhSYGxXyscszYEp35KHN8vvw3svAuLKTzXwCFLtV',
      ),
      if (pendingWithdrawal)
        const CryptoHistoryItem(
          transactionId: 'withdraw-1',
          kind: CryptoTransactionKind.withdrawRequest,
          unitsDelta: -50,
          status: CryptoTransactionStatus.pending,
        ),
    ],
  );
}

Widget _wrap({
  required CryptoFeatureFlags flags,
  CryptoBalanceModel balance = _balance,
  CryptoStakingModel staking = _staking,
  CryptoHistoryResponse history = _emptyHistory,
}) {
  return ProviderScope(
    overrides: [
      cryptoFeatureFlagsProvider.overrideWithValue(flags),
      currentUserCryptoBalanceProvider.overrideWith((ref) async => balance),
      currentUserCryptoStakingProvider.overrideWith((ref) async => staking),
      currentUserCryptoHistoryProvider.overrideWith((ref) async => history),
    ],
    child: const MaterialApp(home: CryptoWalletScreen()),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('CryptoWalletScreen', () {
    testWidgets('shows Crypto unavailable when surfacesEnabled is false',
        (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cryptoFeatureFlagsProvider.overrideWithValue(_disabledFlags),
          ],
          child: const MaterialApp(home: CryptoWalletScreen()),
        ),
      );
      await tester.pump();

      expect(find.text('Crypto unavailable'), findsOneWidget);
      expect(find.byType(Scaffold), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows Wallet not linked for empty history', (tester) async {
      await tester.pumpWidget(_wrap(flags: _enabledFlags));
      await tester.pump();

      expect(find.text('Wallet not linked'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('shows Wallet linked when history contains a walletLink item',
        (tester) async {
      await tester.pumpWidget(
        _wrap(flags: _enabledFlags, history: _linkedHistory()),
      );
      await tester.pump();

      expect(find.text('Wallet linked'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('displays available balance units', (tester) async {
      await tester.pumpWidget(_wrap(flags: _enabledFlags));
      await tester.pump();

      expect(find.text('1250'), findsOneWidget);
    });

    testWidgets('displays staked units', (tester) async {
      await tester.pumpWidget(_wrap(flags: _enabledFlags));
      await tester.pump();

      expect(find.text('300'), findsOneWidget);
    });

    testWidgets('staking summary shows Spendable and Locked values',
        (tester) async {
      await tester.pumpWidget(_wrap(flags: _enabledFlags));
      await tester.pump();

      expect(
        find.textContaining('Spendable: 700 | Locked: 300'),
        findsOneWidget,
      );
    });

    testWidgets('pending withdrawal shows polling notice', (tester) async {
      // The body is a lazy ListView; give it a tall viewport so the transaction
      // history section (below balance/staking) is actually built.
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        _wrap(
          flags: _enabledFlags,
          history: _linkedHistory(pendingWithdrawal: true),
        ),
      );
      await tester.pump();

      expect(
        find.textContaining('Pending withdrawals detected'),
        findsOneWidget,
      );
    });

    testWidgets('no crypto activity shown for empty history', (tester) async {
      tester.view.physicalSize = const Size(1080, 4000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(_wrap(flags: _enabledFlags));
      await tester.pump();

      expect(find.text('No crypto activity yet'), findsOneWidget);
    });
  });
}
