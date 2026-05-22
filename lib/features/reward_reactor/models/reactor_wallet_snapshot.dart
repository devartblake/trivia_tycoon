class ReactorWalletSnapshot {
  final int coins;
  final int gems;
  final int xp;

  const ReactorWalletSnapshot({
    required this.coins,
    required this.gems,
    required this.xp,
  });

  factory ReactorWalletSnapshot.fromJson(Map<String, dynamic> json) {
    return ReactorWalletSnapshot(
      coins: (json['coins'] as num?)?.toInt() ?? 0,
      gems: (json['gems'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'coins': coins,
        'gems': gems,
        'xp': xp,
      };
}
