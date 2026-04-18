import 'package:logging/logging.dart';
import 'package:trivia_tycoon/core/networking/synaptix_api_client.dart';
import 'audio_asset_response.dart';

/// Fetches presigned MinIO URLs for audio assets from the backend.
///
/// Caches each URL until 2 minutes before its expiry so concurrent
/// calls for the same file don't trigger duplicate backend requests.
class AudioAssetService {
  static final _log = Logger('AudioAssetService');

  final SynaptixApiClient _client;
  final Map<String, _CachedUrl> _cache = {};

  AudioAssetService(this._client);

  /// Returns a presigned URL for [filename] (e.g. `end_game.mp3`).
  ///
  /// Served from cache if the cached URL won't expire within the next 2 minutes.
  Future<String> getPresignedUrl(String filename) async {
    final cached = _cache[filename];
    if (cached != null &&
        cached.expiresAt.isAfter(
          DateTime.now().toUtc().add(const Duration(minutes: 2)),
        )) {
      _log.fine('Cache hit for $filename');
      return cached.url;
    }

    _log.info('Fetching presigned URL for $filename');
    final json = await _client.getJson('/v1/assets/audio/songs/$filename');
    final asset = AudioAssetResponse.fromJson(json);

    _cache[filename] = _CachedUrl(asset.presignedUrl, asset.expiresAt);
    return asset.presignedUrl;
  }

  void clearCache() => _cache.clear();
}

class _CachedUrl {
  final String url;
  final DateTime expiresAt;
  _CachedUrl(this.url, this.expiresAt);
}
