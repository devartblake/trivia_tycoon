import 'dart:developer' as developer;
import 'dart:developer';
import 'dart:ui' as ui;
import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:path/path.dart' as path;
import 'package:vector_math/vector_math.dart' as vec32;
import 'package:flutter/material.dart';

void main() => runApp(OBJApp());

class OBJApp extends StatelessWidget {
  const OBJApp({super.key});

  @override
  Widget build(context) {
    return MaterialApp(
      home: OBJHome(),
    );
  }
}

class OBJHome extends StatelessWidget {
  const OBJHome({super.key});

  @override
  Widget build(context) {
    return Container(
      color: Color(0xFF223388),
      child: OBJViewer(),
    );
  }
}

class OBJViewer extends StatefulWidget {
  const OBJViewer({super.key});

  @override
  State createState() {
    return OBJViewerState();
  }
}

class OBJViewerState extends State<OBJViewer> {
  /// One instance per sub-object (keyed by sub-object name).
  Map<String, VertexMeshInstance> _instances = {};
  late vec32.Quaternion _rotation;

  OBJViewerState() : _rotation = vec32.Quaternion.identity();

  @override
  void initState() {
    super.initState();
    _loadMesh();
  }

  @override
  Widget build(context) {
    return GestureDetector(
      onPanUpdate: _handleDragUpdate,
      child: CustomPaint(
        // Render all sub-objects with the same shared transform.
        painter: MultiMeshCustomPainter(_instances.values.toList()),
      ),
    );
  }

  Future<void> _loadMesh() async {
    // Example: load with a scale of 1.0 (pass a different value to resize).
    final meshes = await loadVertexMeshFromOBJAsset(
      context,
      'assets',
      'thing.obj',
      scale: 1.0,
    );
    _instances = meshes.map((name, mesh) => MapEntry(name, VertexMeshInstance(mesh)));
    _updateTransform();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    _rotation *= vec32.Quaternion.axisAngle(
        vec32.Vector3(0.0, 1.0, 0.0), details.delta.dx / 100);
    _rotation *= vec32.Quaternion.axisAngle(
        vec32.Vector3(1.0, 0.0, 0.0), details.delta.dy / 100);
    _rotation.normalize();
    _updateTransform();
  }

  void _updateTransform() {
    final modelMatrix = vec32.Matrix4.compose(
        vec32.Vector3.zero(), _rotation, vec32.Vector3.all(1.0));
    final viewMatrix = vec32.makeViewMatrix(
        vec32.Vector3(0.0, 0.0, 4.0),
        vec32.Vector3(0.0, 0.0, 0.0),
        vec32.Vector3(0.0, 1.0, 0.0));
    final projMatrix =
        vec32.makePerspectiveMatrix(math.pi / 2.0, 320.0 / 480.0, 0.01, 100.0);
    final transform = viewMatrix * modelMatrix;

    setState(() {
      for (final instance in _instances.values) {
        instance.setTransform(transform, projMatrix);
      }
    });
  }
}

class OBJLoaderMaterial {
  String? name;

  Color? diffuseColor;

  String? texturePath;
  ui.Image? texture;
}

class OBJLoaderFace {
  final List<vec32.Vector3> _positions;
  final List<vec32.Vector3> _normals;
  final List<vec32.Vector2> _uvs;
  String? materialName;

  /// Shading group from the `s` OBJ directive.
  /// 0  → flat shading (s off / s 0)
  /// >0 → smooth shading group ID (faces in the same group share averaged normals)
  int shadingGroup = 0;

  OBJLoaderFace()
      : _positions = List<vec32.Vector3>.filled(3, vec32.Vector3.zero()),
        _normals = List<vec32.Vector3>.filled(3, vec32.Vector3.zero()),
        _uvs = List<vec32.Vector2>.filled(3, vec32.Vector2.zero());

  List<vec32.Vector3> get positions => _positions;

