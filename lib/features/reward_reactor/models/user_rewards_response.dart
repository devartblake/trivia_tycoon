import 'reactor_claim_response.dart';
import 'reactor_spin_response.dart';

class UserRewardsResponse {
  final List<ReactorSpinResponse> pendingRewards;
  final List<ReactorClaimResponse> recentRewards;

  const UserRewardsResponse({
    required this.pendingRewards,
    required this.recentRewards,
  });

  const UserRewardsResponse.empty()
      : pendingRewards = const [],
        recentRewards = const [];

  factory UserRewardsResponse.fromJson(Map<String, dynamic> json) {
    return UserRewardsResponse(
      pendingRewards: (json['pendingRewards'] as List? ?? const [])
          .map((e) => ReactorSpinResponse.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
      recentRewards: (json['recentRewards'] as List? ?? const [])
          .map((e) => ReactorClaimResponse.fromJson(
              Map<String, dynamic>.from(e as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'pendingRewards': pendingRewards.map((r) => r.toJson()).toList(),
        'recentRewards': recentRewards.map((r) => r.toJson()).toList(),
      };
}
