import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/reactor_claim_response.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/reactor_spin_response.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/user_rewards_response.dart';
import 'package:trivia_tycoon/features/reward_reactor/providers/reward_reactor_providers.dart';
import 'package:trivia_tycoon/features/reward_reactor/services/reward_reactor_service.dart';
import 'package:trivia_tycoon/game/providers/arcade_providers.dart'
    show rewardReactorServiceProvider;

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

ReactorSpinResponse _pendingSpinResponse() => ReactorSpinResponse.fromJson({
      'spinId': 'test-spin-1',
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
        'rewardId': 'test-reward',
        'displayName': 'Test Reward',
        'lines': [
          {'type': 'coins', 'label': '10 Coins', 'amount': 10}
        ],
      },
      'claimToken': 'test-token',
    });

ReactorSpinResponse _cooldownSpinResponse() => ReactorSpinResponse.fromJson({
      'spinId': '',
      'status': 'cooldown',
      'expiresAtUtc': DateTime.now().toUtc().toIso8601String(),
      'cooldownUntilUtc': DateTime.now()
          .toUtc()
          .add(const Duration(hours: 1))
          .toIso8601String(),
      'animation': {
        'layout': 'reel3',
        'symbols': ['coin'],
        'winningSymbolIndexes': [],
        'rarity': 'common',
        'intensity': 'low',
      },
      'rewardPreview': {
        'rewardId': '',
        'displayName': '',
        'lines': [],
      },
      'claimToken': '',
    });

// ---------------------------------------------------------------------------
// Service test doubles
// ---------------------------------------------------------------------------

class _SpinSuccessService implements RewardReactorService {
  @override
  Future<ReactorSpinResponse> startSpin() async => _pendingSpinResponse();

  @override
  Future<ReactorClaimResponse> claimReward({
    required String spinId,
    required String claimToken,
    required String idempotencyKey,
  }) async =>
      ReactorClaimResponse.fromJson({'spinId': spinId, 'status': 'applied'});

  @override
  Future<UserRewardsResponse> getUserRewards() async =>
      const UserRewardsResponse.empty();
}

class _SpinCooldownService implements RewardReactorService {
  @override
  Future<ReactorSpinResponse> startSpin() async => _cooldownSpinResponse();

  @override
  Future<ReactorClaimResponse> claimReward({
    required String spinId,
    required String claimToken,
    required String idempotencyKey,
  }) =>
      Future.error(Exception('should not be called'));

  @override
  Future<UserRewardsResponse> getUserRewards() async =>
      const UserRewardsResponse.empty();
}

class _SpinErrorService implements RewardReactorService {
  @override
  Future<ReactorSpinResponse> startSpin() =>
      Future.error(Exception('network error'));

  @override
  Future<ReactorClaimResponse> claimReward({
    required String spinId,
    required String claimToken,
    required String idempotencyKey,
  }) =>
      Future.error(Exception('should not be called'));

  @override
  Future<UserRewardsResponse> getUserRewards() async =>
      const UserRewardsResponse.empty();
}

class _ClaimCooldownService implements RewardReactorService {
  @override
  Future<ReactorSpinResponse> startSpin() async => _pendingSpinResponse();

  @override
  Future<ReactorClaimResponse> claimReward({
    required String spinId,
    required String claimToken,
    required String idempotencyKey,
  }) async =>
      ReactorClaimResponse.fromJson({'spinId': spinId, 'status': 'cooldown'});

  @override
  Future<UserRewardsResponse> getUserRewards() async =>
      const UserRewardsResponse.empty();
}

class _ClaimErrorService implements RewardReactorService {
  @override
  Future<ReactorSpinResponse> startSpin() async => _pendingSpinResponse();

  @override
  Future<ReactorClaimResponse> claimReward({
    required String spinId,
    required String claimToken,
    required String idempotencyKey,
  }) =>
      Future.error(Exception('claim network error'));

  @override
  Future<UserRewardsResponse> getUserRewards() async =>
      const UserRewardsResponse.empty();
}

class _SlowClaimService implements RewardReactorService {
  int claimCallCount = 0;

  @override
  Future<ReactorSpinResponse> startSpin() async => _pendingSpinResponse();

  @override
  Future<ReactorClaimResponse> claimReward({
    required String spinId,
    required String claimToken,
    required String idempotencyKey,
  }) async {
    claimCallCount++;
    await Future.delayed(const Duration(milliseconds: 5));
    return ReactorClaimResponse.fromJson({'spinId': spinId, 'status': 'applied'});
  }

  @override
  Future<UserRewardsResponse> getUserRewards() async =>
      const UserRewardsResponse.empty();
}

// ---------------------------------------------------------------------------
// Container builder
// ---------------------------------------------------------------------------

