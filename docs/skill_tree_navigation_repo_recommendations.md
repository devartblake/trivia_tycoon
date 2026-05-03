# Skill Tree Navigation Plan — GitHub Repo Review & Recommendations

**Project:** `devartblake/trivia_tycoon`  
**Area reviewed:** Skill Tree / Pathways navigation, branch detail flow, auto-path planner, hex-grid mini previews, overlay painters, and routing.  
**Review focus:** How the current GitHub implementation aligns with the Skill Tree Navigation Plan and what should be cleaned up next.

---

## 1. Executive Summary

The current repository implementation is **largely aligned** with the Skill Tree Navigation Plan. The core pieces are now present:

- A grouped **Pathways / Skill Tree Navigation** screen.
- Branch cards with mini hex previews, route icons, live progress, XP display, and Auto-Path CTA.
- A Branch Detail screen with path highlighting, query parameter support, zoom controls, and a recommended order flow.
- A centralized `SkillBranchPathPlanner` for weighted topological ordering.
- Shared branch path providers and mini-preview highlighting support.

The main remaining work is **not feature creation**, but **architecture cleanup and consistency**. The repo currently has some duplicated overlay behavior, inconsistent route destinations, and a few areas where derived state is mutated during build. These issues are fixable with focused patches.

---

## 2. Current Status Against the Plan

### 2.1 Completed / Aligned

#### Skill Tree Navigation Screen

The current `SkillTreeNavScreen` has the intended grouped navigation surface:

- Four navigation tabs:
  - Combat
  - Enhancement
  - Utility
  - Advanced
- Branch/group cards with:
  - gradient color themes,
  - hex icon button,
  - available-skill badge,
  - progress percentage,
  - compact Auto-Path button,
  - route icon,
  - mini branch preview,
  - XP badge from `playerXPProvider`.
- Search support across skill title, description, and effects.
- Search result deep-linking with branch route query params.
- Synaptix analytics event when the Pathways surface opens.

This aligns with the plan’s “navigation hub” requirement.

#### Branch Detail Screen

The current `SkillBranchDetailScreen` includes most of the planned advanced detail functionality:

- Branch ID routing.
- Optional initial step support.
- Optional path-highlight support.
- `step` and `showPath` query parameter hydration.
- Recommended path recomputation using `SkillBranchPathPlanner.fromGraph`.
- Branch-specific subgraph filtering.
- XP-aware unlock eligibility through `playerXPProvider`.
- Auto-path modal showing recommended unlock order.
- Zoom controls.
- Path controls for stepping forward/back through the path.
- Overlay painters for recommended path visualization.

This aligns with the plan’s “branch detail + auto-path” requirement.

#### Skill Branch Path Planner

The repo contains `lib/game/planning/skill_branch_path_planner.dart`, which provides:

- `SkillBranchPathPlanner.fromGraph(...)`.
- `forBranch(branchId)` returning ordered `SkillNode` objects.
- A fallback `plan()` returning IDs.
- Weighted topological sort.
- Cycle fallback behavior.
- Shared helper:

```dart
List<SkillNode> computeRecommendedOrderForBranch(
  SkillTreeGraph graph,
  String branchId,
)
```

This aligns with the plan’s “single source of truth for recommended unlock order.”

#### Branch Path Providers

The repo includes `lib/game/providers/branch_path_providers.dart` with:

```dart
branchAutoPathProvider(branchId)
branchCentersProvider(branchId)
```

This aligns with the plan’s “provider-based reuse across Nav + Detail.”

#### Mini Hex Preview

The current `MiniHexBranchPreview` supports:

- `highlightPath`,
- optional `pathIds`,
- `fromGraph`,
- `fromCategory`,
- live graph lookup via `skillTreeProvider`,
- path overlay using `AutoPathOverlayPainter`.

This aligns with the plan’s “compact branch mini-preview.”

---

## 3. Main Issues Found

### Issue 1 — Route naming is inconsistent

The current `SkillTreeNavScreen` has two different route families:

```dart
context.push('/skill-branch/$branchId?step=$initialStep&showPath=1');
```

but also:

```dart
context.push('/skill-tree/$groupId');
```

This means a branch card can navigate to different screens depending on where the user taps:

