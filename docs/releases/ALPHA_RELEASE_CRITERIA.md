# Alpha Release Criteria

**Release:** alpha-june-2026
**Target date:** June 1, 2026
**Last updated:** 2026-05-16

---

## Must Pass — Technical (Flutter Frontend)

- [ ] `flutter analyze` — zero errors (info-level redundant import warnings acceptable)
- [ ] `flutter test` — all 181 unit/widget tests pass
- [ ] Integration smoke test passes against staging (`test/integration/live_backend_smoke_test.dart`)
- [ ] Golden path walkthrough: register → quiz → reward → leaderboard (manual)
- [ ] `/register` route opens signup UI on mobile and web
- [ ] Feature flag route gating: disabled routes redirect to `/home`
- [ ] Startup health check blocks launch when backend is unreachable (shows retry screen)
- [ ] Minimum version check blocks launch when client is below `minimumClientVersion`
- [ ] Wallet re-fetches from backend after every quiz completion

---

## Must Pass — Technical (Backend)

- [ ] All 24 EF Core migrations applied successfully (`db-migrator` exits `0`)
- [ ] `GET /healthz` returns `200`
- [ ] `GET /health/ready` returns `200` with all dependencies healthy
- [ ] `GET /api/v1/app/config` returns correct flags for alpha environment
- [ ] `POST /auth/login` authenticates a valid test account
- [ ] `GET /users/me/wallet` returns wallet with `credits`, `neuralXp`, `synapseShards`
- [ ] `POST /quiz/complete` grants XP/coins (wallet balance increases after quiz)
- [ ] `POST /quiz/complete` is idempotent (duplicate `eventId` returns success without double-grant)
- [ ] `POST /leaderboard` records score (leaderboard entry appears)
- [ ] Disabled feature endpoints return HTTP `403 FeatureDisabled`
- [ ] Hangfire leaderboard recalculation job scheduled (`0 5 * * *`)
- [ ] Rate limiting active (`api` policy: 100 req/min, `matches-submit`: 10 req/10s)
- [ ] `artifacts/migrations/rollback-notes.md` exists and covers all 24 migrations

---

## Must Pass — Operations

- [ ] Database backup confirmed before release
- [ ] `db-migrator` runs in compose and completes before API startup
- [ ] API containers start successfully after migration
- [ ] Structured logs flowing (Serilog → output)
- [ ] OpenTelemetry traces visible in Grafana
- [ ] Redis connected and caching active
- [ ] MinIO accessible (if used for seed catalog)

---

## Should Pass

- [ ] Token refresh works (`POST /auth/refresh` returns new access token)
- [ ] Offline error screen shows with retry button when backend unreachable
- [ ] Post-quiz wallet balance matches backend (`walletProvider` invalidated correctly)
- [ ] CORS preflight (`OPTIONS /auth/login`) allows Flutter web origin
- [ ] Admin dashboard accessible at `/api/v1/admin/*`
- [ ] `flutter test test/integration/live_backend_smoke_test.dart` passes on CI with staging credentials

---

## Known Exceptions (Pre-Approved)

- Tournaments and Advanced Seasons have no dedicated flag — controlled by `realtimeMultiplayerEnabled` gate. Accepted for Alpha.
- Smoke test not validated in automated CI against staging — manual run required before sign-off.

---

## Sign-Off

All "Must Pass" criteria must be confirmed green before release.

| Role | Name | Date | Initials |
|---|---|---|---|
| Frontend Lead | | | |
| Backend Lead | | | |
| QA Lead | | | |
| Release Manager | | | |

---

## How to Run Smoke Test

```bash
# Against local Docker backend:
SYNAPTIX_TEST_EMAIL=<email> \
SYNAPTIX_TEST_PASSWORD=<password> \
SYNAPTIX_API_BASE_URL=http://localhost:5000 \
flutter test test/integration/live_backend_smoke_test.dart --timeout=60s

# Against staging:
SYNAPTIX_TEST_EMAIL=<email> \
SYNAPTIX_TEST_PASSWORD=<password> \
SYNAPTIX_STAGING_API_BASE_URL=https://staging.synaptix.io \
flutter test test/integration/live_backend_smoke_test.dart --timeout=60s
```
