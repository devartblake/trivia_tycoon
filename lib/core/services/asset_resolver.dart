import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:trivia_tycoon/core/env.dart';
import 'package:trivia_tycoon/core/services/asset_download_service.dart';

class AssetResolver {
  static AssetResolver? _instance;

  final AssetDownloadService? _downloadService;

  AssetResolver({AssetDownloadService? downloadService})
      : _downloadService = downloadService;

  factory AssetResolver.fromManifestUrl(String manifestUrl) {
    return AssetResolver(
      downloadService: AssetDownloadService(
        httpClient: http.Client(),
        manifestUrl: _resolveManifestUrl(manifestUrl),
      ),
    );
  }

  static AssetResolver get instance {
    return _instance ??= AssetResolver(
        downloadService: AssetDownloadService(
      httpClient: http.Client(),
      manifestUrl: _defaultManifestUrl(),
    ));
  }

  static void configure(AssetResolver resolver) {
    _instance = resolver;
  }

  Future<void> syncInBackground() async {
    await _downloadService?.syncInBackground();
  }

  Future<String> loadString(
    String key, {
    String? bundledFallbackPath,
  }) async {
    final downloaded = await _downloadService?.loadAsset(key);
    if (downloaded != null) return downloaded;

    if (bundledFallbackPath == null || bundledFallbackPath.isEmpty) {
      throw FlutterError(
        'No server asset is cached for "$key" and no bundled fallback exists.',
      );
    }

    return rootBundle.loadString(bundledFallbackPath);
  }

  Future<Uri> resolveUri(
    String key, {
    String? bundledFallbackPath,
  }) async {
    final downloaded = await _downloadService?.loadAsset(key);
    if (downloaded != null) return Uri.dataFromString(downloaded);

    if (bundledFallbackPath == null || bundledFallbackPath.isEmpty) {
      throw FlutterError(
        'No server asset is cached for "$key" and no bundled fallback exists.',
      );
    }

    return Uri.parse(bundledFallbackPath);
  }

  static String _defaultManifestUrl() {
    return _resolveManifestUrl('/api/v1/assets/manifest');
  }

  static String _resolveManifestUrl(String manifestUrl) {
    final trimmed = manifestUrl.trim();
    final parsed = Uri.tryParse(trimmed);
    if (parsed != null && parsed.hasScheme) {
      return parsed.toString();
    }

    final base = EnvConfig.apiBaseUrl;
    final uri = Uri.parse(base);
    final manifestSegments = Uri.parse(
      trimmed.isEmpty ? '/api/v1/assets/manifest' : trimmed,
    ).pathSegments.where((segment) => segment.isNotEmpty);
    final segments = <String>[
      ...uri.pathSegments.where((segment) => segment.isNotEmpty),
      ...manifestSegments,
    ];
    return uri.replace(pathSegments: segments).toString();
  }
}
