class ScanHistoryItem {
  final String value;
  final DateTime timestamp;
  final String type;

  ScanHistoryItem({
    required this.value,
    required this.timestamp,
    required this.type,
  });

  factory ScanHistoryItem.fromJson(Map<String, dynamic> json) {
    return ScanHistoryItem(
      value: json['value'],
      timestamp: DateTime.parse(json['timestamp']),
      type: json['type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'timestamp': timestamp.toIso8601String(),
      'type': type,
    };
  }
}
