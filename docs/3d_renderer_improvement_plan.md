# 3D Renderer Improvement Plan

**File under review:** `lib/animations/ui/widget_model.dart`
**Author:** Claude Code
**Status:** Awaiting design direction on 3 open questions

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

This is relevant because the three TODOs below directly affect these specific assets.

---

## TODO #1 — Multi-Object Support (`o` directive)

### Current behaviour
The OBJ parser silently **ignores** `o` lines. All faces from all 8 sub-objects in
`flutter_dash.obj` are accumulated into one flat list and rendered as a single
undifferentiated mesh. Sub-object names (e.g. `o Body`, `o Wings`) are discarded.

### What works / what breaks today
- **Works:** The model still renders — all faces from all sub-objects are drawn.
- **Breaks:** You cannot address individual sub-objects (e.g. animate the wings
  separately from the body, hide/show parts, apply different transforms to
  different pieces).

### Two implementation paths

#### Option A — Merge all sub-objects into one mesh (simple)
Finalise the current face list at each `o` line, then continue appending to the
same master list. Result: single `VertexMesh` as today, but the parser no longer
silently skips objects (all faces are still included, and ordering is preserved).

- **Effort:** ~10 lines
- **Trade-off:** No independent sub-object control; visually identical to current behaviour
- **Best if:** You only need the full model rendered as-is

#### Option B — Return a named map of meshes (full support)
Store each sub-object as a separate `VertexMesh` keyed by its name. The caller
(`loadVertexMeshFromOBJAsset`) returns `Map<String, VertexMesh>` instead of a
single `VertexMesh`.

- **Effort:** Medium — requires changing the public API and all call sites
- **Trade-off:** Full sub-object control; enables per-part animation/visibility
- **Best if:** You want to animate `flutter_dash` parts independently

### Questions for you
1. Do you need to animate or manipulate individual parts of `flutter_dash` separately
   (e.g. wing flapping, beak moving)? If yes → Option B. If no → Option A.
2. Are there planned future 3D assets that will require part-level control?

---

## TODO #2 — Smooth Shading Groups (`s` directive)

### Current behaviour
The `s` lines in both OBJ files are silently ignored. Every face is rendered with
**flat shading** — each triangle has its own hard-edged normal, causing visible
faceting on curved surfaces (spheres, rounded shapes).

Both current assets use `s 1` (smooth shading ON) throughout, so both are
currently rendering with unintended flat shading.

> **Clarification:** The `s` directive in OBJ format controls **smooth shading
> groups**, not scale. The current code comment "Set scale value" is incorrect.
> If actual scale support is needed, that requires a separate mechanism (a load-time
> parameter or a custom OBJ extension).

### What smooth shading requires
When `s 1`, vertex normals at shared positions are **averaged** across all faces
that share that vertex. This produces a smooth appearance on curved surfaces.
When `s off`, each face keeps its own flat normal.

**Prerequisite:** This depends on vertex deduplication (TODO #3, being implemented
now). Smooth shading requires knowing which vertices are geometrically shared
between adjacent faces — which vertex dedup establishes.

### Implementation plan (once TODO #3 is done)
1. Track the current smooth shading group during OBJ parsing (parse `s 1` / `s off`).
2. Tag each face with its shading group.
3. In `_buildVertexMesh()`, after deduplication, for each unique vertex that belongs
   to a smooth-shaded group, sum the normals of all faces sharing that vertex and
   normalise the result.
4. Flat-shaded vertices keep their face normal unchanged.

### Performance impact
Normal averaging runs once at load time, not per frame. Zero runtime cost.
The resulting mesh has the same vertex count as the deduped mesh.

### Questions for you
1. Is the current flat-shaded look acceptable for the production app, or is smooth
   shading required for visual quality?
2. Were you aware that `s` controls shading, not scale? If you need actual scale
   support (e.g. `s 2.0` to double a model's size), let me know and I'll design
   a separate load-time scale parameter instead.

---

## TODO #4 — Multi-Material Texture Atlas

### Current state (not currently broken)
The `.mtl` files for both models use **colour-only materials** (`Kd` diffuse colour
values). There are **no texture image files** referenced (`map_Kd` is absent).
Because of this, the current code — which grabs only `_materials.values.first.texture`
and skips the rest — doesn't cause any visual bug today: all textures are `null`,
colours are applied correctly per-face via the vertex colour array.

### When this becomes relevant
If you add 3D assets that include **texture maps** (`.png`/`.jpg` image files
referenced in the `.mtl` via `map_Kd`), the renderer will only apply the first
material's texture to the entire model, ignoring the rest.

### Implementation plan (when texture-mapped models are introduced)
1. At load time, collect all `ui.Image` textures from materials.
2. Build a texture atlas using `dart:ui`'s `Canvas` + `PictureRecorder`:
   - Arrange each texture into a grid on a single composite image.
   - Record each material's sub-region (offset + size) in the atlas.
3. Remap each face's UV coordinates to point into the correct sub-region.
4. Pass the single atlas image to `VertexMesh.texture`.

### Performance impact
- Atlas build: once at load time, not per frame.
- Atlas memory: proportional to total texture area. Keep individual textures
  small (e.g. ≤ 512×512 per material) to avoid excessive atlas size.

### Questions for you
1. Are texture-mapped 3D models planned for the app (i.e. models with image files
   referenced in `.mtl`)?
2. If yes: what is the expected maximum texture count per model, and typical
   texture resolution? This determines atlas size and whether GPU memory limits
   need to be considered on low-end devices.

---

## Summary of decisions needed

| TODO | Decision | Options |
|---|---|---|
| #1 Multi-object | Do you need per-part control? | A (merge all) or B (named map) |
| #2 Smooth shading | Is flat shading acceptable? Is `s` for shading or scale? | Priority call |
| #4 Texture atlas | Are texture-mapped models planned? What sizes? | Timing + spec |

---

## No backend integration needed

All three improvements are **client-side only**. The OBJ/MTL files are static
assets loaded from the app bundle. No API calls, no server changes.
