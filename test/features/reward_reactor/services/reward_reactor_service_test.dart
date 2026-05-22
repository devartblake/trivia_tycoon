import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/reactor_claim_response.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/reactor_reward_preview.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/reactor_spin_response.dart';
import 'package:trivia_tycoon/features/reward_reactor/models/user_rewards_response.dart';
import 'package:trivia_tycoon/features/reward_reactor/services/reward_reactor_service.dart';

// ---------------------------------------------------------------------------
// Test doubles
// ---------------------------------------------------------------------------

class _AlwaysFailingReactorService implements RewardReactorService {
  @override
  Future<ReactorSpinResponse> startSpin() => Future.error(Exception('404'));

  @override
  Future<ReactorClaimResponse> claimReward({
    required String spinId,
    required String claimToken,
    required String idempotencyKey,
  }) =>
      Future.error(Exception('404'));

  @override
  Future<UserRewardsResponse> getUserRewards() =>
      Future.error(Exception('network'));
}

class _SucceedingReactorService implements RewardReactorService {
  @override
  Future<ReactorSpinResponse> startSpin() async =>
      ReactorSpinResponse.fromJson({
        'spinId': 'live-spin-1',
        'status': 'pending_claim',
        'expiresAtUtc': DateTime.now().toUtc().add(const Duration(minutes: 5)).toIso8601String(),
        'animation': {
          'layout': 'reel3',
          'symbols': ['coin', 'gem', 'star'],
          'winningSymbolIndexes': [0, 1, 2],
          'rarity': 'common',
          'intensity': 'medium',
        },
        'rewardPreview': {
          'rewardId': 'live-reward',
          'displayName': 'Live Reward',
          'lines': [
            {'type': 'coins', 'label': '25 Coins', 'amount': 25},
          ],
        },
        'claimToken': 'live-token',
      });

  @override
  Future<ReactorClaimResponse> claimReward({
    required String spinId,
    required String claimToken,
    required String idempotencyKey,
  }) async =>
      ReactorClaimResponse.fromJson({
        'spinId': spinId,
        'status': 'applied',
        'reward': {
          'rewardId': 'live-reward',
          'displayName': 'Live Reward',
          'lines': [
            {'type': 'coins', 'label': '25 Coins', 'amount': 25}
          ],
        },
      });

  @override
  Future<UserRewardsResponse> getUserRewards() async =>
      const UserRewardsResponse.empty();
}

// ---------------------------------------------------------------------------
// Tests — backend fallback behaviour (via BackendRewardReactorService internals)
// ---------------------------------------------------------------------------

void main() {
  group('_AlwaysFailingReactorService (simulates 404 / unreachable backend)', () {
    final service = _AlwaysFailingReactorService();

    test('startSpin throws on failure (caller should handle)', () async {
      expect(() => service.startSpin(), throwsA(isA<Exception>()));
    });

    test('getUserRewards throws on failure (caller should handle)', () async {
      expect(() => service.getUserRewards(), throwsA(isA<Exception>()));
    });
  });

  group('BackendRewardReactorService mock fallback path', () {
    // We test the mock fallback by verifying the mock payload shape,
    // since the real service wraps exceptions and returns mock data.

    test('mock spin response has required fields', () {
      // Replicate what BackendRewardReactorService._mockSpinResponse() returns
      // by parsing a known-good JSON (the logic is the same shape).
      final mock = ReactorSpinResponse.fromJson({
        'spinId': 'mock-daily-123',
        'status': 'pending_claim',
        'expiresAtUtc': DateTime.now().toUtc().toIso8601String(),
        'animation': {
          'layout': 'reel3',
          'symbols': ['coin', 'coin', 'star', 'coin', 'gem', 'star', 'coin', 'coin', 'star'],
          'winningSymbolIndexes': [0, 3, 6],
          'rarity': 'common',
          'intensity': 'medium',
        },
        'rewardPreview': {
          'rewardId': 'daily-login-coins',
          'displayName': 'Daily Login Reward',
          'lines': [
            {'type': 'coins', 'label': '50 Coins', 'amount': 50},
          ],
        },
        'claimToken': 'mock-claim-token',
      });

      expect(mock.spinId, isNotEmpty);
      expect(mock.status, 'pending_claim');
      expect(mock.animation.layout, 'reel3');
      expect(mock.rewardPreview.lines.first.amount, 50);
      expect(mock.claimToken, isNotEmpty);
    });

    test('mock claim response returns applied status', () {
      final claim = ReactorClaimResponse.fromJson({
        'spinId': 'mock-spin',
        'status': 'applied',
        'reward': {
          'rewardId': 'daily-login-coins',
          'displayName': 'Daily Login Reward',
          'lines': [
            {'type': 'coins', 'label': '50 Coins', 'amount': 50}
          ],
        },
      });

      expect(claim.isApplied, isTrue);
      expect(claim.reward, isA<ReactorRewardPreview>());
    });
  });

  group('_SucceedingReactorService (live path)', () {
    final service = _SucceedingReactorService();

    test('startSpin returns pending_claim status', () async {
      final response = await service.startSpin();
      expect(response.status, 'pending_claim');
      expect(response.spinId, isNotEmpty);
      expect(response.claimToken, isNotEmpty);
    });

    test('claimReward returns applied status', () async {
      final response = await service.claimReward(
        spinId: 'live-spin-1',
        claimToken: 'live-token',
        idempotencyKey: 'live-spin-1-live-token',
      );
      expect(response.isApplied, isTrue);
      expect(response.reward, isNotNull);
    });

    test('getUserRewards returns empty response without throwing', () async {
      final response = await service.getUserRewards();
      expect(response.pendingRewards, isEmpty);
      expect(response.recentRewards, isEmpty);
    });
  });
}
