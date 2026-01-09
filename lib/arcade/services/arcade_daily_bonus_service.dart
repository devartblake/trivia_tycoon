import '../../core/services/storage/app_cache_service.dart';

class ArcadeDailyBonusService {
  static const _cacheKey = 'arcade_daily_bonus_utc';

  final AppCacheService _cache;
  DateTime? _lastClaimedUtc;

  ArcadeDailyBonusService(this._cache) {
    _load();
  }

  void _load() {
    final raw = _cache.get<String>(_cacheKey);
    if (raw == null) return;
    _lastClaimedUtc = DateTime.tryParse(raw);
  }

  void _persist() {
    if (_lastClaimedUtc != null) {
      _cache.set(_cacheKey, _lastClaimedUtc!.toIso8601String());
    }
  }

  bool get isClaimedToday {
    final last = _lastClaimedUtc;
    if (last == null) return false;

    final now = DateTime.now().toUtc();
    return last.year == now.year &&
        last.month == now.month &&
        last.day == now.day;
  }

  bool tryClaimToday() {
    if (isClaimedToday) return false;

    _lastClaimedUtc = DateTime.now().toUtc();
    _persist();
    return true;
  }
}
