import 'dart:math';

import '../../core/services/storage/app_cache_service.dart';
import '../domain/arcade_result.dart';
import 'arcade_mission_catalog.dart';
import 'arcade_mission_models.dart';

/// Optional contract for remote missions (backend).
/// Implement later using your ApiService / Supabase / FastAPI.
abstract class ArcadeMissionRemoteSource {
  Future<List<ArcadeMission>> fetchMissions({
    required String seasonId,
  });
}

/// How to combine backend missions with local defaults.
enum ArcadeMissionRemotePolicy {
  /// Use remote missions only (fallback to local if remote empty).
  replace,

  /// Merge remote + local by id (remote overrides local if same id).
  mergeById,

  /// Prefer local always (remote only cached for later / debugging).
  preferLocal,
}

class ArcadeMissionService {
  // V2 keys (avoid collisions with older daily-only storage)
  static const _progressKey = 'arcade_missions_progress_v2';
  static const _rolloverKey = 'arcade_missions_rollover_v2';
  static const _missionDefsKey = 'arcade_missions_defs_v2';

  final AppCacheService _cache;

  /// Optional remote source to allow missions to be managed by backend.
  final ArcadeMissionRemoteSource? _remote;

  /// Season identifier can later be provided by backend config.
  /// For now, keep it stable and change it when you want a full season reset.
  final String _seasonId;

  /// Policy for combining backend missions and local catalog.
  final ArcadeMissionRemotePolicy _remotePolicy;

  late List<ArcadeMission> _missions;

  /// progressByMissionId
  late Map<String, ArcadeMissionProgress> _progress;

  /// In-process claim mutex (prevents same-frame double execution).
  final Set<String> _claimInFlight = <String>{};

  ArcadeMissionService(
      this._cache, {
        ArcadeMissionRemoteSource? remote,
        String seasonId = 'season_v1',
        ArcadeMissionRemotePolicy remotePolicy = ArcadeMissionRemotePolicy.replace,
      })  : _remote = remote,
        _seasonId = seasonId,
        _remotePolicy = remotePolicy {
    _ensureLoadedAndRolledOver();
  }

  /// Keep UI compatibility.
  List<ArcadeMission> get missions => _missions;

  bool get isReady => true;

  ArcadeMissionProgress progressFor(String missionId) {
    return _progress[missionId] ??
        ArcadeMissionProgress(
          missionId: missionId,
          current: 0,
          claimed: false,
        );
  }

  // -----------------------------
  // Core lifecycle + resets
  // -----------------------------

  void _ensureLoadedAndRolledOver() {
    _missions = _loadMissionDefinitions();

    // Load stored progress
    _progress = _loadStoredProgress();

    // Apply rollover per tier (daily/weekly/season)
    _applyTierRollovers();

    // Ensure all current missions exist in progress map
    _ensureAllMissionsHaveProgress();

    // Persist (canonicalize storage after any reset/hydration)
    _persistProgress();
  }

  List<ArcadeMission> _loadMissionDefinitions() {
    // 1) Prefer cached remote missions if present
    final cachedRemote = _loadCachedRemoteMissions();

    // 2) Local catalog fallback (must include tier+type)
    final local = ArcadeMissionCatalog.allMissions(seasonId: _seasonId);

    // 3) Apply policy
    switch (_remotePolicy) {
      case ArcadeMissionRemotePolicy.preferLocal:
        return local;

      case ArcadeMissionRemotePolicy.replace:
        if (cachedRemote.isNotEmpty) return cachedRemote;
        return local;

      case ArcadeMissionRemotePolicy.mergeById:
        return _mergeMissionsById(local: local, remote: cachedRemote);
    }
  }

  List<ArcadeMission> _loadCachedRemoteMissions() {
    final cached = _cache.get<List<dynamic>>(_missionDefsKey);
    if (cached == null || cached.isEmpty) return const <ArcadeMission>[];

    final parsed = <ArcadeMission>[];
    for (final item in cached) {
      if (item is Map) {
        try {
          parsed.add(ArcadeMission.fromJson(Map<String, dynamic>.from(item)));
        } catch (_) {
          // Ignore malformed entries; do not crash initialization.
        }
      }
    }
    return parsed;
  }

