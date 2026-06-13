import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../models/asset_manifest_entry.dart';

/// Downloads and caches server-provided assets as local JSON files.
///
/// Assets are stored at `<documents>/serverAssets/<sanitized-key>` so they
/// survive app updates and offline periods.  On each read the service checks
/// whether a local file exists and falls back to the bundled `rootBundle`
/// copy when it does not.
///
/// Trigger pattern:
/// ```dart
/// // At app startup (non-blocking):
/// unawaited(assetDownloadService.syncInBackground());
/// ```
class AssetDownloadService {
  static const _hiveBoxName = 'asset_downloads';
  static const _manifestCacheKey = 'server_asset_manifest';
  static const _manifestCacheTtlSeconds = 6 * 3600; // 6 h

  final http.Client _http;
  final String _manifestUrl;

  /// Optional override for the local storage directory.
  /// In production this defaults to `<documents>/serverAssets`.
  /// Inject a temp directory in unit tests to avoid path_provider.
  final Directory? _baseDirOverride;

  AssetDownloadService({
    required http.Client httpClient,
    required String manifestUrl,
    Directory? baseDirOverride,
  })  : _http = httpClient,
        _manifestUrl = manifestUrl,
        _baseDirOverride = baseDirOverride;

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Fetch the server manifest and download any asset whose version differs
  /// from the locally stored version.  Safe to call concurrently; errors are
  /// swallowed so callers can fire-and-forget.
  Future<void> syncInBackground() async {
    if (kIsWeb) return;
    try {
      final entries = await checkForUpdates();
      for (final entry in entries) {
        await downloadAsset(entry);
      }
    } catch (e) {
      debugPrint('[AssetDownloadService] sync error: $e');
    }
  }

  /// Return the list of manifest entries whose local version is stale or
  /// absent.  Returns an empty list if the manifest cannot be fetched.
  Future<List<AssetManifestEntry>> checkForUpdates() async {
    if (kIsWeb) return const [];

    List<AssetManifestEntry> manifest;
    try {
      manifest = await _fetchManifest();
    } catch (e) {
      debugPrint('[AssetDownloadService] manifest fetch failed: $e');
      return const [];
    }

    final stale = <AssetManifestEntry>[];
    for (final entry in manifest) {
      final record = await _loadRecord(entry.key);
      if (record == null || record.version != entry.version) {
        stale.add(entry);
      }
    }
    return stale;
  }

  /// Download [entry], verify its SHA-256, write to local disk, and persist
  /// the download record.  Throws on integrity failure or I/O errors.
  Future<void> downloadAsset(AssetManifestEntry entry) async {
    if (kIsWeb) return;

    final response = await _http.get(Uri.parse(entry.url));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          '[AssetDownloadService] HTTP ${response.statusCode} for ${entry.url}');
    }

    // Integrity check.
    if (entry.sha256.isNotEmpty) {
      final digest = sha256.convert(response.bodyBytes).toString();
      if (digest != entry.sha256) {
        throw Exception(
            '[AssetDownloadService] SHA-256 mismatch for ${entry.key}: '
            'expected ${entry.sha256}, got $digest');
      }
    }

    // Persist to disk.
    final file = await _localFileFor(entry.key);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(response.bodyBytes);

    // Save download record.
    await _saveRecord(DownloadedAssetRecord(
      key: entry.key,
      version: entry.version,
      sha256: entry.sha256,
      downloadedAt: DateTime.now().toUtc().toIso8601String(),
    ));
  }

  /// Return the raw string content of a previously downloaded asset, or
  /// `null` if no local copy exists.
  Future<String?> loadAsset(String key) async {
    if (kIsWeb) return null;
    final file = await _localFileFor(key);
    if (!await file.exists()) return null;
    return file.readAsString();
  }

  /// Return local content if a downloaded copy exists; otherwise fall back to
  /// `rootBundle.loadString(bundlePath)`.
  Future<String> loadAssetOrBundle(String key, String bundlePath) async {
    if (!kIsWeb) {
      final local = await loadAsset(key);
      if (local != null) return local;
    }
    return rootBundle.loadString(bundlePath);
  }

  /// Delete all locally downloaded asset files and clear the Hive records.
  Future<void> clearDownloadedAssets() async {
    if (kIsWeb) return;
    final dir = await _serverAssetsDir();
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
    final box = await Hive.openBox(_hiveBoxName);
    await box.clear();
  }

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  Future<List<AssetManifestEntry>> _fetchManifest() async {
    // Check Hive cache first.
    final box = await Hive.openBox(_hiveBoxName);
    final cachedJson = box.get(_manifestCacheKey);
    final cachedAt = box.get('${_manifestCacheKey}_at');

    if (cachedJson != null && cachedAt is String) {
      final age = DateTime.now()
          .difference(DateTime.tryParse(cachedAt) ?? DateTime(2000))
          .inSeconds;
      if (age < _manifestCacheTtlSeconds) {
        return _parseManifestJson(cachedJson as String);
      }
    }

    // Fetch from server.
    final response = await _http.get(Uri.parse(_manifestUrl));
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          '[AssetDownloadService] manifest HTTP ${response.statusCode}');
    }

    final body = response.body;

    // Cache the response.
    await box.put(_manifestCacheKey, body);
    await box.put(
        '${_manifestCacheKey}_at', DateTime.now().toUtc().toIso8601String());

    return _parseManifestJson(body);
  }

  List<AssetManifestEntry> _parseManifestJson(String raw) {
    final decoded = jsonDecode(raw);
    final items = decoded is List
        ? decoded
        : decoded is Map
            ? decoded['items']
            : null;
    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((m) => AssetManifestEntry.fromJson(Map<String, dynamic>.from(m)))
        .where((entry) => entry.key.isNotEmpty && entry.url.isNotEmpty)
        .toList();
  }

  Future<Directory> _serverAssetsDir() async {
    if (_baseDirOverride != null) return _baseDirOverride!;
    final docs = await getApplicationDocumentsDirectory();
    return Directory(p.join(docs.path, 'serverAssets'));
  }

  Future<File> _localFileFor(String key) async {
    final dir = await _serverAssetsDir();
    // Sanitise the key: replace path separators and invalid chars with '_'.
    final safeName = key.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    return File(p.join(dir.path, safeName));
  }

  Future<DownloadedAssetRecord?> _loadRecord(String key) async {
    final box = await Hive.openBox(_hiveBoxName);
    final raw = box.get('record:$key');
    if (raw is! String) return null;
    try {
      return DownloadedAssetRecord.fromJson(
          jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> _saveRecord(DownloadedAssetRecord record) async {
    final box = await Hive.openBox(_hiveBoxName);
    await box.put('record:${record.key}', jsonEncode(record.toJson()));
  }
}
