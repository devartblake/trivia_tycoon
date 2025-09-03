class MissionAnalyticsEntry {
  final DateTime date;
  final int missionsCompleted;
  final int missionsSwapped;
  final int xpEarned;
  final String userType; // 'premium' or 'free'

  MissionAnalyticsEntry({
    required this.date,
    required this.missionsCompleted,
    required this.missionsSwapped,
    required this.xpEarned,
    required this.userType,
  });

  factory MissionAnalyticsEntry.fromJson(Map<String, dynamic> json) {
    return MissionAnalyticsEntry(
      date: DateTime.parse(json['date']),
      missionsCompleted: json['missionsCompleted'] ?? 0,
      missionsSwapped: json['missionsSwapped'] ?? 0,
      xpEarned: json['xpEarned'] ?? 0,
      userType: json['userType'] ?? 'free',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'missionsCompleted': missionsCompleted,
      'missionsSwapped': missionsSwapped,
      'xpEarned': xpEarned,
      'userType': userType,
    };
  }

  MissionAnalyticsEntry copyWith({
    DateTime? date,
    int? missionsCompleted,
    int? missionsSwapped,
    int? xpEarned,
    String? userType,
  }) {
    return MissionAnalyticsEntry(
      date: date ?? this.date,
      missionsCompleted: missionsCompleted ?? this.missionsCompleted,
      missionsSwapped: missionsSwapped ?? this.missionsSwapped,
      xpEarned: xpEarned ?? this.xpEarned,
      userType: userType ?? this.userType,
    );
  }
}