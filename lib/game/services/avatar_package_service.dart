import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/services/storage/app_cache_service.dart';
import '../models/avatar_package_models.dart';

/// Optional contract for backend.
/// Your FastAPI will eventually back this:
/// GET /avatar-packages -> List<AvatarPackageMetadata>
abstract class AvatarPackageRemoteSource {
  Future<List<AvatarPackageMetadata>> fetchPackages();
}

class AvatarPackageService {
  /// Cache key for server list (List<Map>).
  static const _cacheKeyServerList = 'avatar_packages_server_list_v1';

  /// Cache key for installed index (Map<String, dynamic> of installs).
  static const _cacheKeyInstalledIndex = 'avatar_packages_installed_index_v1';

  final AppCacheService _cache;
  final AvatarPackageRemoteSource? _remote;

  AvatarPackageService(
      this._cache, {
        AvatarPackageRemoteSource? remote,
      }) : _remote = remote;

  bool get hasRemoteSource => _remote != null;

  /// Where packages are installed:
  /// <documents>/avatarPackages/<packageId_version>/
  Future<Directory> get _packagesRootDir async {
    final docs = await getApplicationDocumentsDirectory();
    final root = Directory(p.join(docs.path, 'avatarPackages'));
    if (!await root.exists()) {
      await root.create(recursive: true);
    }
    return root;
  }

  Future<File> _manifestFile(Directory installDir) async {
    return File(p.join(installDir.path, 'manifest.json'));
  }

  /// ---------------------------------------------------------------------------
  /// Server list
  /// ---------------------------------------------------------------------------