- route icon / Auto-Path path → `/skill-branch/...`
- general card tap → `/skill-tree/...`

That is confusing and can break the mental model.

#### Recommendation

Use `/skill-branch/:branchId` for branch detail screens. Reserve `/skill-tree` for the global/full skill tree view only.

Update:

```dart
void _navigateToSkillTree(String groupId) {
  context.push('/skill-tree/$groupId');
}
```

To:

```dart
void _navigateToSkillTree(String groupId) {
  context.push('/skill-branch/$groupId');
}
```

And keep Auto-Path deep-linking as:

```dart
void _deepLinkToBranchStep(
  String branchId, {
  int initialStep = 0,
  bool showPath = true,
}) {
  context.push(
    '/skill-branch/$branchId?step=$initialStep&showPath=${showPath ? 1 : 0}',
  );
}
```

#### Priority

**High** — this should be fixed first.

---

### Issue 2 — Branch Detail currently uses two overlay systems

`SkillBranchDetailScreen` currently imports and renders both:

```dart
import '../../../ui_components/hex_grid/paint/auto_path_overlay_painter.dart';
import '../../ui_components/hex_grid/paint/branch_path_overlay_painter.dart';
```

The screen also renders both overlay layers:

- `BranchPathOverlayPainter`
- `AutoPathOverlayPainter`

This can cause:

- duplicate path lines,
- visual clutter,
- mismatched highlights,
- harder debugging,
- future type/import conflicts.

#### Recommendation

Keep one overlay system.

Since `AutoPathOverlayPainter` is the newer generalized overlay for guided step focus and mini-preview support, keep it and remove the older `BranchPathOverlayPainter` layer unless there is a specific visual behavior you still need from it.

Remove this import from `SkillBranchDetailScreen`:

```dart
import '../../ui_components/hex_grid/paint/branch_path_overlay_painter.dart';
```

Remove this block:

```dart
if (_showPath && _computedPath.isNotEmpty)
  Positioned.fill(
    child: IgnorePointer(
      child: CustomPaint(
        painter: BranchPathOverlayPainter(
          positionsWorld: positions,
          worldToScreen: _transform.value,
          path: _computedPath,
          currentStep: _pathIndex,
          nodeRadius: _nodeRadius,
          showStepNumbers: true,
          pathColor: branchColor,
          pathGlowColor: branchColor.withValues(alpha: 0.5),
          haloColor: const Color(0xFFFFC857),
          strokeWidth: 3,
        ),
      ),
    ),
  ),
```

Keep this type of overlay layer:

```dart
Positioned.fill(
  child: ValueListenableBuilder<bool>(
    valueListenable: _showFullPath,
    builder: (_, show, __) => ValueListenableBuilder<int>(
      valueListenable: _currentStep,
      builder: (_, step, __) => IgnorePointer(
        child: CustomPaint(
          painter: AutoPathOverlayPainter(
            centers: _centers,
            pathIds: _pathIds,
            currentIndex: step,
            showFullPath: show,
            fullPathColor: branchColor.withValues(alpha: 0.4),
            stepPathColor: branchColor,
            stepPathWidth: 4.0,
          ),
        ),
      ),
    ),
  ),
),
```

#### Priority

**High** — this prevents duplicate rendering and simplifies future work.

---

### Issue 3 — `branchCentersProvider` says screen-space but returns layout/world positions

The provider comment says:

```dart
/// Returns a map of nodeId -> screen-space center
```

but implementation reads directly from:

```dart
state.positions[n.id]
```

Those positions are the skill tree layout/world positions, not transformed screen-space centers.

In `SkillBranchDetailScreen`, transformed centers are already captured in `_filterPositions(...)` via:

```dart
final screenPos = _transformPoint(_transform.value, p);
_centers[id] = screenPos;
```

This means there are two possible sources for node centers:

- provider centers = world/layout coordinates,
- detail screen `_centers` = transformed screen coordinates.

Using the wrong one can misalign overlays.

#### Recommendation

For now, keep `branchAutoPathProvider` if desired, but do **not** use `branchCentersProvider` inside `SkillBranchDetailScreen` unless it is renamed or changed.

Option A — simplest:

