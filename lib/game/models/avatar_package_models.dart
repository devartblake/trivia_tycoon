import 'dart:convert';

/// Keep server packages image-only for now.
/// Later, you can extend render hints to include 3D/DepthCard configs.
enum AvatarPackageType {
  image,
  threeD,
}

/// Where an avatar came from.
enum AvatarSource {
  asset,
  file,
  remote,
}

class AvatarEntry {
  final String id;
  final String path;
  final List<String> tags;
  final AvatarSource source;

  const AvatarEntry({
    required this.id,
    required this.path,
    required this.source,
    this.tags = const [],
  });

  factory AvatarEntry.fromJson(Map<String, dynamic> json, AvatarSource source) {
    return AvatarEntry(
      id: json['id'],
      path: json['path'],
      tags: List<String>.from(json['tags'] ?? []),
      source: source,
    );
  }
}

class AvatarPackage {
  final String packageId;
  final String displayName;
  final String version;
  final AvatarPackageType type;
  final List<AvatarEntry> avatars;

  const AvatarPackage({
    required this.packageId,
    required this.displayName,
    required this.version,
    required this.type,
    required this.avatars,
  });

  factory AvatarPackage.fromJson(
      Map<String, dynamic> json,
      AvatarSource source,
      ) {
    return AvatarPackage(
      packageId: json['packageId'],
      displayName: json['displayName'],
      version: json['version'],
      type: AvatarPackageType.values.byName(json['type']),
      avatars: (json['avatars'] as List)
          .map((e) => AvatarEntry.fromJson(e, source))
          .toList(),
    );
  }
}

/// Simple, Flutter-friendly resolved asset used by UI.
class AvatarResolvedAsset {
  final AvatarSource source;

  /// If [source] == asset => Flutter asset path (e.g. assets/images/avatars/a.png)
  /// If [source] == file  => absolute file path on device
  final String path;

  /// Optional: which package this came from (local installed package id)
  final String? packageId;

  const AvatarResolvedAsset({
    required this.source,
    required this.path,
    this.packageId,
  });
}

/// A single avatar “thing” that can be displayed/selected.
/// For now, it is just a path + source.
/// Later you can extend this to include render hints (DepthCardConfig, etc.).
class AvatarAssetRef {
  final AvatarSource source;

  /// For [AvatarSource.asset], this is an asset path like `assets/images/...`.
  /// For [AvatarSource.file], this is an absolute file path.
  final String path;

  /// Which package this came from (local installed package id)
  final String? packageId;

  const AvatarAssetRef({
    required this.source,
    required this.path,
    this.packageId,
  });
}

class AvatarPackageRenderHints {
  final AvatarPackageKind kind;

  /// Optional: recommended preview image path inside package folder.
  /// Example: "previews/cover.png"
  final String? previewImagePath;

  const AvatarPackageRenderHints({
    this.kind = AvatarPackageKind.image,
    this.previewImagePath,
  });

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'previewImagePath': previewImagePath,
  };

  factory AvatarPackageRenderHints.fromJson(Map<String, dynamic> json) {
    final kindStr = (json['kind'] ?? 'image').toString();
    final kind = AvatarPackageKind.values.firstWhere(
          (x) => x.name == kindStr,
      orElse: () => AvatarPackageKind.image,
    );

    return AvatarPackageRenderHints(
      kind: kind,
      previewImagePath: json['previewImagePath']?.toString(),
    );
  }
}

class AvatarPackageMetadata {
  final String id;
  final String name;

  /// Semver-ish string. Up to you.
  final String version;

  /// URL to a preview/thumbnail image (can be CDN).
  final String? thumbnailUrl;

  /// URL to archive file (.zip / .tar.gz / .tgz / .tar)
  final String? archiveUrl;

  final int? sizeBytes;

  /// Optional checksum for integrity (hex).
  final String? sha256;

  final AvatarPackageRenderHints render;

  const AvatarPackageMetadata({
    required this.id,
    required this.name,
    required this.version,
    this.thumbnailUrl,
    this.archiveUrl,
    this.sizeBytes,
    this.sha256,
    this.render = const AvatarPackageRenderHints(),
  });

