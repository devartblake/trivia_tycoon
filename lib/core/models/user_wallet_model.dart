/// Response model for GET /users/me/wallet
///
/// Field name mapping from server → app:
///   credits        → coins
///   neuralXp       → xp
///   synapseShards  → diamonds
class UserWallet {
  final String playerId;
  final int coins;
  final int xp;
  final int diamonds;
  final DateTime? updatedAtUtc;

  const UserWallet({
    required this.playerId,
    required this.coins,
    required this.xp,
    required this.diamonds,
    this.updatedAtUtc,
  });

  factory UserWallet.fromJson(Map<String, dynamic> json) {
    return UserWallet(
      playerId: json['playerId'] as String? ?? '',
      coins: (json['credits'] as num?)?.toInt() ?? 0,
      xp: (json['neuralXp'] as num?)?.toInt() ?? 0,
      diamonds: (json['synapseShards'] as num?)?.toInt() ?? 0,
      updatedAtUtc: json['updatedAtUtc'] != null
          ? DateTime.tryParse(json['updatedAtUtc'].toString())
          : null,
    );
  }

  static const UserWallet empty = UserWallet(
    playerId: '',
    coins: 0,
    xp: 0,
    diamonds: 0,
  );
}
