# Synaptix Alpha QA / Runtime Validation Checklist

_Last updated: 2026-03-31_

This checklist defines the **runtime evidence** needed before marking Synaptix Alpha items complete.

## 1) Required artifacts (trackable)

- `artifacts/test_reports/flutter_test_machine.log` (full machine test stream)
- `artifacts/test_reports/flutter_test_summary.json` (pass/fail counts)
- `artifacts/runtime/profile_sync_smoke.md` (manual runtime notes for profile sync)
- `artifacts/runtime/alpha_navigation_smoke.md` (manual navigation checklist results)

Use:

```bash
./scripts/run_tests_with_tracking.sh
```

---

## 2) QA/runtime validation items to provide

## A. Automated test evidence

- [ ] Unit/integration tests executed via tracked script.
- [ ] `flutter_test_summary.json.status == "pass"`.
- [ ] Any failing tests are linked to issue IDs with owner + ETA.

## B. Profile sync runtime validation

- [ ] Login with valid token and update profile.
- [ ] Confirm request targets `/users/me` first.
- [ ] Confirm no repeated 404 backoff sequence for `/profile`, `/user/profile`, `/auth/profile` when `/users/me` is available.
- [ ] Confirm 401 on `/users/me` triggers refresh path and retry.
- [ ] Confirm successful sync updates local persisted display name/username.

## C. Synaptix Alpha flow checks (mobile + web)

- [ ] App launch
- [ ] Auth/bootstrap
- [ ] Onboarding flow (age group -> mode mapping)
- [ ] Hub rendering (Kids/Teen/Adult)
- [ ] Mode selection and mapping
- [ ] Arena launch and navigation
- [ ] Labs launch and navigation
- [ ] Pathways launch and navigation
- [ ] Journey/profile load
- [ ] Circles/messages/groups
- [ ] Command/admin
- [ ] Settings and persistence
- [ ] Economy labels consistency

## D. Branding/consistency checks

- [ ] No high-visibility “Trivia Tycoon” strings remain
- [ ] No mixed old/new adjacent screen language
- [ ] Mode-specific differences render correctly
- [ ] Frontend labels align with backend/dashboard terminology

---

## 3) Test directory integrity review (current)

Current test tree review indicates:

- 32 test files present.
- No missing relative imports in `test/`.
- Duplicate basenames exist across folders (expected but potentially confusing in reporting):
  - `auth_service_test.dart` (core/dto vs core/services)
  - `game_flow_test.dart` (core/dto vs game/services)
  - `multiplayer_repository_test.dart` (core/dto vs game/multiplayer)
  - `profile_service_test.dart` (core/dto vs game/services)
  - `skill_tree_controller_test.dart` (core/dto vs game/controllers)
  - `xp_service_test.dart` (core/services vs game/services)

Recommendation:
- Keep both if intentionally testing different layers, but include full path in CI reporting output.
- If duplicates are accidental, de-duplicate or rename to reduce confusion.

---

## Tonight Implementation Sprint (2026-04-04)

Reference plan: `docs/frontend_priority_execution_plan_2026-04-04.md`

### Completion goal
- [ ] Reach >=55% weighted completion (all P0 + at least 2 P1 tasks).

### Must-complete tonight (P0)
- [ ] Admin auth/role gate hardening verified in UI (401/403 states).
- [ ] Admin API pagination/error-envelope mapping verified against contract.
- [ ] Admin smoke-check runbook executed and outcome documented.

### Stretch (P1)
- [ ] Audio studio resilience cleanup verified (invalid asset behavior).
- [ ] `/users/me` profile-sync regression check run.
- [ ] Hub featured-match fallback policy implemented and validated.
