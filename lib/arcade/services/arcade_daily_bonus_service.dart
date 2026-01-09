class ArcadeDailyBonusService {
  DateTime? _lastClaimedUtcDate; // track date only in UTC (stable)

  bool get isClaimedToday {
    final last = _lastClaimedUtcDate;
    if (last == null) return false;
    final now = DateTime.now().toUtc();
    return (last.year == now.year && last.month == now.month && last.day == now.day);
  }

  /// Marks claimed if not already. Returns true if newly claimed.
  bool tryClaimToday() {
    if (isClaimedToday) return false;
    _lastClaimedUtcDate = DateTime.now().toUtc();
    return true;
  }
}
