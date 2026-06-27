# 3D Renderer Improvement Plan

**File under review:** `lib/animations/ui/widget_model.dart`
**Author:** Claude Code
**Status:** ✅ COMPLETE — all items implemented

---

## Context

The app includes a hand-written OBJ/MTL 3D model renderer that uses Flutter's
low-level `Canvas.drawVertices()` API. It parses `.obj` and `.mtl` asset files
and renders rotating 3D models.

**Assets currently in use:**

| Asset | Sub-objects (`o`) | Materials (`newmtl`) | Has textures? | Smooth shading? |
|---|---|---|---|---|
| `assets/models/flutter_dash.obj` | **8** | 7 (in `.mtl`) | No — color only | Yes (`s 1`) |
| `assets/models/cartoon_character.obj` | 1 | Unknown | Unknown | Yes (`s 1`) |

---

## TODO #1 — Multi-Object Support (`o` directive) ✅ IMPLEMENTED

**Decision:** Option B — named map of meshes (full sub-object control).

### What changed
- `OBJLoader` now maintains a `Map<String, List<OBJLoaderFace>> _objectFaces` keyed by sub-object name.
- Each `o <name>` line in the OBJ file starts a new entry in that map; subsequent faces are accumulated under that key.
- `parse()` returns `Map<String, VertexMesh>` (was: single `VertexMesh`).
- `loadVertexMeshFromOBJAsset()` returns `Map<String, VertexMesh>`.
- `OBJViewerState` stores `Map<String, VertexMeshInstance>` and renders via `MultiMeshCustomPainter`.
- Sub-objects with no faces (empty `o` sections) are silently skipped.

### New public API
```dart
Future<Map<String, VertexMesh>> loadVertexMeshFromOBJAsset(
  BuildContext context, String basePath, String objPath, {double scale = 1.0});
```

---

## TODO #2 — Smooth Shading Groups (`s` directive) ✅ IMPLEMENTED

**Decision:** Smooth shading is required. `s` is parsed as a shading-group directive per
the OBJ spec, NOT as scale (a separate `scale` load-time parameter was added instead).

### What changed
- `OBJLoaderFace` now carries an `int shadingGroup` field (`0` = flat, `>0` = smooth group ID).
- During OBJ parsing, `s off` / `s 0` sets `currentShadingGroup = 0`; `s N` sets it to `N`.
- New `_computeSmoothNormals()` method runs a two-pass average:
  1. Accumulates geometric face normals (cross product of edges) per unique vertex position + shading group.
  2. Normalises each accumulated normal.
- In `_buildVertexMeshForObject()`, smooth-shaded vertices use the averaged normal from the above map.
  The vertex deduplication key for smooth-shaded vertices **excludes** the normal component so that
  adjacent faces sharing the same position are merged into one vertex entry.
- Flat-shaded faces (`shadingGroup == 0`) keep per-face geometric normals and use the full
  `position|normal|uv|material` dedup key (preserving hard edges).
- Normal averaging runs once at load time — zero per-frame cost.

### Load-time scale parameter (also added here)
```dart
OBJLoader(bundle, basePath, objPath, scale: 1.0)
// All parsed vertex positions are multiplied by scale at parse time.
```

---

## TODO #3 — Vertex Deduplication ✅ IMPLEMENTED (prerequisite for #2)

### What changed
- `_buildVertexMeshForObject()` maintains a `Map<String, int> indexMap` keyed by a
  canonical vertex string.
- For flat-shaded vertices: key = `"x,y,z|nx,ny,nz|u,v|material"`.
- For smooth-shaded vertices: key = `"x,y,z|u,v|material"` (normal excluded; looked up from smooth-normal map).
- Duplicate vertices reuse the existing index rather than appending a new entry.
- Resulting meshes have significantly fewer vertices than the pre-dedup face-list form.

---

## TODO #4 — Multi-Material Texture Atlas ✅ IMPLEMENTED

**Decision:** Texture-mapped models are planned. GPU memory limits for low-end devices
must be considered.

### What changed
- `_buildTextureAtlas()` collects all non-null `ui.Image` textures from loaded materials.
- **Single-texture fast path:** if only one material has a texture, the atlas is bypassed
  and that image is used directly — no atlas overhead.
- **Multi-texture path:** textures are arranged in a square grid
  (`ceil(√N) × ceil(N/cols)` layout). Each cell is capped at **512×512 px** to
  stay within OpenGL ES 2.0 minimums on low-end devices. If the resulting atlas
  would exceed **2048×2048 px** (the OpenGL ES 2.0 guaranteed maximum texture size),
  a warning is logged via `dart:developer` `log()`.
- `_AtlasRegion` records `(uOffset, vOffset, uScale, vScale)` per material so that
  UV coordinates are remapped into the correct sub-region before vertex deduplication.
- UV remapping happens **before** deduplication so the dedup key uses atlas-space UVs.
- The single atlas `ui.Image` is stored on `VertexMesh.texture`.

### GPU memory guidance
| Atlas size | Memory (RGBA8) | Status |
|---|---|---|
| 512 × 512 | 1 MB | Safe on all devices |
| 1024 × 1024 | 4 MB | Safe |
| 2048 × 2048 | 16 MB | Boundary — warn |
| 4096 × 4096 | 64 MB | Exceeds many low-end GPUs |

---

## TODO #5 — `shouldRepaint` State Diff ✅ IMPLEMENTED

### What changed
- `MultiMeshCustomPainter.shouldRepaint()` compares `_instances` list length and
  per-instance identity / `isDirty` flag rather than always returning `true`.
- `VertexMeshInstance.isDirty` is set when the transform matrix changes and cleared
  after each paint cycle, preventing unnecessary repaints when nothing has changed.

---

## Summary

| TODO | Decision | Status |
|---|---|---|
| #1 Multi-object (`o`) | Option B — named map of meshes | ✅ Done |
| #2 Smooth shading (`s`) | Smooth required; `s` = shading group (not scale); scale = separate param | ✅ Done |
| #3 Vertex deduplication | Canonical key per vertex; dedup before mesh build | ✅ Done |
| #4 Texture atlas | GPU-aware square-grid atlas; 512 px/cell cap; 2048 atlas warn | ✅ Done |
| #5 `shouldRepaint` diff | Per-instance dirty flag + length check | ✅ Done |

All improvements are client-side only — no backend changes required.
