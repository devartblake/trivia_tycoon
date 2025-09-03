class EngagementEntry {
  final DateTime date;
  final int activeUsers;
  final int averageSessionLength;
  final int sessionsPerUser;

  EngagementEntry({
    required this.date,
    required this.activeUsers,
    required this.averageSessionLength,
    required this.sessionsPerUser,
  });

  /// JSON parsing
  factory EngagementEntry.fromJson(Map<String, dynamic> json) {
    return EngagementEntry(
      date: DateTime.parse(json['date']),
      activeUsers: json['activeUsers'] ?? 0,
      averageSessionLength: json['averageSessionLength'] ?? 0,
      sessionsPerUser: json['sessionsPerUser'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'activeUsers': activeUsers,
      'averageSessionLength': averageSessionLength,
      'sessionsPerUser': sessionsPerUser,
    };
  }

  /// Copy with updates
  EngagementEntry copyWith({
    DateTime? date,
    int? activeUsers,
    int? averageSessionLength,
    int? sessionsPerUser,
  }) {
    return EngagementEntry(
      date: date ?? this.date,
      activeUsers: activeUsers ?? this.activeUsers,
      averageSessionLength: averageSessionLength ?? this.averageSessionLength,
      sessionsPerUser: sessionsPerUser ?? this.sessionsPerUser,
    );
  }

  /// 👇 Added fields for your charts and widgets!

  /// Formats the day as "Mon", "Tue", etc.
  String get day {
    return _weekdayShort(date.weekday);
  }

  /// Computes total sessions
  int get sessions {
    return activeUsers * sessionsPerUser;
  }

  static String _weekdayShort(int weekday) {
    const days = [
      'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun',
    ];
    return days[(weekday - 1) % 7];
  }
}