  List<vec32.Vector3> get normals => _normals;

  List<vec32.Vector2> get uvs => _uvs;
}

// ---------------------------------------------------------------------------
// Texture-atlas helpers
// ---------------------------------------------------------------------------

/// UV sub-region within the atlas for a single material's texture.
/// All values are in normalised atlas coordinates [0, 1].
class _AtlasRegion {
  final double uOffset;
  final double vOffset;
  final double uScale;
  final double vScale;

  const _AtlasRegion({
    required this.uOffset,
    required this.vOffset,
    required this.uScale,
    required this.vScale,
  });

  /// Remap a face UV coordinate into atlas space.
  ui.Offset remap(double u, double v) =>
      ui.Offset(uOffset + u * uScale, vOffset + v * vScale);
}

/// Result of a texture-atlas build: the combined image and per-material regions.
class _AtlasResult {
  final ui.Image image;
  final Map<String, _AtlasRegion> regions;

  _AtlasResult({required this.image, required this.regions});
}

// ---------------------------------------------------------------------------

class OBJLoader {
  final AssetBundle _bundle;
  final String _basePath;
  final String _objPath;

  /// Uniform scale applied to all vertex positions at load time.
  final double _scale;

  String? _mtlPath;
  String? _objSource;
  String? _mtlSource;

  /// Faces grouped by sub-object name (from `o` directives).
  final Map<String, List<OBJLoaderFace>> _objectFaces;

  /// The sub-object name currently being parsed.
  String _currentObjectName;

  final Map<String, OBJLoaderMaterial> _materials;

  /// Maximum size (px) to which individual textures are clamped before
  /// being placed in the atlas.  Keeps atlas memory in check on low-end GPUs.
  static const int _maxTextureSize = 512;

  /// Maximum atlas dimension.  Guaranteed to fit in OpenGL ES 2.0 (min 2048).
  static const int _maxAtlasDim = 2048;

  OBJLoader(this._bundle, this._basePath, this._objPath, {double scale = 1.0})
      : _scale = scale,
        _objectFaces = <String, List<OBJLoaderFace>>{},
        _currentObjectName = 'default',
        _materials = <String, OBJLoaderMaterial>{};

  /// Parse the OBJ (and its MTL) and return one [VertexMesh] per sub-object.
  ///
  /// Models without `o` lines are returned under the key `'default'`.
  Future<Map<String, VertexMesh>> parse() async {
    String p = path.join(_basePath, _objPath);
    _objSource = await _bundle.loadString(p);
    _parseOBJFile();

    if (_mtlPath != null) {
      p = path.join(_basePath, _mtlPath!);
      try {
        _mtlSource = await _bundle.loadString(p);
        _parseMTLFile();
        await _loadMTLTextures();
      } catch (_) {
        // MTL may be absent or fail to load — continue with colour-only rendering.
      }
    }

    final atlas = await _buildTextureAtlas();

    final result = <String, VertexMesh>{};
    for (final entry in _objectFaces.entries) {
      if (entry.value.isNotEmpty) {
        result[entry.key] = _buildVertexMeshForObject(entry.value, atlas);
      }
    }
    return result;
  }