- Leave `branchCentersProvider` in place for future use.
- Update its comment to say “layout/world positions.”
- Keep using `_centers` inside Branch Detail.

Change the provider comment to:

```dart
/// Returns a map of nodeId -> layout/world center for a given branchId,
/// using positions from the current SkillTreeState.
///
/// Important: These are not transformed screen-space positions. Screens using
/// TransformationController should convert them before painting overlays.
```

Option B — more advanced:

- Create a new provider that only returns world positions.
- Let the screen transform them.

Suggested name:

```dart
branchWorldCentersProvider
```

#### Priority

**Medium-high** — this can produce visual bugs if used incorrectly.

---

### Issue 4 — `SkillBranchDetailScreen` mutates derived path fields during build

The screen currently calls:

```dart
_recomputePath();
```

inside `build()`.

`_recomputePath()` mutates:

```dart
_computedPath
_pathIds
_currentStep.value
```

Even though this may not immediately throw Riverpod errors, mutating state-like fields during build can create subtle problems:

- redundant repaints,
- inconsistent overlays,
- hard-to-reproduce UI state bugs,
- step index changes while the widget is rendering.

#### Recommendation

Move path computation into local derived variables inside `build`, or update path state only in post-frame callbacks when the graph/branch changes.

Preferred local approach:

```dart
final orderedNodes = SkillBranchPathPlanner.fromGraph(state.graph)
    .forBranch(widget.branchId);

final computedPath = orderedNodes.map((n) => n.id).toList(growable: false);
```

Then pass `computedPath` directly to painters and controls.

If you still need `_computedPath` because helper methods reference it, sync it safely:

```dart
void _syncComputedPath(List<String> computedPath) {
  if (listEquals(_computedPath, computedPath)) return;

  WidgetsBinding.instance.addPostFrameCallback((_) {
    if (!mounted) return;
    setState(() {
      _computedPath = computedPath;
      _pathIds = computedPath;
      if (_pathIndex >= _computedPath.length) {
        _pathIndex = _computedPath.isEmpty ? 0 : _computedPath.length - 1;
      }
      _currentStep.value = _pathIndex;
    });
  });
}
```

You will need:

```dart
import 'package:flutter/foundation.dart';
```

#### Priority

**Medium-high** — this improves stability and avoids future lifecycle bugs.

---

### Issue 5 — `MiniHexBranchPreview.fromGraph` accepts `graph` but does not use it

The factory signature includes:

```dart
factory MiniHexBranchPreview.fromGraph({
  required SkillTreeGraph graph,
  required String branchId,
  ...
})
```

but the factory only returns:

```dart
return MiniHexBranchPreview(
  branchId: branchId,
  ...
);
```

Then `build()` reads the graph again from:

```dart
final state = ref.watch(skillTreeProvider);
final graph = state.graph;
```

This works, but the `fromGraph` name is misleading because the supplied graph is ignored.

#### Recommendation

Choose one design.

Option A — Riverpod-driven widget, simpler:

Remove the `graph` parameter from `fromGraph`, or rename it to avoid confusion:

```dart
factory MiniHexBranchPreview.forBranch({
  Key? key,
  required String branchId,
  Color? baseColor,
  Color? textColor,
  bool highlightPath = false,
  List<String>? pathIds,
})
```

Option B — true graph override:

Add a field:

```dart
final SkillTreeGraph? graphOverride;
```

Constructor:

```dart
const MiniHexBranchPreview({
  super.key,
  required this.branchId,
  required this.baseColor,
  required this.textColor,
  this.highlightPath = false,
  this.pathIds,
  this.graphOverride,
});
```

Factory:

```dart
factory MiniHexBranchPreview.fromGraph({
  Key? key,
  required SkillTreeGraph graph,
  required String branchId,
  Color? baseColor,
  Color? textColor,
  bool highlightPath = false,
  List<String>? pathIds,
}) {
  return MiniHexBranchPreview(
    key: key,
    branchId: branchId,
    baseColor: baseColor ?? Colors.white24,
    textColor: textColor ?? Colors.white,
    highlightPath: highlightPath,
    pathIds: pathIds,
    graphOverride: graph,
  );
}
```

Build method:

