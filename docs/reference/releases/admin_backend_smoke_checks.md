# Admin backend smoke checks

This script provides lightweight backend-connected validation for the admin flows.

## Script

- `scripts/admin_backend_smoke_checks.sh`

## Required env vars

- `ADMIN_API_BASE_URL` (example: `https://api.example.com/api/v1`)

## Optional env vars

- `ADMIN_ACCESS_TOKEN`: bearer token for protected admin endpoints.
- `ADMIN_REFRESH_TOKEN`: refresh token to validate refresh contract endpoints.
- `ADMIN_LOGIN_EMAIL` + `ADMIN_LOGIN_PASSWORD`: if set, script will also call `/admin/auth/login`.
- `ADMIN_OTP_CODE`: optional OTP included in login payload.
- `DRY_RUN=1`: print commands without executing requests.

## Usage

```bash
DRY_RUN=1 \
ADMIN_API_BASE_URL="https://api.example.com/api/v1" \
./scripts/admin_backend_smoke_checks.sh
```

```bash
ADMIN_API_BASE_URL="https://api.example.com/api/v1" \
ADMIN_ACCESS_TOKEN="<access>" \
ADMIN_REFRESH_TOKEN="<refresh>" \
./scripts/admin_backend_smoke_checks.sh
```

## Covered checks

1. `/admin/auth/login` (optional)
2. `/admin/auth/me`
3. `/admin/auth/refresh` and `/auth/refresh` (if refresh token provided)
4. `/admin/users?page=1&pageSize=1`
5. `/admin/questions?page=1&pageSize=1`
6. `/admin/event-queue/upload` with noop payload (`{"events":[]}`)

## Notes

- This is intentionally a smoke-level script (contract/access/response check), not a full integration suite.
- The script exits non-zero on HTTP >= 400 for any executed request.


## Known-good response checklist (for frontend verification)

Use this checklist after running smoke checks against a real backend.

### 1) `GET /admin/auth/me`
- [ ] HTTP status is `200`.
- [ ] Response includes admin identity fields (`id`, `email` or `displayName`).
- [ ] Response includes either `roles` (array) or `role` (string).
- [ ] At least one role resolves to `admin` for admin test account.

### 2) `GET /admin/users?page=1&pageSize=1`
- [ ] HTTP status is `200`.
- [ ] Envelope has `items` (array), `page`, `pageSize`, `totalItems`, `totalPages`.
- [ ] `items[0]` (if present) includes key user fields (`id`, `username`/`email`, role/status fields).

### 3) `GET /admin/questions?page=1&pageSize=1`
- [ ] HTTP status is `200`.
- [ ] Envelope has `items` (array), `page`, `pageSize`, `totalItems`, `totalPages`.
- [ ] `items[0]` (if present) includes stable question identity (e.g. `id`) and readable prompt field.

### Error envelope spot-check (all endpoints)
- [ ] For intentional auth failure, response uses shape:
  - `error.code`
  - `error.message`
  - optional `error.details`
- [ ] 401/403 paths render correct frontend state (session-expired vs forbidden).

## Latest execution status (2026-04-04)

- Dry-run: ✅ Completed.
- Live run: ⚠️ Blocked in current environment.
  - Command used: `ADMIN_API_BASE_URL="https://example.invalid/api/v1" ./scripts/admin_backend_smoke_checks.sh`
  - First failing step: `GET /admin/auth/me`
  - Error: `curl: (56) CONNECT tunnel failed, response 403`

Next action:
- Re-run against reachable backend URL + valid admin token/refresh token from target environment.