  void _parseOBJFile() {
    final List<vec32.Vector3> positions = <vec32.Vector3>[];
    final List<vec32.Vector3> normals = <vec32.Vector3>[];
    final List<vec32.Vector2> uvs = <vec32.Vector2>[];
    String? currentMaterialName;
    int currentShadingGroup = 0;

    // Initialise the default sub-object bucket.
    _objectFaces.putIfAbsent(_currentObjectName, () => <OBJLoaderFace>[]);

    final objLines = _objSource?.split('\n') ?? [];
    for (var line in objLines) {
      line = line.replaceAll('\r', '').trim();

      if (line.startsWith('v ')) {
        final args = line.split(' ');
        positions.add(vec32.Vector3(
          double.parse(args[1]) * _scale,
          double.parse(args[2]) * _scale,
          double.parse(args[3]) * _scale,
        ));
      } else if (line.startsWith('vn ')) {
        final args = line.split(' ');
        normals.add(vec32.Vector3(
          double.parse(args[1]),
          double.parse(args[2]),
          double.parse(args[3]),
        ));
      } else if (line.startsWith('vt ')) {
        final args = line.split(' ');
        uvs.add(vec32.Vector2(double.parse(args[1]), double.parse(args[2])));

      } else if (line.startsWith('o ')) {
        // Begin a new named sub-object.
        _currentObjectName = line.substring(2).trim();
        _objectFaces.putIfAbsent(_currentObjectName, () => <OBJLoaderFace>[]);

      } else if (line.startsWith('f ')) {
        final args = line.split(' ');
        // Only triangulated faces (3 vertices) are supported.
        if (args.length != 4) continue;

        final v0 = args[1].split('/');
        final v1 = args[2].split('/');
        final v2 = args[3].split('/');

        final face = OBJLoaderFace();

        face.positions[0] = positions[int.parse(v0[0]) - 1];
        face.positions[1] = positions[int.parse(v1[0]) - 1];
        face.positions[2] = positions[int.parse(v2[0]) - 1];

        // Vertex normals (vn index is the third '/'-separated component).
        if (normals.isNotEmpty && v0.length > 2 && v0[2].isNotEmpty) {
          face.normals[0] = normals[int.parse(v0[2]) - 1];
          face.normals[1] = normals[int.parse(v1[2]) - 1];
          face.normals[2] = normals[int.parse(v2[2]) - 1];
        } else {
          // No stored normals — will be computed geometrically during mesh build.
          face.normals[0] = face.normals[1] = face.normals[2] = vec32.Vector3.zero();
        }

        // UV coordinates (vt index is the second component).
        if (uvs.isNotEmpty && v0.length > 1 && v0[1].isNotEmpty) {
          face.uvs[0] = uvs[int.parse(v0[1]) - 1];
          face.uvs[1] = uvs[int.parse(v1[1]) - 1];
          face.uvs[2] = uvs[int.parse(v2[1]) - 1];
        } else {
          face.uvs[0] = face.uvs[1] = face.uvs[2] = vec32.Vector2.zero();
        }

        face.materialName = currentMaterialName;
        face.shadingGroup = currentShadingGroup;
        _objectFaces[_currentObjectName]!.add(face);

      } else if (line.startsWith('mtllib ')) {
        _mtlPath = line.split(' ')[1];

      } else if (line.startsWith('usemtl ')) {
        currentMaterialName = line.split(' ').skip(1).join(' ');

      } else if (line.startsWith('s ')) {
        // `s 1` / `s <n>` → smooth shading group N.
        // `s off` / `s 0` → flat shading.
        final arg = line.split(' ').skip(1).join(' ').trim();
        currentShadingGroup =
            (arg == 'off' || arg == '0') ? 0 : (int.tryParse(arg) ?? 1);
      }
    }
  }

  void _parseMTLFile() {
    final mtlLines = _mtlSource?.split('\n') ?? [];

    OBJLoaderMaterial? currentMaterial;

    for (var line in mtlLines) {
      line = line.replaceAll("\r", "");
      if (line.startsWith('newmtl ')) {
        if (currentMaterial != null) _materials[currentMaterial.name!] = currentMaterial;

        currentMaterial = OBJLoaderMaterial();
        currentMaterial.name = line.split(' ')[1];
      } else if (line.startsWith('Kd ')) {
        if (currentMaterial != null) {
          final args = line.split(' ');
          currentMaterial.diffuseColor = Color.fromARGB(255, (double.parse(args[1]) * 255).round(),
              (double.parse(args[2]) * 255).round(), (double.parse(args[3]) * 255).round());
        }
      } else if (line.startsWith('map_Kd ')) {
        if (currentMaterial != null) {
          final args = line.split(' ');
          currentMaterial.texturePath = args[1];
        }
      }
    }

    if (currentMaterial != null) _materials[currentMaterial.name!] = currentMaterial;
  }

