class PrizeEntry {
  final String prize;
  final DateTime timestamp;

  PrizeEntry({required this.prize, required this.timestamp});

  Map<String, dynamic> toJson() => {
    'prize': prize,
    'timestamp': timestamp.toIso8601String(),
  };

  factory PrizeEntry.fromJson(Map<String, dynamic> json) => PrizeEntry(
    prize: json['prize'],
    timestamp: DateTime.parse(json['timestamp']),
  );
}
