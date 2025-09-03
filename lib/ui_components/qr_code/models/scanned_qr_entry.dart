import 'package:uuid/uuid.dart';
import '../utils/qr_scan_format_utils.dart';

class ScannedQrEntry {
  final String id;
  final String text;
  final QrContentType type;
  final DateTime timestamp;

  ScannedQrEntry({
    required this.id,
    required this.text,
    required this.type,
    required this.timestamp,
  });

  /// Create a new scan from text (auto assigns ID, type, timestamp)
  factory ScannedQrEntry.fromScan(String raw) {
    return ScannedQrEntry(
      id: const Uuid().v4(),
      text: raw,
      type: QrFormatUtils.detectType(raw),
      timestamp: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'type': type.name,
    'timestamp': timestamp.toIso8601String(),
  };

  factory ScannedQrEntry.fromJson(Map<String, dynamic> json) {
    return ScannedQrEntry(
      id: json['id'],
      text: json['text'],
      type: QrFormatUtils.fromName(json['type']),
      timestamp: DateTime.parse(json['timestamp']),
    );
  }
}