  String get installFolderName => '${id}_$version';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'thumbnailUrl': thumbnailUrl,
    'archiveUrl': archiveUrl,
    'sizeBytes': sizeBytes,
    'sha256': sha256,
    'render': render.toJson(),
  };

  factory AvatarPackageMetadata.fromJson(Map<String, dynamic> json) {
    return AvatarPackageMetadata(
      id: json['id'].toString(),
      name: (json['name'] ?? '').toString(),
      version: (json['version'] ?? '1.0.0').toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      archiveUrl: json['archiveUrl']?.toString(),
      sizeBytes: json['sizeBytes'] is int ? json['sizeBytes'] as int : int.tryParse('${json['sizeBytes']}'),
      sha256: json['sha256']?.toString(),
      render: json['render'] is Map
          ? AvatarPackageRenderHints.fromJson(Map<String, dynamic>.from(json['render'] as Map))
          : const AvatarPackageRenderHints(),
    );
  }
}

/// Local install record (derived from manifest.json).
class AvatarPackageInstall {
  final AvatarPackageMetadata meta;

  /// Absolute folder on device where package is extracted.
  final String installDir;

  /// ISO UTC.
  final String installedAtUtcIso;

  const AvatarPackageInstall({
    required this.meta,
    required this.installDir,
    required this.installedAtUtcIso,
  });

  Map<String, dynamic> toJson() => {
    'meta': meta.toJson(),
    'installDir': installDir,
    'installedAtUtcIso': installedAtUtcIso,
  };

  factory AvatarPackageInstall.fromJson(Map<String, dynamic> json) {
    return AvatarPackageInstall(
      meta: AvatarPackageMetadata.fromJson(Map<String, dynamic>.from(json['meta'] as Map)),
      installDir: json['installDir'].toString(),
      installedAtUtcIso: json['installedAtUtcIso'].toString(),
    );
  }

  String toPrettyJson() => const JsonEncoder.withIndent('  ').convert(toJson());
}

/// Lightweight “index.json” format for assets.
/// This matches the indexes you generated in the zip:
/// {
///   "version": 1,
///   "generatedAt": "...",
///   "items": [ "avatars/a.png", "packages/p1.png", ... ]
/// }
class FolderIndex {
  final int version;
  final List<String> items;

  const FolderIndex({
    required this.version,
    required this.items,
  });

  factory FolderIndex.fromJson(Map<String, dynamic> json) {
    final raw = json['items'];
    final items = <String>[];
    if (raw is List) {
      for (final v in raw) {
        if (v != null) items.add(v.toString());
      }
    }
    return FolderIndex(
      version: (json['version'] ?? 1) is int ? (json['version'] as int) : 1,
      items: items,
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'items': items,
  };

  static FolderIndex decode(String s) =>
      FolderIndex.fromJson(jsonDecode(s) as Map<String, dynamic>);
}

/// A package manifest (local or remote).
/// Keep JSON keys stable so your FastAPI can return the same structure later.
class AvatarPackageManifest {
  final String id;
  final String name;
  final String version; // "1.0.0"
  final String description;

  /// image-only for now (your current requirement).
  /// Keep string for backend friendliness: "image" | "model3d"
  final String kind;

  /// Optional preview image (asset or url depending on where used).
  final String? thumbnail;

  /// Optional categories/tags for UI.
  final List<String> tags;

  /// Where to find assets inside the installed package folder.
  /// Example:
  ///  - imagesDir: "images"
  ///  - modelsDir: "models"
  final String imagesDir;
  final String modelsDir;

  const AvatarPackageManifest({
    required this.id,
    required this.name,
    required this.version,
    required this.description,
    required this.kind,
    this.thumbnail,
    this.tags = const [],
    this.imagesDir = 'images',
    this.modelsDir = 'models',
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'version': version,
    'description': description,
    'kind': kind,
    'thumbnail': thumbnail,
    'tags': tags,
    'imagesDir': imagesDir,
    'modelsDir': modelsDir,
  };

  factory AvatarPackageManifest.fromJson(Map<String, dynamic> json) {
    return AvatarPackageManifest(
      id: (json['id'] ?? '').toString(),
      name: (json['name'] ?? '').toString(),
      version: (json['version'] ?? '1.0.0').toString(),
      description: (json['description'] ?? '').toString(),
      kind: (json['kind'] ?? 'image').toString(), // "image" default
      thumbnail: json['thumbnail']?.toString(),
      tags: (json['tags'] is List)
          ? (json['tags'] as List).map((e) => e.toString()).toList()
          : const [],
      imagesDir: (json['imagesDir'] ?? 'images').toString(),
      modelsDir: (json['modelsDir'] ?? 'models').toString(),
    );
  }
}