  Future<void> _loadMTLTextures() async {
    List<Future<void>> imageFutures = <Future<void>>[];

    for (var mtl in _materials.values) {
      if (mtl.texturePath != null) {
        log('loading texture: ${mtl.texturePath}');
        final c = Completer<void>();
        imageFutures.add(c.future);
        AssetImage(path.join(_basePath, mtl.texturePath), bundle: _bundle).resolve(ImageConfiguration()).addListener(
          ImageStreamListener((ImageInfo info, bool _) {
            log('loaded texture: ${mtl.texturePath}');
            mtl.texture = info.image;
            c.complete();
          }),
        );
      }
    }

    await Future.wait(imageFutures);
  }

  // ---------------------------------------------------------------------------
  // Smooth-shading normal computation
  // ---------------------------------------------------------------------------

  /// For every face that belongs to a non-zero shading group, compute the
  /// geometric face normal and accumulate it at each vertex position within
  /// that shading group.  After accumulation the normals are normalised.
  ///
  /// Returns a map keyed by `'<group>|<x>,<y>,<z>'` → averaged normal.
  Map<String, vec32.Vector3> _computeSmoothNormals(List<OBJLoaderFace> faces) {
    final accumulator = <String, vec32.Vector3>{};

    for (final face in faces) {
      if (face.shadingGroup == 0) continue;

      // Geometric face normal (cross product of two edges).
      final p0 = face.positions[0];
      final p1 = face.positions[1];
      final p2 = face.positions[2];
      final edge1 = p1 - p0;
      final edge2 = p2 - p0;
      final faceNormal = edge1.cross(edge2);
      if (faceNormal.length < 1e-8) continue; // degenerate face

      faceNormal.normalize();

      for (int j = 0; j < 3; j++) {
        final p = face.positions[j];
        final key = '${face.shadingGroup}|${p.x},${p.y},${p.z}';
        accumulator.update(
          key,
          (existing) => existing + faceNormal,
          ifAbsent: () => faceNormal.clone(),
        );
      }
    }

    // Normalise accumulated normals.
    for (final n in accumulator.values) {
      if (n.length > 1e-8) n.normalize();
    }

    return accumulator;
  }

  // ---------------------------------------------------------------------------
  // Per-sub-object vertex mesh builder
  // ---------------------------------------------------------------------------

