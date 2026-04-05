# Synaptix Alpha Outstanding Task Audit

_Date: 2026-03-31_

## 0) ProfileSyncService 404/backoff root cause (resolved)

- The app was attempting profile sync against fallback endpoints:
  - `/profile`
  - `/user/profile`
  - `/auth/profile`
- Those were returning `404`, which correctly triggered `ProfileSyncService` endpoint backoff logs.
- The repository API contract includes user profile updates on `/users/me` (`PATCH /users/me`).
- Resolution applied:
  - Added `/users/me` as the first profile-sync endpoint candidate.
  - Added `/users/me` to `ApiService` protected-path detection so 401 refresh handling applies consistently.

## 1) TODO/FIXME inventory

- `lib/` currently contains **46** TODO/FIXME comments (Dart files).
- The full repository currently contains **71** TODO/FIXME comments.

### Synaptix-branded frontend TODOs still open
- `lib/main.dart`
  - `TODO(Synaptix Phase 8): Rename TriviaTycoonApp -> SynaptixApp`
- `lib/synaptix/widgets/hub_daily_quest.dart`
  - Replace mock quest content with provider-driven quest data.
- `lib/synaptix/widgets/hub_featured_match.dart`
  - Replace static featured match with data-driven recommendations.
- `lib/synaptix/widgets/hub_live_ticker.dart`
  - Replace static ticker text with provider/stream live data.

## 2) Synaptix markdown docs: outstanding work

## `docs/synaptix_frontend_plan.md`
Open checklists still indicate pending Phase 7 QA/stabilization work:

- App launch, auth/bootstrap, onboarding, hub rendering, mode mapping, and all major surface navigation checks remain unchecked.
- Consistency/brand checks remain unchecked, including:
  - No remaining visible "Trivia Tycoon" labels
  - No mixed old/new adjacent screen language
  - Mode-specific rendering validation
  - Frontend/backend label consistency verification

## `docs/synaptix_onboarding_production_implementation.md`
Implementation order and acceptance criteria are documented, but treated as work to execute (not marked complete):

- 14-step file-by-file conversion sequence for production onboarding.
- Acceptance criteria include persistence restore, mode mapping, first-session challenge completion, reward reveal before `/home`, and route gating correctness.

## `docs/synaptix_master_playbook.md`
This file presents strategic sequencing; it still lists the next execution path as:

1. Implement Flutter onboarding system
2. Build monetization backend (FastAPI)
3. Implement UI polish system
4. Prepare beta launch
5. Scale growth engine

## 3) Alpha-focused recommendation

For Synaptix **Alpha (mobile + web)**, treat the following as the minimum outstanding execution set:

1. Close high-visibility Synaptix TODOs in hub widgets and app naming.
2. Complete Phase 7 QA checklist in `synaptix_frontend_plan.md` and mark completed items.
3. Run onboarding acceptance criteria from `synaptix_onboarding_production_implementation.md` as explicit test cases.
4. Decide whether Phase 8 technical rename (`TriviaTycoonApp` -> `SynaptixApp`) is in Alpha scope or deferred.

## 4) 2026-04-04 execution plan update

A prioritized execution plan for tonight has been added:
- `docs/frontend_priority_execution_plan_2026-04-04.md`

Key operating target for tonight:
- Complete all P0 items and at least 2 P1 items (>=55% completion by weighted score).

Backend handoff note:
- The requested files `frontend_admin_security_rollout_plan` and `frontend_backend_handoff_alpha_2026-04-04` were not present in this repo when planning; this plan uses existing admin contract/smoke docs as source of truth until those files are added.

Progress update (execution in progress):
- Completed: planning doc created, priority breakdown finalized, smoke script dry-run validated, admin dashboard role-gate hardening implemented, known-good smoke response checklist documented, contract/error mapping pass implemented for Admin Users + Question Bank + Admin User Detail + activity-log + dataset-status + config-sync pathways, non-dry-run smoke check outcome logged (current blocker: network/backend access), Admin Audio invalid-asset retry suppression cache implemented, `/users/me` profile-sync troubleshooting guide added, and Hub featured-match fallback policy implemented (including preferred-category source feed fix).
- Remaining next: finish any tiny leftover P0.2 surfaces, complete P1.2 test execution in a Flutter-enabled environment, and add/execute P1.3 fallback rendering test.
