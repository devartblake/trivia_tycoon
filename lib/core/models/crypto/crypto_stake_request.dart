class CryptoStakeRequest {
  const CryptoStakeRequest({
    required this.playerId,
    required this.units,
    this.stakeId,
  });

  final String playerId;
  final int units;
  final String? stakeId;

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'units': units,
      if (stakeId != null && stakeId!.isNotEmpty) 'stakeId': stakeId,
    };
  }
}
