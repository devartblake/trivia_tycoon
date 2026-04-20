class SeasonDto {
  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final bool isActive;

  const SeasonDto({
    required this.id,
    required this.name,
    required this.startsAt,
    required this.endsAt,
    required this.isActive,
  });

  factory SeasonDto.fromJson(Map<String, dynamic> j) => SeasonDto(
        id: j['id'] as String,
        name: j['name'] as String,
        startsAt: DateTime.parse(j['startsAt'] as String),
        endsAt: DateTime.parse(j['endsAt'] as String),
        isActive: j['isActive'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'startsAt': startsAt.toIso8601String(),
        'endsAt': endsAt.toIso8601String(),
        'isActive': isActive,
      };
}

class PlayerSeasonStateDto {
  final String playerId;
  final String seasonId;
  final int tier;
  final int xp;
  final int rank;
  final int guardiansDefeated;
  final int tilesControlled;

  const PlayerSeasonStateDto({
    required this.playerId,
    required this.seasonId,
    required this.tier,
    required this.xp,
    required this.rank,
    required this.guardiansDefeated,
    required this.tilesControlled,
  });

  factory PlayerSeasonStateDto.fromJson(Map<String, dynamic> j) =>
      PlayerSeasonStateDto(
        playerId: j['playerId'] as String,
        seasonId: j['seasonId'] as String,
        tier: j['tier'] as int? ?? 1,
        xp: j['xp'] as int? ?? 0,
        rank: j['rank'] as int? ?? 0,
        guardiansDefeated: j['guardiansDefeated'] as int? ?? 0,
        tilesControlled: j['tilesControlled'] as int? ?? 0,
      );

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'seasonId': seasonId,
        'tier': tier,
        'xp': xp,
        'rank': rank,
        'guardiansDefeated': guardiansDefeated,
        'tilesControlled': tilesControlled,
      };
}
