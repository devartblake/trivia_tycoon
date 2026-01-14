import 'dart:convert';
import 'package:flutter/services.dart';

import '../../core/services/storage/app_cache_service.dart';
import '../models/avatar_package_models.dart';
import '../services/avatar_package_service.dart';

class AvatarAssetLoader {
  // Bundled asset folders
  static const String imageAvatarPath = 'assets/images/avatars/';
  static const String threeDAvatarPath = 'assets/3d/characters/';

  /// Index files generated in your zip build step
  static const String _imagesIndexAsset = 'assets/images/index.json';
  static const String _threeDIndexAsset = 'assets/3d/index.json';

  /// If you want to disable local packages temporarily, flip this.
  static bool enableLocalPackages = true;

  /// Loads image avatars from:
  /// 1) bundled assets via index.json (preferred)
  /// 2) fallback to AssetManifest.json if index missing
  /// 3) local installed packages (optional)
  static Future<List<String>> loadImageAvatars({AppCacheService? cache}) async {
    final assetList = await _loadBundledImages();

    if (!enableLocalPackages || cache == null) {
      return _dedupeSorted(assetList);
    }

    final pkg = AvatarPackageService(cache);
    final locals = await pkg.loadAllLocalImageAvatars();

    final merged = <String>[
      ...assetList,
      ...locals.where((e) => e.source == AvatarSource.file).map((e) => e.path),
    ];

    return _dedupeSorted(merged);
  }

  /// Loads 3D avatars from:
  /// 1) bundled assets via index.json (preferred)
  /// 2) fallback to AssetManifest.json if index missing
  /// 3) local installed packages (optional)
  static Future<List<String>> loadThreeDAvatars({AppCacheService? cache}) async {
    final assetList = await _loadBundled3d();

    if (!enableLocalPackages || cache == null) {
      return _dedupeSorted(assetList);
    }

    final pkg = AvatarPackageService(cache);
    final locals = await pkg.loadAllLocalThreeDAvatars();

    final merged = <String>[
      ...assetList,
      ...locals.where((e) => e.source == AvatarSource.file).map((e) => e.path),
    ];

    return _dedupeSorted(merged);
  }

  // ------------------------
  // Bundled assets via index.json
  // ------------------------

  static Future<List<String>> _loadBundledImages() async {
    final idx = await _tryLoadIndex(_imagesIndexAsset);
    if (idx != null) {
      // items contain "avatars/xxx.png" relative to assets/images/
      final out = idx.items
          .where((p) => p.startsWith('avatars/'))
          .where(_isImageRel)
          .map((rel) => 'assets/images/$rel')
          .toList()
        ..sort();
      return out;
    }

    // Fallback
    return _loadFromAssetManifest(imageAvatarPath, is3D: false);
  }

  static Future<List<String>> _loadBundled3d() async {
    final idx = await _tryLoadIndex(_threeDIndexAsset);
    if (idx != null) {
      // items contain "characters/xxx.glb" relative to assets/3d/
      final out = idx.items
          .where((p) => p.startsWith('characters/'))
          .where(_is3dRel)
          .map((rel) => 'assets/3d/$rel')
          .toList()
        ..sort();
      return out;
    }

    // Fallback
    return _loadFromAssetManifest(threeDAvatarPath, is3D: true);
  }

  static Future<_Index?> _tryLoadIndex(String assetPath) async {
    try {
      final s = await rootBundle.loadString(assetPath);
      final map = jsonDecode(s) as Map<String, dynamic>;
      final raw = map['items'];
      if (raw is! List) return null;
      final items = raw.map((e) => e.toString()).toList();
      return _Index(items: items);
    } catch (_) {
      return null;
    }
  }

  // ------------------------
  // Fallback: AssetManifest.json
  // ------------------------

  static Future<List<String>> _loadFromAssetManifest(String path, {required bool is3D}) async {
    try {
      final manifestContent = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = json.decode(manifestContent);

      final allAssets = manifestMap.keys.where((String key) {
        if (!key.startsWith(path)) return false;
        if (is3D) return key.endsWith('.glb') || key.endsWith('.gltf');
        return key.endsWith('.png') ||
            key.endsWith('.jpg') ||
            key.endsWith('.jpeg') ||
            key.endsWith('.webp');
      }).toList();

      allAssets.sort();
      return allAssets;
    } catch (_) {
      // If manifest truly unavailable, return empty rather than crash.
      return const [];
    }
  }

  // ------------------------
  // Helpers
  // ------------------------

  static bool _isImageRel(String rel) {
    final l = rel.toLowerCase();
    return l.endsWith('.png') || l.endsWith('.jpg') || l.endsWith('.jpeg') || l.endsWith('.webp');
  }

  static bool _is3dRel(String rel) {
    final l = rel.toLowerCase();
    return l.endsWith('.glb') || l.endsWith('.gltf');
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
}

class _Index {
  final List<String> items;
  const _Index({required this.items});
}
