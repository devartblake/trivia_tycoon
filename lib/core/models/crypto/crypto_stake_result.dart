class CryptoStakeResult {
  const CryptoStakeResult({
    required this.transactionId,
    required this.playerId,
    required this.units,
    required this.currentStakedUnits,
    required this.status,
  });

  final String transactionId;
  final String playerId;
  final int units;
  final int currentStakedUnits;
  final String status;

  factory CryptoStakeResult.fromJson(Map<String, dynamic> json) {
    return CryptoStakeResult(
      transactionId: json['transactionId']?.toString() ?? '',
      playerId: json['playerId']?.toString() ?? '',
      units: (json['units'] as num?)?.toInt() ?? 0,
      currentStakedUnits: (json['currentStakedUnits'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
    );
  }
}
