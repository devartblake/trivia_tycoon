class SeasonPlayer {
  final String playerId;
  final String playerName;
  final int points;
  final int rank;
  final DateTime lastActive;

  SeasonPlayer({
    required this.playerId,
    required this.playerName,
    required this.points,
    required this.rank,
    required this.lastActive,
  });

  /// Accepts both the legacy client shape (playerName/points/lastActive) and
  /// the backend leaderboard entry shape from
  /// GET /seasons/{id}/leaderboard (handle/displayName/rankPoints, no
  /// lastActive — the backend doesn't track per-season activity timestamps).
  factory SeasonPlayer.fromJson(Map<String, dynamic> json) {
    final lastActiveRaw = json['lastActive'] as String?;
    return SeasonPlayer(
      playerId: json['playerId']?.toString() ?? '',
      playerName: (json['playerName'] ??
              json['displayName'] ??
              json['handle'] ??
              'Unknown')
          .toString(),
      points: (json['points'] ?? json['rankPoints'] ?? 0) as int,
      rank: (json['rank'] ?? 0) as int,
      lastActive: lastActiveRaw != null
          ? DateTime.parse(lastActiveRaw)
          : DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class SeasonEndResult {
  final List<SeasonPlayer> promoted;
  final List<SeasonPlayer> demoted;
  final List<List<SeasonPlayer>> tiebreakers;
  final String seasonId;
  final String? error;

  SeasonEndResult({
    required this.promoted,
    required this.demoted,
    required this.tiebreakers,
    required this.seasonId,
    this.error,
  });

  SeasonEndResult.error(String errorMessage)
      : promoted = [],
        demoted = [],
        tiebreakers = [],
        seasonId = '',
        error = errorMessage;

  bool get hasError => error != null;
  bool get hasTiebreakers => tiebreakers.isNotEmpty;
}
