import 'reactor_reward_preview.dart';
import 'reactor_wallet_snapshot.dart';

class ReactorClaimResponse {
  final String spinId;
  final String status;
  final ReactorRewardPreview? reward;
  final ReactorWalletSnapshot? walletSnapshot;

  const ReactorClaimResponse({
    required this.spinId,
    required this.status,
    this.reward,
    this.walletSnapshot,
  });

  bool get isApplied => status == 'applied';
  bool get isDuplicate => status == 'duplicate';
  bool get isExpired => status == 'expired';
  bool get isCooldown => status == 'cooldown';

  factory ReactorClaimResponse.fromJson(Map<String, dynamic> json) {
    final rewardJson = json['reward'] as Map?;
    final walletJson = json['walletSnapshot'] as Map?;
    return ReactorClaimResponse(
      spinId: json['spinId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'applied',
      reward: rewardJson != null
          ? ReactorRewardPreview.fromJson(Map<String, dynamic>.from(rewardJson))
          : null,
      walletSnapshot: walletJson != null
          ? ReactorWalletSnapshot.fromJson(Map<String, dynamic>.from(walletJson))
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'spinId': spinId,
        'status': status,
        if (reward != null) 'reward': reward!.toJson(),
        if (walletSnapshot != null) 'walletSnapshot': walletSnapshot!.toJson(),
      };
}
