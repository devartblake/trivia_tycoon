# Alpha Release — Rollback Plan

**Release:** alpha-june-2026
**Last updated:** 2026-05-16

---

## Decision Tree

```
Issue detected
  ↓
Is it a single feature?
  YES → Level 1: Feature Flag Toggle (instant, no downtime)
  NO ↓
Is it an API/service crash?
  YES → Level 2: Container Rollback (< 5 min)
  NO ↓
Is it data corruption or migration regression?
  YES → Level 3: Database Restore (15–30 min)
```

---

## Level 1 — Feature Flag Toggle

**Use when:** A specific feature (trivia, wallet, leaderboard) is behaving incorrectly but the system is otherwise stable.

**Time to execute:** < 30 seconds. No downtime.

**Steps:**

1. Obtain admin token.
2. Send PATCH to disable the affected flag:

```http
PATCH /api/v1/admin/config
Authorization: Bearer <admin-token>
Content-Type: application/json

{
  "coreTriviaEnabled": false
}
```

3. Flutter clients pick up the change on next app launch (or next `/api/v1/app/config` fetch).
4. Affected routes redirect to `/home`. Backend endpoints return HTTP 403.

**Available flags to disable:**

| Flag | Effect |
|---|---|
| `coreTriviaEnabled` | Disables trivia gameplay |
| `walletEnabled` | Hides wallet UI |
| `leaderboardEnabled` | Hides leaderboard |
| `storeEnabled` | Hides store catalog |

---

## Level 2 — Container Rollback

**Use when:** An API service is crashing or returning unexpected errors across multiple features.

**Time to execute:** < 5 minutes. Brief downtime during restart.

**Steps:**

1. Identify the failing service (gateway, backend-api, migration-service).
2. Roll back to the previous container image tag in `compose.yml`.
3. If the schema changed in the current release, also roll back `db-migrator` to the previous image.
4. Restart the affected services:

```bash
docker compose pull <service-name>
docker compose up -d <service-name>
```

5. Verify `GET /healthz` returns 200.
6. Run smoke test to confirm golden path:

```bash
SYNAPTIX_TEST_EMAIL=<email> \
SYNAPTIX_TEST_PASSWORD=<password> \
SYNAPTIX_API_BASE_URL=http://localhost:5000 \
flutter test test/integration/live_backend_smoke_test.dart --timeout=60s
```

---

## Level 3 — Database Restore

**Use when:** Data corruption, failed migration, or wallet/reward integrity issues are detected.

**Time to execute:** 15–30 minutes. Full downtime.

**Steps:**

1. Stop all API services immediately:

```bash
docker compose stop backend-api gateway
```

2. Restore from the most recent pre-release backup:

```bash
# Example using pg_restore:
pg_restore -h <host> -U <user> -d tycoon --clean <backup-file>
```

3. Verify the restored schema matches the expected migration state.
4. If a migration caused the issue, do NOT re-apply it. Use the previous `db-migrator` image.
5. Restart API services after confirming schema integrity.
6. Run spot-check queries on wallet balances:

```sql
SELECT player_id, credits, neural_xp, synapse_shards
FROM player_wallets
ORDER BY updated_at DESC
LIMIT 20;
```

7. Verify `GET /healthz` and `GET /health/ready` return 200.
8. Run smoke test before re-opening to users.
9. Document the incident in `ALPHA_KNOWN_ISSUES.md`.

---

## Rollback Notes Reference

Full migration rollback documentation:

```text
artifacts/migrations/rollback-notes.md
```

Covers all 24 EF Core migrations with:
- schema change summary
- data risk assessment (Low / Medium / High)
- whether rollback is safe automatically
- manual rollback steps where needed

---

## Contact

| Role | Responsibility |
|---|---|
| Backend Lead | Level 2 / Level 3 execution |
| Frontend Lead | Level 1 flag toggle, Flutter client verification |
| Release Manager | Decision authority for Level 2+ |
| On-call | Monitor Grafana, Serilog dashboards |
