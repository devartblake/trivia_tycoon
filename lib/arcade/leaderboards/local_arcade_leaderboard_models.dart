import '../domain/arcade_difficulty.dart';
import '../domain/arcade_game_id.dart';

class LocalArcadeScoreEntry {
  final String id; // stable unique id
  final ArcadeGameId gameId;
  final ArcadeDifficulty difficulty;
  final int score;
  final int durationMs;
  final DateTime achievedAtUtc;

  const LocalArcadeScoreEntry({
    required this.id,
    required this.gameId,
    required this.difficulty,
    required this.score,
    required this.durationMs,
    required this.achievedAtUtc,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'gameId': gameId.name,
    'difficulty': difficulty.name,
    'score': score,
    'durationMs': durationMs,
    'achievedAtUtc': achievedAtUtc.toIso8601String(),
  };

  static LocalArcadeScoreEntry fromJson(Map<String, dynamic> json) {
    return LocalArcadeScoreEntry(
      id: (json['id'] as String?) ?? '',
      gameId: ArcadeGameId.values.firstWhere(
            (e) => e.name == (json['gameId'] as String?),
        orElse: () => ArcadeGameId.patternSprint,
      ),
      difficulty: ArcadeDifficulty.values.firstWhere(
            (e) => e.name == (json['difficulty'] as String?),
        orElse: () => ArcadeDifficulty.normal,
      ),
      score: (json['score'] as num?)?.toInt() ?? 0,
      durationMs: (json['durationMs'] as num?)?.toInt() ?? 0,
      achievedAtUtc:
      DateTime.tryParse((json['achievedAtUtc'] as String?) ?? '') ??
          DateTime.now().toUtc(),
    );
  }
}
