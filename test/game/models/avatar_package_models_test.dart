import 'package:flutter_test/flutter_test.dart';
import 'package:synaptix/game/models/avatar_package_models.dart';

void main() {
  // -------------------------------------------------------------------------
  // AvatarEntry.fromJson
  // -------------------------------------------------------------------------

  group('AvatarEntry.fromJson — basic fields', () {
    test('parses id and path', () {
      final entry =
          AvatarEntry.fromJson({'id': 'av1', 'path': 'assets/av1.png'});
      expect(entry.id, 'av1');
      expect(entry.path, 'assets/av1.png');
    });

    test('parses optional displayName', () {
      final entry = AvatarEntry.fromJson({
        'id': 'av1',
        'path': 'p',
        'displayName': 'Cool Avatar',
      });
      expect(entry.displayName, 'Cool Avatar');
    });

    test('displayName is null when absent', () {
      final entry = AvatarEntry.fromJson({'id': 'x', 'path': 'p'});
      expect(entry.displayName, isNull);
    });

    test('parses thumbnailPath', () {
      final entry = AvatarEntry.fromJson({
        'id': 'av2',
        'path': 'p',
        'thumbnailPath': 'assets/thumb.png',
      });
      expect(entry.thumbnailPath, 'assets/thumb.png');
    });

    test('parses tags list', () {
      final entry = AvatarEntry.fromJson({
        'id': 'av3',
        'path': 'p',
        'tags': ['hero', 'fantasy'],
      });
      expect(entry.tags, ['hero', 'fantasy']);
    });

    test('tags defaults to empty list when absent', () {
      final entry = AvatarEntry.fromJson({'id': 'av4', 'path': 'p'});
      expect(entry.tags, isEmpty);
    });

    test('parses source from string', () {
      final entry =
          AvatarEntry.fromJson({'id': 'x', 'path': 'p', 'source': 'remote'});
      expect(entry.source, AvatarSource.remote);
    });

    test('defaults source to asset when unknown string', () {
      final entry =
          AvatarEntry.fromJson({'id': 'x', 'path': 'p', 'source': 'bogus'});
      expect(entry.source, AvatarSource.asset);
    });

    test('sourceOverride takes priority over JSON source', () {
      final entry = AvatarEntry.fromJson(
        {'id': 'x', 'path': 'p', 'source': 'remote'},
        sourceOverride: AvatarSource.file,
      );
      expect(entry.source, AvatarSource.file);
    });

    test('parses kind from string', () {
      final entry =
          AvatarEntry.fromJson({'id': 'x', 'path': 'p', 'kind': 'threeD'});
      expect(entry.kind, AvatarKind.threeD);
    });

    test('defaults kind to image when unknown string', () {
      final entry =
          AvatarEntry.fromJson({'id': 'x', 'path': 'p', 'kind': 'unknown'});
      expect(entry.kind, AvatarKind.image);
    });

    test('kindOverride takes priority', () {
      final entry = AvatarEntry.fromJson(
        {'id': 'x', 'path': 'p', 'kind': 'image'},
        kindOverride: AvatarKind.threeD,
      );
      expect(entry.kind, AvatarKind.threeD);
    });

    test('parses packageId', () {
      final entry = AvatarEntry.fromJson({
        'id': 'av5',
        'path': 'p',
        'packageId': 'pack_001',
      });
      expect(entry.packageId, 'pack_001');
    });

    test('packageIdOverride takes priority over JSON packageId', () {
      final entry = AvatarEntry.fromJson(
        {'id': 'x', 'path': 'p', 'packageId': 'original'},
        packageIdOverride: 'overridden',
      );
      expect(entry.packageId, 'overridden');
    });

    test('parses meta map', () {
      final entry = AvatarEntry.fromJson({
        'id': 'x',
        'path': 'p',
        'meta': {'rarity': 'epic', 'level': 5},
      });
      expect(entry.meta['rarity'], 'epic');
      expect(entry.meta['level'], 5);
    });

    test('meta defaults to empty map when absent', () {
      final entry = AvatarEntry.fromJson({'id': 'x', 'path': 'p'});
      expect(entry.meta, isEmpty);
    });

    test('id defaults to empty string when absent', () {
      final entry = AvatarEntry.fromJson({'path': 'p'});
      expect(entry.id, '');
    });
  });

  // -------------------------------------------------------------------------
  // AvatarEntry.toJson
  // -------------------------------------------------------------------------

  group('AvatarEntry.toJson', () {
    test('serializes all fields', () {
      const entry = AvatarEntry(
        id: 'av_toJson',
        path: 'assets/av.png',
        source: AvatarSource.network,
        displayName: 'My Avatar',
        thumbnailPath: 'assets/thumb.png',
        tags: ['sci-fi'],
        packageId: 'pack_2',
        kind: AvatarKind.threeD,
        meta: {'bonus': true},
      );

      final json = entry.toJson();

      expect(json['id'], 'av_toJson');
      expect(json['path'], 'assets/av.png');
      expect(json['displayName'], 'My Avatar');
      expect(json['thumbnailPath'], 'assets/thumb.png');
      expect(json['tags'], ['sci-fi']);
      expect(json['source'], 'network');
      expect(json['packageId'], 'pack_2');
      expect(json['kind'], 'threeD');
      expect(json['meta'], {'bonus': true});
    });

    test('null optional fields appear as null in JSON', () {
      const entry = AvatarEntry(
        id: 'x',
        path: 'p',
        source: AvatarSource.asset,
      );
      final json = entry.toJson();
      expect(json['displayName'], isNull);
      expect(json['thumbnailPath'], isNull);
      expect(json['packageId'], isNull);
    });
  });

  // -------------------------------------------------------------------------
  // AvatarEntry.copyWith
  // -------------------------------------------------------------------------

  group('AvatarEntry.copyWith', () {
    test('copies id', () {
      const e = AvatarEntry(id: 'old', path: 'p', source: AvatarSource.asset);
      expect(e.copyWith(id: 'new').id, 'new');
    });

    test('copies path', () {
      const e =
          AvatarEntry(id: 'x', path: 'old_path', source: AvatarSource.asset);
      expect(e.copyWith(path: 'new_path').path, 'new_path');
    });

    test('copies source', () {
      const e = AvatarEntry(id: 'x', path: 'p', source: AvatarSource.asset);
      expect(
          e.copyWith(source: AvatarSource.remote).source, AvatarSource.remote);
    });

    test('copies kind', () {
      const e = AvatarEntry(id: 'x', path: 'p', source: AvatarSource.asset);
      expect(e.copyWith(kind: AvatarKind.threeD).kind, AvatarKind.threeD);
    });

    test('copies tags', () {
      const e = AvatarEntry(
          id: 'x', path: 'p', source: AvatarSource.asset, tags: ['a']);
      expect(e.copyWith(tags: ['b', 'c']).tags, ['b', 'c']);
    });

    test('preserves unchanged fields', () {
      const e = AvatarEntry(
        id: 'orig',
        path: 'orig_path',
        source: AvatarSource.file,
        displayName: 'Name',
        kind: AvatarKind.threeD,
      );
      final updated = e.copyWith(id: 'new_id');
      expect(updated.path, 'orig_path');
      expect(updated.source, AvatarSource.file);
      expect(updated.displayName, 'Name');
      expect(updated.kind, AvatarKind.threeD);
    });
  });

  // -------------------------------------------------------------------------
  // AvatarPackage.fromJson / toJson
  // -------------------------------------------------------------------------

  group('AvatarPackage.fromJson', () {
    test('parses packageId, displayName, version', () {
      final pkg = AvatarPackage.fromJson(
        {
          'packageId': 'pkg_1',
          'displayName': 'Fantasy Pack',
          'version': '2.0.0',
          'type': 'image',
          'avatars': [],
        },
        source: AvatarSource.asset,
      );
      expect(pkg.packageId, 'pkg_1');
      expect(pkg.displayName, 'Fantasy Pack');
      expect(pkg.version, '2.0.0');
    });

    test('parses type correctly', () {
      final pkg = AvatarPackage.fromJson(
        {
          'packageId': 'x',
          'displayName': 'd',
          'version': '1',
          'type': 'depthCard',
          'avatars': []
        },
        source: AvatarSource.asset,
      );
      expect(pkg.type, AvatarPackageType.depthCard);
    });

    test('defaults type to image when unknown', () {
      final pkg = AvatarPackage.fromJson(
        {
          'packageId': 'x',
          'displayName': 'd',
          'version': '1',
          'type': 'xyz',
          'avatars': []
        },
        source: AvatarSource.asset,
      );
      expect(pkg.type, AvatarPackageType.image);
    });

    test('parses avatars list with source and packageId override', () {
      final pkg = AvatarPackage.fromJson(
        {
          'packageId': 'pkg_2',
          'displayName': 'Sci-Fi',
          'version': '1.0',
          'type': 'image',
          'avatars': [
            {'id': 'av1', 'path': 'assets/av1.png'},
            {'id': 'av2', 'path': 'assets/av2.png'},
          ],
        },
        source: AvatarSource.remote,
      );
      expect(pkg.avatars.length, 2);
      expect(pkg.avatars[0].source, AvatarSource.remote);
      expect(pkg.avatars[0].packageId, 'pkg_2');
    });

    test('defaults version to 1.0.0 when absent', () {
      final pkg = AvatarPackage.fromJson(
        {'packageId': 'x', 'displayName': 'd', 'type': 'image', 'avatars': []},
        source: AvatarSource.asset,
      );
      expect(pkg.version, '1.0.0');
    });
  });

  group('AvatarPackage.toJson', () {
    test('serializes type and source as strings', () {
      const pkg = AvatarPackage(
        packageId: 'pk',
        displayName: 'Test',
        version: '1.0',
        type: AvatarPackageType.depthCard,
        source: AvatarSource.file,
        avatars: [],
      );
      final json = pkg.toJson();
      expect(json['type'], 'depthCard');
      expect(json['source'], 'file');
      expect(json['avatars'], isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // AvatarPackageRenderHints
  // -------------------------------------------------------------------------

  group('AvatarPackageRenderHints.fromJson', () {
    test('parses kind image', () {
      final h = AvatarPackageRenderHints.fromJson({'kind': 'image'});
      expect(h.kind, AvatarPackageType.image);
    });

    test('parses kind depthCard', () {
      final h = AvatarPackageRenderHints.fromJson({'kind': 'depthCard'});
      expect(h.kind, AvatarPackageType.depthCard);
    });

    test('defaults to image when kind absent', () {
      final h = AvatarPackageRenderHints.fromJson({});
      expect(h.kind, AvatarPackageType.image);
    });

    test('parses previewImagePath', () {
      final h = AvatarPackageRenderHints.fromJson(
          {'kind': 'image', 'previewImagePath': 'previews/cover.png'});
      expect(h.previewImagePath, 'previews/cover.png');
    });

    test('previewImagePath is null when absent', () {
      final h = AvatarPackageRenderHints.fromJson({'kind': 'image'});
      expect(h.previewImagePath, isNull);
    });
  });

  group('AvatarPackageRenderHints.toJson', () {
    test('serializes kind as string', () {
      const h = AvatarPackageRenderHints(
        kind: AvatarPackageType.depthCard,
        previewImagePath: 'preview.png',
      );
      final json = h.toJson();
      expect(json['kind'], 'depthCard');
      expect(json['previewImagePath'], 'preview.png');
    });
  });

  // -------------------------------------------------------------------------
  // AvatarPackageMetadata
  // -------------------------------------------------------------------------

  group('AvatarPackageMetadata.fromJson', () {
    test('parses basic fields', () {
      final meta = AvatarPackageMetadata.fromJson({
        'id': 'meta_1',
        'name': 'Fantasy',
        'version': '3.0.0',
        'thumbnailUrl': 'http://cdn.example.com/thumb.jpg',
        'archiveUrl': 'http://cdn.example.com/pack.zip',
        'sizeBytes': 204800,
        'sha256': 'abc123',
        'render': {'kind': 'image'},
      });
      expect(meta.id, 'meta_1');
      expect(meta.name, 'Fantasy');
      expect(meta.version, '3.0.0');
      expect(meta.thumbnailUrl, 'http://cdn.example.com/thumb.jpg');
      expect(meta.archiveUrl, 'http://cdn.example.com/pack.zip');
      expect(meta.sizeBytes, 204800);
      expect(meta.sha256, 'abc123');
      expect(meta.render.kind, AvatarPackageType.image);
    });

    test('defaults version to 1.0.0 when absent', () {
      final meta = AvatarPackageMetadata.fromJson({'id': 'x', 'name': 'n'});
      expect(meta.version, '1.0.0');
    });

    test('optional fields are null when absent', () {
      final meta = AvatarPackageMetadata.fromJson({'id': 'x', 'name': 'n'});
      expect(meta.thumbnailUrl, isNull);
      expect(meta.archiveUrl, isNull);
      expect(meta.sizeBytes, isNull);
      expect(meta.sha256, isNull);
    });

    test('parses sizeBytes from string', () {
      final meta = AvatarPackageMetadata.fromJson(
          {'id': 'x', 'name': 'n', 'sizeBytes': '1024'});
      expect(meta.sizeBytes, 1024);
    });
  });

  group('AvatarPackageMetadata — installFolderName', () {
    test('returns id_version format', () {
      const meta = AvatarPackageMetadata(
          id: 'fantasy', name: 'Fantasy', version: '1.2.0');
      expect(meta.installFolderName, 'fantasy_1.2.0');
    });
  });

  group('AvatarPackageMetadata.toJson', () {
    test('serializes nested render hints', () {
      const meta = AvatarPackageMetadata(
        id: 'm1',
        name: 'Test',
        version: '1.0',
        render: AvatarPackageRenderHints(kind: AvatarPackageType.depthCard),
      );
      final json = meta.toJson();
      expect((json['render'] as Map)['kind'], 'depthCard');
    });
  });

  // -------------------------------------------------------------------------
  // AvatarPackageInstall
  // -------------------------------------------------------------------------

  group('AvatarPackageInstall.fromJson / toJson', () {
    final installJson = {
      'meta': {
        'id': 'pkg_install',
        'name': 'Install Pack',
        'version': '1.0.0',
        'render': {'kind': 'image'},
      },
      'installDir': '/data/packages/pkg_install_1.0.0',
      'installedAtUtcIso': '2025-01-01T00:00:00.000Z',
    };

    test('parses meta, installDir, installedAtUtcIso', () {
      final install = AvatarPackageInstall.fromJson(installJson);
      expect(install.meta.id, 'pkg_install');
      expect(install.installDir, '/data/packages/pkg_install_1.0.0');
      expect(install.installedAtUtcIso, '2025-01-01T00:00:00.000Z');
    });

    test('toJson round-trips installDir', () {
      final install = AvatarPackageInstall.fromJson(installJson);
      final json = install.toJson();
      expect(json['installDir'], '/data/packages/pkg_install_1.0.0');
      expect(json['installedAtUtcIso'], '2025-01-01T00:00:00.000Z');
      expect((json['meta'] as Map)['id'], 'pkg_install');
    });
  });

  // -------------------------------------------------------------------------
  // FolderIndex
  // -------------------------------------------------------------------------

  group('FolderIndex.fromJson', () {
    test('parses version and items', () {
      final fi = FolderIndex.fromJson({
        'version': 2,
        'items': ['a.png', 'b.png', 'c.png'],
      });
      expect(fi.version, 2);
      expect(fi.items, ['a.png', 'b.png', 'c.png']);
    });

    test('defaults version to 1 when absent', () {
      final fi = FolderIndex.fromJson({'items': []});
      expect(fi.version, 1);
    });

    test('items defaults to empty when absent', () {
      final fi = FolderIndex.fromJson({'version': 1});
      expect(fi.items, isEmpty);
    });

    test('nulls in items list are skipped', () {
      final fi = FolderIndex.fromJson({
        'version': 1,
        'items': ['a.png', null, 'c.png'],
      });
      expect(fi.items, ['a.png', 'c.png']);
    });
  });

  group('FolderIndex.toJson', () {
    test('serializes version and items', () {
      const fi = FolderIndex(version: 3, items: ['x.png']);
      final json = fi.toJson();
      expect(json['version'], 3);
      expect(json['items'], ['x.png']);
    });
  });

  group('FolderIndex.decode', () {
    test('decodes from JSON string', () {
      const jsonStr = '{"version": 1, "items": ["img1.png", "img2.png"]}';
      final fi = FolderIndex.decode(jsonStr);
      expect(fi.version, 1);
      expect(fi.items, ['img1.png', 'img2.png']);
    });
  });

  // -------------------------------------------------------------------------
  // AvatarPackageManifest
  // -------------------------------------------------------------------------

  group('AvatarPackageManifest.fromJson', () {
    test('parses all fields', () {
      final manifest = AvatarPackageManifest.fromJson({
        'id': 'man_1',
        'name': 'Sci-Fi Pack',
        'version': '1.5.0',
        'description': 'Futuristic avatars',
        'kind': 'image',
        'thumbnail': 'assets/thumb.png',
        'tags': ['sci-fi', 'futuristic'],
        'imagesDir': 'assets/images',
        'modelsDir': 'assets/models',
      });
      expect(manifest.id, 'man_1');
      expect(manifest.name, 'Sci-Fi Pack');
      expect(manifest.version, '1.5.0');
      expect(manifest.description, 'Futuristic avatars');
      expect(manifest.kind, 'image');
      expect(manifest.thumbnail, 'assets/thumb.png');
      expect(manifest.tags, ['sci-fi', 'futuristic']);
      expect(manifest.imagesDir, 'assets/images');
      expect(manifest.modelsDir, 'assets/models');
    });

    test('defaults when optional fields absent', () {
      final manifest = AvatarPackageManifest.fromJson({
        'id': 'x',
        'name': 'n',
        'version': '1',
        'description': 'd',
        'kind': 'image',
      });
      expect(manifest.thumbnail, isNull);
      expect(manifest.tags, isEmpty);
      expect(manifest.imagesDir, 'images');
      expect(manifest.modelsDir, 'models');
    });

    test('defaults version to 1.0.0 when absent', () {
      final manifest = AvatarPackageManifest.fromJson(
          {'id': 'x', 'name': 'n', 'description': 'd', 'kind': 'image'});
      expect(manifest.version, '1.0.0');
    });
  });

  group('AvatarPackageManifest.toJson', () {
    test('serializes all fields', () {
      const manifest = AvatarPackageManifest(
        id: 'man_2',
        name: 'Fantasy',
        version: '2.0',
        description: 'Magic avatars',
        kind: 'image',
        thumbnail: 'thumb.png',
        tags: ['magic'],
        imagesDir: 'imgs',
        modelsDir: 'mdls',
      );
      final json = manifest.toJson();
      expect(json['id'], 'man_2');
      expect(json['name'], 'Fantasy');
      expect(json['kind'], 'image');
      expect(json['tags'], ['magic']);
      expect(json['imagesDir'], 'imgs');
    });
  });
}
