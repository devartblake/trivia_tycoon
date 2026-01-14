import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;

import '../../core/services/storage/app_cache_service.dart';
import '../models/avatar_package_models.dart';

/// Remote listing contract (plug into FastAPI later).
abstract class AvatarPackageRemoteSource {
  Future<List<AvatarPackageManifest>> fetchPackages();
  Future<Uri> resolveDownloadUrl(String packageId);
}

class AvatarPackageService {
  static const _installedKey = 'avatar_packages_installed_v1';

  /// Root folder where packages are installed:
  /// <app-doc-dir>/avatar_packages/<packageId>/
  static const String packagesRootFolderName = 'avatar_packages';

  final AppCacheService _cache;
  final AvatarPackageRemoteSource? _remote;

  AvatarPackageService(this._cache, {AvatarPackageRemoteSource? remote})
      : _remote = remote;

  // ----------------------------
  // Installed package registry
  // ----------------------------

  Future<List<AvatarPackageManifest>> listInstalledPackages() async {
    final raw = _cache.get<Map<String, dynamic>>(_installedKey);
    if (raw == null || raw.isEmpty) return const [];

    final out = <AvatarPackageManifest>[];
    for (final entry in raw.entries) {
      final v = entry.value;
      if (v is Map) {
        out.add(AvatarPackageManifest.fromJson(Map<String, dynamic>.from(v)));
      }
    }
    return out;
  }

  Future<void> upsertInstalledPackage(AvatarPackageManifest manifest) async {
    final raw = _cache.get<Map<String, dynamic>>(_installedKey) ?? <String, dynamic>{};
    raw[manifest.id] = manifest.toJson();
    _cache.setJson(_installedKey, raw);
  }

  Future<void> removeInstalledPackage(String packageId) async {
    final raw = _cache.get<Map<String, dynamic>>(_installedKey) ?? <String, dynamic>{};
    raw.remove(packageId);
    _cache.setJson(_installedKey, raw);
  }

  // ----------------------------
  // Paths
  // ----------------------------

  /// You should implement this in AppCacheService already (or provide it).
  /// Expected: returns app documents directory.
  Future<Directory> _appDocDir() => _cache.getAppDocDir(); // Error: The method 'getAppDocDir' isn't defined for the type 'AppCacheService'. Try correcting the name to the name of an existing method, or defining a method named 'getAppDocDir'.

