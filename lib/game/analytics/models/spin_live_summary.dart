class SpinLiveSummary {
  final int todayCount;
  final int dailyLimit;
  final int weeklyCount;
  final int totalSpins;
  final bool canSpin;
  final int spinsRemaining;
  final double rewardPoints;
  final String userName;
  final String userId;
  final DateTime snapshotAt;
  final String source;

  const SpinLiveSummary({
    required this.todayCount,
    required this.dailyLimit,
    required this.weeklyCount,
    required this.totalSpins,
    required this.canSpin,
    required this.spinsRemaining,
    required this.rewardPoints,
    required this.userName,
    required this.userId,
    required this.snapshotAt,
    required this.source,
  });

  factory SpinLiveSummary.fromMap(
    Map<String, dynamic> map, {
    required String fallbackUserName,
    required String fallbackUserId,
    required String source,
  }) {
    final rawTimestamp = map['snapshot_at'] ?? map['timestamp'] ?? map['date'];

    return SpinLiveSummary(
      todayCount: (map['today_count'] as num?)?.toInt() ?? 0,
      dailyLimit: (map['daily_limit'] as num?)?.toInt() ?? 0,
      weeklyCount: (map['weekly_count'] as num?)?.toInt() ?? 0,
      totalSpins: (map['total_spins'] as num?)?.toInt() ?? 0,
      canSpin: map['can_spin'] as bool? ?? false,
      spinsRemaining: (map['spins_remaining'] as num?)?.toInt() ?? 0,
      rewardPoints: (map['reward_points'] as num?)?.toDouble() ?? 0,
      userName: (map['user_name'] as String?)?.trim().isNotEmpty == true
          ? map['user_name'] as String
          : fallbackUserName,
      userId: (map['user_id'] as String?)?.trim().isNotEmpty == true
          ? map['user_id'] as String
          : fallbackUserId,
      snapshotAt:
          DateTime.tryParse(rawTimestamp?.toString() ?? '') ?? DateTime.now(),
      source: source,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'today_count': todayCount,
      'daily_limit': dailyLimit,
      'weekly_count': weeklyCount,
      'total_spins': totalSpins,
      'can_spin': canSpin,
      'spins_remaining': spinsRemaining,
      'reward_points': rewardPoints,
      'user_name': userName,
      'user_id': userId,
      'snapshot_at': snapshotAt.toIso8601String(),
      'source': source,
    };
  }

  /// Used to suppress duplicate UI/log/analytics updates.
  String get dedupeKey => [
        todayCount,
        dailyLimit,
        weeklyCount,
        totalSpins,
        canSpin,
        spinsRemaining,
        rewardPoints,
        userId,
        snapshotAt.toIso8601String(),
        source,
      ].join('|');
}
