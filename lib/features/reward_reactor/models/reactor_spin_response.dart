import 'reactor_animation_hints.dart';
import 'reactor_reward_preview.dart';

class ReactorSpinResponse {
  final String spinId;
  final String status;
  final DateTime expiresAtUtc;
  final DateTime? cooldownUntilUtc;
  final ReactorAnimationHints animation;
  final ReactorRewardPreview rewardPreview;
  final String claimToken;

  const ReactorSpinResponse({
    required this.spinId,
    required this.status,
    required this.expiresAtUtc,
    this.cooldownUntilUtc,
    required this.animation,
    required this.rewardPreview,
    required this.claimToken,
  });

  factory ReactorSpinResponse.fromJson(Map<String, dynamic> json) {
    return ReactorSpinResponse(
      spinId: json['spinId']?.toString() ?? '',
      status: json['status']?.toString() ?? 'pending_claim',
      expiresAtUtc:
          DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '')?.toUtc() ??
              DateTime.now().toUtc().add(const Duration(minutes: 5)),
      cooldownUntilUtc:
          DateTime.tryParse(json['cooldownUntilUtc']?.toString() ?? '')?.toUtc(),
      animation: ReactorAnimationHints.fromJson(
          Map<String, dynamic>.from(json['animation'] as Map? ?? {})),
      rewardPreview: ReactorRewardPreview.fromJson(
          Map<String, dynamic>.from(json['rewardPreview'] as Map? ?? {})),
      claimToken: json['claimToken']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'spinId': spinId,
        'status': status,
        'expiresAtUtc': expiresAtUtc.toIso8601String(),
        if (cooldownUntilUtc != null)
          'cooldownUntilUtc': cooldownUntilUtc!.toIso8601String(),
        'animation': animation.toJson(),
        'rewardPreview': rewardPreview.toJson(),
        'claimToken': claimToken,
      };
}
