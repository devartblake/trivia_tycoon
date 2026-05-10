# Skill Tree Navigation — Current Status

_Last updated: 2026-05-10._

## Scope
- Source package: `docs/trivia_tycoon_migration_frontend_github_issues.json`
- Review baseline: `docs/skill_tree_navigation_repo_recommendations.md`
- Last verified against code: 2026-05-07

## Route map (current)
- `/skills` → `SkillTreeNavScreen` (Pathways navigation hub)
- `/skills-test` → `SkillTreeNavTestScreen`
- `/skill-tree` → `SkillTreeScreen` (global tree view)
- `/skill-branch/:branchId` → `SkillBranchDetailScreen`
  - Supported query params:
    - `step=<int>`
    - `showPath=1|0` (also tolerates `true|false` in screen hydration)

## Key file map
- Router wiring
  - `lib/core/navigation/app_router.dart`
- Navigation hub
  - `lib/screens/skills_tree/skill_tree_nav_screen.dart`
- Branch detail flow
  - `lib/screens/skills_tree/skill_branch_detail_screen.dart`
- Auto-path planning/providers
  - `lib/game/planning/skill_branch_path_planner.dart`
  - `lib/game/providers/branch_path_providers.dart`
- Mini branch preview + overlay
  - `lib/ui_components/hex_grid/widgets/mini_hex_preview.dart`
  - `lib/ui_components/hex_grid/paint/auto_path_overlay_painter.dart`
- Cooldown integration
  - `lib/game/providers/skill_cooldown_service_provider.dart`

## Test coverage map
- `test/game/planning/skill_branch_path_planner_test.dart`
  - Weighted topological planning for DAG and cycle fallback paths.
- `test/screens/skills_tree/skill_tree_nav_screen_test.dart`
  - Deep-link route construction for `/skill-branch/:branchId?step=0&showPath=1`.
  - Auto-path preview highlight toggle to `showPath=0|1` route behavior.
- `test/screens/skills_tree/skill_branch_detail_screen_test.dart`
  - Empty vs valid branch states.
  - Overlay painter hydration from deep-link query params (`step`, `showPath`).

## Architecture snapshot
- `SkillTreeNavScreen` is the grouped Pathways entry surface with search, route icon CTA, and Auto-Path deep-link support.
- `SkillBranchDetailScreen` hydrates branch context from route + query params, computes/reads branch auto-path IDs, renders graph + overlay, and supports unlock/use actions.
- Recommended order logic is centralized in `SkillBranchPathPlanner` and reused by providers/UI.
- Overlay rendering in branch detail currently uses `AutoPathOverlayPainter` as the active path visualization layer.
- Persisted auto-path progress is node-id based (`branchSavedAutoPathNodeIdProvider` / `branchPersistAutoPathNodeIdProvider`).

## 2026-05-10 reconciliation
- Route normalization is complete: branch cards, route icons, Auto-Path, and search use `/skill-branch/:branchId`.
- Branch detail overlay consolidation is complete: branch detail uses `AutoPathOverlayPainter`; the older `BranchPathOverlayPainter` remains available for other legacy views only.
- Coordinate naming/docs are clarified: `branchWorldCentersProvider` returns world/layout coordinates and `branchCentersProvider` is a compatibility alias.
- Build-time path recomputation mutation has been removed from `SkillBranchDetailScreen`.
- `MiniHexBranchPreview.fromGraph` now uses the provided graph through `graphOverride`.

## Known issues / risks (current-state)
1. **State complexity in detail screen**: `SkillBranchDetailScreen` still maintains multiple path-related mutable fields/notifiers (`_showPath`, `_pathIndex`, `_showFullPath`, `_currentStep`) that increase regression risk during refactors.
2. **Query hydration duplication risk**: route/query hydration occurs in more than one lifecycle path (`initState`, post-frame, and helper methods), so precedence/ordering should remain covered by regression tests.
3. **Debug controls exposed in UI**: `_overlayControls()` is still rendered in the detail stack; keep/guard this intentionally to avoid shipping accidental debug affordances.

## Recommended next sequence
1. Decide whether `_overlayControls()` should be debug-only behind a flag.
2. Add/expand widget tests for route query hydration (`step`, `showPath`) and branch switching behavior.
3. Add explicit QA regression runs for cooldown timer transitions during step navigation.
4. Continue future enhancements: cooldown chips, persisted auto-path progress, backend/profile sync, and stronger unlock guard messaging.

## QA checklist
- [ ] **Navigation routes**
  - [ ] `/skills` loads Pathways tabs and branch cards.
  - [ ] Branch card taps route to `/skill-branch/:branchId`.
  - [ ] Search result tap routes to `/skill-branch/:branchId?step=0&showPath=1`.
- [ ] **Auto-path flow**
  - [ ] Auto-Path bottom sheet opens from Pathways cards.
  - [ ] “Start Auto-Path” deep-links to branch detail with expected `step`/`showPath`.
  - [ ] Saved auto-path node restores step when no `step` query param is provided.
- [ ] **Overlay behavior**
  - [ ] Full-path toggle updates overlay visibility.
  - [ ] Step changes update highlighted segment/index.
  - [ ] Overlay remains aligned during zoom in/out/reset.
- [ ] **Cooldown + use/unlock flows**
  - [ ] Unlock action consumes XP and advances to next recommended step.
  - [ ] Use action respects cooldown state and updates status label.
  - [ ] Cooldown countdown text/tick refreshes while screen remains open.
- [ ] **Regression sanity**
  - [ ] No crashes when branch has empty/short auto-path.
  - [ ] No crashes when invalid/out-of-range `step` query param is passed.
