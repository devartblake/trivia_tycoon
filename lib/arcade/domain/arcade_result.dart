import 'arcade_difficulty.dart';
import 'arcade_game_id.dart';

class ArcadeResult {
  final ArcadeGameId gameId;
  final ArcadeDifficulty difficulty;

  /// “Game score” – not coins/XP. Rewards are derived from this.
  final int score;

  /// Session duration.
  final Duration duration;

  /// Optional telemetry: accuracy, streak, moves, etc.
  final Map<String, Object?> metadata;

  const ArcadeResult({
    required this.gameId,
    required this.difficulty,
    required this.score,
    required this.duration,
    this.metadata = const {},
  });
}

class ArcadeRewards {
  final int xp;
  final int coins;
  final int gems;

  const ArcadeRewards({
    required this.xp,
    required this.coins,
    required this.gems,
  });
}
