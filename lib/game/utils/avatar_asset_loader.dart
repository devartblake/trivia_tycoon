import 'dart:convert';
import 'package:flutter/services.dart';
import '../../core/services/storage/app_cache_service.dart';
import '../models/avatar_package_models.dart';
import '../services/avatar_package_service.dart';

class AvatarAssetLoader {
  // Your existing paths remain unchanged
  static const String imageAvatarPath = 'assets/images/avatars/';
  static const String threeDAvatarPath = 'assets/3d/characters/';

  /// If you want to disable local packages temporarily, flip this.
  static bool enableLocalPackages = true;

  /// Loads image avatars from bundled assets AND local installed packages.
  ///
  /// Returns a list of strings. For compatibility:
  /// - asset images are returned as asset paths (as before)
  /// - local images are returned as absolute file paths
  static Future<List<String>> loadImageAvatars({
    AppCacheService? cache,
  }) async {
    final assetList = await _loadAvatarsFromAssets(imageAvatarPath, is3D: false);

    if (!enableLocalPackages || cache == null) {
      return assetList;
    }

    final pkg = AvatarPackageService(cache);
    final locals = await pkg.loadAllLocalImageAvatars();

    final merged = <String>[
      ...assetList,
      ...locals.where((e) => e.source == AvatarSource.file).map((e) => e.path),
    ];

    return _dedupeSorted(merged);
  }

  /// Loads 3D avatars from bundled assets AND local installed packages.
  ///
  /// Returns a list of strings. For compatibility:
  /// - asset models are returned as asset paths (as before)
  /// - local models are returned as absolute file paths
  ///
  /// Note: whether your 3D renderer supports file paths depends on your DepthCard3D stack.
  static Future<List<String>> loadThreeDAvatars({
    AppCacheService? cache,
  }) async {
    final assetList = await _loadAvatarsFromAssets(threeDAvatarPath, is3D: true);

    if (!enableLocalPackages || cache == null) {
      return assetList;
    }

    final pkg = AvatarPackageService(cache);
    final locals = await pkg.loadAllLocalThreeDAvatars();

    final merged = <String>[
      ...assetList,
      ...locals.where((e) => e.source == AvatarSource.file).map((e) => e.path),
    ];

    return _dedupeSorted(merged);
  }

  static Future<List<String>> _loadAvatarsFromAssets(String path, {required bool is3D}) async {
    final manifestContent = await rootBundle.loadString('AssetManifest.json');
    final Map<String, dynamic> manifestMap = json.decode(manifestContent);

    final allAssets = manifestMap.keys
        .where((String key) {
      if (!key.startsWith(path)) return false;

      if (is3D) {
        return key.endsWith('.glb') || key.endsWith('.gltf');
      }
      return key.endsWith('.png') || key.endsWith('.jpg') || key.endsWith('.jpeg') || key.endsWith('.webp');
    })
        .toList();

    allAssets.sort();
    return allAssets;
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
