# Alpha Release — Enabled Features

**Release:** alpha-june-2026
**Last updated:** 2026-05-16

---

## Active Backend Endpoints

### Authentication

| Endpoint | Method | Description |
|---|---|---|
| `/auth/register` | POST | Email registration |
| `/auth/signup` | POST | Combined register + login (mobile) |
| `/auth/login` | POST | Email + password login |
| `/auth/refresh` | POST | JWT token refresh |
| `/auth/logout` | POST | Session termination |

### User Profile

| Endpoint | Method | Description |
|---|---|---|
| `/users/me` | GET | Fetch current user profile |
| `/users/me/wallet` | GET | Fetch wallet balances (XP, coins, diamonds) |
| `/avatars` | GET | Fetch avatar catalog |

### Core Trivia Gameplay

| Endpoint | Method | Description |
|---|---|---|
| `/questions/set` | GET | Fetch question set (with optional category/difficulty/count filters) |
| `/questions/bootstrap` | GET | Load initial question pool |
| `/questions/check` | POST | Validate single answer |
| `/questions/check-batch` | POST | Validate multiple answers |
| `/study` | GET | Study session endpoints |

### Match Results & Rewards

| Endpoint | Method | Description |
|---|---|---|
| `/quiz/complete` | POST | Authoritative XP/coin grant with idempotency (EventId deduplication) |
| `/leaderboard` | POST | Record solo quiz score |
| `/matches` | POST | Submit match result |

### Leaderboards

| Endpoint | Method | Description |
|---|---|---|
| `/leaderboards/tiers/{tierId}` | GET | Tier leaderboard with pagination |
| `/leaderboards/me/{playerId}` | GET | Player rank lookup |

### Config & Health

| Endpoint | Method | Description |
|---|---|---|
| `/api/v1/app/config` | GET | Feature flags + minimum client version (unauthenticated) |
| `/health` | GET | Backend health check |
| `/healthz` | GET | Liveness probe |
| `/health/ready` | GET | Readiness probe with dependency status |

### Admin

| Endpoint | Method | Description |
|---|---|---|
| `/api/v1/admin/config` | GET | Read feature flags |
| `/api/v1/admin/config` | PATCH | Toggle feature flags at runtime |
| `/hangfire` | GET | Background job dashboard (development only) |

---

## Active Flutter Routes

| Route | Screen | Notes |
|---|---|---|
| `/login` | LoginScreen / LoginScreenMobile | Email + password login |
| `/register` | LoginScreen in signup mode | Opens signup UI |
| `/home` | HomeScreen | Main hub after login |
| `/quiz` | Quiz flow | Question → Answer → Results |
| `/leaderboard` | LeaderboardScreen | Tier leaderboards |
| `/profile` | ProfileScreen | XP level, avatar, stats |
| `/store` | StoreScreen | Basic item catalog (optional) |
| `/settings` | SettingsScreen | App preferences |

---

## Active Feature Flags

All flags are backend-owned and served via `GET /api/v1/app/config`.

| Flag | Alpha Value |
|---|---|
| `coreTriviaEnabled` | `true` |
| `walletEnabled` | `true` |
| `leaderboardEnabled` | `true` |
| `storeEnabled` | `true` |

All other flags default to `false` — see `ALPHA_DISABLED_FEATURES.md`.
