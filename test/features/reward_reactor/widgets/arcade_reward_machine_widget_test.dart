import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/features/reward_reactor/controllers/reactor_notifier.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/reactor_claim_response.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/reactor_spin_response.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/user_rewards_response.dart';
import 'package:trivia_tycoon/features/reward_reactor/providers/reward_reactor_providers.dart';
import 'package:trivia_tycoon/features/reward_reactor/services/reward_reactor_service.dart';
import 'package:trivia_tycoon/features/reward_reactor/widgets/arcade_reward_machine_widget.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

ReactorSpinResponse _mockSpin() => ReactorSpinResponse.fromJson({
      'spinId': 'widget-test-spin',
      'status': 'pending_claim',
      'expiresAtUtc': DateTime.now()
          .toUtc()
          .add(const Duration(minutes: 5))
          .toIso8601String(),
      'animation': {
        'layout': 'reel3',
        'symbols': ['coin', 'gem', 'star'],
        'winningSymbolIndexes': [0, 1, 2],
        'rarity': 'common',
        'intensity': 'medium',
      },
      'rewardPreview': {
        'rewardId': 'widget-reward',
        'displayName': 'Widget Test Reward',
        'lines': [
          {'type': 'coins', 'label': '25 Coins', 'amount': 25}
        ],
      },
      'claimToken': 'widget-token',
    });

class _NoOpService implements RewardReactorService {
  @override
  Future<ReactorSpinResponse> startSpin() => Completer<ReactorSpinResponse>().future;

  @override
  Future<ReactorClaimResponse> claimReward({
    required String spinId,
    required String claimToken,
    required String idempotencyKey,
  }) =>
      Completer<ReactorClaimResponse>().future;

  @override
  Future<UserRewardsResponse> getUserRewards() async =>
      const UserRewardsResponse.empty();
}

// Seeded notifier lets us start in any phase without driving the service.
class _SeededReactorNotifier extends ReactorNotifier {
  _SeededReactorNotifier(super.service, ReactorState seed) {
    state = seed;
  }
}

Widget _buildWidget(ReactorState seedState) {
  return ProviderScope(
    overrides: [
      reactorProvider.overrideWith(
        (ref) => _SeededReactorNotifier(_NoOpService(), seedState),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(
        backgroundColor: Color(0xFF0A0718),
        body: SafeArea(
          child: SingleChildScrollView(
            child: ArcadeRewardMachineWidget(),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ArcadeRewardMachineWidget', () {
    testWidgets('idle state — SPIN button present and no CLAIM button',
        (WidgetTester tester) async {
      await tester.pumpWidget(_buildWidget(const ReactorState()));
      await tester.pump();

      expect(find.text('SPIN'), findsOneWidget);
      expect(find.text('CLAIM'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'pendingClaim state — SPIN and CLAIM buttons present; reward banner shows displayName',
        (WidgetTester tester) async {
      final state = ReactorState(
        phase: ReactorPhase.pendingClaim,
        pendingReward: _mockSpin(),
      );
      await tester.pumpWidget(_buildWidget(state));
      await tester.pump();

      expect(find.text('SPIN'), findsOneWidget);
      expect(find.text('CLAIM'), findsOneWidget);
      expect(find.text('Widget Test Reward'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'claiming state (isClaimInFlight) — CircularProgressIndicator present instead of CLAIM text',
        (WidgetTester tester) async {
      final state = ReactorState(
        phase: ReactorPhase.claiming,
        pendingReward: _mockSpin(),
        isClaimInFlight: true,
      );
      await tester.pumpWidget(_buildWidget(state));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('CLAIM'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('applied state — renders without crash; no CLAIM button',
        (WidgetTester tester) async {
      final state = ReactorState(
        phase: ReactorPhase.applied,
        pendingReward: _mockSpin(),
        lastClaim: ReactorClaimResponse.fromJson(
          {'spinId': 'widget-test-spin', 'status': 'applied'},
        ),
      );
      await tester.pumpWidget(_buildWidget(state));
      await tester.pump();

      expect(find.byType(ArcadeRewardMachineWidget), findsOneWidget);
      expect(find.text('CLAIM'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
