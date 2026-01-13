import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:crypto/crypto.dart';
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
  static const _cacheKeyServerList = 'avatar_packages_server_list_v1';

  final AppCacheService _cache;
  final AvatarPackageRemoteSource? _remote;

  AvatarPackageService(
      this._cache, {
        AvatarPackageRemoteSource? remote,
      }) : _remote = remote;

  /// Where packages are installed:
  /// <documents>/avatarPackages/<packageId_version>/
  Future<Directory> _packagesRootDir() async {
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

  /// Local: discover installed packages by scanning avatarPackages/*/manifest.json.
  Future<List<AvatarPackageInstall>> listInstalled() async {
    final root = await _packagesRootDir();
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

  Future<bool> isInstalled(AvatarPackageMetadata meta) async {
    final root = await _packagesRootDir();
    final folder = Directory(p.join(root.path, meta.installFolderName));
    final manifest = File(p.join(folder.path, 'manifest.json'));
    return await folder.exists() && await manifest.exists();
  }

  /// Install flow:
  /// 1) download archive
  /// 2) optional sha256 verify
  /// 3) extract to install dir
  /// 4) write manifest.json
  Future<AvatarPackageInstall> downloadAndInstall(AvatarPackageMetadata meta) async {
    final url = meta.archiveUrl;
    if (url == null || url.isEmpty) {
      throw StateError('archiveUrl is missing for package ${meta.id}.');
    }

    final root = await _packagesRootDir();
    final installDir = Directory(p.join(root.path, meta.installFolderName));

    // If a previous install exists, delete it to avoid mixed files.
    if (await installDir.exists()) {
      await installDir.delete(recursive: true);
    }
    await installDir.create(recursive: true);

    final tmp = await getTemporaryDirectory();
    final archiveFile = File(p.join(tmp.path, '${meta.installFolderName}${_guessArchiveSuffix(url)}'));

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

    final manifest = await _manifestFile(installDir);
    await manifest.writeAsString(install.toPrettyJson());

    return install;
  }

  Future<void> uninstall(AvatarPackageInstall install) async {
    final dir = Directory(install.installDir);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<List<AvatarAssetRef>> loadAllLocalImageAvatars() async {
    final installs = await listInstalled();
    final out = <AvatarAssetRef>[];

    const exts = ['.png', '.jpg', '.jpeg', '.webp'];

    for (final install in installs) {
      final dir = Directory(install.installDir);
      if (!await dir.exists()) continue;

      final files = dir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) {
        final e = p.extension(f.path).toLowerCase();
        return exts.contains(e);
      });

      for (final f in files) {
        out.add(AvatarAssetRef(source: AvatarSource.file, path: f.path));
      }
    }

    return out;
  }

  Future<List<AvatarAssetRef>> loadAllLocalThreeDAvatars() async {
    final installs = await listInstalled();
    final out = <AvatarAssetRef>[];

    const exts = ['.glb', '.gltf'];

    for (final install in installs) {
      final dir = Directory(install.installDir);
      if (!await dir.exists()) continue;

      final files = dir
          .listSync(recursive: true, followLinks: false)
          .whereType<File>()
          .where((f) {
        final e = p.extension(f.path).toLowerCase();
        return exts.contains(e);
      });

      for (final f in files) {
        out.add(AvatarAssetRef(source: AvatarSource.file, path: f.path));
      }
    }

    return out;
  }

  // -----------------------
  // Internals
  // -----------------------

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

  String _guessArchiveSuffix(String url) {
    final lower = url.toLowerCase();
    if (lower.endsWith('.tar.gz')) return '.tar.gz';
    if (lower.endsWith('.tgz')) return '.tgz';
    if (lower.endsWith('.tar')) return '.tar';
    if (lower.endsWith('.zip')) return '.zip';
    // default: zip
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
      // Most reliable approach with archive package:
      // bytes -> gunzip -> untar
      final bytes = await archiveFile.readAsBytes();
      final tarBytes = GZipDecoder().decodeBytes(bytes);
      final archive = TarDecoder().decodeBytes(tarBytes);
      await _writeArchiveToDisk(archive, destDir);
      return;
    }

    // NOTE: RAR is not supported by `archive` package.
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
        await outFile.writeAsBytes(data);
      } else {
        final outDirectory = Directory(outPath);
        await outDirectory.create(recursive: true);
      }
    }
  }
}
