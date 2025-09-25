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

  factory SeasonPlayer.fromJson(Map<String, dynamic> json) {
    return SeasonPlayer(
      playerId: json['playerId'],
      playerName: json['playerName'],
      points: json['points'],
      rank: json['rank'],
      lastActive: DateTime.parse(json['lastActive']),
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
