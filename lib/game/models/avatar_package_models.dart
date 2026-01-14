import 'dart:convert';

/// Keep server packages image-only for now.
/// Later, you can extend render hints to include 3D/DepthCard configs.
enum AvatarPackageType {
  image,
  depthCard,
}

/// Where an avatar came from.
enum AvatarSource {
  asset,
  file,
  remote,
}

/// More Flutter-friendly, future-proof avatar kind.
/// This lets you evolve beyond [AvatarPackageType] without breaking existing data.
enum AvatarKind {
  image,
  threeD,
}

AvatarKind _kindFromPackageType(AvatarPackageType t) {
  switch (t) {
    case AvatarPackageType.image:
      return AvatarKind.image;
    case AvatarPackageType.depthCard:
      return AvatarKind.threeD;
  }
}

/// A single avatar item you can render/select.
/// This is the core object the UI should work with.
class AvatarEntry {
  /// Stable identifier for selection/storage.
  /// For packaged avatars, you can use something like: "packageId:relativePath"
  final String id;

  /// Asset path (assets/...), absolute file path, or remote URL depending on [source].
  final String path;

  /// Optional nicer label for UI.
  final String? displayName;

  /// Optional thumbnail (asset/file/url) for faster grid rendering.
  /// If null, the UI can render [path] directly for images.
  final String? thumbnailPath;

  /// Tags for filtering/search.
  final List<String> tags;

  /// Where this avatar comes from.
  final AvatarSource source;

  /// Optional: which package it came from (helps with uninstall/debug).
  final String? packageId;

  /// Optional: type info without relying on file extension.
  final AvatarKind kind;

  /// Future-proof bucket for extra fields (rarer use).
  final Map<String, dynamic> meta;

  const AvatarEntry({
    required this.id,
    required this.path,
    required this.source,
    this.displayName,
    this.thumbnailPath,
    this.tags = const [],
    this.packageId,
    this.kind = AvatarKind.image,
    this.meta = const {},
  });

  AvatarEntry copyWith({
    String? id,
    String? path,
    AvatarSource? source,
    String? displayName,
    String? thumbnailPath,
    List<String>? tags,
    String? packageId,
    AvatarKind? kind,
    Map<String, dynamic>? meta,
  }) {
    return AvatarEntry(
      id: id ?? this.id,
      path: path ?? this.path,
      source: source ?? this.source,
      displayName: displayName ?? this.displayName,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      tags: tags ?? this.tags,
      packageId: packageId ?? this.packageId,
      kind: kind ?? this.kind,
      meta: meta ?? this.meta,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'path': path,
    'displayName': displayName,
    'thumbnailPath': thumbnailPath,
    'tags': tags,
    'source': source.name,
    'packageId': packageId,
    'kind': kind.name,
    'meta': meta,
  };

  /// Note: source may be supplied externally (e.g. you know the package is local),
  /// but we also allow reading it from JSON for flexibility.
  factory AvatarEntry.fromJson(
      Map<String, dynamic> json, {
        AvatarSource? sourceOverride,
        String? packageIdOverride,
        AvatarKind? kindOverride,
      }) {
    final sourceStr = json['source']?.toString();
    final src = sourceOverride ??
        AvatarSource.values.firstWhere(
              (e) => e.name == sourceStr,
          orElse: () => AvatarSource.asset,
        );

    final kindStr = json['kind']?.toString();
    final kind = kindOverride ??
        AvatarKind.values.firstWhere(
              (e) => e.name == kindStr,
          orElse: () => AvatarKind.image,
        );

    final rawTags = json['tags'];
    final tags = (rawTags is List)
        ? rawTags.map((e) => e.toString()).toList()
        : const <String>[];

    final meta = (json['meta'] is Map)
        ? Map<String, dynamic>.from(json['meta'] as Map)
        : const <String, dynamic>{};

    return AvatarEntry(
      id: (json['id'] ?? '').toString(),
      path: (json['path'] ?? '').toString(),
      displayName: json['displayName']?.toString(),
      thumbnailPath: json['thumbnailPath']?.toString(),
      tags: tags,
      source: src,
      packageId: packageIdOverride ?? json['packageId']?.toString(),
      kind: kind,
      meta: meta,
    );
  }
}

class AvatarPackage {
  final String packageId;
  final String displayName;
  final String version;
  final AvatarPackageType type;

  /// Where this package came from (local install vs remote catalog vs asset-bundled).
  final AvatarSource source;

  final List<AvatarEntry> avatars;

  const AvatarPackage({
    required this.packageId,
    required this.displayName,
    required this.version,
    required this.type,
    required this.source,
    required this.avatars,
  });

  Map<String, dynamic> toJson() => {
    'packageId': packageId,
    'displayName': displayName,
    'version': version,
    'type': type.name,
    'source': source.name,
    'avatars': avatars.map((a) => a.toJson()).toList(),
  };

  factory AvatarPackage.fromJson(
      Map<String, dynamic> json, {
        required AvatarSource source,
      }) {
    final typeStr = json['type']?.toString() ?? 'image';
    final type = AvatarPackageType.values.firstWhere(
          (e) => e.name == typeStr,
      orElse: () => AvatarPackageType.image,
    );

    final kind = _kindFromPackageType(type);

    final rawAvatars = json['avatars'];
    final avatars = (rawAvatars is List)
        ? rawAvatars
        .whereType<Map>()
        .map((e) => AvatarEntry.fromJson(
      Map<String, dynamic>.from(e),
      sourceOverride: source,
      packageIdOverride: json['packageId']?.toString(),
      kindOverride: kind,
    ))
        .toList()
        : <AvatarEntry>[];

    return AvatarPackage(
      packageId: (json['packageId'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      version: (json['version'] ?? '1.0.0').toString(),
      type: type,
      source: source,
      avatars: avatars,
    );
  }
}

/// A small reference type.
/// Recommendation: keep for compatibility, but prefer using [AvatarEntry] everywhere.
///
/// You can deprecate later:
/// @Deprecated('Use AvatarEntry instead.')
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
  /// NOTE: this field name is “kind” but it aligns with package type.
  final AvatarPackageType kind;

  /// Optional: recommended preview image path inside package folder.
  /// Example: "previews/cover.png"
  final String? previewImagePath;

  const AvatarPackageRenderHints({
    this.kind = AvatarPackageType.image,
    this.previewImagePath,
  });

  Map<String, dynamic> toJson() => {
    'kind': kind.name,
    'previewImagePath': previewImagePath,
  };

  factory AvatarPackageRenderHints.fromJson(Map<String, dynamic> json) {
    final kindStr = (json['kind'] ?? 'image').toString();
    final kind = AvatarPackageType.values.firstWhere(
          (x) => x.name == kindStr,
      orElse: () => AvatarPackageType.image,
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
      sizeBytes: json['sizeBytes'] is int
          ? json['sizeBytes'] as int
          : int.tryParse('${json['sizeBytes']}'),
      sha256: json['sha256']?.toString(),
      render: json['render'] is Map
          ? AvatarPackageRenderHints.fromJson(
        Map<String, dynamic>.from(json['render'] as Map),
      )
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
      meta: AvatarPackageMetadata.fromJson(
        Map<String, dynamic>.from(json['meta'] as Map),
      ),
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