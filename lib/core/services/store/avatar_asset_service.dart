import 'package:logging/logging.dart';
import '../../networking/synaptix_api_client.dart';

class AvatarAssetResponse {
  final String presignedUrl;
  final String? thumbnailUrl;
  final DateTime expiresAt;
  final String? sha256;
  final String archiveFormat;

  const AvatarAssetResponse({
    required this.presignedUrl,
    this.thumbnailUrl,
    required this.expiresAt,
    this.sha256,
    this.archiveFormat = 'zip',
  });

  factory AvatarAssetResponse.fromJson(Map<String, dynamic> json) {
    return AvatarAssetResponse(
      presignedUrl: json['presignedUrl'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      sha256: json['sha256'] as String?,
      archiveFormat: (json['archiveFormat'] as String?) ?? 'zip',
    );
  }
}

/// Fetches presigned MinIO URLs for 3D avatar archives from the backend.
///
/// Endpoint: GET /v1/assets/avatars/{avatarId}
/// Response: { presignedUrl, thumbnailUrl, expiresAt, sha256?, archiveFormat }
///
/// Caches each URL until 2 minutes before expiry to avoid duplicate requests.
class AvatarAssetService {
  static final _log = Logger('AvatarAssetService');

  final SynaptixApiClient _client;
  final Map<String, _CachedEntry> _cache = {};

  AvatarAssetService(this._client);

  Future<AvatarAssetResponse> getAvatarAsset(String avatarId) async {
    final cached = _cache[avatarId];
    if (cached != null &&
        cached.response.expiresAt.isAfter(
          DateTime.now().toUtc().add(const Duration(minutes: 2)),
        )) {
      _log.fine('Cache hit for avatar $avatarId');
      return cached.response;
    }

    _log.info('Fetching presigned URL for avatar $avatarId');
    final json = await _client.getJson('/v1/assets/avatars/$avatarId');
    final response = AvatarAssetResponse.fromJson(json);
    _cache[avatarId] = _CachedEntry(response);
    return response;
  }

  void clearCache() => _cache.clear();
}

class _CachedEntry {
  final AvatarAssetResponse response;
  _CachedEntry(this.response);
}
