import 'dart:math';

import '../../core/services/storage/app_cache_service.dart';
import '../domain/arcade_difficulty.dart';
import '../domain/arcade_game_id.dart';
import '../domain/arcade_result.dart';
import 'local_arcade_leaderboard_models.dart';

class LocalArcadeLeaderboardService {
  static const _cacheKey = 'arcade_local_leaderboards_v1';

  final AppCacheService _cache;

  /// Map key: "game|difficulty" -> list of entries (sorted)
  final Map<String, List<LocalArcadeScoreEntry>> _boards = {};

  LocalArcadeLeaderboardService(this._cache) {
    _load();
  }

  String _key(ArcadeGameId gameId, ArcadeDifficulty difficulty) =>
      '${gameId.name}|${difficulty.name}';

  void _load() {
    final raw = _cache.get<Map<String, dynamic>>(_cacheKey);
    if (raw == null) return;

    for (final e in raw.entries) {
      final listRaw = e.value;
      if (listRaw is List) {
        final parsed = <LocalArcadeScoreEntry>[];
        for (final item in listRaw) {
          if (item is Map<String, dynamic>) {
            parsed.add(LocalArcadeScoreEntry.fromJson(item));
          }
        }
        _boards[e.key] = _sort(parsed);
      }
    }
  }

  void _persist() {
    final out = <String, dynamic>{};
    _boards.forEach((k, v) {
      out[k] = v.map((x) => x.toJson()).toList();
    });
    _cache.setJson(_cacheKey, out);
  }

  List<LocalArcadeScoreEntry> _sort(List<LocalArcadeScoreEntry> list) {
    // Score desc, then duration asc, then achievedAt desc
    list.sort((a, b) {
      final s = b.score.compareTo(a.score);
      if (s != 0) return s;
      final d = a.durationMs.compareTo(b.durationMs);
      if (d != 0) return d;
      return b.achievedAtUtc.compareTo(a.achievedAtUtc);
    });
    return list;
  }

  /// Returns top N (default 10) for a specific board.
  List<LocalArcadeScoreEntry> top(
      ArcadeGameId gameId,
      ArcadeDifficulty difficulty, {
        int limit = 10,
      }) {
    final k = _key(gameId, difficulty);
    final list = _boards[k] ?? const <LocalArcadeScoreEntry>[];
    return list.take(limit).toList();
  }

  /// Returns a merged view across difficulties for the game (top N overall).
  List<LocalArcadeScoreEntry> topForGame(ArcadeGameId gameId, {int limit = 10}) {
    final all = <LocalArcadeScoreEntry>[];
    for (final d in ArcadeDifficulty.values) {
      all.addAll(top(gameId, d, limit: limit));
    }
    return _sort(all).take(limit).toList();
  }

  /// Add a run result. Keeps only top `maxEntries` per game+difficulty.
  void recordRun(ArcadeResult result, {int maxEntries = 25}) {
    final k = _key(result.gameId, result.difficulty);
    final list = List<LocalArcadeScoreEntry>.from(_boards[k] ?? const []);

    final id = _makeEntryId(result);
    list.add(
      LocalArcadeScoreEntry(
        id: id,
        gameId: result.gameId,
        difficulty: result.difficulty,
        score: result.score,
        durationMs: result.duration.inMilliseconds,
        achievedAtUtc: DateTime.now().toUtc(),
      ),
    );

    final sorted = _sort(list);

    // Enforce cap
    _boards[k] = sorted.take(maxEntries).toList();
    _persist();
  }

  /// Clear all boards
  void clearAll() {
    _boards.clear();
    _persist();
  }

  String _makeEntryId(ArcadeResult r) {
    // Deterministic-enough without extra deps
    final ms = DateTime.now().microsecondsSinceEpoch;
    final salt = Random().nextInt(1 << 20);
    return '${r.gameId.name}-${r.difficulty.name}-${r.score}-$ms-$salt';
  }
}