  VertexMesh _buildVertexMeshForObject(
      List<OBJLoaderFace> faces, _AtlasResult? atlas) {
    final smoothNormals = _computeSmoothNormals(faces);

    final Map<String, int> vertexMap = {};
    final List<double> uniquePositions = [];
    final List<double> uniqueNormals = [];
    final List<double> uniqueUVs = [];
    final List<int> uniqueColors = [];
    final List<int> indexList = [];

    // Texture to use: atlas image if available, otherwise the first single
    // material texture.
    final ui.Image? texture = atlas?.image ??
        (_materials.values
            .firstWhere((m) => m.texture != null,
                orElse: () => OBJLoaderMaterial())
            .texture);

    for (final face in faces) {
      final matColor =
          _materials[face.materialName]?.diffuseColor?.value ?? 0xFFFFFFFF;
      final atlasRegion = atlas?.regions[face.materialName];

      for (int j = 0; j < 3; j++) {
        final p = face.positions[j];
        final uv = face.uvs[j];

        // Resolve normal: smooth-shaded → averaged geometric normal;
        // flat-shaded → stored per-vertex normal (or zero if absent).
        final vec32.Vector3 n;
        if (face.shadingGroup != 0) {
          final key = '${face.shadingGroup}|${p.x},${p.y},${p.z}';
          n = smoothNormals[key] ?? face.normals[j];
        } else {
          n = face.normals[j];
        }

        // Remap UV into atlas space when applicable.
        final double atlasU;
        final double atlasV;
        if (atlasRegion != null) {
          final remapped = atlasRegion.remap(uv.x, uv.y);
          atlasU = remapped.dx;
          atlasV = remapped.dy;
        } else {
          atlasU = uv.x;
          atlasV = uv.y;
        }

        // Vertex deduplication key.
        // Smooth-shaded vertices are keyed by position+uv+material (the normal
        // is the same for all faces sharing the position in the same group).
        // Flat-shaded vertices include the stored normal in the key so that
        // hard-edge corners are preserved.
        final String key;
        if (face.shadingGroup != 0) {
          key = '${p.x},${p.y},${p.z}|${atlasU},${atlasV}|${face.materialName}';
        } else {
          key = '${p.x},${p.y},${p.z}|${n.x},${n.y},${n.z}|${atlasU},${atlasV}|${face.materialName}';
        }

        if (!vertexMap.containsKey(key)) {
          vertexMap[key] = vertexMap.length;
          uniquePositions.addAll([p.x, p.y, p.z]);
          uniqueNormals.addAll([n.x, n.y, n.z]);
          uniqueUVs.addAll([atlasU, atlasV]);
          uniqueColors.add(matColor);
        }
        indexList.add(vertexMap[key]!);
      }
    }

    return VertexMesh(
      positions: Float32List.fromList(uniquePositions),
      normals: Float32List.fromList(uniqueNormals),
      uvs: Float32List.fromList(uniqueUVs),
      colors: Int32List.fromList(uniqueColors),
      indices: Uint16List.fromList(indexList),
      texture: texture,
    );
  }

  // ---------------------------------------------------------------------------
  // Texture atlas builder
  // ---------------------------------------------------------------------------