  /// Server: if remote is present, use it.
  /// If not, return cached list (or empty).
  Future<List<AvatarPackageMetadata>> fetchServerPackages({bool allowCache = true}) async {
    if (_remote == null) {
      if (!allowCache) return const [];
      final cached = _cache.get<List<dynamic>>(_cacheKeyServerList);
      if (cached == null) return const [];
      return cached
          .whereType<Map>()
          .map((m) => AvatarPackageMetadata.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    final list = await _remote!.fetchPackages();
    // Cache for offline browsing.
    await _cache.setJson(_cacheKeyServerList, list.map((x) => x.toJson()).toList());
    return list;
  }

  /// ---------------------------------------------------------------------------
  /// Installed packages
  /// ---------------------------------------------------------------------------

  /// Local: discover installed packages by scanning avatarPackages/*/manifest.json.
  Future<List<AvatarPackageInstall>> listInstalled() async {
    final root = await _packagesRootDir;
    final out = <AvatarPackageInstall>[];

    if (!await root.exists()) return out;

    final children = root.listSync(followLinks: false);
    for (final entity in children) {
      if (entity is! Directory) continue;

      final manifest = await _manifestFile(entity);
      if (!await manifest.exists()) continue;

      try {
        final text = await manifest.readAsString();
        final jsonMap = json.decode(text);
        if (jsonMap is Map) {
          out.add(AvatarPackageInstall.fromJson(Map<String, dynamic>.from(jsonMap)));
        }
      } catch (_) {
        // Ignore broken manifests.
      }
    }

    // newest first
    out.sort((a, b) => b.installedAtUtcIso.compareTo(a.installedAtUtcIso));
    return out;
  }

  /// Strategy:
  /// 1) Prefer the persisted installed index in AppCacheService for speed.
  /// 2) Fallback: scan disk for `manifest.json` files.
  Future<List<AvatarPackageInstall>> loadInstalledPackages() async {
    // 1) Try installed index first (Map)
    final indexed = _cache.get<Map<String, dynamic>>(_cacheKeyInstalledIndex);
    if (indexed != null && indexed.isNotEmpty) {
      final installs = <AvatarPackageInstall>[];

      for (final entry in indexed.entries) {
        final raw = entry.value;
        if (raw is Map) {
          try {
            installs.add(
              AvatarPackageInstall.fromJson(
                Map<String, dynamic>.from(raw),
              ),
            );
          } catch (_) {
            // ignore bad entry (we will still return what we can)
          }
        }
      }

      // Verify folders still exist; prune missing
      final filtered = <AvatarPackageInstall>[];
      bool changed = false;

      for (final i in installs) {
        final dir = Directory(i.installDir);
        if (await dir.exists()) {
          filtered.add(i);
        } else {
          changed = true;
        }
      }

      if (changed) {
        await _persistInstalledIndex(filtered);
      }

      filtered.sort((a, b) => b.installedAtUtcIso.compareTo(a.installedAtUtcIso));
      return filtered;
    }

    // 2) Fallback scan
    final scanned = await _scanInstalledPackagesFromDisk();
    await _persistInstalledIndex(scanned);

    scanned.sort((a, b) => b.installedAtUtcIso.compareTo(a.installedAtUtcIso));
    return scanned;
  }

  Future<bool> isInstalled(AvatarPackageMetadata meta) async {
    final root = await _packagesRootDir;
    final folder = Directory(p.join(root.path, meta.installFolderName));
    final manifest = File(p.join(folder.path, 'manifest.json'));
    return await folder.exists() && await manifest.exists();
  }

  Future<AvatarPackageInstall?> _findInstallById(String id) async {
    final installs = await loadInstalledPackages();
    for (final i in installs) {
      if (i.meta.id == id) return i;
    }
    return null;
  }

  /// ---------------------------------------------------------------------------
  /// Install flows
  /// ---------------------------------------------------------------------------

  /// Install flow:
  /// 1) download archive
  /// 2) optional sha256 verify
  /// 3) extract to install dir
  /// 4) write manifest.json
  /// 5) update installed index cache
  Future<AvatarPackageInstall> downloadAndInstall(AvatarPackageMetadata meta) async {
    final url = meta.archiveUrl;
    if (url == null || url.isEmpty) {
      throw StateError('archiveUrl is missing for package ${meta.id}.');
    }

    final tmp = await getTemporaryDirectory();
    final archiveFile = File(p.join(tmp.path, '${meta.installFolderName}${_guessArchiveSuffix(url)}'));

    await _downloadToFile(url, archiveFile);

    if (meta.sha256 != null && meta.sha256!.trim().isNotEmpty) {
      final ok = await _verifySha256(archiveFile, meta.sha256!.trim());
      if (!ok) {
        throw StateError('SHA-256 mismatch for ${meta.id}.');
      }
    }

    return _installFromArchiveFile(meta, archiveFile);
  }

  /// Step 2: Install a package from a bundled ZIP/TAR/etc shipped in assets.
  ///
  /// Example asset path:
  ///   assets/zip/demo_avatar_package_animals_v1.zip
  ///
  /// Notes:
  /// - This is idempotent: if already installed, returns existing install record.
  /// - We do NOT require manifest.json to be inside the zip. We create our own
  ///   manifest.json after extraction (same as server install).
  Future<AvatarPackageInstall> installBundledZip({
    required AvatarPackageMetadata meta,
    required String assetArchivePath,
  }) async {
    // If already installed, return existing record.
    final existing = await _findInstallById(meta.id);
    if (existing != null) return existing;

    // Load bytes from asset bundle
    final data = await rootBundle.load(assetArchivePath);
    final bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);

    // Stage to temp file (archive package APIs are file/stream oriented)
    final tmp = await getTemporaryDirectory();
    final ext = _guessArchiveSuffix(assetArchivePath);
    final archiveFile = File(p.join(tmp.path, '${meta.installFolderName}$ext'));

    await archiveFile.writeAsBytes(bytes, flush: true);

    return _installFromArchiveFile(meta, archiveFile);
  }

  /// Shared install pipeline for both remote downloads and bundled archives.
  Future<AvatarPackageInstall> _installFromArchiveFile(
      AvatarPackageMetadata meta,
      File archiveFile,
      ) async {
    final root = await _packagesRootDir;
    final installDir = Directory(p.join(root.path, meta.installFolderName));

    // Clean previous install folder to avoid mixed files.
    if (await installDir.exists()) {
      await installDir.delete(recursive: true);
    }
    await installDir.create(recursive: true);

    // Extract archive
    await _extractArchive(archiveFile, installDir);

    // Write install manifest (authoritative record for scanning/listing)
    final install = AvatarPackageInstall(
      meta: meta,
      installDir: installDir.path,
      installedAtUtcIso: DateTime.now().toUtc().toIso8601String(),
    );

    final manifest = await _manifestFile(installDir);
    await manifest.writeAsString(install.toPrettyJson(), flush: true);

    // Update installed index cache
    final current = await loadInstalledPackages();
    final updated = <AvatarPackageInstall>[
      ...current.where((x) => x.meta.id != meta.id),
      install,
    ];
    await _persistInstalledIndex(updated);

    return install;
  }

  Future<void> uninstall(AvatarPackageInstall install) async {
    final dir = Directory(install.installDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    // Update installed index
    final current = await loadInstalledPackages();
    final updated = current.where((x) => x.meta.id != install.meta.id).toList();
    await _persistInstalledIndex(updated);
  }

  /// ---------------------------------------------------------------------------
  /// Local avatar discovery (used by AvatarAssetLoader)
  /// ---------------------------------------------------------------------------

  Future<List<AvatarAssetRef>> loadAllLocalImageAvatars() async {
    final installs = await loadInstalledPackages();
    final out = <AvatarAssetRef>[];

    const exts = ['.png', '.jpg', '.jpeg', '.webp'];

    for (final install in installs) {
      final dir = Directory(install.installDir);
      if (!await dir.exists()) continue;

      final files = dir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => exts.contains(p.extension(f.path).toLowerCase()));

      for (final f in files) {
        out.add(AvatarAssetRef(source: AvatarSource.file, path: f.path));
      }
    }

    return out;
  }

  Future<List<AvatarAssetRef>> loadAllLocalThreeDAvatars() async {
    final installs = await loadInstalledPackages();
    final out = <AvatarAssetRef>[];

    const exts = ['.glb', '.gltf'];

    for (final install in installs) {
      final dir = Directory(install.installDir);
      if (!await dir.exists()) continue;

      final files = dir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) => exts.contains(p.extension(f.path).toLowerCase()));

      for (final f in files) {
        out.add(AvatarAssetRef(source: AvatarSource.file, path: f.path));
      }
    }

