import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:synaptix/core/models/asset_manifest_entry.dart';
import 'package:synaptix/core/services/asset_download_service.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

String _sha256Of(String content) =>
    sha256.convert(utf8.encode(content)).toString();

/// Build an [AssetDownloadService] wired to [handler] for all HTTP calls.
/// Uses [hiveDir] as the Hive base and [assetsDir] as the local file store.
AssetDownloadService _svc(
  Directory hiveDir,
  Directory assetsDir,
  MockClientHandler handler,
) {
  return AssetDownloadService(
    httpClient: MockClient(handler),
    manifestUrl: 'https://test.example/manifest.json',
    baseDirOverride: assetsDir,
  );
}

void main() {
  late Directory tempDir;
  late Directory hiveDir;
  late Directory assetsDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('asset_dl_test_');
    hiveDir = Directory('${tempDir.path}/hive');
    assetsDir = Directory('${tempDir.path}/assets');
    await hiveDir.create();
    await assetsDir.create();
    Hive.init(hiveDir.path);
  });

  tearDown(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  // -------------------------------------------------------------------------
  // AssetManifestEntry — model
  // -------------------------------------------------------------------------

  group('AssetManifestEntry', () {
    test('fromJson parses all fields', () {
      final e = AssetManifestEntry.fromJson({
        'key': 'questions/general',
        'url': 'https://cdn.example/q.json',
        'sha256': 'abc123',
        'version': 'v2',
        'sizeBytes': 1024,
      });
      expect(e.key, 'questions/general');
      expect(e.url, 'https://cdn.example/q.json');
      expect(e.sha256, 'abc123');
      expect(e.version, 'v2');
      expect(e.sizeBytes, 1024);
    });

    test('fromJson accepts backend id/downloadUrl fields', () {
      final e = AssetManifestEntry.fromJson({
        'id': 'env_arena_default',
        'downloadUrl': 'https://cdn.example/arena.glb',
        'sha256': 'abc123',
        'version': 'v1',
      });
      expect(e.key, 'env_arena_default');
      expect(e.url, 'https://cdn.example/arena.glb');
      expect(e.version, 'v1');
    });

    test('fromJson sizeBytes defaults 0 when absent', () {
      final e = AssetManifestEntry.fromJson({
        'key': 'k',
        'url': 'u',
        'sha256': 's',
        'version': 'v',
      });
      expect(e.sizeBytes, 0);
    });

    test('toJson round-trip', () {
      const e = AssetManifestEntry(
        key: 'k',
        url: 'u',
        sha256: 's',
        version: 'v1',
        sizeBytes: 512,
      );
      final j = e.toJson();
      expect(j['key'], 'k');
      expect(j['version'], 'v1');
      expect(j['sizeBytes'], 512);
    });
  });

  // -------------------------------------------------------------------------
  // DownloadedAssetRecord — model
  // -------------------------------------------------------------------------

  group('DownloadedAssetRecord', () {
    test('fromJson parses all fields', () {
      final r = DownloadedAssetRecord.fromJson({
        'key': 'q/gen',
        'version': 'v3',
        'sha256': 'deadbeef',
        'downloadedAt': '2025-06-01T10:00:00.000Z',
      });
      expect(r.key, 'q/gen');
      expect(r.version, 'v3');
      expect(r.sha256, 'deadbeef');
      expect(r.downloadedAt, '2025-06-01T10:00:00.000Z');
    });

    test('toJson round-trip', () {
      const r = DownloadedAssetRecord(
        key: 'k',
        version: 'v1',
        sha256: 'abc',
        downloadedAt: '2025-01-01T00:00:00.000Z',
      );
      final j = r.toJson();
      expect(j['key'], 'k');
      expect(j['sha256'], 'abc');
    });
  });

  // -------------------------------------------------------------------------
  // checkForUpdates
  // -------------------------------------------------------------------------

  group('checkForUpdates', () {
    test('returns all entries when nothing is locally stored', () async {
      final manifest = jsonEncode([
        {'key': 'q/general', 'url': 'u1', 'sha256': 's1', 'version': 'v1'},
        {'key': 'q/science', 'url': 'u2', 'sha256': 's2', 'version': 'v2'},
      ]);

      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response(manifest, 200);
      });

      final stale = await svc.checkForUpdates();
      expect(stale.length, 2);
      expect(stale.map((e) => e.key), containsAll(['q/general', 'q/science']));
    });

    test('returns empty list on HTTP error', () async {
      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response('error', 500);
      });

      final stale = await svc.checkForUpdates();
      expect(stale, isEmpty);
    });

    test('returns empty list when manifest is empty array', () async {
      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response('[]', 200);
      });
      expect(await svc.checkForUpdates(), isEmpty);
    });

    test('accepts backend manifest envelope with items', () async {
      final manifest = jsonEncode({
        'generatedAt': '2026-06-12T00:00:00.000Z',
        'expiresAt': '2026-06-13T00:00:00.000Z',
        'items': [
          {
            'id': 'env_arena_default',
            'downloadUrl': 'https://cdn.example/arena.glb',
            'sha256': '',
            'version': '1.0.0',
          },
        ],
      });

      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response(manifest, 200);
      });

      final stale = await svc.checkForUpdates();
      expect(stale, hasLength(1));
      expect(stale.single.key, 'env_arena_default');
      expect(stale.single.url, 'https://cdn.example/arena.glb');
    });
  });

  // -------------------------------------------------------------------------
  // downloadAsset
  // -------------------------------------------------------------------------

  group('downloadAsset', () {
    test('writes file to disk and stores record in Hive', () async {
      const content = '{"questions": []}';
      final hash = _sha256Of(content);

      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response(content, 200);
      });

      final entry = AssetManifestEntry(
        key: 'questions_general',
        url: 'https://test.example/q.json',
        sha256: hash,
        version: 'v1',
      );

      await svc.downloadAsset(entry);

      final localFile = File('${assetsDir.path}/questions_general');
      expect(await localFile.exists(), isTrue);
      expect(await localFile.readAsString(), content);
    });

    test('throws on SHA-256 mismatch', () async {
      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response('actual content', 200);
      });

      final entry = AssetManifestEntry(
        key: 'bad_hash',
        url: 'https://test.example/bad.json',
        sha256: 'wrong_sha256_value',
        version: 'v1',
      );

      await expectLater(
        svc.downloadAsset(entry),
        throwsException,
      );
    });

    test('throws on non-2xx HTTP status', () async {
      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response('not found', 404);
      });

      final entry = AssetManifestEntry(
        key: 'missing',
        url: 'https://test.example/missing.json',
        sha256: '',
        version: 'v1',
      );

      await expectLater(
        svc.downloadAsset(entry),
        throwsException,
      );
    });

    test('skips SHA-256 check when sha256 is empty', () async {
      const content = 'any content';
      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response(content, 200);
      });

      final entry = AssetManifestEntry(
        key: 'no_hash',
        url: 'https://test.example/n.json',
        sha256: '', // empty → skip check
        version: 'v1',
      );

      await expectLater(svc.downloadAsset(entry), completes);

      final file = File('${assetsDir.path}/no_hash');
      expect(await file.exists(), isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // loadAsset
  // -------------------------------------------------------------------------

  group('loadAsset', () {
    test('returns null when no local file exists', () async {
      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response('[]', 200);
      });

      expect(await svc.loadAsset('nonexistent'), isNull);
    });

    test('returns content after downloadAsset writes the file', () async {
      const content = '{"data": 42}';
      final hash = _sha256Of(content);

      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response(content, 200);
      });

      await svc.downloadAsset(AssetManifestEntry(
        key: 'my_asset',
        url: 'https://test.example/my.json',
        sha256: hash,
        version: 'v1',
      ));

      final loaded = await svc.loadAsset('my_asset');
      expect(loaded, content);
    });
  });

  // -------------------------------------------------------------------------
  // loadAssetOrBundle — local path only (rootBundle not available in unit tests)
  // -------------------------------------------------------------------------

  group('loadAssetOrBundle', () {
    test('returns local file content when downloaded file exists', () async {
      const content = '{"local": true}';
      final hash = _sha256Of(content);

      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response(content, 200);
      });

      await svc.downloadAsset(AssetManifestEntry(
        key: 'local_asset',
        url: 'https://test.example/local.json',
        sha256: hash,
        version: 'v2',
      ));

      final result = await svc.loadAssetOrBundle(
        'local_asset',
        'assets/fallback.json',
      );
      expect(result, content);
    });
  });

  // -------------------------------------------------------------------------
  // clearDownloadedAssets
  // -------------------------------------------------------------------------

  group('clearDownloadedAssets', () {
    test('removes downloaded files and clears Hive records', () async {
      const content = 'some data';
      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response(content, 200);
      });

      await svc.downloadAsset(AssetManifestEntry(
        key: 'to_clear',
        url: 'https://test.example/c.json',
        sha256: '', // skip hash
        version: 'v1',
      ));

      final file = File('${assetsDir.path}/to_clear');
      expect(await file.exists(), isTrue);

      await svc.clearDownloadedAssets();

      expect(await assetsDir.exists(), isFalse);
      expect(await svc.loadAsset('to_clear'), isNull);
    });

    test('completes without error when nothing has been downloaded', () async {
      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response('[]', 200);
      });
      await expectLater(svc.clearDownloadedAssets(), completes);
    });
  });

  // -------------------------------------------------------------------------
  // Key sanitisation
  // -------------------------------------------------------------------------

  group('key sanitisation', () {
    test('keys with path separators are stored safely', () async {
      const content = 'path test';
      final svc = _svc(hiveDir, assetsDir, (_) async {
        return http.Response(content, 200);
      });

      await svc.downloadAsset(AssetManifestEntry(
        key: 'questions/general/v1',
        url: 'https://test.example/q.json',
        sha256: '',
        version: 'v1',
      ));

      // The key is sanitised so it becomes a simple file name.
      final loaded = await svc.loadAsset('questions/general/v1');
      expect(loaded, content);
    });
  });
}