  /// Builds a texture atlas from all materials that have a loaded texture.
  ///
  /// Atlas layout: textures are arranged in a square grid, each cell clamped
  /// to [_maxTextureSize] × [_maxTextureSize].  Returns `null` when no
  /// textured materials exist.  A single-texture model bypasses the atlas path
  /// for efficiency.
  ///
  /// GPU memory note: the atlas is capped at [_maxAtlasDim] × [_maxAtlasDim]
  /// (2048 × 2048), which fits within the OpenGL ES 2.0 minimum guarantee.
  Future<_AtlasResult?> _buildTextureAtlas() async {
    final textured =
        _materials.values.where((m) => m.texture != null).toList();

    if (textured.isEmpty) return null;

    // Single texture — wrap it without building a full atlas.
    if (textured.length == 1) {
      final mat = textured.first;
      return _AtlasResult(
        image: mat.texture!,
        regions: {
          mat.name!: const _AtlasRegion(
              uOffset: 0, vOffset: 0, uScale: 1, vScale: 1),
        },
      );
    }

    // Determine grid dimensions (ceil(sqrt(N)) × ceil(N / cols)).
    final n = textured.length;
    final cols = math.sqrt(n).ceil();
    final rows = (n / cols).ceil();

    // Cell size: smallest power-of-two that fits all textures, capped.
    int cellSize = _maxTextureSize;
    for (final m in textured) {
      final w = m.texture!.width;
      final h = m.texture!.height;
      cellSize = math.max(cellSize, math.max(w, h));
    }
    cellSize = math.min(cellSize, _maxTextureSize);

    final atlasW = cols * cellSize;
    final atlasH = rows * cellSize;

    if (atlasW > _maxAtlasDim || atlasH > _maxAtlasDim) {
      log('[OBJLoader] Warning: texture atlas ${atlasW}×${atlasH} exceeds '
          '$_maxAtlasDim×$_maxAtlasDim. Consider reducing texture count or '
          'resolution for low-end GPU compatibility.');
    }

    // Render each texture into a grid cell on a single canvas.
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final regions = <String, _AtlasRegion>{};

    for (int i = 0; i < textured.length; i++) {
      final mat = textured[i];
      final col = i % cols;
      final row = i ~/ cols;

      final destX = (col * cellSize).toDouble();
      final destY = (row * cellSize).toDouble();

      // Draw texture into its atlas cell, scaling to fit cellSize.
      final src = ui.Rect.fromLTWH(
          0, 0, mat.texture!.width.toDouble(), mat.texture!.height.toDouble());
      final dst =
          ui.Rect.fromLTWH(destX, destY, cellSize.toDouble(), cellSize.toDouble());
      canvas.drawImageRect(mat.texture!, src, dst, ui.Paint());

      regions[mat.name!] = _AtlasRegion(
        uOffset: destX / atlasW,
        vOffset: destY / atlasH,
        uScale: cellSize / atlasW,
        vScale: cellSize / atlasH,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(atlasW, atlasH);
    picture.dispose();

    return _AtlasResult(image: image, regions: regions);
  }
}

/// Load an OBJ asset and return a named map of [VertexMesh] objects, one per
/// sub-object defined by `o` directives in the file.  Models without explicit
/// `o` lines are returned under the key `'default'`.
///
/// [scale] is a uniform scale applied to all vertex positions at load time.
/// Use it to resize a model without modifying the asset file.
Future<Map<String, VertexMesh>> loadVertexMeshFromOBJAsset(
  BuildContext context,
  String basePath,
  String objPath, {
  double scale = 1.0,
}) async {
  final bundle = DefaultAssetBundle.of(context);
  final loader = OBJLoader(bundle, basePath, objPath, scale: scale);
  return loader.parse();
}

class VertexMesh {
  /// 3D local space position vertex data
  Float32List positions;

  /// 3D local space normal vertex data
  Float32List normals;

  /// 2D texture space uv vertex data
  Float32List uvs;

  /// Material vertex color's
  Int32List colors;

  /// Triangle indices
  Uint16List indices;

  /// Material texture
  ui.Image? texture;

  VertexMesh({
    required this.positions,
    required this.normals,
    required this.uvs,
    required this.colors,
    required this.indices,
    this.texture,
  });

  int get vertexCount => positions.length ~/ 3;

  void log() {
    for (int i = 0; i < indices.length; i += 3) {
      var x0 = positions[indices[i + 0] * 3 + 0];
      var y0 = positions[indices[i + 0] * 3 + 1];
      var z0 = positions[indices[i + 0] * 3 + 2];

      var x1 = positions[indices[i + 1] * 3 + 0];
      var y1 = positions[indices[i + 1] * 3 + 1];
      var z1 = positions[indices[i + 1] * 3 + 2];

      var x2 = positions[indices[i + 2] * 3 + 0];
      var y2 = positions[indices[i + 2] * 3 + 1];
      var z2 = positions[indices[i + 2] * 3 + 2];

      developer.log('f: {${x0.toStringAsFixed(3)}, ${y0.toStringAsFixed(3)}, ${z0.toStringAsFixed(3)}}, {${x1.toStringAsFixed(3)}, ${y1.toStringAsFixed(3)}, ${z1.toStringAsFixed(3)}}, {${x2.toStringAsFixed(3)}, ${y2.toStringAsFixed(3)}, ${z2.toStringAsFixed(3)}}');
    }
  }
}

class VertexMeshInstance {
  final VertexMesh _mesh;

  /// Post transform draw ready vertices
  late ui.Vertices _vertices;

  late vec32.Matrix4 _modelView;
  late vec32.Matrix4 _projection;

  bool _vertexCacheInvalid;

  /// True when the mesh transform has changed and a repaint is needed.
  bool get isDirty => _vertexCacheInvalid;

  VertexMeshInstance(this._mesh) : _vertexCacheInvalid = true;

  void setTransform(vec32.Matrix4 modelView, vec32.Matrix4 projection) {
    _modelView = modelView;
    _projection = projection;
    _vertexCacheInvalid = true;
  }

  ui.Vertices get vertices {
    if (_vertexCacheInvalid) _cacheVertices();

    return _vertices;
  }

  ui.Image? get texture {
    return _mesh.texture;
  }

  void _cacheVertices() {
    // Create vertices from mesh data
    List<vec32.Vector4> transformedPositions = List<vec32.Vector4>.filled(_mesh.vertexCount, vec32.Vector4.zero());
    List<int> culledIndices = <int>[];

    final transform = _projection * _modelView;

    // Transform vertices
    for (int i = 0; i < _mesh.vertexCount; ++i) {
      vec32.Vector4 position =
      vec32.Vector4(_mesh.positions[i * 3 + 0], _mesh.positions[i * 3 + 1], _mesh.positions[i * 3 + 2], 1.0);
      position = transform.transform(position);
      position.xyz /= position.w;

      transformedPositions[i] = position;
    }

    // Cull back faces
    for (int i = 0; i < _mesh.indices.length; i += 3) {
      final a = transformedPositions[_mesh.indices[i + 0]].xyz;
      final b = transformedPositions[_mesh.indices[i + 1]].xyz;
      final c = transformedPositions[_mesh.indices[i + 2]].xyz;

      final ab = b - a;
      final ac = c - a;

      if (ab.cross(ac).z > 0.0) {
        // Insert the faces that are visible (vertices with ccw winding with a normal pointed towards the camera)
        culledIndices.add(_mesh.indices[i + 0]);
        culledIndices.add(_mesh.indices[i + 1]);
        culledIndices.add(_mesh.indices[i + 2]);
      }
    }

    // Depth sort
        {
      final tmpCulledIndices = List<int>.from(culledIndices);
      assert(tmpCulledIndices.length == culledIndices.length);
      _triangleMergeSortSplit(transformedPositions, culledIndices, tmpCulledIndices, 0, culledIndices.length ~/ 3);
    }

    // Build 2d positions array
    Float32List positions2D = Float32List(_mesh.vertexCount * 2);
    for (int i = 0; i < _mesh.vertexCount; ++i) {
      // Transformed positions are in ndc space, transform that into view coordinates
      positions2D[i * 2 + 0] = transformedPositions[i].x;
      positions2D[i * 2 + 1] = transformedPositions[i].y;
    }

    // Basic light
    Int32List colors = Int32List(_mesh.vertexCount);
    for (int i = 0; i < colors.length; ++i) {
      final b = 1.0; //xn.dot(vec32.Vector3(0.5, 0.5, 1.0).normalized()).clamp(0.1, 1.0);

      colors[i] = 0xFF000000 |
      ((b * ((_mesh.colors[i] >> 16) & 0xFF)).floor() << 16) |
      ((b * ((_mesh.colors[i] >> 8) & 0xFF)).floor() << 8) |
      ((b * ((_mesh.colors[i] >> 0) & 0xFF)).floor() << 0);
    }

    _vertices = ui.Vertices.raw(VertexMode.triangles, positions2D,
        indices: Uint16List.fromList(culledIndices), textureCoordinates: _mesh.uvs, colors: colors);

    _vertexCacheInvalid = false;
  }
}

/// Painter that renders a list of [VertexMeshInstance] objects (i.e. multiple
/// sub-objects) in a single [CustomPaint] pass, sharing the same canvas
/// transform.  Each sub-object retains its own texture/colour state.
class MultiMeshCustomPainter extends CustomPainter {
  final List<VertexMeshInstance> _instances;

  MultiMeshCustomPainter(this._instances);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width * 0.5, size.height * 0.5);
    canvas.translate(1.0, 1.0);
    canvas.scale(1, -1); // flip Y from NDC to screen space

    for (final instance in _instances) {
      final paint = Paint();
      if (instance.texture != null) {
        paint.shader = ImageShader(
          instance.texture!,
          TileMode.clamp,
          TileMode.clamp,
          Matrix4.identity()
              .scaled(1 / instance.texture!.width,
                  1 / instance.texture!.height, 1.0)
              .storage,
        );
      }
      canvas.drawVertices(instance.vertices, BlendMode.multiply, paint);
    }
  }

