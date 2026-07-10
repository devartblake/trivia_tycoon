// Real-time messages for a live Champion vs Tier match, pushed over the
// NotificationHub (`game-event:{id}` group). Mirror the backend records in
// Synaptix.Shared.Contracts.Realtime.GameEvents.ChampionRoundMessages.

class ChampionRoundOption {
  final String optionId;
  final String text;
  const ChampionRoundOption({required this.optionId, required this.text});

  factory ChampionRoundOption.fromJson(Map<String, dynamic> j) =>
      ChampionRoundOption(
        optionId: (j['optionId'] ?? j['OptionId'] ?? '').toString(),
        text: (j['text'] ?? j['Text'] ?? '').toString(),
      );
}

/// A live round opened — question + options + answer deadline.
class ChampionRoundStartedDto {
  final String gameEventId;
  final int roundNumber;
  final String questionId;
  final String prompt;
  final List<ChampionRoundOption> options;
  final DateTime deadlineUtc;
  final int aliveCount;
  final int jackpotPool;

  const ChampionRoundStartedDto({
    required this.gameEventId,
    required this.roundNumber,
    required this.questionId,
    required this.prompt,
    required this.options,
    required this.deadlineUtc,
    required this.aliveCount,
    required this.jackpotPool,
  });

  factory ChampionRoundStartedDto.fromJson(Map<String, dynamic> j) {
    String s(String a, String b) => (j[a] ?? j[b] ?? '').toString();
    int i(String a, String b) => (j[a] ?? j[b] ?? 0) as int;
    final rawOptions = (j['options'] ?? j['Options'] ?? const []) as List;
    return ChampionRoundStartedDto(
      gameEventId: s('gameEventId', 'GameEventId'),
      roundNumber: i('roundNumber', 'RoundNumber'),
      questionId: s('questionId', 'QuestionId'),
      prompt: s('prompt', 'Prompt'),
      options: rawOptions
          .map((e) => ChampionRoundOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      deadlineUtc:
          DateTime.tryParse(s('deadlineUtc', 'DeadlineUtc'))?.toUtc() ??
              DateTime.now().toUtc(),
      aliveCount: i('aliveCount', 'AliveCount'),
      jackpotPool: i('jackpotPool', 'JackpotPool'),
    );
  }
}

/// A round resolved — correct answer, who's out, who survives.
class ChampionRoundResolvedDto {
  final String gameEventId;
  final int roundNumber;
  final String correctOptionId;
  final List<String> eliminatedPlayerIds;
  final int survivorsRemaining;
  final bool championAlive;
  final int jackpotPool;

  const ChampionRoundResolvedDto({
    required this.gameEventId,
    required this.roundNumber,
    required this.correctOptionId,
    required this.eliminatedPlayerIds,
    required this.survivorsRemaining,
    required this.championAlive,
    required this.jackpotPool,
  });

  factory ChampionRoundResolvedDto.fromJson(Map<String, dynamic> j) {
    String s(String a, String b) => (j[a] ?? j[b] ?? '').toString();
    int i(String a, String b) => (j[a] ?? j[b] ?? 0) as int;
    final raw = (j['eliminatedPlayerIds'] ??
        j['EliminatedPlayerIds'] ??
        const []) as List;
    return ChampionRoundResolvedDto(
      gameEventId: s('gameEventId', 'GameEventId'),
      roundNumber: i('roundNumber', 'RoundNumber'),
      correctOptionId: s('correctOptionId', 'CorrectOptionId'),
      eliminatedPlayerIds: raw.map((e) => e.toString()).toList(),
      survivorsRemaining: i('survivorsRemaining', 'SurvivorsRemaining'),
      championAlive:
          (j['championAlive'] ?? j['ChampionAlive'] ?? false) as bool,
      jackpotPool: i('jackpotPool', 'JackpotPool'),
    );
  }
}

/// A champion duel opened (the champion called out a challenger). Reuses the
/// round option shape.
class ChampionDuelStartedDto {
  final String gameEventId;
  final String duelId;
  final String championPlayerId;
  final String challengerPlayerId;
  final String questionId;
  final String prompt;
  final List<ChampionRoundOption> options;
  final DateTime deadlineUtc;

  const ChampionDuelStartedDto({
    required this.gameEventId,
    required this.duelId,
    required this.championPlayerId,
    required this.challengerPlayerId,
    required this.questionId,
    required this.prompt,
    required this.options,
    required this.deadlineUtc,
  });

  factory ChampionDuelStartedDto.fromJson(Map<String, dynamic> j) {
    String s(String a, String b) => (j[a] ?? j[b] ?? '').toString();
    final rawOptions = (j['options'] ?? j['Options'] ?? const []) as List;
    return ChampionDuelStartedDto(
      gameEventId: s('gameEventId', 'GameEventId'),
      duelId: s('duelId', 'DuelId'),
      championPlayerId: s('championPlayerId', 'ChampionPlayerId'),
      challengerPlayerId: s('challengerPlayerId', 'ChallengerPlayerId'),
      questionId: s('questionId', 'QuestionId'),
      prompt: s('prompt', 'Prompt'),
      options: rawOptions
          .map((e) => ChampionRoundOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      deadlineUtc:
          DateTime.tryParse(s('deadlineUtc', 'DeadlineUtc'))?.toUtc() ??
              DateTime.now().toUtc(),
    );
  }
}

/// A duel resolved.
class ChampionDuelResolvedDto {
  final String gameEventId;
  final String duelId;
  final String winnerPlayerId;
  final String loserPlayerId;
  final String correctOptionId;
  final bool championAlive;
  final int survivorsRemaining;
  final int jackpotPool;

