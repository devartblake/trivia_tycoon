import 'dart:convert';

class SpinResult {
  final String label;
  final String? imagePath;
  final int reward;
  final DateTime timestamp;

  SpinResult({
    required this.label,
    this.imagePath,
    required this.reward,
    required this.timestamp,
  });

  factory SpinResult.fromJson(Map<String, dynamic> json) => SpinResult(
    label: json['label'],
    imagePath: json['imagePath'],
    reward: json['reward'],
    timestamp: DateTime.parse(json['timestamp']),
  );

  Map<String, dynamic> toJson() => {
    'label': label,
    'imagePath': imagePath,
    'reward': reward,
    'timestamp': timestamp.toIso8601String(),
  };

  static String encodeList(List<SpinResult> results) =>
      json.encode(results.map((e) => e.toJson()).toList());

  static List<SpinResult> decodeList(String raw) {
    final List decoded = json.decode(raw);
    return decoded.map((e) => SpinResult.fromJson(e)).toList();
  }
}
