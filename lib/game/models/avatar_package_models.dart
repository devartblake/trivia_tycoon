import 'dart:convert';

/// Keep server packages image-only for now.
/// Later, you can extend render hints to include 3D/DepthCard configs.
enum AvatarPackageKind {
  image,
  // depthCard3d, // later
}

/// Where an avatar came from.
enum AvatarSource {
  asset,
  file,
}

/// A single avatar “thing” that can be displayed/selected.
/// For now, it is just a path + source.
/// Later you can extend this to include render hints (DepthCardConfig, etc.).
class AvatarAssetRef {
  final AvatarSource source;

  /// For [AvatarSource.asset], this is an asset path like `assets/images/...`.
  /// For [AvatarSource.file], this is an absolute file path.
  final String path;

  const AvatarAssetRef({
    required this.source,
    required this.path,
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
