class CryptoFundPrizePoolRequest {
  const CryptoFundPrizePoolRequest({
    required this.playerId,
    required this.units,
    this.poolId,
  });

  final String playerId;
  final int units;
  final String? poolId;

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'units': units,
      if (poolId != null && poolId!.isNotEmpty) 'poolId': poolId,
    };
  }
}
