import '../../core/services/storage/app_cache_service.dart';
import '../domain/arcade_result.dart';
import 'arcade_mission_catalog.dart';
import 'arcade_mission_models.dart';

class ArcadeMissionService {
  static const _cacheKey = 'arcade_daily_missions_v1';
  static const _dateKey = 'arcade_daily_missions_date_utc_v1';

  final AppCacheService _cache;

  late List<ArcadeMission> _missions;
  late Map<String, ArcadeMissionProgress> _progress;

  ArcadeMissionService(this._cache) {
    _ensureLoadedForToday();
  }

  List<ArcadeMission> get missions => _missions;

  ArcadeMissionProgress progressFor(String missionId) {
    return _progress[missionId] ??
        ArcadeMissionProgress(missionId: missionId, current: 0, claimed: false);
  }

  bool get isReady => true;

  void _ensureLoadedForToday() {
    final now = DateTime.now().toUtc();
    final todayStr = '${now.year}-${now.month}-${now.day}';

    final last = _cache.get<String>(_dateKey);

    if (last != todayStr) {
      // reset for new day
      _missions = ArcadeMissionCatalog.dailyMissions();
      _progress = {
        for (final m in _missions)
          m.id: ArcadeMissionProgress(missionId: m.id, current: 0, claimed: false),
      };
      _cache.set(_dateKey, todayStr);
      _persist();
      return;
    }

    // load existing
    _missions = ArcadeMissionCatalog.dailyMissions();
    final stored = _cache.get<Map<String, dynamic>>(_cacheKey) ?? const {};

    _progress = {};
    for (final m in _missions) {
      final raw = stored[m.id];
      if (raw is Map<String, dynamic>) {
        _progress[m.id] = ArcadeMissionProgress.fromJson(raw);
      } else {
        _progress[m.id] = ArcadeMissionProgress(missionId: m.id, current: 0, claimed: false);
      }
    }
  }

  void _persist() {
    final payload = <String, dynamic>{};
    _progress.forEach((k, v) => payload[k] = v.toJson());
    _cache.setJson(_cacheKey, payload);
  }

  /// Call this from ArcadeGameShell.completeRun().
  void onArcadeRunCompleted(ArcadeResult result) {
    // Basic signals
    final meta = result.metadata ?? const <String, dynamic>{};
    final isNewPb = meta['isNewPb'] == true;

    for (final m in _missions) {
      final p = progressFor(m.id);
      if (p.claimed) continue;

      switch (m.type) {
        case ArcadeMissionType.playRuns:
          _progress[m.id] = p.copyWith(current: (p.current + 1).clamp(0, m.target));
          break;

        case ArcadeMissionType.scoreAtLeast:
          if (m.gameId != null && result.gameId == m.gameId) {
            if (result.score >= m.target) {
              _progress[m.id] = p.copyWith(current: m.target);
            }
          }
          break;

        case ArcadeMissionType.setNewPb:
          if (isNewPb) {
            _progress[m.id] = p.copyWith(current: (p.current + 1).clamp(0, m.target));
          }
          break;
      }
    }

    _persist();
  }

  bool canClaim(String missionId) {
    final m = _missions.firstWhere((x) => x.id == missionId);
    final p = progressFor(missionId);
    return !p.claimed && p.current >= m.target;
  }

  /// Mark claimed (does not award currency; caller does).
  void markClaimed(String missionId) {
    final p = progressFor(missionId);
    _progress[missionId] = p.copyWith(claimed: true);
    _persist();
  }
}
