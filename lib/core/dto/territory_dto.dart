class TileDto {
  final String id;
  final String? ownerId;
  final String? ownerUsername;
  final int row;
  final int col;
  final double xpMultiplier;

  const TileDto({
    required this.id,
    this.ownerId,
    this.ownerUsername,
    required this.row,
    required this.col,
    required this.xpMultiplier,
  });

  factory TileDto.fromJson(Map<String, dynamic> j) => TileDto(
    id: j['id'] as String,
    ownerId: j['ownerId'] as String?,
    ownerUsername: j['ownerUsername'] as String?,
    row: j['row'] as int? ?? 0,
    col: j['col'] as int? ?? 0,
    xpMultiplier: (j['xpMultiplier'] as num?)?.toDouble() ?? 1.0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'ownerId': ownerId,
    'ownerUsername': ownerUsername,
    'row': row,
    'col': col,
    'xpMultiplier': xpMultiplier,
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

class DuelResultDto {
  final String matchId;
  final String tileId;

  const DuelResultDto({required this.matchId, required this.tileId});

  factory DuelResultDto.fromJson(Map<String, dynamic> j) => DuelResultDto(
    matchId: j['matchId'] as String,
    tileId: j['tileId'] as String,
  );

  Map<String, dynamic> toJson() => {'matchId': matchId, 'tileId': tileId};
}