  @override
  bool shouldRepaint(MultiMeshCustomPainter old) {
    if (_instances.length != old._instances.length) return true;
    for (int i = 0; i < _instances.length; i++) {
      if (_instances[i] != old._instances[i] || _instances[i].isDirty) {
        return true;
      }
    }
    return false;
  }
}

class MeshCustomPainter extends CustomPainter {
  final VertexMeshInstance? _meshInstance;

  MeshCustomPainter(this._meshInstance);

  @override
  void paint(canvas, size) {
    canvas.scale(size.width * 0.5, size.height * 0.5);
    canvas.translate(1.0, 1.0);

    // Flip y
    canvas.scale(1, -1);

    if (_meshInstance != null) {
      final paint = Paint();
      if (_meshInstance!.texture != null) {
        paint.shader = ImageShader(
            _meshInstance!.texture!,
            TileMode.clamp,
            TileMode.clamp,
            Matrix4.identity()
                .scaled(1 / _meshInstance!.texture!.width, 1 / _meshInstance!.texture!.height, 1.0)
                .storage);
      }

      canvas.drawVertices(_meshInstance!.vertices, BlendMode.multiply, paint);
    }
  }

  @override
  bool shouldRepaint(MeshCustomPainter oldDelegate) {
    // Repaint when the mesh instance changes identity, or when the existing
    // instance has pending transform updates (isDirty is set by setModelView /
    // setProjection and cleared inside _cacheVertices after each paint).
    return _meshInstance != oldDelegate._meshInstance ||
        (_meshInstance?.isDirty ?? false);
  }
}

