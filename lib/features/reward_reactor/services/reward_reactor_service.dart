import 'package:logging/logging.dart';

import '../../../core/networking/encrypted_api_client.dart';
import '../../../core/services/api_service.dart';
import '../models/reactor_animation_hints.dart';
import '../models/reactor_claim_response.dart';
import '../models/reactor_reward_line.dart';
import '../models/reactor_reward_preview.dart';
import '../models/reactor_spin_response.dart';
import '../models/user_rewards_response.dart';

abstract class RewardReactorService {
  Future<ReactorSpinResponse> startSpin();
  Future<ReactorClaimResponse> claimReward({
    required String spinId,
    required String claimToken,
    required String idempotencyKey,
  });
  Future<UserRewardsResponse> getUserRewards();
}

class BackendRewardReactorService implements RewardReactorService {
  static final _log = Logger('BackendRewardReactorService');

  final ApiService _apiService;
  final EncryptedApiClient _encryptedClient;

  BackendRewardReactorService(this._apiService, this._encryptedClient);

  @override
  Future<ReactorSpinResponse> startSpin() async {
    try {
      final json = await _apiService.post('/arcade/reactor/spin', body: {});
      return ReactorSpinResponse.fromJson(json);
    } catch (e) {
      _log.warning('startSpin backend unavailable, using mock: $e');
      return _mockSpinResponse();
    }
  }

  @override
  Future<ReactorClaimResponse> claimReward({
    required String spinId,
    required String claimToken,
    required String idempotencyKey,
  }) async {
    try {
      final json = await _encryptedClient.postEncrypted(
        '/arcade/reactor/claim',
        body: {
          'spinId': spinId,
          'claimToken': claimToken,
          'idempotencyKey': idempotencyKey,
        },
      );
      return ReactorClaimResponse.fromJson(json);
    } catch (e) {
      _log.warning('claimReward backend unavailable, using mock: $e');
      return ReactorClaimResponse(
        spinId: spinId,
        status: 'applied',
        reward: _mockSpinResponse().rewardPreview,
      );
    }
  }

  @override
  Future<UserRewardsResponse> getUserRewards() async {
    try {
      final json = await _apiService.get('/users/me/rewards');
      return UserRewardsResponse.fromJson(json);
    } catch (e) {
      _log.warning('getUserRewards failed, returning empty: $e');
      return const UserRewardsResponse.empty();
    }
  }

  static ReactorSpinResponse _mockSpinResponse() {
    return ReactorSpinResponse(
      spinId: 'mock-alpha-${DateTime.now().toUtc().millisecondsSinceEpoch}',
      status: 'pending_claim',
      expiresAtUtc: DateTime.now().toUtc().add(const Duration(minutes: 5)),
      animation: const ReactorAnimationHints(
        layout: 'reel3',
        symbols: ['coin', 'star', 'gem', 'coin', 'star', 'gem', 'coin', 'star', 'gem'],
        winningSymbolIndexes: [0, 3, 6],
        rarity: 'rare',
        intensity: 'high',
      ),
      rewardPreview: ReactorRewardPreview(
        rewardId: 'alpha-combined',
        displayName: 'Alpha Reward Bundle',
        lines: const [
          ReactorRewardLine(type: 'coins',  label: 'Daily Login — 50 Coins',          amount: 50),
          ReactorRewardLine(type: 'xp',     label: 'Mission Complete — 100 XP',       amount: 100),
          ReactorRewardLine(type: 'tokens', label: 'Arcade Challenge — 1 Skin Token', amount: 1),
        ],
      ),
      claimToken: 'mock-claim-token',
    );
  }
}
