import 'dart:convert';

import 'package:flutter/services.dart';

import '../../core/services/storage/app_cache_service.dart';
import '../models/avatar_package_models.dart';
import '../services/avatar_package_service.dart';

/// AvatarAssetLoader
///
/// Loads avatar assets from:
/// 1) Bundled "index.json" (preferred; stable even if AssetManifest has issues)
/// 2) Fallback: AssetManifest.json (bundled assets only)
/// 3) Optional: locally installed avatar packages via AvatarPackageService
///
/// IMPORTANT:
/// - The legacy API returns List<String> for UI compatibility.
/// - The preferred API returns List<AvatarAssetRef> so UI can correctly render
///   AssetImage vs FileImage without guessing.
///
/// Index format expected:
/// {
///   "items": ["avatars/a.png", "avatars/b.webp", ...]   // for images index
/// }
/// and
/// {
///   "items": ["characters/a.glb", "characters/b.gltf", ...] // for 3d index
/// }
class AvatarAssetLoader {
  // Bundled asset folders
  static const String imageAvatarPath = 'assets/images/avatars/';
  static const String threeDAvatarPath = 'assets/3d/characters/';

  /// Index files generated in your zip build step.
  /// These should be declared as assets in pubspec.yaml.
  static const String imagesIndexAsset = 'assets/images/index.json';
  static const String threeDIndexAsset = 'assets/3d/index.json';

  /// If you want to disable local packages temporarily, flip this.
  static bool enableLocalPackages = true;

  // ---------------------------------------------------------------------------
  // Legacy API (non-breaking): returns List<String>
  // ---------------------------------------------------------------------------

  /// Loads image avatars as paths.
  ///
  /// For compatibility with existing code:
  /// - assets return "assets/images/..." paths
  /// - local package avatars return absolute file paths
  ///
  /// NOTE: Your current UI uses AssetImage(imagePath).
  /// AssetImage will NOT work for file paths. If you enable local packages
  /// in the screen, you should switch the UI to use [loadImageAvatarRefs]
  /// and choose AssetImage/FileImage accordingly.
  static Future<List<String>> loadImageAvatars({AppCacheService? cache}) async {
    final refs = await loadImageAvatarRefs(cache: cache);
    return _dedupeSorted(refs.map((e) => e.path).toList());
  }

  /// Loads 3D avatars as paths.
  ///
  /// For compatibility with existing code:
  /// - assets return "assets/3d/..." paths
  /// - local package avatars return absolute file paths
  static Future<List<String>> loadThreeDAvatars(
      {AppCacheService? cache}) async {
    final refs = await loadThreeDAvatarsRefsCompat(cache: cache);
    return _dedupeSorted(refs.map((e) => e.path).toList());
  }

  // ---------------------------------------------------------------------------
  // Preferred API: returns AvatarAssetRef (Flutter-friendly)
  // ---------------------------------------------------------------------------

  /// Loads image avatars as typed refs (asset vs file).
  static Future<List<AvatarAssetRef>> loadImageAvatarRefs({
    AppCacheService? cache,
  }) async {
    final bundled = await _loadBundledImagesRefs();

    // If local packages are disabled or cache not provided, return bundled only.
    if (!enableLocalPackages || cache == null) {
      return _dedupeRefsSorted(bundled);
    }

    final pkg = AvatarPackageService(cache);
    final locals = await pkg.loadAllLocalImageAvatars();

    final merged = <AvatarAssetRef>[
      ...bundled,
      ...locals.where((e) => e.source == AvatarSource.file),
    ];

    return _dedupeRefsSorted(merged);
  }

  /// Loads 3D avatars as typed refs (asset vs file).
  static Future<List<AvatarAssetRef>> loadThreeDAvatarsRefsCompat({
    AppCacheService? cache,
  }) async {
    // Backward-compat alias if you prefer this naming.
    return loadThreeDAvatarsRefs(cache: cache);
  }

  /// Loads 3D avatars as typed refs (asset vs file).
  static Future<List<AvatarAssetRef>> loadThreeDAvatarsRefs({
    AppCacheService? cache,
  }) async {
    final bundled = await _loadBundled3dRefs();

    if (!enableLocalPackages || cache == null) {
      return _dedupeRefsSorted(bundled);
    }

    final pkg = AvatarPackageService(cache);
    final locals = await pkg.loadAllLocalThreeDAvatars();

    final merged = <AvatarAssetRef>[
      ...bundled,
      ...locals.where((e) => e.source == AvatarSource.file),
    ];

    return _dedupeRefsSorted(merged);
  }

  // ---------------------------------------------------------------------------
  // Bundled assets via index.json (preferred)
  // ---------------------------------------------------------------------------