  List<ArcadeMission> _mergeMissionsById({
    required List<ArcadeMission> local,
    required List<ArcadeMission> remote,
  }) {
    if (remote.isEmpty) return local;

    final out = <String, ArcadeMission>{};

    // Start with local
    for (final m in local) {
      out[m.id] = m;
    }

    // Remote overrides local by id
    for (final m in remote) {
      out[m.id] = m;
    }

    // Stable order: daily -> weekly -> season, then title
    final list = out.values.toList();
    list.sort((a, b) {
      final t = a.tier.index.compareTo(b.tier.index);
      if (t != 0) return t;
      return a.title.compareTo(b.title);
    });

    return list;
  }

  Map<String, ArcadeMissionProgress> _loadStoredProgress() {
    final stored = _cache.get<Map<String, dynamic>>(_progressKey);
    if (stored == null || stored.isEmpty) return {};

    final out = <String, ArcadeMissionProgress>{};
    for (final entry in stored.entries) {
      final id = entry.key;
      final raw = entry.value;
      if (raw is Map) {
       try {
          out[id] =
              ArcadeMissionProgress.fromJson(Map<String, dynamic>.from(raw));
        } catch (_) {
          // Ignore malformed entries; do not crash initialization.
        }
      }
    }
    return out;
  }

  void _ensureAllMissionsHaveProgress() {
    // Ensures entries exist for active missions
    for (final m in _missions) {
      _progress[m.id] ??= ArcadeMissionProgress(
        missionId: m.id,
        current: 0,
        claimed: false,
      );
    }

    // Prune progress for missions that no longer exist in definitions
    final ids = _missions.map((m) => m.id).toSet();
    _progress.removeWhere((id, _) => !ids.contains(id));
  }

  void _applyTierRollovers() {
    final rollover = _cache.get<Map<String, dynamic>>(_rolloverKey) ?? <String, dynamic>{};

    final dailyToken = _dailyTokenUtc();
    final weeklyToken = _weeklyTokenUtc();
    final seasonToken = _seasonId;

    final lastDaily = rollover['daily']?.toString();
    final lastWeekly = rollover['weekly']?.toString();
    final lastSeason = rollover['season']?.toString();

    final dailyChanged = lastDaily != dailyToken;
    final weeklyChanged = lastWeekly != weeklyToken;
    final seasonChanged = lastSeason != seasonToken;

    if (dailyChanged) _resetTier(ArcadeMissionTier.daily);
    if (weeklyChanged) _resetTier(ArcadeMissionTier.weekly);
    if (seasonChanged) _resetTier(ArcadeMissionTier.season);

    rollover['daily'] = dailyToken;
    rollover['weekly'] = weeklyToken;
    rollover['season'] = seasonToken;

    // Persist rollover tokens
    _cache.setJson(_rolloverKey, rollover);
  }

  void _resetTier(ArcadeMissionTier tier) {
    for (final m in _missions.where((x) => x.tier == tier)) {
      _progress[m.id] = ArcadeMissionProgress(
        missionId: m.id,
        current: 0,
        claimed: false,
        claimedAtUtcIso: null,
      );
    }
  }

