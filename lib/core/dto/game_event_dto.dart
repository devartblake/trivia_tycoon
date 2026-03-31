class GameEventDto {
  final String id;
  final String name;
  final String status; // 'upcoming' | 'live' | 'closed'
  final DateTime startsAt;
  final int entryFee;
  final int maxPlayers;
  final int currentPlayers;
  final int aliveCount;

  const GameEventDto({
    required this.id,
    required this.name,
    required this.status,
    required this.startsAt,
    required this.entryFee,
    required this.maxPlayers,
    required this.currentPlayers,
    required this.aliveCount,
  });

  factory GameEventDto.fromJson(Map<String, dynamic> j) => GameEventDto(
    id: j['id'] as String,
    name: j['name'] as String,
    status: j['status'] as String? ?? 'upcoming',
    startsAt: DateTime.parse(j['startsAt'] as String),
    entryFee: j['entryFee'] as int? ?? 0,
    maxPlayers: j['maxPlayers'] as int? ?? 0,
    currentPlayers: j['currentPlayers'] as int? ?? 0,
    aliveCount: j['aliveCount'] as int? ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'status': status,
    'startsAt': startsAt.toIso8601String(),
    'entryFee': entryFee,
    'maxPlayers': maxPlayers,
    'currentPlayers': currentPlayers,
    'aliveCount': aliveCount,
  };
}

class GameEventLeaderboardEntryDto {
  final String playerId;
  final String username;
  final int rank;
  final int score;
  final bool isEliminated;

  const GameEventLeaderboardEntryDto({
    required this.playerId,
    required this.username,
    required this.rank,
    required this.score,
    required this.isEliminated,
  });

  factory GameEventLeaderboardEntryDto.fromJson(Map<String, dynamic> j) =>
      GameEventLeaderboardEntryDto(
        playerId: j['playerId'] as String,
        username: j['username'] as String,
        rank: j['rank'] as int? ?? 0,
        score: j['score'] as int? ?? 0,
        isEliminated: j['isEliminated'] as bool? ?? false,
      );

  Map<String, dynamic> toJson() => {
    'playerId': playerId,
    'username': username,
    'rank': rank,
    'score': score,
    'isEliminated': isEliminated,
  };
}
