class CryptoPrizePoolModel {
  const CryptoPrizePoolModel({
    required this.poolId,
    required this.units,
    required this.unitType,
  });

  final String poolId;
  final int units;
  final String unitType;

  factory CryptoPrizePoolModel.fromJson(Map<String, dynamic> json) {
    return CryptoPrizePoolModel(
      poolId: json['poolId']?.toString() ?? 'global',
      units: (json['units'] as num?)?.toInt() ?? 0,
      unitType: json['unitType']?.toString() ?? 'CRYPTO_UNITS',
    );
  }
}
