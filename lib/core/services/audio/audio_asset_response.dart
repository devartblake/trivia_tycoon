/// Response model for the backend audio-asset endpoint.
///
/// Backend contract:
///   GET /v1/assets/audio/songs/{filename}
///   → { presignedUrl, expiresAt, contentType?, cacheHints?: { maxAgeSeconds } }
class AudioAssetResponse {
  final String presignedUrl;
  final DateTime expiresAt;
  final String contentType;
  final Duration? cacheDuration;

  const AudioAssetResponse({
    required this.presignedUrl,
    required this.expiresAt,
    required this.contentType,
    this.cacheDuration,
  });

  factory AudioAssetResponse.fromJson(Map<String, dynamic> json) {
    final cacheHints = json['cacheHints'];
    Duration? cacheDuration;
    if (cacheHints is Map && cacheHints['maxAgeSeconds'] is int) {
      cacheDuration = Duration(seconds: cacheHints['maxAgeSeconds'] as int);
    }

    return AudioAssetResponse(
      presignedUrl: json['presignedUrl'] as String,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      contentType: (json['contentType'] as String?) ?? 'audio/mpeg',
      cacheDuration: cacheDuration,
    );
  }
}
