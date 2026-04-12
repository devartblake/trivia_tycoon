class CryptoFundPrizePoolResult {
  const CryptoFundPrizePoolResult({
    required this.transactionId,
    required this.poolId,
    required this.unitsFunded,
    required this.poolUnits,
    required this.status,
  });

  final String transactionId;
  final String poolId;
  final int unitsFunded;
  final int poolUnits;
  final String status;

  factory CryptoFundPrizePoolResult.fromJson(Map<String, dynamic> json) {
    return CryptoFundPrizePoolResult(
      transactionId: json['transactionId']?.toString() ?? '',
      poolId: json['poolId']?.toString() ?? 'global',
      unitsFunded: (json['unitsFunded'] as num?)?.toInt() ?? 0,
      poolUnits: (json['poolUnits'] as num?)?.toInt() ?? 0,
      status: json['status']?.toString() ?? '',
    );
  }
}
