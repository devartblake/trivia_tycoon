class CryptoBalanceModel {
  const CryptoBalanceModel({
    required this.playerId,
    required this.units,
    required this.unitType,
  });

  final String playerId;
  final int units;
  final String unitType;

  factory CryptoBalanceModel.fromJson(Map<String, dynamic> json) {
    return CryptoBalanceModel(
      playerId: json['playerId']?.toString() ?? '',
      units: (json['units'] as num?)?.toInt() ?? 0,
      unitType: json['unitType']?.toString() ?? 'CRYPTO_UNITS',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'units': units,
      'unitType': unitType,
    };
  }
}
