/// Premium spectator view of a Champion vs Tier match, from
/// GET /game-events/{id}/spectate. Basic counts are free; the elimination feed
/// is populated only for premium-pass holders.
class ChampionElimination {
  final String playerId;
  final String handle;
  final DateTime eliminatedAtUtc;
  final bool wasChampion;
  final int? finalRank;

  const ChampionElimination({
    required this.playerId,
    required this.handle,
    required this.eliminatedAtUtc,
    required this.wasChampion,
    required this.finalRank,
  });

  factory ChampionElimination.fromJson(Map<String, dynamic> j) {
    String s(String a, String b) => (j[a] ?? j[b] ?? '').toString();
    return ChampionElimination(
      playerId: s('playerId', 'PlayerId'),
      handle: s('handle', 'Handle'),
      eliminatedAtUtc:
          DateTime.tryParse(s('eliminatedAtUtc', 'EliminatedAtUtc'))?.toUtc() ??
              DateTime.fromMillisecondsSinceEpoch(0),
      wasChampion: (j['wasChampion'] ?? j['WasChampion'] ?? false) as bool,
      finalRank: (j['finalRank'] ?? j['FinalRank']) as int?,
    );
  }
}

class ChampionSpectatorView {
  final String gameEventId;
  final bool isLive;
  final bool isPremium;
  final int aliveCount;
  final int jackpotPool;
  final List<ChampionElimination> eliminationFeed;

  const ChampionSpectatorView({
    required this.gameEventId,
    required this.isLive,
    required this.isPremium,
    required this.aliveCount,
    required this.jackpotPool,
    required this.eliminationFeed,
  });

  factory ChampionSpectatorView.fromJson(Map<String, dynamic> j) {
    int i(String a, String b) => (j[a] ?? j[b] ?? 0) as int;
    final raw =
        (j['eliminationFeed'] ?? j['EliminationFeed'] ?? const []) as List;
    return ChampionSpectatorView(
      gameEventId: (j['gameEventId'] ?? j['GameEventId'] ?? '').toString(),
      isLive: (j['isLive'] ?? j['IsLive'] ?? false) as bool,
      isPremium: (j['isPremium'] ?? j['IsPremium'] ?? false) as bool,
      aliveCount: i('aliveCount', 'AliveCount'),
      jackpotPool: i('jackpotPool', 'JackpotPool'),
      eliminationFeed: raw
          .map((e) => ChampionElimination.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
