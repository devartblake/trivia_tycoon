import '../../core/services/storage/app_cache_service.dart';

class ArcadeMissionClaimService {
  static const _cacheKey = 'arcade_mission_claims_v1';

  final AppCacheService _cache;

  ArcadeMissionClaimService(this._cache);

  String _todayKey() {
    final now = DateTime.now();
    final y = now.year.toString().padLeft(4, '0');
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  /// Storage shape:
  /// {
  ///   "2026-01-09": { "missionIdA": "2026-01-09T12:34:56Z", ... }
  /// }
  Map<String, dynamic> _readAll() {
    final raw = _cache.get<Map<String, dynamic>>(_cacheKey);
    if (raw == null) return <String, dynamic>{};
    return raw;
  }

  Map<String, dynamic> _readToday() {
    final all = _readAll();
    final key = _todayKey();
    final raw = all[key];
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return <String, dynamic>{};
  }

  bool isClaimedToday(String missionId) {
    final today = _readToday();
    return today.containsKey(missionId);
  }

  Future<void> markClaimedToday(String missionId) async {
    final all = _readAll();
    final key = _todayKey();
    final today = _readToday();

    today[missionId] = DateTime.now().toUtc().toIso8601String();
    all[key] = today;

    await _cache.setJson(_cacheKey, all);
  }

  Future<void> clearToday() async {
    final all = _readAll();
    all.remove(_todayKey());
    await _cache.setJson(_cacheKey, all);
  }
}
