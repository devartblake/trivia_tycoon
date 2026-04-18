import 'package:logging/logging.dart';
import 'package:trivia_tycoon/core/networking/synaptix_api_client.dart';
import 'audio_asset_response.dart';

/// Fetches presigned MinIO URLs for audio assets from the backend.
///
/// Supports both music and SFX categories via the [category] parameter:
///   - `'songs'`  → GET /v1/assets/audio/songs/{filename}
///   - `'sfx'`    → GET /v1/assets/audio/sfx/{filename}
///
/// Caches each URL until 2 minutes before its expiry so concurrent
/// calls for the same file don't trigger duplicate backend requests.
class AudioAssetService {
  static final _log = Logger('AudioAssetService');

  final SynaptixApiClient _client;
  // Cache key is '$category/$filename' to isolate the two namespaces.
  final Map<String, _CachedUrl> _cache = {};

  AudioAssetService(this._client);

  /// Returns a presigned URL for [filename] under [category].
  ///
  /// [category] defaults to `'songs'` for music. Pass `'sfx'` for
  /// sound effects. The cache key includes the category so the two
  /// namespaces are fully independent.
  Future<String> getPresignedUrl(String filename, {String category = 'songs'}) async {
    final cacheKey = '$category/$filename';
    final cached = _cache[cacheKey];
    if (cached != null &&
        cached.expiresAt.isAfter(
          DateTime.now().toUtc().add(const Duration(minutes: 2)),
        )) {
      _log.fine('Cache hit for $cacheKey');
      return cached.url;
    }

    _log.info('Fetching presigned URL for $cacheKey');
    final json = await _client.getJson('/v1/assets/audio/$category/$filename');
    final asset = AudioAssetResponse.fromJson(json);

    _cache[cacheKey] = _CachedUrl(asset.presignedUrl, asset.expiresAt);
    return asset.presignedUrl;
  }

  void clearCache() => _cache.clear();
}

class _CachedUrl {
  final String url;
  final DateTime expiresAt;
  _CachedUrl(this.url, this.expiresAt);
}
