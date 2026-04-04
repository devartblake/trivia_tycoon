# Frontend Priority Execution Plan (Alpha Handoff)

_Date: 2026-04-04_
_Owner: Frontend_

## 0) Input check (requested backend handoff files)

Requested files were not found in this repository at the time of planning:

- `frontend_admin_security_rollout_plan`
- `frontend_backend_handoff_alpha_2026-04-04`

Plan below is based on the closest backend/frontend contract docs currently present:

- `docs/admin_backend_contract_checklist.md`
- `docs/admin_backend_smoke_checks.md`
- `docs/ALPHA_TASK_AUDIT.md`
- `docs/QA_RUNTIME_VALIDATION_CHECKLIST.md`

---

## 1) Tonight target: achieve >=50% implementation progress

### Definition of "50% tonight"
Complete all **P0** items and at least **2 of 3 P1** items (estimated 4.5-6.0 focused hours).

Progress score model:
- P0 item = 15% each (x3 = 45%)
- P1 item = 10% each (x3 = 30%)
- P2 items = 5% each (x5 = 25%)

**Tonight success bar:** 55%-65% total (P0 + 2 P1 minimum).

---


## 1.1) Live status (updated 2026-04-04)

- Completed this session:
  - ✅ Input-check for requested backend handoff files (both missing in repo).
  - ✅ Smoke-check script reviewed and dry-run executed successfully.
  - ✅ QA/Audit docs updated with tonight sprint tracking.
- Remaining for tonight:
  - ⏳ P0.1 Admin auth/role gate hardening implementation.
  - ⏳ P0.2 Admin contract/error-envelope mapping verification.
  - ⏳ P0.3 Real backend smoke run (non-DRY-RUN) with valid env tokens and URL.

Current weighted completion estimate: **20%** (planning + dry-run setup done, implementation still pending).

---

## 2) Priority backlog (actionable)

## P0 (Do first - block Alpha confidence)

### P0.1 Admin auth/role gate hardening in UI (15%)
**Why first:** Backend contract states admin endpoints are protected and role-enforced; UI must fail closed.

Tasks:
1. Ensure admin routes/screens check role claims before rendering privileged actions.
2. Add unified 401/403 handling UI state (`session expired` vs `insufficient permissions`).
3. Add a visible fallback state for unauthorized admin dashboard access.

Done when:
- Manual check confirms non-admin user cannot access admin action controls.
- Admin screen behavior is deterministic for 401/403.

---

### P0.2 Admin contract-aligned API shape + error envelope mapping (15%)
**Why first:** Backend endpoints require consistent envelope and pagination fields.

Tasks:
1. Add/verify frontend model mapping for:
   - `items/page/pageSize/totalItems/totalPages`
   - `error.code/error.message/error.details`
2. Normalize admin API errors into one frontend error type.
3. Add null-safe mapping + defensive defaults for all list screens.

Done when:
- Admin lists render with server pagination metadata.
- Known error envelopes surface readable messages and codes in UI logs.

---

### P0.3 Admin smoke script runbook integration (15%)
**Why first:** Fastest end-to-end signal of contract compatibility before deeper refactors.

Tasks:
1. [x] Add a frontend runbook section documenting exact env vars + commands for `scripts/admin_backend_smoke_checks.sh` (covered by existing `docs/admin_backend_smoke_checks.md` + this plan linkage).
2. [ ] Create one "known-good" response checklist for `/admin/auth/me`, `/admin/users`, `/admin/questions`.
3. [ ] Record tonight run outcome in docs (`pass/fail/blocker`).

Done when:
- Engineer can execute smoke checks in <10 minutes with copy/paste commands.
- Result documented in project markdown.

---

## P1 (Tonight after P0)

### P1.1 Admin audio studio resilience cleanup (10%)
Tasks:
1. Keep SFX preview usable if asset is invalid (already partially guarded).
2. Add one banner/toast pointing to invalid asset replacement path.
3. Ensure no repeated noisy retries for known-invalid file.

### P1.2 `/users/me` profile sync verification pass (10%)
Tasks:
1. Re-run unit test subset for profile sync/service auth.
2. Add a short troubleshooting section for 404/backoff regression symptoms.

### P1.3 Hub featured-match production data fallback policy (10%)
Tasks:
1. Define UI fallback if provider returns empty/error.
2. Add one test case for fallback rendering.

---

## P2 (Can defer after tonight)

1. Expand admin endpoint contract tests for edge pagination/sorting combos.
2. Add stricter analytics events around admin auth failures.
3. Complete remaining Synaptix TODO/FIXME items listed in alpha audit.
4. Refresh cross-comparison docs after backend handoff files are added.
5. Add CI step to archive admin smoke-check output.

---

## 3) Time-boxed execution schedule for tonight

- **Hour 0-0.5**: setup + validate environment + open docs.
- **Hour 0.5-2.0**: P0.1 implementation + quick verification.
- **Hour 2.0-3.0**: P0.2 contract/error mapping updates.
- **Hour 3.0-3.5**: P0.3 runbook + smoke-check attempt + status logging.
- **Hour 3.5-5.0**: P1.1 and P1.2.
- **Hour 5.0-6.0**: P1.3 or spillover + doc updates.

---

## 4) Risks + immediate mitigations

- **Risk:** backend handoff files missing in repo.
  - **Mitigation:** proceed from existing contract docs; rebase plan once files land.
- **Risk:** audio assets invalid (decoder errors).
  - **Mitigation:** use validation + fallback behavior; replace placeholder assets.
- **Risk:** auth state drift between admin and user flows.
  - **Mitigation:** centralize 401/403 handling and document expected UX states.

---

## 5) Deliverables expected by end of tonight

1. P0 tasks complete and documented.
2. At least 2 P1 tasks complete.
3. Updated status notes in `docs/ALPHA_TASK_AUDIT.md` and `docs/QA_RUNTIME_VALIDATION_CHECKLIST.md`.
4. Blockers list for backend follow-up if handoff docs are still missing.
