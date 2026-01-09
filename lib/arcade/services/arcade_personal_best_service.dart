import '../../core/services/storage/app_cache_service.dart';
import '../domain/arcade_difficulty.dart';
import '../domain/arcade_game_id.dart';
import '../domain/arcade_result.dart';

class ArcadePersonalBestService {
  static const _cacheKey = 'arcade_pb_v1';

  final AppCacheService _cache;
  final Map<String, int> _bestScores = {};

  ArcadePersonalBestService(this._cache) {
    _load();
  }

  String _key(ArcadeGameId gameId, ArcadeDifficulty difficulty) =>
      '${gameId.name}|${difficulty.name}';

  void _load() {
    final stored = _cache.get<Map<String, dynamic>>(_cacheKey);
    if (stored == null) return;

    for (final entry in stored.entries) {
      final value = entry.value;
      if (value is int) {
        _bestScores[entry.key] = value;
      }
    }
  }

  void _persist() {
    _cache.setJson(_cacheKey, _bestScores);
  }

  int getBest(ArcadeGameId gameId, ArcadeDifficulty difficulty) {
    return _bestScores[_key(gameId, difficulty)] ?? 0;
  }

  bool trySetBest(ArcadeResult result) {
    final k = _key(result.gameId, result.difficulty);
    final prev = _bestScores[k] ?? 0;

    if (result.score > prev) {
      _bestScores[k] = result.score;
      _persist();
      return true;
    }
    return false;
  }
}
