import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
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
  /// Cached server package listing (metadata).
  static const _cacheKeyServerList = 'avatar_packages_server_list_v1';

  /// Installed package index (fast load; survives restarts).
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

  File _manifestFileSync(Directory installDir) {
    return File(p.join(installDir.path, 'manifest.json'));
  }

  Future<File> _manifestFile(Directory installDir) async {
    return File(p.join(installDir.path, 'manifest.json'));
  }

  // ---------------------------------------------------------------------------
  // Installed listing (disk scan)
  // ---------------------------------------------------------------------------

  /// Local: discover installed packages by scanning avatarPackages/*/manifest.json.
  /// This is the authoritative fallback.
  Future<List<AvatarPackageInstall>> listInstalled() async {
    if (kIsWeb) return const [];
    final root = await _packagesRootDir;
    final out = <AvatarPackageInstall>[];

    if (!await root.exists()) return out;

    final children = root.listSync(followLinks: false);
    for (final entity in children) {
      if (entity is! Directory) continue;

      final manifest = _manifestFileSync(entity);
      if (!manifest.existsSync()) continue;

      try {
        final text = manifest.readAsStringSync();
        final jsonMap = json.decode(text);
        if (jsonMap is Map) {
          out.add(
            AvatarPackageInstall.fromJson(
              Map<String, dynamic>.from(jsonMap),
            ),
          );
        }
      } catch (_) {
        // Ignore broken manifests.
      }
    }

    // newest first
    out.sort((a, b) => b.installedAtUtcIso.compareTo(a.installedAtUtcIso));
    return out;
  }

  // ---------------------------------------------------------------------------
  // Server listing
  // ---------------------------------------------------------------------------

  /// Server: if remote is present, use it.
  /// If not, return cached list (or empty).
  Future<List<AvatarPackageMetadata>> fetchServerPackages({
    bool allowCache = true,
  }) async {
    if (_remote == null) {
      if (!allowCache) return const [];
      final cached = _cache.get<List<dynamic>>(_cacheKeyServerList);
      if (cached == null) return const [];
      return cached
          .whereType<Map>()
          .map((m) =>
              AvatarPackageMetadata.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    final list = await _remote!.fetchPackages();

    // Cache for offline browsing.
    await _cache.setJson(
      _cacheKeyServerList,
      list.map((x) => x.toJson()).toList(),
    );

    return list;
  }

  // ---------------------------------------------------------------------------
  // Installed packages (provider-friendly)
  // ---------------------------------------------------------------------------

  /// Strategy:
  /// 1) Prefer installed index in AppCacheService for speed.
  /// 2) Fallback: scan disk.
  Future<List<AvatarPackageInstall>> loadInstalledPackages() async {
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
            // ignore bad entry
          }
        }
      }

      // Verify install dirs still exist; prune missing.
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

      filtered
          .sort((a, b) => b.installedAtUtcIso.compareTo(a.installedAtUtcIso));
      return filtered;
    }

    // Fallback scan and then persist index.
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

  // ---------------------------------------------------------------------------
  // Install: Server download + extract
  // ---------------------------------------------------------------------------

  /// Install flow:
  /// 1) download archive
  /// 2) optional sha256 verify
  /// 3) extract to install dir
  /// 4) write manifest.json (normalized)
  /// 5) update installed index
  Future<AvatarPackageInstall> downloadAndInstall(
      AvatarPackageMetadata meta) async {
    if (kIsWeb) throw UnsupportedError('Avatar package installation is not supported on web.');
    final url = meta.archiveUrl;
    if (url == null || url.isEmpty) {
      throw StateError('archiveUrl is missing for package ${meta.id}.');
    }

    final root = await _packagesRootDir;
    final installDir = Directory(p.join(root.path, meta.installFolderName));

    // If a previous install exists, delete it to avoid mixed files.
    if (await installDir.exists()) {
      await installDir.delete(recursive: true);
    }
    await installDir.create(recursive: true);

    final tmp = await getTemporaryDirectory();
    final archiveFile = File(
      p.join(
        tmp.path,
        '${meta.installFolderName}${_guessArchiveSuffix(url)}',
      ),
    );

    await _downloadToFile(url, archiveFile);

    if (meta.sha256 != null && meta.sha256!.trim().isNotEmpty) {
      final ok = await _verifySha256(archiveFile, meta.sha256!.trim());
      if (!ok) {
        // cleanup
        if (await installDir.exists()) await installDir.delete(recursive: true);
        throw StateError('SHA-256 mismatch for ${meta.id}.');
      }
    }

    await _extractArchive(archiveFile, installDir);

    final install = AvatarPackageInstall(
      meta: meta,
      installDir: installDir.path,
      installedAtUtcIso: DateTime.now().toUtc().toIso8601String(),
    );

    // Normalize / overwrite manifest to match your model.
    final manifest = await _manifestFile(installDir);
    await manifest.writeAsString(install.toPrettyJson());

    // Update installed index
    final installs = await listInstalled();
    await _persistInstalledIndex(installs);

    return install;
  }

  // ---------------------------------------------------------------------------
  // ✅ Step 2: Install bundled asset archive (ZIP/TAR) shipped with app
  // ---------------------------------------------------------------------------

  /// Install a package from a bundled asset archive (ZIP/TAR/etc).
  ///
  /// Use this for demo packs shipped with the app:
  ///   assets/zip/demo_avatar_package_animals_v1_fixed.zip
  ///
  /// This uses the same extraction + manifest/indexing pipeline as server installs.
  Future<AvatarPackageInstall> installBundledAssetArchive({
    required AvatarPackageMetadata meta,
    required String assetArchivePath,
  }) async {
    if (kIsWeb) throw UnsupportedError('Avatar package installation is not supported on web.');
    final root = await _packagesRootDir;
    final installDir = Directory(p.join(root.path, meta.installFolderName));

    // If already installed, return existing record (idempotent).
    final existing = await _findInstallById(meta.id);
    if (existing != null) return existing;

    // 1) Load bytes from bundled assets.
    final data = await rootBundle.load(assetArchivePath);
    final Uint8List bytes = data.buffer.asUint8List();

    // 2) Write to temp file (archive APIs are file/stream oriented).
    final tmpDir = await Directory.systemTemp.createTemp('avatar_pkg_asset_');
    final ext = _guessArchiveSuffix(assetArchivePath);
    final archiveFile =
        File(p.join(tmpDir.path, '${meta.installFolderName}$ext'));
    await archiveFile.writeAsBytes(bytes, flush: true);

    try {
      // 3) Extract.
      if (await installDir.exists()) {
        await installDir.delete(recursive: true);
      }
      await installDir.create(recursive: true);

      await _extractArchive(archiveFile, installDir);

      // 4) Create/overwrite manifest.json (normalized).
      final install = AvatarPackageInstall(
        meta: meta,
        installDir: installDir.path,
        installedAtUtcIso: DateTime.now().toUtc().toIso8601String(),
      );

      final manifest = await _manifestFile(installDir);
      await manifest.writeAsString(install.toPrettyJson());

      // 5) Update installed index.
      final installs = await listInstalled();
      await _persistInstalledIndex(installs);

      return install;
    } finally {
      // best-effort cleanup
      try {
        if (await tmpDir.exists()) {
          await tmpDir.delete(recursive: true);
        }
      } catch (_) {}
    }
  }

  /// Find an install by package id.
  Future<AvatarPackageInstall?> _findInstallById(String id) async {
    final installs = await loadInstalledPackages();
    for (final i in installs) {
      if (i.meta.id == id) return i;
    }
    return null;
  }

  Future<void> uninstall(AvatarPackageInstall install) async {
    final dir = Directory(install.installDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }

    // Refresh installed index after uninstall.
    final installs = await listInstalled();
    await _persistInstalledIndex(installs);
  }

  // ---------------------------------------------------------------------------
  // Local avatar enumeration for AvatarAssetLoader
  // ---------------------------------------------------------------------------

  Future<List<AvatarAssetRef>> loadAllLocalImageAvatars() async {
    final installs = await loadInstalledPackages();
    final out = <AvatarAssetRef>[];

    const exts = ['.png', '.jpg', '.jpeg', '.webp'];

    for (final install in installs) {
      // If the pack is not image-based, you may skip; but for now you asked image-only.
      if (install.meta.render.kind != AvatarPackageType.image) {
        // Keep permissive if you want mixed packs later.
        // continue;
      }

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

  // ---------------------------------------------------------------------------
  // Internals: scan disk + persist index
  // ---------------------------------------------------------------------------

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

        // Normalize installDir to the actual folder we scanned.
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

  Future<void> _persistInstalledIndex(
      List<AvatarPackageInstall> installs) async {
    final payload = <String, dynamic>{};

    // Key by package id (stable, simple)
    for (final i in installs) {
      payload[i.meta.id] = i.toJson();
    }

    await _cache.setJson(_cacheKeyInstalledIndex, payload);
  }

  // ---------------------------------------------------------------------------
  // Download + integrity
  // ---------------------------------------------------------------------------

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

  // ---------------------------------------------------------------------------
  // Extraction helpers
  // ---------------------------------------------------------------------------

  String _guessArchiveSuffix(String urlOrPath) {
    final lower = urlOrPath.toLowerCase();
    if (lower.endsWith('.tar.gz')) return '.tar.gz';
    if (lower.endsWith('.tgz')) return '.tgz';
    if (lower.endsWith('.tar')) return '.tar';
    if (lower.endsWith('.zip')) return '.zip';
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
      // Read gz into bytes, inflate, then decode tar bytes.
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
