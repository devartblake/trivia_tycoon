class RetentionEntry {
  final DateTime date;
  final int day1Retention;
  final int day7Retention;
  final int day30Retention;

  RetentionEntry({
    required this.date,
    required this.day1Retention,
    required this.day7Retention,
    required this.day30Retention,
  });

  factory RetentionEntry.fromJson(Map<String, dynamic> json) {
    return RetentionEntry(
      date: DateTime.parse(json['date']),
      day1Retention: json['day1Retention'] ?? 0,
      day7Retention: json['day7Retention'] ?? 0,
      day30Retention: json['day30Retention'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String(),
      'day1Retention': day1Retention,
      'day7Retention': day7Retention,
      'day30Retention': day30Retention,
    };
  }

  RetentionEntry copyWith({
    DateTime? date,
    int? day1Retention,
    int? day7Retention,
    int? day30Retention,
  }) {
    return RetentionEntry(
      date: date ?? this.date,
      day1Retention: day1Retention ?? this.day1Retention,
      day7Retention: day7Retention ?? this.day7Retention,
      day30Retention: day30Retention ?? this.day30Retention,
    );
  }


  /// New computed field based on day1Retention
  double get retentionPercentage => day1Retention.toDouble();

  /// New computed field to get short day label
  String get day => _formatDay(date);

  /// Private helper to format day name (e.g., "Mon", "Tue", etc.)
  static String _formatDay(DateTime date) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return weekdays[date.weekday % 7];
  }
}