  Future<Directory> getPackagesRootDir() async {
    final doc = await _appDocDir();
    final dir = Directory(p.join(doc.path, packagesRootFolderName));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<Directory> getPackageDir(String packageId) async {
    final root = await getPackagesRootDir();
    final dir = Directory(p.join(root.path, packageId));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  // ----------------------------
  // Local asset listing (used by AvatarAssetLoader)
  // ----------------------------

  /// Load ALL local image avatars from installed packages.
  /// Returns resolved file paths that UI can display.
  Future<List<AvatarResolvedAsset>> loadAllLocalImageAvatars() async {
    final pkgs = await listInstalledPackages();
    final out = <AvatarResolvedAsset>[];

    for (final pkgManifest in pkgs) {
      final pkgDir = await getPackageDir(pkgManifest.id);

      // Images folder
      final imagesDir = Directory(p.join(pkgDir.path, pkgManifest.imagesDir));
      if (!await imagesDir.exists()) continue;

      // Prefer index.json if present (fast + stable).
      final indexed = await _tryReadIndex(imagesDir);
      if (indexed != null) {
        for (final rel in indexed.items) {
          if (_isImage(rel)) {
            out.add(
              AvatarResolvedAsset(
                source: AvatarSource.file,
                path: p.join(imagesDir.path, rel),
                packageId: pkgManifest.id,
              ),
            );
          }
        }
        continue;
      }

      // Fallback: recursive scan (slower, but robust)
      final files = await imagesDir
          .list(recursive: true, followLinks: false)
          .where((e) => e is File)
          .cast<File>()
          .toList();

      for (final f in files) {
        if (_isImage(f.path)) {
          out.add(
            AvatarResolvedAsset(
              source: AvatarSource.file,
              path: f.path,
              packageId: pkgManifest.id,
            ),
          );
        }
      }
    }

    return _dedupeResolved(out);
  }

  /// Load ALL local 3D avatars from installed packages.
  /// Note: your current UI can ignore these until DepthCard properly supports file paths.
  Future<List<AvatarResolvedAsset>> loadAllLocalThreeDAvatars() async {
    final pkgs = await listInstalledPackages();
    final out = <AvatarResolvedAsset>[];

    for (final pkgManifest in pkgs) {
      final pkgDir = await getPackageDir(pkgManifest.id);

      final modelsDir = Directory(p.join(pkgDir.path, pkgManifest.modelsDir));
      if (!await modelsDir.exists()) continue;

      final indexed = await _tryReadIndex(modelsDir);
      if (indexed != null) {
        for (final rel in indexed.items) {
          if (_is3d(rel)) {
            out.add(
              AvatarResolvedAsset(
                source: AvatarSource.file,
                path: p.join(modelsDir.path, rel),
                packageId: pkgManifest.id,
              ),
            );
          }
        }
        continue;
      }

      final files = await modelsDir
          .list(recursive: true, followLinks: false)
          .where((e) => e is File)
          .cast<File>()
          .toList();

      for (final f in files) {
        if (_is3d(f.path)) {
          out.add(
            AvatarResolvedAsset(
              source: AvatarSource.file,
              path: f.path,
              packageId: pkgManifest.id,
            ),
          );
        }
      }
    }

    return _dedupeResolved(out);
  }

  Future<FolderIndex?> _tryReadIndex(Directory dir) async {
    final f = File(p.join(dir.path, 'index.json'));
    if (!await f.exists()) return null;

    try {
      final s = await f.readAsString();
      final json = jsonDecode(s) as Map<String, dynamic>;
      return FolderIndex.fromJson(json);
    } catch (_) {
      return null;
    }
  }

  // ----------------------------
  // Download + install (server later)
  // ----------------------------

  /// Installs a downloaded archive into a package folder and writes/updates manifest.
  /// You’ll call this from your “Packages” tab later.
  Future<void> installFromArchive({
    required String packageId,
    required File archiveFile,
    required AvatarPackageManifest manifest,
  }) async {
    final dest = await getPackageDir(packageId);

    // Clean existing folder first (prevents file leftovers from older versions).
    if (await dest.exists()) {
      await dest.delete(recursive: true);
    }
    await dest.create(recursive: true);

    await _extractArchive(archiveFile, dest);
    await upsertInstalledPackage(manifest);
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
      // Robust approach: bytes -> gunzip -> tar
      final bytes = await archiveFile.readAsBytes();
      final ungz = GZipDecoder().decodeBytes(bytes);
      final archive = TarDecoder().decodeBytes(ungz);
      await _writeArchiveToDisk(archive, destDir);
      return;
    }

    throw UnsupportedError('Unsupported archive type: ${archiveFile.path}');
  }

  Future<void> _writeArchiveToDisk(Archive archive, Directory destDir) async {
    for (final file in archive) {
      final filename = file.name;

      // prevent zip-slip
      final normalized = p.normalize(filename);
      if (p.isAbsolute(normalized) || normalized.startsWith('..')) continue;

      final outPath = p.join(destDir.path, normalized);

      if (file.isFile) {
        final outFile = File(outPath);
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      } else {
        final outDir = Directory(outPath);
        await outDir.create(recursive: true);
      }
    }
  }

  // ----------------------------
  // Helpers
  // ----------------------------

  static bool _isImage(String path) {
    final l = path.toLowerCase();
    return l.endsWith('.png') ||
        l.endsWith('.jpg') ||
        l.endsWith('.jpeg') ||
        l.endsWith('.webp');
  }

  static bool _is3d(String path) {
    final l = path.toLowerCase();
    return l.endsWith('.glb') || l.endsWith('.gltf');
  }

  static List<AvatarResolvedAsset> _dedupeResolved(List<AvatarResolvedAsset> items) {
    final seen = <String>{};
    final out = <AvatarResolvedAsset>[];
    for (final it in items) {
      final key = '${it.source.name}:${it.path}';
      if (seen.add(key)) out.add(it);
    }
    out.sort((a, b) => a.path.compareTo(b.path));
    return out;
  }
}
