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
      deadlineUtc: DateTime.tryParse(s('deadlineUtc', 'DeadlineUtc'))?.toUtc() ??
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
    final raw = (j['eliminatedPlayerIds'] ?? j['EliminatedPlayerIds'] ?? const [])
        as List;
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
