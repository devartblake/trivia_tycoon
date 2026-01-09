import '../domain/arcade_difficulty.dart';
import '../domain/arcade_game_id.dart';
import '../domain/arcade_result.dart';

class ArcadePersonalBestService {
  final Map<String, int> _bestScores = {}; // key: gameId|difficulty

  String _key(ArcadeGameId gameId, ArcadeDifficulty difficulty) => '${gameId.name}|${difficulty.name}';

  int getBest(ArcadeGameId gameId, ArcadeDifficulty difficulty) {
    return _bestScores[_key(gameId, difficulty)] ?? 0;
  }

  /// Returns true if this result sets a new personal best.
  bool trySetBest(ArcadeResult result) {
    final k = _key(result.gameId, result.difficulty);
    final prev = _bestScores[k] ?? 0;
    if (result.score > prev) {
      _bestScores[k] = result.score;
      return true;
    }
    return false;
  }
}
