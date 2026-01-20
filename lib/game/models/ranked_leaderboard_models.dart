class RankedLeaderboardEntry {
  final String playerId;
  final int seasonRank;
  final int tier;
  final int tierRank;
  final int rankPoints;
  final int wins;
  final int losses;
  final int draws;
  final int matchesPlayed;

  const RankedLeaderboardEntry({
    required this.playerId,
    required this.seasonRank,
    required this.tier,
    required this.tierRank,
    required this.rankPoints,
    required this.wins,
    required this.losses,
    required this.draws,
    required this.matchesPlayed,
  });

  factory RankedLeaderboardEntry.fromJson(Map<String, dynamic> j) {
    return RankedLeaderboardEntry(
      playerId: j['playerId'] as String,
      seasonRank: j['seasonRank'] as int,
      tier: j['tier'] as int,
      tierRank: j['tierRank'] as int,
      rankPoints: j['rankPoints'] as int,
      wins: j['wins'] as int,
      losses: j['losses'] as int,
      draws: j['draws'] as int,
      matchesPlayed: j['matchesPlayed'] as int,
    );
  }
}

class RankedLeaderboardResponse {
  final String seasonId;
  final int page;
  final int pageSize;
  final int total;
  final List<RankedLeaderboardEntry> items;

  const RankedLeaderboardResponse({
    required this.seasonId,
    required this.page,
    required this.pageSize,
    required this.total,
    required this.items,
  });

  factory RankedLeaderboardResponse.fromJson(Map<String, dynamic> j) {
    final raw = (j['items'] as List).cast<Map<String, dynamic>>();
    return RankedLeaderboardResponse(
      seasonId: j['seasonId'] as String,
      page: j['page'] as int,
      pageSize: j['pageSize'] as int,
      total: j['total'] as int,
      items: raw.map(RankedLeaderboardEntry.fromJson).toList(),
    );
  }
}