  String _dailyTokenUtc() {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  /// ISO-ish week token (good enough for weekly resets).
  String _weeklyTokenUtc() {
    final now = DateTime.now().toUtc();
    // Convert to "Thursday week" rule commonly used to compute ISO week
    final weekday = now.weekday; // 1..7 (Mon..Sun)
    final thursday = now.add(Duration(days: 4 - weekday));
    final yearStart = DateTime.utc(thursday.year, 1, 1);
    final weekNumber = ((thursday.difference(yearStart).inDays) / 7).floor() + 1;
    return '${thursday.year}-W${weekNumber.toString().padLeft(2, '0')}';
  }

  void _persistProgress() {
    final payload = <String, dynamic>{};
    _progress.forEach((k, v) => payload[k] = v.toJson());
    _cache.setJson(_progressKey, payload);
  }

  // -----------------------------
  // Backend extensibility
  // -----------------------------

  /// Optional: Call this on app start or Admin refresh.
  /// It will cache backend missions for offline use.
  ///
  /// Safe behavior:
  /// - Does not crash if backend returns malformed missions.
  /// - After refresh, ensures progress map is updated and rollovers re-applied.
  Future<void> refreshFromBackend() async {
    if (_remote == null) return;

    final fresh = await _remote!.fetchMissions(seasonId: _seasonId);
    if (fresh.isEmpty) return;

    // Cache remote missions for offline use
    await _cache.setJson(_missionDefsKey, fresh.map((m) => m.toJson()).toList());

    // Reload with policy
    _missions = _loadMissionDefinitions();

    _ensureAllMissionsHaveProgress();
    _applyTierRollovers();
    _persistProgress();
  }

  // -----------------------------
  // Progress updates from runs
  // -----------------------------

  /// Call this from ArcadeGameShell.completeRun().
  void onArcadeRunCompleted(ArcadeResult result) {
    final meta = result.metadata;
    final isNewPb = meta['isNewPb'] == true;

    for (final m in _missions) {
      final p = progressFor(m.id);

      // Claimed missions are locked; do not allow re-progress until next reset.
      if (p.claimed) continue;

      switch (m.type) {
        case ArcadeMissionType.playRuns:
        // Optional filter by gameId
          if (m.gameId == null || result.gameId == m.gameId) {
            _progress[m.id] = p.copyWith(
              current: min(p.current + 1, m.target),
            );
          }
          break;

        case ArcadeMissionType.scoreAtLeast:
          if (m.gameId == null || result.gameId == m.gameId) {
            if (result.score >= m.target) {
              _progress[m.id] = p.copyWith(current: m.target);
            }
          }
          break;

        case ArcadeMissionType.setNewPb:
          if (isNewPb) {
            if (m.gameId == null || result.gameId == m.gameId) {
              _progress[m.id] = p.copyWith(
                current: min(p.current + 1, m.target),
              );
            }
          }
          break;
      }
    }

    _persistProgress();
  }

  // -----------------------------
  // Claim / anti-abuse
  // -----------------------------

  bool canClaim(String missionId) {
    final m = _missions.firstWhere((x) => x.id == missionId);
    final p = progressFor(missionId);
    return !p.claimed && p.current >= m.target;
  }

  /// Atomic claim gate:
  /// - prevents double-claim even if UI calls twice quickly
  /// - persists immediately (survives restarts)
  /// Returns true only if the claim is accepted.
  bool tryClaim(String missionId) {
    // In-frame mutex
    if(_claimInFlight.contains(missionId)) return false;
    _claimInFlight.add(missionId);

    // Actual claim ()
    try {
      final m = _missions.firstWhere((x) => x.id == missionId);
      final p = progressFor(missionId);

      // Hard lock: once claimed, always false until tier reset.
      if (p.claimed) return false;

      // Not complete
      if (p.current < m.target) return false;

      _progress[missionId] = p.copyWith(
        claimed: true,
        claimedAtUtcIso: DateTime.now().toUtc().toIso8601String(),
      );

      // Persist immediately so restart/tap-spam cannot bypass.
      _persistProgress();
      return true;
    } finally {
      _claimInFlight.remove(missionId);
    }
  }

  /// Keep existing method for UI compatibility.
  /// Make it safe/idempotent.
  void markClaimed(String missionId) {
    // If already claimed or not claimable, do nothing.
    tryClaim(missionId);
  }

  // -----------------------------
  // Optional helpers (useful for Step 8C screens)
  // -----------------------------

  /// Convenience: missions by tier for future screens (Daily/Weekly/Season pages).
  List<ArcadeMission> missionsForTier(ArcadeMissionTier tier) =>
      _missions.where((m) => m.tier == tier).toList();

  /// Convenience: percent complete 0..1 (UI can render progress bars easily).
  double progressRatio(String missionId) {
    final m = _missions.firstWhere((x) => x.id == missionId);
    final p = progressFor(missionId);
    if (m.target <= 0) return 0.0;
    return (p.current / m.target).clamp(0.0, 1.0);
  }
}
