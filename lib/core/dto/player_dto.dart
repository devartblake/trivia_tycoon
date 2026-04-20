class WalletDto {
  final int coins;
  final int gems;

  const WalletDto({required this.coins, required this.gems});

  factory WalletDto.fromJson(Map<String, dynamic> j) => WalletDto(
        coins: j['coins'] as int? ?? 0,
        gems: j['gems'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {'coins': coins, 'gems': gems};
}

class PlayerDto {
  final String id;
  final String username;
  final String email;
  final String handle;
  final String? avatarUrl;
  final String? country;
  final String ageGroup;
  final String role;
  final WalletDto wallet;
  final int xp;
  final int level;
  final DateTime createdAt;

  const PlayerDto({
    required this.id,
    required this.username,
    required this.email,
    required this.handle,
    this.avatarUrl,
    this.country,
    required this.ageGroup,
    required this.role,
    required this.wallet,
    required this.xp,
    required this.level,
    required this.createdAt,
  });

  factory PlayerDto.fromJson(Map<String, dynamic> j) => PlayerDto(
        id: j['id'] as String,
        username: j['username'] as String,
        email: j['email'] as String,
        handle: j['handle'] as String? ?? '',
        avatarUrl: j['avatarUrl'] as String?,
        country: j['country'] as String?,
        ageGroup: j['ageGroup'] as String? ?? 'general',
        role: j['role'] as String? ?? 'user',
        wallet: WalletDto.fromJson(j['wallet'] as Map<String, dynamic>? ?? {}),
        xp: j['xp'] as int? ?? 0,
        level: j['level'] as int? ?? 1,
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ??
            DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'email': email,
        'handle': handle,
        'avatarUrl': avatarUrl,
        'country': country,
        'ageGroup': ageGroup,
        'role': role,
        'wallet': wallet.toJson(),
        'xp': xp,
        'level': level,
        'createdAt': createdAt.toIso8601String(),
      };
}
