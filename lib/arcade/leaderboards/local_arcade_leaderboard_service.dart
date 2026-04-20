import 'dart:math';

import '../../core/services/storage/app_cache_service.dart';
import '../domain/arcade_difficulty.dart';
import '../domain/arcade_game_id.dart';
import '../domain/arcade_result.dart';
import 'local_arcade_leaderboard_models.dart';

/// Local (on-device) leaderboards per game + difficulty.
///
/// Storage:
/// - Keyed by "game|difficulty"
/// - Persisted to AppCacheService as a JSON map under [_cacheKey]
///
/// Sort order:
/// 1) score DESC
/// 2) duration ASC
/// 3) achievedAtUtc DESC
class LocalArcadeLeaderboardService {
  static const String _cacheKey = 'arcade_local_leaderboards_v1';

  final AppCacheService _cache;

  /// Map key: "game|difficulty" -> list of entries (sorted)
  final Map<String, List<LocalArcadeScoreEntry>> _boards = {};

  LocalArcadeLeaderboardService(this._cache) {
    _load();
  }

  String _key(ArcadeGameId gameId, ArcadeDifficulty difficulty) =>
      '${gameId.name}|${difficulty.name}';

  void _load() {
    final raw = _cache.getJsonMap(_cacheKey);
    if (raw == null) return;

    for (final entry in raw.entries) {
      final value = entry.value;

      // Expect: value is List<Map<String,dynamic>>
      if (value is List) {
        final parsed = <LocalArcadeScoreEntry>[];

        for (final item in value) {
          if (item is Map<String, dynamic>) {
            parsed.add(LocalArcadeScoreEntry.fromJson(item));
          } else if (item is Map) {
            // Safety: normalize dynamic map keys
            parsed.add(
              LocalArcadeScoreEntry.fromJson(
                Map<String, dynamic>.from(
                  item.map((k, v) => MapEntry(k.toString(), v)),
                ),
              ),
            );
          }
        }

        _boards[entry.key] = _sort(parsed);
      }
    }
  }

  Future<void> _persist() async {
    final out = <String, dynamic>{};
    _boards.forEach((k, v) {
      out[k] = v.map((x) => x.toJson()).toList();
    });

    // Store as JSON for stable decoding.
    await _cache.setJson(_cacheKey, out);
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
  List<LocalArcadeScoreEntry> topForGame(
    ArcadeGameId gameId, {
    int limit = 10,
  }) {
    final all = <LocalArcadeScoreEntry>[];
    for (final d in ArcadeDifficulty.values) {
      all.addAll(top(gameId, d, limit: limit));
    }
    return _sort(all).take(limit).toList();
  }

  /// Add a run result.
  /// Keeps only top `maxEntries` per game+difficulty.
  Future<void> recordRun(
    ArcadeResult result, {
    int maxEntries = 25,
  }) async {
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

    await _persist();
  }

  /// Clear all boards
  Future<void> clearAll() async {
    _boards.clear();
    await _persist();
  }

  /// Clear for a specific game+difficulty
  Future<void> clearBoard(
    ArcadeGameId gameId,
    ArcadeDifficulty difficulty,
  ) async {
    final k = _key(gameId, difficulty);
    _boards.remove(k);
    await _persist();
  }

  /// Returns the best entry for a board (or null if none).
  LocalArcadeScoreEntry? best(
    ArcadeGameId gameId,
    ArcadeDifficulty difficulty,
  ) {
    final k = _key(gameId, difficulty);
    final list = _boards[k];
    if (list == null || list.isEmpty) return null;
    return list.first;
  }

  /// Returns rank (1-based) of a score entry by id, or null if not found.
  int? rankOf(
    ArcadeGameId gameId,
    ArcadeDifficulty difficulty,
    String entryId,
  ) {
    final k = _key(gameId, difficulty);
    final list = _boards[k];
    if (list == null) return null;

    for (var i = 0; i < list.length; i++) {
      if (list[i].id == entryId) return i + 1;
    }
    return null;
  }

  /// True if the provided result would qualify as a new personal best
  /// for the given board under the same ranking rules.
  bool wouldBeNewBest(ArcadeResult result) {
    final current = best(result.gameId, result.difficulty);
    if (current == null) return true;

    // Compare with sort order:
    // score desc, duration asc, achievedAt desc (achievedAt irrelevant for comparison here)
    if (result.score > current.score) return true;
    if (result.score < current.score) return false;

    final durationMs = result.duration.inMilliseconds;
    if (durationMs < current.durationMs) return true;
    if (durationMs > current.durationMs) return false;

    // Same score + same duration -> treat as not a PB
    return false;
  }

  String _makeEntryId(ArcadeResult r) {
    // Deterministic-enough without extra deps
    final us = DateTime.now().microsecondsSinceEpoch;
    final salt = Random().nextInt(1 << 20);
    return '${r.gameId.name}-${r.difficulty.name}-${r.score}-$us-$salt';
  }
}