ProviderContainer _buildContainer(RewardReactorService svc) =>
    ProviderContainer(
      overrides: [rewardReactorServiceProvider.overrideWithValue(svc)],
    );

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('ReactorNotifier', () {
    test('initial state — idle phase, all nullable fields null, isClaimInFlight false',
        () {
      final container = _buildContainer(_SpinSuccessService());
      addTearDown(container.dispose);
      final sub = container.listen(reactorProvider, (_, __) {});
      addTearDown(sub.close);

      final state = container.read(reactorProvider);
      expect(state.phase, ReactorPhase.idle);
      expect(state.pendingReward, isNull);
      expect(state.lastClaim, isNull);
      expect(state.cooldownUntil, isNull);
      expect(state.isClaimInFlight, isFalse);
      expect(state.errorMessage, isNull);
    });

    group('spin()', () {
      test('success — idle → pendingClaim; pendingReward set with correct status',
          () async {
        final container = _buildContainer(_SpinSuccessService());
        addTearDown(container.dispose);
        final sub = container.listen(reactorProvider, (_, __) {});
        addTearDown(sub.close);

        await container.read(reactorProvider.notifier).spin();

        final state = container.read(reactorProvider);
        expect(state.phase, ReactorPhase.pendingClaim);
        expect(state.pendingReward, isNotNull);
        expect(state.pendingReward!.status, 'pending_claim');
        expect(state.pendingReward!.spinId, isNotEmpty);
        expect(state.pendingReward!.claimToken, isNotEmpty);
      });

      test('cooldown response — idle → cooldown; cooldownUntil set in the future',
          () async {
        final container = _buildContainer(_SpinCooldownService());
        addTearDown(container.dispose);
        final sub = container.listen(reactorProvider, (_, __) {});
        addTearDown(sub.close);

        await container.read(reactorProvider.notifier).spin();

        final state = container.read(reactorProvider);
        expect(state.phase, ReactorPhase.cooldown);
        expect(state.cooldownUntil, isNotNull);
        expect(state.cooldownUntil!.isAfter(DateTime.now().toUtc()), isTrue);
      });

      test('error — idle → error; errorMessage non-null', () async {
        final container = _buildContainer(_SpinErrorService());
        addTearDown(container.dispose);
        final sub = container.listen(reactorProvider, (_, __) {});
        addTearDown(sub.close);

        await container.read(reactorProvider.notifier).spin();

        final state = container.read(reactorProvider);
        expect(state.phase, ReactorPhase.error);
        expect(state.errorMessage, isNotNull);
        expect(state.errorMessage, isNotEmpty);
      });

      test('no-op when phase is not idle — second spin() leaves state unchanged',
          () async {
        final container = _buildContainer(_SpinSuccessService());
        addTearDown(container.dispose);
        final sub = container.listen(reactorProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(reactorProvider.notifier);
        await notifier.spin();
        expect(container.read(reactorProvider).phase, ReactorPhase.pendingClaim);

        final spinIdBefore =
            container.read(reactorProvider).pendingReward!.spinId;
        await notifier.spin();

        final state = container.read(reactorProvider);
        expect(state.phase, ReactorPhase.pendingClaim);
        expect(state.pendingReward!.spinId, spinIdBefore);
      });
    });

    group('claim()', () {
      test('success — pendingClaim → applied; lastClaim.isApplied true; pendingReward preserved',
          () async {
        final container = _buildContainer(_SpinSuccessService());
        addTearDown(container.dispose);
        final sub = container.listen(reactorProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(reactorProvider.notifier);
        await notifier.spin();
        await notifier.claim();

        final state = container.read(reactorProvider);
        expect(state.phase, ReactorPhase.applied);
        expect(state.lastClaim, isNotNull);
        expect(state.lastClaim!.isApplied, isTrue);
        expect(state.pendingReward, isNotNull);
        expect(state.isClaimInFlight, isFalse);
      });

      test('cooldown response — pendingClaim → cooldown', () async {
        final container = _buildContainer(_ClaimCooldownService());
        addTearDown(container.dispose);
        final sub = container.listen(reactorProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(reactorProvider.notifier);
        await notifier.spin();
        await notifier.claim();

        expect(container.read(reactorProvider).phase, ReactorPhase.cooldown);
      });

      test('error recovery — snaps back to pendingClaim; errorMessage set; isClaimInFlight reset',
          () async {
        final container = _buildContainer(_ClaimErrorService());
        addTearDown(container.dispose);
        final sub = container.listen(reactorProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(reactorProvider.notifier);
        await notifier.spin();
        await notifier.claim();

        final state = container.read(reactorProvider);
        expect(state.phase, ReactorPhase.pendingClaim);
        expect(state.errorMessage, isNotNull);
        expect(state.isClaimInFlight, isFalse);
        expect(state.pendingReward, isNotNull);
      });

      test('double-tap guard — second concurrent claim() does not trigger a second service call',
          () async {
        final svc = _SlowClaimService();
        final container = _buildContainer(svc);
        addTearDown(container.dispose);
        final sub = container.listen(reactorProvider, (_, __) {});
        addTearDown(sub.close);

        final notifier = container.read(reactorProvider.notifier);
        await notifier.spin();

        final f1 = notifier.claim();
        final f2 = notifier.claim();
        await Future.wait([f1, f2]);

        expect(svc.claimCallCount, 1);
      });
    });

    test('dismiss() — resets any phase back to idle with cleared fields', () async {
      final container = _buildContainer(_SpinErrorService());
      addTearDown(container.dispose);
      final sub = container.listen(reactorProvider, (_, __) {});
      addTearDown(sub.close);

      final notifier = container.read(reactorProvider.notifier);
      await notifier.spin();
      expect(container.read(reactorProvider).phase, ReactorPhase.error);

      notifier.dismiss();

      final state = container.read(reactorProvider);
      expect(state.phase, ReactorPhase.idle);
      expect(state.errorMessage, isNull);
      expect(state.pendingReward, isNull);
      expect(state.isClaimInFlight, isFalse);
    });
  });
}
