class CryptoStakingModel {
  const CryptoStakingModel({
    required this.playerId,
    required this.availableUnits,
    required this.stakedUnits,
    required this.unitType,
  });

  final String playerId;
  final int availableUnits;
  final int stakedUnits;
  final String unitType;

  factory CryptoStakingModel.fromJson(Map<String, dynamic> json) {
    return CryptoStakingModel(
      playerId: json['playerId']?.toString() ?? '',
      availableUnits: (json['availableUnits'] as num?)?.toInt() ?? 0,
      stakedUnits: (json['stakedUnits'] as num?)?.toInt() ?? 0,
      unitType: json['unitType']?.toString() ?? 'CRYPTO_UNITS',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      'availableUnits': availableUnits,
      'stakedUnits': stakedUnits,
      'unitType': unitType,
    };
  }
}