  static Future<List<AvatarAssetRef>> _loadBundledImagesRefs() async {
    final idxItems = await _tryLoadIndexItems(imagesIndexAsset);

    if (idxItems != null) {
      // items may contain either:
      // - "avatars/xxx.png" (relative to assets/images/)
      // - full asset path
      final paths = idxItems
          .where(_isImageRel)
          .where((p) =>
              p.startsWith('avatars/') ||
              p.startsWith('assets/images/avatars/'))
          .map((rel) =>
              rel.startsWith('assets/images/') ? rel : 'assets/images/$rel')
          .toList()
        ..sort();

      return paths
          .map((p) => AvatarAssetRef(source: AvatarSource.asset, path: p))
          .toList();
    }

    // Fallback: AssetManifest.json
    final fallback = await _loadFromAssetManifest(imageAvatarPath, is3D: false);
    return fallback
        .map((p) => AvatarAssetRef(source: AvatarSource.asset, path: p))
        .toList();
  }

  static Future<List<AvatarAssetRef>> _loadBundled3dRefs() async {
    final idxItems = await _tryLoadIndexItems(threeDIndexAsset);

    if (idxItems != null) {
      // items may contain either:
      // - "characters/xxx.glb" (relative to assets/3d/)
      // - "xxx.fbx" from generator file schema
      final paths = idxItems.where(_is3dRel).map((rel) {
        if (rel.startsWith('assets/3d/')) return rel;
        if (rel.startsWith('characters/')) return 'assets/3d/$rel';
        return 'assets/3d/characters/$rel';
      }).toList()
        ..sort();

      return paths
          .map((p) => AvatarAssetRef(source: AvatarSource.asset, path: p))
          .toList();
    }

    // Fallback: AssetManifest.json
    final fallback = await _loadFromAssetManifest(threeDAvatarPath, is3D: true);
    return fallback
        .map((p) => AvatarAssetRef(source: AvatarSource.asset, path: p))
        .toList();
  }

  static Future<List<String>?> _tryLoadIndexItems(String assetPath) async {
    try {
      final s = await rootBundle.loadString(assetPath);
      final map = jsonDecode(s);

      if (map is! Map<String, dynamic>) return null;

      // Preferred schema: {"items": ["avatars/a.png", ...]}
      final rawItems = map['items'];
      if (rawItems is List) {
        final items = rawItems.map((e) => e.toString()).toList();
        if (items.isNotEmpty) return items;
      }

      // New index schema used by asset index generator:
      // {"files": [{"path": "avatars/a.png", ...}, ...]}
      final rawFiles = map['files'];
      if (rawFiles is List) {
        final items = rawFiles
            .whereType<Map>()
            .map((e) => e['path'])
            .whereType<String>()
            .toList();
        if (items.isNotEmpty) return items;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Fallback: AssetManifest.json
  // ---------------------------------------------------------------------------

  static Future<List<String>> _loadFromAssetManifest(
    String path, {
    required bool is3D,
  }) async {
    try {
      // AssetManifest.json is generated by Flutter at build time when assets exist.
      // It should be available in release builds, but may behave unexpectedly if
      // assets are misdeclared or hot reload is in a broken state.
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final decoded = json.decode(manifestContent);

      if (decoded is! Map<String, dynamic>) return const [];

      final allAssets = decoded.keys.where((String key) {
        if (!key.startsWith(path)) return false;
        if (is3D) return key.endsWith('.glb') || key.endsWith('.gltf');
        return key.endsWith('.png') ||
            key.endsWith('.jpg') ||
            key.endsWith('.jpeg') ||
            key.endsWith('.webp');
      }).toList()
        ..sort();

      return allAssets;
    } catch (_) {
      // If manifest truly unavailable, return empty rather than crash.
      return const [];
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  static bool _isImageRel(String rel) {
    final l = rel.toLowerCase();
    return l.endsWith('.png') ||
        l.endsWith('.jpg') ||
        l.endsWith('.jpeg') ||
        l.endsWith('.webp');
  }

  static bool _is3dRel(String rel) {
    final l = rel.toLowerCase();
    return l.endsWith('.glb') || l.endsWith('.gltf') || l.endsWith('.fbx');
  }

  static List<String> _dedupeSorted(List<String> items) {
    final set = <String>{};
    final out = <String>[];
    for (final it in items) {
      if (set.add(it)) out.add(it);
    }
    out.sort();
    return out;
  }

  static List<AvatarAssetRef> _dedupeRefsSorted(List<AvatarAssetRef> items) {
    // Dedupe by "source|path" to avoid duplicates if the same asset appears twice.
    final set = <String>{};
    final out = <AvatarAssetRef>[];

    for (final it in items) {
      final k = '${it.source.name}|${it.path}';
      if (set.add(k)) out.add(it);
    }

    out.sort((a, b) => a.path.compareTo(b.path));
    return out;
  }
}