```dart
final state = ref.watch(skillTreeProvider);
final graph = graphOverride ?? state.graph;
```

#### Priority

**Medium** — not a breaking bug, but should be cleaned up.

---

## 4. Recommended Implementation Order

### Step 1 — Normalize routes

Update:

```dart
void _navigateToSkillTree(String groupId) {
  context.push('/skill-tree/$groupId');
}
```

To:

```dart
void _navigateToSkillTree(String groupId) {
  context.push('/skill-branch/$groupId');
}
```

Then verify all these navigate to the same branch detail route:

- branch card tap,
- route icon,
- mini preview modal start button,
- search result tap.

Expected route family:

```text
/skill-branch/:branchId
/skill-branch/:branchId?step=0&showPath=1
```

---

### Step 2 — Keep one overlay painter in Branch Detail

Recommended final state:

- Use `AutoPathOverlayPainter` only.
- Remove `BranchPathOverlayPainter` import and layer.
- Keep one source of current step:

```dart
_currentStep
```

Ideally phase out duplicate fields:

```dart
_pathIndex
_showPath
_computedPath
```

or keep them only as compatibility state until you refactor the controls.

---

### Step 3 — Clarify center-coordinate providers

Update the comment in `branch_path_providers.dart` so it does not incorrectly claim screen-space coordinates.

Better naming:

```dart
branchWorldCentersProvider
```

Current implementation is fine as world/layout positions, but it should not be treated as transformed screen-space.

---

### Step 4 — Move path recompute out of build-time mutation

Replace:

```dart
_recomputePath();
```

inside build with local computation:

```dart
final orderedNodes = SkillBranchPathPlanner.fromGraph(state.graph)
    .forBranch(widget.branchId);
final computedPath = orderedNodes.map((n) => n.id).toList(growable: false);
```

Then either:

- pass `computedPath` directly to UI helpers, or
- sync fields post-frame.

---

### Step 5 — Clean up `MiniHexBranchPreview.fromGraph`

Decide whether it should be:

- Riverpod-driven, or
- graph-override-driven.

For your current architecture, graph override is flexible and useful for tests/previews.

Recommended: add `graphOverride` and make `fromGraph` actually use its graph.

---

## 5. Suggested Exact Patches

### 5.1 Patch — Route normalization

File:

```text
lib/screens/skills_tree/skill_tree_nav_screen.dart
```

Change:

```dart
void _navigateToSkillTree(String groupId) {
  // Navigate to specific skill tree view using go_router
  context.push('/skill-tree/$groupId');
}
```

To:

```dart
void _navigateToSkillTree(String groupId) {
  // Navigate to branch detail. The global tree remains /skill-tree.
  context.push('/skill-branch/$groupId');
}
```

---

### 5.2 Patch — Remove duplicate branch overlay layer

File:

```text
lib/screens/skills_tree/skill_branch_detail_screen.dart
```

Remove import:

```dart
import '../../ui_components/hex_grid/paint/branch_path_overlay_painter.dart';
```

Remove block:

```dart
if (_showPath && _computedPath.isNotEmpty)
  Positioned.fill(
    child: IgnorePointer(
      child: CustomPaint(
        painter: BranchPathOverlayPainter(...),
      ),
    ),
  ),
```

Keep `AutoPathOverlayPainter` block.

---

### 5.3 Patch — Update branch center provider comment

File:

```text
lib/game/providers/branch_path_providers.dart
```

Replace:

```dart
/// Returns a map of nodeId -> screen-space center for a given branchId,
/// using positions from the current SkillTreeState.
```

With:

```dart
/// Returns a map of nodeId -> layout/world center for a given branchId,
/// using positions from the current SkillTreeState.
///
/// Important: these are not transformed screen-space positions. Screens using
/// a TransformationController should transform these centers before using them
/// in overlay painters.
```

Optional rename:

```dart
final branchWorldCentersProvider =
    Provider.family<Map<String, Offset>, String>((ref, branchId) {
  ...
});
```

Keep the old provider temporarily as an alias if needed:

```dart
final branchCentersProvider = branchWorldCentersProvider;
```

---

### 5.4 Patch — Make `MiniHexBranchPreview.fromGraph` actually use graph

