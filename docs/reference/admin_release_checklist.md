# Admin Backend Rollout Release Checklist (CI/Staging)

Use this checklist to execute **Steps 2–5** consistently before promoting admin backend changes.

---

## Scope

This checklist validates:

- Step 2: Backend-connected smoke verification.
- Step 3: Refresh endpoint contract finalization.
- Step 4: Pagination contract finalization.
- Step 5: Targeted regression tests and full quality gates.

---

## Environment prerequisites

Set these in CI/staging job environment:

- `ADMIN_API_BASE_URL` (example: `https://staging-api.example.com/api/v1`)
- `ADMIN_ACCESS_TOKEN` (staging admin bearer)
- `ADMIN_REFRESH_TOKEN` (staging admin refresh token)
- optional: `ADMIN_LOGIN_EMAIL`, `ADMIN_LOGIN_PASSWORD`, `ADMIN_OTP_CODE`

Tooling required in the runner:

- Flutter SDK + Dart SDK
- bash + curl

---

<<<<<<< codex/analyze-admin-directory-for-backend-integration

## 0) CI automation

A GitHub Actions workflow is available at:

- `.github/workflows/admin-release-checks.yml`

It runs the quality gates (format/analyze/tests) plus smoke-script dry-run on admin-relevant PRs.
A manual `workflow_dispatch` can also run live smoke checks when secrets are configured.

---

=======
>>>>>>> main
## 1) Preflight checks

Run from repo root:

```bash
git rev-parse --abbrev-ref HEAD
git status --short
dart --version
flutter --version
```

Pass criteria:

- Expected branch is checked out.
- No unintended local changes.
- Flutter/Dart available.

---

## 2) Step 5 quality gates (unit/static)

### 2.1 Formatting

```bash
dart format --set-exit-if-changed lib test docs
```

### 2.2 Analysis

```bash
flutter analyze
```

### 2.3 Focused Step 5 tests

```bash
flutter test test/core/services/api_service_test.dart
flutter test test/admin/providers/admin_auth_providers_test.dart
```

### 2.4 Full test suite

```bash
flutter test
```

Pass criteria:

- All commands exit 0.
- No new analyzer errors.

---

## 3) Step 2 backend-connected smoke checks

### 3.1 Dry run (sanity)

```bash
DRY_RUN=1 \
ADMIN_API_BASE_URL="$ADMIN_API_BASE_URL" \
./scripts/admin_backend_smoke_checks.sh
```

### 3.2 Live run (staging backend)

```bash
ADMIN_API_BASE_URL="$ADMIN_API_BASE_URL" \
ADMIN_ACCESS_TOKEN="$ADMIN_ACCESS_TOKEN" \
ADMIN_REFRESH_TOKEN="$ADMIN_REFRESH_TOKEN" \
ADMIN_LOGIN_EMAIL="${ADMIN_LOGIN_EMAIL:-}" \
ADMIN_LOGIN_PASSWORD="${ADMIN_LOGIN_PASSWORD:-}" \
ADMIN_OTP_CODE="${ADMIN_OTP_CODE:-}" \
./scripts/admin_backend_smoke_checks.sh
```

Pass criteria:

- Script exits 0.
- Endpoint checks succeed for:
  - `/admin/auth/me`
  - `/admin/auth/refresh` and `/auth/refresh` (when refresh token provided)
  - `/admin/users?page=1&pageSize=1`
  - `/admin/questions?page=1&pageSize=1`
  - `/admin/event-queue/upload`

---

## 4) Step 3 refresh contract finalization (decision gate)

Record one of the following in PR/release notes:

- **Option A (temporary compatibility):** Keep both `/admin/auth/refresh` and `/auth/refresh`.
- **Option B (finalized contract):** Standardize to one endpoint and remove fallback paths.

If choosing Option B, required follow-ups:

1. Remove fallback logic from `ApiService` and `admin_auth_providers`.
2. Update tests accordingly.
3. Re-run sections 2 and 3.

---

## 5) Step 4 pagination contract finalization (decision gate)

Confirm and document envelope shape used by backend responses:

- preferred keys: `items`, `page`, `pageSize`, `total`, `totalPages`
- accepted variants remain supported by `parsePageEnvelope` for compatibility

If removing compatibility behavior, ensure:

1. All admin call sites consume canonical envelope keys.
2. Tests cover expected/legacy envelope behavior intentionally.
3. Sections 2 and 3 are re-run.

---

## 6) Manual staging UI verification (high-risk flows)

Execute manual checks in staging app build:

1. Admin login (+ OTP when enabled).
2. Admin claims load and gated navigation visibility.
3. Users: list/detail/create/update/ban/unban/delete.
4. Questions: list/create/update/delete + bulk/upload path.
5. Event queue: upload + per-event reprocess.
6. Notifications admin access gating.

Pass criteria:

- No blocking errors.
- Unauthorized states correctly redirect/gate.
- Retry/refresh behavior is non-disruptive.

---

## 7) Release sign-off template

Copy into PR comment / release notes:

```markdown
## Admin backend rollout sign-off

- [ ] Formatting/analyze/tests passed
- [ ] Focused Step 5 tests passed
- [ ] Backend smoke script passed in staging
- [ ] Refresh contract decision recorded (A/B)
- [ ] Pagination contract decision recorded
- [ ] Manual staging UI checks completed
- [ ] No unresolved inline review comments
```