bool _compareDepth(List<vec32.Vector4> positions, List<int> src, int indexA, int indexB) {
  double depthA, depthB;
  {
    final a = positions[src[indexA * 3 + 0]];
    final b = positions[src[indexA * 3 + 1]];
    final c = positions[src[indexA * 3 + 2]];

    depthA = (a.z + b.z + c.z) / 3.0;
  }
  {
    final a = positions[src[indexB * 3 + 0]];
    final b = positions[src[indexB * 3 + 1]];
    final c = positions[src[indexB * 3 + 2]];

    depthB = (a.z + b.z + c.z) / 3.0;
  }

  return depthA > depthB;
}

void _triangleMergeSortMerge(
    List<vec32.Vector4> positions, List<int> dst, List<int> src, int begin, int middle, int end) {
  assert(begin < middle && middle < end);
  int j = begin, k = middle;
  for (int i = begin; i < end; ++i) {
    if (j < middle && (k >= end || _compareDepth(positions, src, j, k))) {
      dst[i * 3 + 0] = src[j * 3 + 0];
      dst[i * 3 + 1] = src[j * 3 + 1];
      dst[i * 3 + 2] = src[j * 3 + 2];
      ++j;
    } else {
      dst[i * 3 + 0] = src[k * 3 + 0];
      dst[i * 3 + 1] = src[k * 3 + 1];
      dst[i * 3 + 2] = src[k * 3 + 2];
      ++k;
    }
  }
}

void _triangleMergeSortSplit(List<vec32.Vector4> positions, List<int> dst, List<int> src, int begin, int end) {
  final count = end - begin;
  final middle = begin + count ~/ 2;
  if (count > 2) {
    _triangleMergeSortSplit(positions, src, dst, begin, middle);
    _triangleMergeSortSplit(positions, src, dst, middle, end);
    _triangleMergeSortMerge(positions, dst, src, begin, middle, end);
  }
}