  const ChampionDuelResolvedDto({
    required this.gameEventId,
    required this.duelId,
    required this.winnerPlayerId,
    required this.loserPlayerId,
    required this.correctOptionId,
    required this.championAlive,
    required this.survivorsRemaining,
    required this.jackpotPool,
  });

  factory ChampionDuelResolvedDto.fromJson(Map<String, dynamic> j) {
    String s(String a, String b) => (j[a] ?? j[b] ?? '').toString();
    int i(String a, String b) => (j[a] ?? j[b] ?? 0) as int;
    return ChampionDuelResolvedDto(
      gameEventId: s('gameEventId', 'GameEventId'),
      duelId: s('duelId', 'DuelId'),
      winnerPlayerId: s('winnerPlayerId', 'WinnerPlayerId'),
      loserPlayerId: s('loserPlayerId', 'LoserPlayerId'),
      correctOptionId: s('correctOptionId', 'CorrectOptionId'),
      championAlive:
          (j['championAlive'] ?? j['ChampionAlive'] ?? false) as bool,
      survivorsRemaining: i('survivorsRemaining', 'SurvivorsRemaining'),
      jackpotPool: i('jackpotPool', 'JackpotPool'),
    );
  }
}

/// Replay-on-join snapshot: the current open round and/or duel.
class ChampionLiveSnapshotDto {
  final String gameEventId;
  final int aliveCount;
  final int jackpotPool;
  final bool isLive;
  final ChampionRoundStartedDto? currentRound;
  final ChampionDuelStartedDto? currentDuel;
  final String? championPlayerId;
  final int duelsUsed;
  final int maxDuels;

  const ChampionLiveSnapshotDto({
    required this.gameEventId,
    required this.aliveCount,
    required this.jackpotPool,
    required this.isLive,
    required this.currentRound,
    required this.currentDuel,
    this.championPlayerId,
    this.duelsUsed = 0,
    this.maxDuels = 0,
  });

  int get duelsRemaining => (maxDuels - duelsUsed).clamp(0, maxDuels);

  factory ChampionLiveSnapshotDto.fromJson(Map<String, dynamic> j) {
    Map<String, dynamic>? asMap(Object? v) =>
        v is Map<String, dynamic> ? v : null;
    final round = asMap(j['currentRound'] ?? j['CurrentRound']);
    final duel = asMap(j['currentDuel'] ?? j['CurrentDuel']);
    final champ = (j['championPlayerId'] ?? j['ChampionPlayerId'])?.toString();
    return ChampionLiveSnapshotDto(
      gameEventId: (j['gameEventId'] ?? j['GameEventId'] ?? '').toString(),
      aliveCount: (j['aliveCount'] ?? j['AliveCount'] ?? 0) as int,
      jackpotPool: (j['jackpotPool'] ?? j['JackpotPool'] ?? 0) as int,
      isLive: (j['isLive'] ?? j['IsLive'] ?? false) as bool,
      currentRound:
          round == null ? null : ChampionRoundStartedDto.fromJson(round),
      currentDuel: duel == null ? null : ChampionDuelStartedDto.fromJson(duel),
      championPlayerId: (champ == null || champ.isEmpty) ? null : champ,
      duelsUsed: (j['duelsUsed'] ?? j['DuelsUsed'] ?? 0) as int,
      maxDuels: (j['maxDuels'] ?? j['MaxDuels'] ?? 0) as int,
    );
  }
}

/// One player in the live match roster (GET /game-events/{id}/participants).
class ChampionParticipant {
  final String playerId;
  final String handle;
  final String displayName;
  final String? avatarUrl;
  final bool isChampion;
  final bool eliminated;

  const ChampionParticipant({
    required this.playerId,
    required this.handle,
    required this.displayName,
    required this.avatarUrl,
    required this.isChampion,
    required this.eliminated,
  });

  factory ChampionParticipant.fromJson(Map<String, dynamic> j) {
    String s(String a, String b) => (j[a] ?? j[b] ?? '').toString();
    return ChampionParticipant(
      playerId: s('playerId', 'PlayerId'),
      handle: s('handle', 'Handle'),
      displayName: (j['displayName'] ?? j['DisplayName'] ?? j['handle'] ?? '')
          .toString(),
      avatarUrl: (j['avatarUrl'] ?? j['AvatarUrl'])?.toString(),
      isChampion: (j['isChampion'] ?? j['IsChampion'] ?? false) as bool,
      eliminated: (j['eliminated'] ?? j['Eliminated'] ?? false) as bool,
    );
  }
}

/// The match ended.
class ChampionMatchEndedDto {
  final String gameEventId;
  final String? winnerPlayerId;
  final bool championDefended;
  final int jackpotAwarded;
  final int roundsPlayed;

  const ChampionMatchEndedDto({
    required this.gameEventId,
    required this.winnerPlayerId,
    required this.championDefended,
    required this.jackpotAwarded,
    required this.roundsPlayed,
  });

  factory ChampionMatchEndedDto.fromJson(Map<String, dynamic> j) {
    String s(String a, String b) => (j[a] ?? j[b] ?? '').toString();
    int i(String a, String b) => (j[a] ?? j[b] ?? 0) as int;
    final winner = (j['winnerPlayerId'] ?? j['WinnerPlayerId'])?.toString();
    return ChampionMatchEndedDto(
      gameEventId: s('gameEventId', 'GameEventId'),
      winnerPlayerId: (winner == null || winner.isEmpty) ? null : winner,
      championDefended:
          (j['championDefended'] ?? j['ChampionDefended'] ?? false) as bool,
      jackpotAwarded: i('jackpotAwarded', 'JackpotAwarded'),
      roundsPlayed: i('roundsPlayed', 'RoundsPlayed'),
    );
  }
}
