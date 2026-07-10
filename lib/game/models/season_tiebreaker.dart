/// A pending or resolved end-of-season tie-breaker, as served by
/// `GET /seasons/tiebreakers/mine` and `GET /seasons/{id}/tiebreakers`
/// (SeasonTiebreakerDto).
class SeasonTiebreaker {
  final String id;
  final String seasonId;

  /// 'top1' (championship), 'tier-promotion' (reward boundary) or 'custom'.
  final String scope;
  final int tier;
  final int boundaryRank;
  final int rankPoints;
  final List<String> playerIds;
  final DateTime scheduledAtUtc;
  final DateTime expiresAtUtc;

  /// Scheduled | InProgress | Completed | Cancelled | Expired
  final String status;
  final String? matchId;
  final String? winnerPlayerId;

  const SeasonTiebreaker({
    required this.id,
    required this.seasonId,
    required this.scope,
    required this.tier,
    required this.boundaryRank,
    required this.rankPoints,
    required this.playerIds,
    required this.scheduledAtUtc,
    required this.expiresAtUtc,
    required this.status,
    this.matchId,
    this.winnerPlayerId,
  });

  bool get isPending => status == 'Scheduled' || status == 'InProgress';
  bool get isChampionship => scope == 'top1';

  factory SeasonTiebreaker.fromJson(Map<String, dynamic> json) {
    return SeasonTiebreaker(
      id: json['id']?.toString() ?? '',
      seasonId: json['seasonId']?.toString() ?? '',
      scope: json['scope']?.toString() ?? 'custom',
      tier: (json['tier'] as num?)?.toInt() ?? 0,
      boundaryRank: (json['boundaryRank'] as num?)?.toInt() ?? 0,
      rankPoints: (json['rankPoints'] as num?)?.toInt() ?? 0,
      playerIds: (json['playerIds'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      scheduledAtUtc:
          DateTime.tryParse(json['scheduledAtUtc']?.toString() ?? '') ??
              DateTime.fromMillisecondsSinceEpoch(0),
      expiresAtUtc: DateTime.tryParse(json['expiresAtUtc']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      status: json['status']?.toString() ?? 'Scheduled',
      matchId: json['matchId']?.toString(),
      winnerPlayerId: json['winnerPlayerId']?.toString(),
    );
  }
}
