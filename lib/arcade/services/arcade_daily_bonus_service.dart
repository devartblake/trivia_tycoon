import '../../core/services/storage/app_cache_service.dart';

class ArcadeDailyBonusService {
  static const _keyRoot = 'arcade_daily_bonus_v1';
  static const _lastClaimDayKey = '$_keyRoot.lastDay';
  static const _claimedKey = '$_keyRoot.claimed';
  static const _streakKey = '$_keyRoot.streak';
  static const _bestStreakKey = '$_keyRoot.bestStreak';

  final AppCacheService _cache;

  ArcadeDailyBonusService(this._cache) {
    _ensureInitialized();
  }

  // ---------------------------------------------------------------------------
  // Reward schedule (adjust freely)
  // ---------------------------------------------------------------------------
  //
  // This schedule is 1-based: Day 1 reward, Day 2 reward, etc.
  // After the last index, we "cap" at the last reward (no wrap).
  static const List<DailyBonusReward> _schedule = <DailyBonusReward>[
    DailyBonusReward(coins: 250, gems: 2),  // Day 1
    DailyBonusReward(coins: 300, gems: 2),  // Day 2
    DailyBonusReward(coins: 350, gems: 3),  // Day 3
    DailyBonusReward(coins: 450, gems: 3),  // Day 4
    DailyBonusReward(coins: 550, gems: 4),  // Day 5
    DailyBonusReward(coins: 700, gems: 4),  // Day 6
    DailyBonusReward(coins: 900, gems: 5),  // Day 7
  ];

  // ---------------------------------------------------------------------------
  // Public API expected by your DailyBonusScreen
  // ---------------------------------------------------------------------------

  /// Alias to match UI expectation.
  int get currentStreak {
    _ensureInitialized();
    return streakDays;
  }

  /// "Today's" reward shown in the UI (what you would get if you claim now).
  DailyBonusReward get todayReward {
    _ensureInitialized();
    final dayIndex = _nextStreakIfClaimedToday();
    return _rewardForStreakDay(dayIndex);
  }

  int get todayCoins => todayReward.coins;
  int get todayGems => todayReward.gems;

  /// Preview the next day's reward (useful for a "Tomorrow" card).
  DailyBonusReward previewTomorrowReward() {
    _ensureInitialized();
    final tomorrowStreak = (_nextStreakIfClaimedToday() + 1);
    return _rewardForStreakDay(tomorrowStreak);
  }

  // ---------------------------------------------------------------------------
  // Existing API (kept intact)
  // ---------------------------------------------------------------------------

  /// yyyy-MM-dd (local calendar day)
  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  bool get isClaimedToday {
    final lastDay = _cache.get<String>(_lastClaimDayKey);
    final claimed = _cache.get<bool>(_claimedKey) ?? false;
    return lastDay == _todayKey() && claimed;
  }

  int get streakDays {
    _ensureInitialized();
    return _cache.get<int>(_streakKey) ?? 0;
  }

  int get bestStreakDays {
    _ensureInitialized();
    return _cache.get<int>(_bestStreakKey) ?? streakDays;
  }

  /// Attempt to claim today's bonus.
  /// Returns true if successful, false if already claimed.
  bool tryClaimToday() {
    final today = _todayKey();

    if (isClaimedToday) {
      return false;
    }

    final lastDay = _cache.get<String>(_lastClaimDayKey);

    final int newStreak;
    if (_isYesterday(lastDay, today)) {
      newStreak = streakDays + 1;
    } else {
      newStreak = 1;
    }

    _cache.put(_lastClaimDayKey, today);
    _cache.put(_claimedKey, true);
    _cache.put(_streakKey, newStreak);

    if (newStreak > bestStreakDays) {
      _cache.put(_bestStreakKey, newStreak);
    }

    return true;
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  /// Reset claim flag automatically when day changes
  void _ensureInitialized() {
    final today = _todayKey();
    final lastDay = _cache.get<String>(_lastClaimDayKey);

    if (lastDay != today) {
      _cache.put(_claimedKey, false);
    }
  }

  bool _isYesterday(String? lastDay, String today) {
    if (lastDay == null) return false;

    try {
      final last = DateTime.parse(lastDay);
      final now = DateTime.parse(today);
      return now.difference(last).inDays == 1;
    } catch (_) {
      return false;
    }
  }

  /// Determines what the streak would be if the user claims right now.
  int _nextStreakIfClaimedToday() {
    if (isClaimedToday) {
      // Already claimed; "today's reward" should reflect the streak you have.
      // This keeps UI stable after claiming.
      return streakDays <= 0 ? 1 : streakDays;
    }

    final today = _todayKey();
    final lastDay = _cache.get<String>(_lastClaimDayKey);

    if (_isYesterday(lastDay, today)) {
      return (streakDays <= 0) ? 1 : (streakDays + 1);
    }
    return 1;
  }

  DailyBonusReward _rewardForStreakDay(int streakDay) {
    // 1-based day -> 0-based index
    final idx = streakDay - 1;

    if (idx < 0) return _schedule.first;
    if (idx >= _schedule.length) return _schedule.last; // cap at last reward
    return _schedule[idx];
  }
}

/// Simple value object used by the UI to display today's/tomorrow's reward.
class DailyBonusReward {
  final int coins;
  final int gems;

  const DailyBonusReward({
    required this.coins,
    required this.gems,
  });

  Map<String, dynamic> toJson() => {
    'coins': coins,
    'gems': gems,
  };

  factory DailyBonusReward.fromJson(Map<String, dynamic> json) {
    return DailyBonusReward(
      coins: (json['coins'] ?? 0) as int,
      gems: (json['gems'] ?? 0) as int,
    );
  }
}