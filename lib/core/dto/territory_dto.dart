/// Mirrors backend TerritoryTileDto: tiles are keyed by quiz category, and the
/// XP multiplier is transported in basis points (10000 bps = 1.0x).
class TileDto {
  final String category;
  final String? ownerId;
  final double xpMultiplier;

  const TileDto({
    required this.category,
    this.ownerId,
    required this.xpMultiplier,
  });

  factory TileDto.fromJson(Map<String, dynamic> j) => TileDto(
        category: j['category'] as String,
        ownerId: j['ownerId'] as String?,
        xpMultiplier: ((j['xpMultiplierBps'] as num?) ?? 10000) / 10000.0,
      );

  Map<String, dynamic> toJson() => {
        'category': category,
        'ownerId': ownerId,
        'xpMultiplierBps': (xpMultiplier * 10000).round(),
      };
}

class TerritoryBoardDto {
  final String seasonId;
  final int tierNumber;
  final List<TileDto> tiles;

  const TerritoryBoardDto({
    required this.seasonId,
    required this.tierNumber,
    required this.tiles,
  });

  factory TerritoryBoardDto.fromJson(Map<String, dynamic> j) =>
      TerritoryBoardDto(
        seasonId: j['seasonId'] as String,
        tierNumber: j['tierNumber'] as int? ?? 1,
        tiles: (j['tiles'] as List<dynamic>?)
                ?.map((e) => TileDto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'seasonId': seasonId,
        'tierNumber': tierNumber,
        'tiles': tiles.map((t) => t.toJson()).toList(),
      };
}

/// Mirrors backend StartTerritoryDuelResponse.
class DuelResultDto {
  final String matchId;
  final String? tileOwnerId;
  final String? status;

  const DuelResultDto({required this.matchId, this.tileOwnerId, this.status});

  factory DuelResultDto.fromJson(Map<String, dynamic> j) => DuelResultDto(
        matchId: j['matchId'] as String,
        tileOwnerId: j['tileOwnerId'] as String?,
        status: j['status'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'tileOwnerId': tileOwnerId,
        'status': status,
      };
}

/// Mirrors backend TerritoryDominanceDto (dominance leaderboard rows).
class TerritoryDominanceDto {
  final String playerId;
  final int tilesOwned;
  final double totalXpMultiplier;

  const TerritoryDominanceDto({
    required this.playerId,
    required this.tilesOwned,
    required this.totalXpMultiplier,
  });

  factory TerritoryDominanceDto.fromJson(Map<String, dynamic> j) =>
      TerritoryDominanceDto(
        playerId: j['playerId'] as String,
        tilesOwned: j['tilesOwned'] as int? ?? 0,
        totalXpMultiplier: ((j['totalXpMultiplierBps'] as num?) ?? 0) / 10000.0,
      );

  Map<String, dynamic> toJson() => {
        'playerId': playerId,
        'tilesOwned': tilesOwned,
        'totalXpMultiplierBps': (totalXpMultiplier * 10000).round(),
      };
}