    return out;
  }

  // -----------------------
  // Internals
  // -----------------------

  /// Disk scan fallback: find <root>/*/manifest.json
  Future<List<AvatarPackageInstall>> _scanInstalledPackagesFromDisk() async {
    final root = await _packagesRootDir;
    if (!await root.exists()) return const [];

    final installs = <AvatarPackageInstall>[];

    final children = root.listSync(followLinks: false);
    for (final entity in children) {
      if (entity is! Directory) continue;

      final manifestFile = File(p.join(entity.path, 'manifest.json'));
      if (!manifestFile.existsSync()) continue;

      try {
        final s = manifestFile.readAsStringSync();
        final map = jsonDecode(s) as Map<String, dynamic>;
        final install = AvatarPackageInstall.fromJson(map);

        // Normalize installDir to current folder (authoritative location)
        installs.add(
          AvatarPackageInstall(
            meta: install.meta,
            installDir: entity.path,
            installedAtUtcIso: install.installedAtUtcIso,
          ),
        );
      } catch (_) {
        // ignore malformed manifest
      }
    }

    return installs;
  }

  /// Persist installed index (Map<String, dynamic>).
  /// Key by installFolderName so versioned installs are unique.
  Future<void> _persistInstalledIndex(List<AvatarPackageInstall> installs) async {
    final payload = <String, dynamic>{};
    for (final i in installs) {
      payload[i.meta.installFolderName] = i.toJson();
    }
    await _cache.setJson(_cacheKeyInstalledIndex, payload);
  }

  Future<void> _downloadToFile(String url, File out) async {
    final client = http.Client();
    try {
      final req = http.Request('GET', Uri.parse(url));
      final resp = await client.send(req);

      if (resp.statusCode < 200 || resp.statusCode >= 300) {
        throw HttpException('Download failed (${resp.statusCode}).');
      }

      final sink = out.openWrite();
      await resp.stream.pipe(sink);
      await sink.flush();
      await sink.close();
    } finally {
      client.close();
    }
  }

  Future<bool> _verifySha256(File file, String expectedHexLower) async {
    final bytes = await file.readAsBytes();
    final digest = sha256.convert(bytes).toString().toLowerCase();
    return digest == expectedHexLower.toLowerCase();
  }

  /// Guess archive suffix based on path.
  String _guessArchiveSuffix(String urlOrPath) {
    final lower = urlOrPath.toLowerCase();
    if (lower.endsWith('.tar.gz')) return '.tar.gz';
    if (lower.endsWith('.tgz')) return '.tgz';
    if (lower.endsWith('.tar')) return '.tar';
    if (lower.endsWith('.zip')) return '.zip';
    // default
    return '.zip';
  }

  Future<void> _extractArchive(File archiveFile, Directory destDir) async {
    final lower = archiveFile.path.toLowerCase();

    if (lower.endsWith('.zip')) {
      final input = InputFileStream(archiveFile.path);
      final archive = ZipDecoder().decodeStream(input);
      await _writeArchiveToDisk(archive, destDir);
      return;
    }

    if (lower.endsWith('.tar')) {
      final input = InputFileStream(archiveFile.path);
      final archive = TarDecoder().decodeStream(input);
      await _writeArchiveToDisk(archive, destDir);
      return;
    }

    if (lower.endsWith('.tar.gz') || lower.endsWith('.tgz')) {
      final bytes = await archiveFile.readAsBytes();
      final gzBytes = GZipDecoder().decodeBytes(bytes);
      final archive = TarDecoder().decodeBytes(gzBytes);
      await _writeArchiveToDisk(archive, destDir);
      return;
    }

    throw UnsupportedError('Unsupported archive type: ${archiveFile.path}');
  }

  Future<void> _writeArchiveToDisk(Archive archive, Directory destDir) async {
    for (final file in archive) {
      final filename = file.name;

      // Guard against zip-slip
      final normalized = p.normalize(filename);
      if (p.isAbsolute(normalized) || normalized.startsWith('..')) {
        continue;
      }

      final outPath = p.join(destDir.path, normalized);

      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        final data = file.content as List<int>;
        await outFile.writeAsBytes(data, flush: true);
      } else {
        final outDirectory = Directory(outPath);
        await outDirectory.create(recursive: true);
      }
    }
  }
}
