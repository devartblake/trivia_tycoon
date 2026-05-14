/// Describes a single downloadable server asset.
///
/// The server returns a list of these at its manifest endpoint.
/// The client compares the version/sha256 against locally stored metadata
/// to decide whether a download is needed.
class AssetManifestEntry {
  /// Logical key that identifies this asset (e.g. `'questions/general'`).
  /// Used as the storage file name and lookup key.
  final String key;

  /// Full URL to download the raw asset content.
  final String url;

  /// Expected SHA-256 hex digest of the downloaded bytes (for integrity check).
  final String sha256;

  /// Opaque version string (e.g. `'v3'`, `'2025-06-01'`).
  /// Used to detect staleness without re-downloading.
  final String version;

  /// Expected size in bytes (used for progress reporting; 0 = unknown).
  final int sizeBytes;

  const AssetManifestEntry({
    required this.key,
    required this.url,
    required this.sha256,
    required this.version,
    this.sizeBytes = 0,
  });

  factory AssetManifestEntry.fromJson(Map<String, dynamic> j) {
    return AssetManifestEntry(
      key: j['key'] as String? ?? '',
      url: j['url'] as String? ?? '',
      sha256: j['sha256'] as String? ?? '',
      version: j['version'] as String? ?? '',
      sizeBytes: j['sizeBytes'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'url': url,
        'sha256': sha256,
        'version': version,
        'sizeBytes': sizeBytes,
      };
}

/// Metadata persisted locally once an asset has been downloaded successfully.
class DownloadedAssetRecord {
  final String key;
  final String version;
  final String sha256;
  final String downloadedAt; // ISO-8601 UTC

  const DownloadedAssetRecord({
    required this.key,
    required this.version,
    required this.sha256,
    required this.downloadedAt,
  });

  factory DownloadedAssetRecord.fromJson(Map<String, dynamic> j) {
    return DownloadedAssetRecord(
      key: j['key'] as String? ?? '',
      version: j['version'] as String? ?? '',
      sha256: j['sha256'] as String? ?? '',
      downloadedAt: j['downloadedAt'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'key': key,
        'version': version,
        'sha256': sha256,
        'downloadedAt': downloadedAt,
      };
}