File:

```text
lib/ui_components/hex_grid/widgets/mini_hex_preview.dart
```

Add field:

```dart
final SkillTreeGraph? graphOverride;
```

Update constructor:

```dart
const MiniHexBranchPreview({
  super.key,
  required this.branchId,
  required this.baseColor,
  required this.textColor,
  this.highlightPath = false,
  this.pathIds,
  this.graphOverride,
});
```

Update factory:

```dart
factory MiniHexBranchPreview.fromGraph({
  Key? key,
  required SkillTreeGraph graph,
  required String branchId,
  Color? baseColor,
  Color? textColor,
  bool highlightPath = false,
  List<String>? pathIds,
}) {
  return MiniHexBranchPreview(
    key: key,
    branchId: branchId,
    baseColor: baseColor ?? Colors.white24,
    textColor: textColor ?? Colors.white,
    highlightPath: highlightPath,
    pathIds: pathIds,
    graphOverride: graph,
  );
}
```

Update build:

```dart
final state = ref.watch(skillTreeProvider);
final graph = graphOverride ?? state.graph;
```

---

## 6. Medium-Term Enhancements

After the above cleanup, the next feature-level improvements should be:

### 6.1 Persist Auto-Path progress per branch

Add persistence for:

```dart
branchId -> currentStep
branchId -> showPath preference
branchId -> lastFocusedNodeId
```

This allows the player to return to a branch and resume their recommended path.

### 6.2 Add cooldown chips to Branch Detail action bar

In the bottom action bar, show:

- locked,
- available,
- unlocked,
- on cooldown,
- next available in `mm:ss`.

This should read from `SkillCooldownService`.

### 6.3 Add “Unlock Next” guard states

The Branch Detail bottom bar should explicitly show why a node cannot unlock:

- insufficient XP,
- prerequisite missing,
- branch locked,
- elite/cross-branch requirement missing.

### 6.4 Add cross-group prerequisite validation

Elite/Wildcard/General branches should support unlock rules like:

```json
{
  "requires_groups": [
    { "group": "combat", "min_unlocked": 3 },
    { "group": "enhancement", "min_unlocked": 3 }
  ]
}
```

This should be handled outside the UI, ideally in a validator/service.

### 6.5 Unit tests

Add tests for:

- `SkillBranchPathPlanner` DAG sorting,
- cycle fallback,
- effect-weight priority,
- branch filtering by category/branchId/id-prefix,
- unlock eligibility,
- cooldown behavior,
- route query parsing.

---

## 7. Final Recommended Architecture

The clean final architecture should look like this:

```text
SkillTreeNavScreen
 ├─ displays branch groups
 ├─ reads skillTreeProvider + playerXPProvider
 ├─ uses MiniHexBranchPreview
 ├─ opens Auto-Path modal
 └─ routes to /skill-branch/:branchId?step=&showPath=

SkillBranchDetailScreen
 ├─ reads branchId + query params
 ├─ uses SkillBranchPathPlanner
 ├─ computes ordered path
 ├─ transforms node centers locally
 ├─ uses AutoPathOverlayPainter only
 ├─ unlocks via SkillTreeController.unlockSkill
 └─ uses via SkillTreeController.useSkill

SkillBranchPathPlanner
 ├─ central weighted topological sort
 ├─ category/branch/id-prefix matching
 └─ cycle fallback

MiniHexBranchPreview
 ├─ renders compact read-only preview
 ├─ supports highlightPath/pathIds
 └─ optionally supports graphOverride

branch_path_providers.dart
 ├─ branchAutoPathProvider
 └─ branchWorldCentersProvider (or correctly documented branchCentersProvider)
```

---

## 8. Final Assessment

The repository is in a good state and has crossed the hardest implementation threshold. The Skill Tree Navigation Plan is no longer theoretical; the majority of the UX and data flow is present.

The remaining work should focus on:

1. **Route consistency**.
2. **One overlay source of truth**.
3. **Coordinate-system clarity**.
4. **Avoiding build-time derived state mutation**.
5. **Cleaning up misleading factory/API names**.

Once these are completed, the Skill Tree Navigation system will be stable enough to move into persistence, cooldown UX, and backend/profile sync.
