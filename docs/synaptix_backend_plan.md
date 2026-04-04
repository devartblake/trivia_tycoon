# Synaptix Backend Implementation Plan
## FastAPI Backend for Alpha Release

**Context:** The Flutter frontend (Packets A-D + onboarding evolution) is complete. This plan defines the backend work needed to support the alpha demo and subsequent releases. The frontend has a comprehensive API client (`TycoonApiClient`) with 50+ endpoints already defined — the backend must implement these contracts.

**Stack:** FastAPI (Python) — selected for rapid development during alpha
**Frontend Companion:** `docs/synaptix_frontend_plan.md` (Packets A-D complete)

---

## Current State

### What the Frontend Already Expects

The Flutter app has a fully typed API client at `lib/core/networking/tycoon_api_client.dart` with endpoints for auth, quiz, leaderboard, matches, economy, achievements, seasons, skills, store, social, analytics, guardians, territory, votes, and health. All requests go through `AuthHttpClient` which auto-attaches `Authorization: Bearer <JWT>`.

### What Currently Works Without Backend
- Auth: `BackendAuthService` with real API calls (login/signup/refresh/logout)
- Onboarding: 11-step flow, syncs profile via `ProfileSyncService` (retry queue)
- Quiz: Fetches questions from `GET /quiz/play`, submits via `POST /quiz/submit`
- Economy: `WalletService` persists coins/gems locally via Hive (no backend sync)
- Leaderboard: 3-tier loading (asset → cache → real API), WebSocket for live updates
- Multiplayer: Real API with mock fallback when backend unavailable
- Profile: Local Hive persistence + sync to backend on onboarding completion

### What's Missing on the Backend
- Economy state sync (coins/gems/energy live on device only)
- Crypto reward layer (micro-rewards, prize pools, staking)
- Real question bank / content management
- Match anti-cheat verification
- Admin analytics dashboard data
- Push notifications
- Synaptix-specific fields (intent, playStyle, synaptixMode) in user profiles

---

## Tier 1: CRITICAL — Must Work for Alpha Demo

These endpoints are actively called during the core user journey: **Launch → Auth → Onboard → Quiz → Score → Economy**.

### BE-A1: Authentication (`/auth/*`)

The frontend's `AuthApiClient` (`lib/core/services/auth_api_client.dart`) expects:

| Endpoint | Method | Request Body | Response |
|----------|--------|-------------|----------|
| `/auth/signup` | POST | `email`, `password`, `username`, `country`, `deviceId`, `deviceType` | `accessToken`, `refreshToken`, `expiresAtUtc`, `userId`, `user` object |
| `/auth/login` | POST | `email`, `password`, `deviceId`, `deviceType` | Same as signup |
| `/auth/refresh` | POST | `refreshToken`, `deviceId`, `deviceType` (supports both snake_case and camelCase) | `accessToken`, `refreshToken`, `expiresAtUtc` |
| `/auth/logout` | POST | `deviceId`, `deviceType`, `userId` | 204 No Content |

**Token contract** (from `docs/BACKEND_DECISIONS.md`):
- Access JWT: 10-minute TTL, includes `role`, `tier`, `isPremium`, `handle`, `mmr`, `email`
- Refresh token: Opaque string, 14-day TTL, rotating on every use
- Replay detection: Revoke entire session family if old refresh token reused
- Device tracking: All auth calls include `deviceId` for multi-device support

**Implementation notes:**
- Use `python-jose` or `PyJWT` for JWT generation
- Use `bcrypt` or `argon2` for password hashing
- Store refresh tokens hashed in DB
- User table needs: `id`, `email`, `password_hash`, `handle`, `role`, `is_active`, `is_premium`, `tier`, `mmr`, `country`, `age_group`, `created_at`

### BE-A2: Profile Sync (`/profile`, `/users/{id}`)

The onboarding completion handler syncs profile data. `ProfileSyncService` tries three paths in order:

| Endpoint | Method | Request Body | Response |
|----------|--------|-------------|----------|
| `PATCH /profile` | PATCH | `display_name`, `displayName`, `username`, `handle` | Confirmed `display_name`, `username` |
| `GET /users/{userId}` | GET | — | Full user profile |
| `PATCH /users/{userId}` | PATCH | `updates` map | Updated profile |

**Synaptix-specific profile fields** (new, from onboarding evolution):
- `synaptix_mode` — kids/teen/adult
- `intent` — train/compete/play
- `play_style` — fast/strategic/explorer
- `preferred_home_surface` — arena/pathways/labs/home
- `onboarding_completed` — boolean
- `first_challenge_score` — int
- `starter_rewards_claimed` — boolean

### BE-A3: Quiz Questions (`/quiz/*`)

| Endpoint | Method | Params/Body | Response |
|----------|--------|-------------|----------|
| `GET /quiz/play` | GET | `amount`, `category?`, `difficulty?` | `List` of `{question, answers[], correctIndex, category, difficulty}` |
| `POST /quiz/submit` | POST | `quizId`, `answers[]`, `score`, `totalQuestions` | Result with `coins`, `xp`, `diamonds` earned |

**Implementation notes:**
- Seed a question bank (500+ questions across 12 categories from `categories_step.dart`: general_knowledge, science, history, geography, entertainment, sports, arts_literature, technology, music, food_drink, mythology, animals)
- Support difficulty levels: easy, medium, hard
- `quizId` should be server-generated UUID for anti-cheat tracking
- Score calculation server-side: verify answers, compute rewards

### BE-A4: Health Check

| Endpoint | Method | Response |
|----------|--------|----------|
| `GET /health` | GET | 200 OK |

---

## Tier 2: HIGH — Should Work for Alpha (Core Features)

### BE-B1: Leaderboard (`/leaderboard/*`)

| Endpoint | Method | Params | Response |
|----------|--------|--------|----------|
| `GET /leaderboard` | GET | `limit`, `offset`, `category?` | Sorted `List` of `{playerId, playerName, score, rank, avatar}` |
| `POST /leaderboard` | POST | `playerName`, `score` | Created entry |
| `GET /leaderboard/user/{userId}` | GET | — | `{rank, score, tier}` |

**Notes:**
- Frontend's `LeaderboardDataService` loads from asset → cache → API (3-tier)
- WebSocket `leaderboard.subscribe` / `leaderboard.update` / `leaderboard.snapshot` are nice-to-have for alpha

### BE-B2: Economy State (`/mobile/economy/*`)

The frontend has a comprehensive economy client but WalletService is currently local-only. For alpha, implement:

| Endpoint | Method | Body | Response |
|----------|--------|------|----------|
| `GET /mobile/economy/state` | GET | `playerId` | `EconomyStateDto` — coins, gems, energy, lives, daily ticket status |
| `POST /mobile/economy/session/start` | POST | `playerId` | `SessionStartDto` — session rates, bonuses |

**Deferred to post-alpha:**
- `/mobile/economy/daily-jackpot-ticket/claim`
- `/mobile/economy/revive/quote`
- `/mobile/economy/pity/report-loss` / `report-win`
- `/mobile/matches/start` (policy-enforced match start)

### BE-B3: Achievements (`/users/{id}/achievements`)

| Endpoint | Method | Response |
|----------|--------|----------|
| `GET /users/{id}/achievements` | GET | List of earned achievements |
| `POST /users/{id}/achievements/{aid}` | POST | Unlock confirmation |

### BE-B4: Store (`/store/*`)

| Endpoint | Method | Response |
|----------|--------|----------|
| `GET /store/items` | GET | List of purchasable items (category filter) |
| `POST /store/purchase` | POST | Purchase result, updated balance |

---

## Tier 3: MEDIUM — Post-Alpha Features

### BE-C1: Multiplayer & Matchmaking

Full match flow from `docs/API_SPEC.md` section 10:

1. `POST /match/find` — Create/find match (201)
2. `POST /match/{id}/ready` — Lock questions, return per-question HMAC tokens
3. `POST /match/{id}/answer` — Submit answer with token (anti-cheat)
4. `GET /match/{id}/state` — Poll for opponent state
5. `POST /match/{id}/complete` — Apply MMR/season points (internal)

Additional:
- `POST /matchmaking/queue` — Join queue
- `DELETE /matchmaking/queue/{playerId}` — Cancel queue
- `GET /matches` — List player's matches
- `POST /matches/{id}/submit` — Submit final results
- `POST /matches/{id}/forfeit` — Forfeit match

### BE-C2: Seasons & Tiers

| Endpoint | Method | Response |
|----------|--------|----------|
| `GET /seasons/current` | GET | Current season metadata |
| `GET /seasons/active` | GET | Active `SeasonDto` |
| `GET /seasons/player-state/{playerId}` | GET | `PlayerSeasonStateDto` — tier, points, rank |
| `GET /seasons/{id}/leaderboard` | GET | Season-specific leaderboard |

### BE-C3: Skill Tree / Pathways

| Endpoint | Method | Response |
|----------|--------|----------|
| `GET /skills/tree` | GET | Full `SkillTreeDto` with nodes and connections |
| `POST /skills/{nodeId}/unlock` | POST | Unlocked `SkillNodeDto`, updated resources |

### BE-C4: Social / Friends

| Endpoint | Method | Response |
|----------|--------|----------|
| `GET /users/{id}/friends` | GET | Friends list |
| `POST /users/{id}/friends/request` | POST | Friend request sent |
| `POST /users/{id}/friends/accept` | POST | Request accepted |

### BE-C5: WebSocket Server

Implement the WsEnvelope protocol from `docs/WEBSOCKET_PROTOCOL.md`:

```json
{
  "op": "operation_name",
  "ts": 1234567890,
  "seq": 42,
  "data": {}
}
```

Priority operations:
1. `hello` / `ping` / `pong` — Connection lifecycle
2. `leaderboard.subscribe` / `leaderboard.update` / `leaderboard.snapshot` — Live rankings
3. `presence.subscribe` / `presence.update` — Online status
4. `chat.message` / `chat.typing` — Social messaging (Circles)

---

## Tier 4: Crypto Economy Layer

As discussed, this is a backend-only concern. The frontend's WalletService and economy providers are already wired for coins/gems — the crypto layer sits behind the same economy endpoints.

### BE-D1: Crypto Micro-Rewards Engine

**Concept:** Players earn fractional crypto tokens for engagement activities. This supplements the existing coin/gem system — it does NOT replace it.

**Reward triggers (mapped from frontend analytics events):**
- `synaptix_surface_opened` — small reward for daily engagement
- Quiz completion (`POST /quiz/submit`) — reward proportional to score
- Streak maintenance — bonus multiplier for consecutive days
- Arena tier advancement — milestone reward
- Onboarding completion — welcome bonus

**Architecture:**
```
[FastAPI] → [Reward Rules Engine] → [Transaction Ledger (Postgres)]
                                  → [Blockchain Bridge (async)]
```

**Database schema:**
```sql
CREATE TABLE crypto_ledger (
    id UUID PRIMARY KEY,
    player_id UUID REFERENCES users(id),
    amount DECIMAL(18,8) NOT NULL,
    currency VARCHAR(10) DEFAULT 'SYN',  -- Synaptix token
    trigger_event VARCHAR(50) NOT NULL,   -- quiz_complete, streak_bonus, etc.
    trigger_ref VARCHAR(100),             -- quizId, matchId, etc.
    status VARCHAR(20) DEFAULT 'pending', -- pending, confirmed, failed
    blockchain_tx_hash VARCHAR(100),      -- populated after chain confirmation
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE crypto_wallets (
    player_id UUID PRIMARY KEY REFERENCES users(id),
    wallet_address VARCHAR(100),          -- player's crypto wallet
    total_earned DECIMAL(18,8) DEFAULT 0,
    total_withdrawn DECIMAL(18,8) DEFAULT 0,
    pending_balance DECIMAL(18,8) DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
```

**Endpoints:**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `GET /crypto/balance` | GET | Player's crypto balance (earned, pending, withdrawn) |
| `GET /crypto/history` | GET | Transaction history with pagination |
| `POST /crypto/wallet/link` | POST | Link external wallet address |
| `POST /crypto/withdraw` | POST | Initiate withdrawal to linked wallet |

**Reward rules (configurable, server-side):**
```python
REWARD_RULES = {
    "quiz_complete": {"base": 0.01, "per_correct": 0.005, "streak_multiplier": 1.1},
    "daily_login": {"base": 0.005},
    "arena_tier_up": {"base": 0.05, "per_tier": 0.02},
    "onboarding_complete": {"base": 0.10},
    "weekly_top_10": {"base": 0.50},
}
```

### BE-D2: Weekly Prize Pools

**Concept:** A percentage of platform revenue or token allocation goes into weekly prize pools. Top performers in Arena receive crypto payouts.

**Endpoints:**
| Endpoint | Method | Purpose |
|----------|--------|---------|
| `GET /crypto/prize-pool/current` | GET | Current pool size, time remaining, top contenders |
| `GET /crypto/prize-pool/history` | GET | Past pools and winners |
| `GET /crypto/prize-pool/eligibility` | GET | Player's eligibility and current standing |

**Distribution logic:**
- Pool resets weekly (Sunday UTC midnight)
- Top 10% of Arena players split the pool
- Distribution: 1st: 30%, 2nd: 20%, 3rd: 15%, 4th-10th: equal split of remaining 35%
- Minimum pool threshold before distribution activates

### BE-D3: Future — Optional Staking

Defer to post-alpha. Design notes for later:
- Players lock tokens for boosted in-game multipliers
- Lock periods: 7d (1.1x), 30d (1.25x), 90d (1.5x)
- Unlocking before period ends forfeits bonus
- Smart contract integration required

---

## Database Schema (Core Tables for Alpha)

```sql
-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    handle VARCHAR(50) UNIQUE,
    display_name VARCHAR(100),
    role VARCHAR(20) DEFAULT 'USER',
    is_active BOOLEAN DEFAULT TRUE,
    is_premium BOOLEAN DEFAULT FALSE,
    tier INT DEFAULT 0,
    mmr INT DEFAULT 1000,
    country VARCHAR(3),
    age_group VARCHAR(20),
    avatar_url VARCHAR(500),
    -- Synaptix-specific fields
    synaptix_mode VARCHAR(10),        -- kids/teen/adult
    intent VARCHAR(20),               -- train/compete/play
    play_style VARCHAR(20),           -- fast/strategic/explorer
    preferred_home_surface VARCHAR(20), -- arena/pathways/labs/home
    onboarding_completed BOOLEAN DEFAULT FALSE,
    first_challenge_score INT,
    starter_rewards_claimed BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Auth sessions
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    device_id VARCHAR(100) NOT NULL,
    device_type VARCHAR(20),
    family_id UUID NOT NULL,           -- for replay detection
    expires_at TIMESTAMPTZ NOT NULL,
    revoked BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Economy
CREATE TABLE wallets (
    player_id UUID PRIMARY KEY REFERENCES users(id),
    coins INT DEFAULT 0,
    gems INT DEFAULT 0,
    energy INT DEFAULT 100,
    max_energy INT DEFAULT 100,
    lives INT DEFAULT 5,
    max_lives INT DEFAULT 5,
    last_energy_regen TIMESTAMPTZ DEFAULT NOW(),
    last_lives_regen TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Questions
CREATE TABLE questions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    question TEXT NOT NULL,
    answers JSONB NOT NULL,            -- ["answer1", "answer2", "answer3", "answer4"]
    correct_index INT NOT NULL,
    category VARCHAR(50) NOT NULL,
    difficulty VARCHAR(20) NOT NULL,   -- easy/medium/hard
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Quiz sessions
CREATE TABLE quiz_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID REFERENCES users(id),
    category VARCHAR(50),
    difficulty VARCHAR(20),
    question_ids JSONB NOT NULL,       -- ordered list of question UUIDs
    answers JSONB,                     -- player's submitted answers
    score INT,
    total_questions INT,
    coins_earned INT DEFAULT 0,
    xp_earned INT DEFAULT 0,
    gems_earned INT DEFAULT 0,
    started_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ
);

-- Leaderboard
CREATE TABLE leaderboard_entries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    player_id UUID REFERENCES users(id),
    player_name VARCHAR(100),
    score INT NOT NULL,
    category VARCHAR(50),
    season_id UUID,
    avatar_url VARCHAR(500),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Achievements
CREATE TABLE achievements (
    id VARCHAR(50) PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    description TEXT,
    icon VARCHAR(100),
    category VARCHAR(50)
);

CREATE TABLE player_achievements (
    player_id UUID REFERENCES users(id),
    achievement_id VARCHAR(50) REFERENCES achievements(id),
    unlocked_at TIMESTAMPTZ DEFAULT NOW(),
    PRIMARY KEY (player_id, achievement_id)
);

-- Store items
CREATE TABLE store_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(100) NOT NULL,
    description TEXT,
    category VARCHAR(50),
    price_coins INT DEFAULT 0,
    price_gems INT DEFAULT 0,
    icon VARCHAR(100),
    is_active BOOLEAN DEFAULT TRUE
);

-- Analytics events
CREATE TABLE analytics_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    event_name VARCHAR(100) NOT NULL,
    properties JSONB,
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    event_hash VARCHAR(64)             -- for dedup per BACKEND_DECISIONS.md
);
```

---

## FastAPI Project Structure

```
synaptix-backend/
├── app/
│   ├── main.py                    # FastAPI app entry, CORS, lifespan
│   ├── config.py                  # Settings (env-based)
│   ├── database.py                # SQLAlchemy / asyncpg setup
│   │
│   ├── auth/
│   │   ├── router.py              # /auth/* endpoints
│   │   ├── service.py             # Token generation, password hashing
│   │   ├── models.py              # User, RefreshToken SQLAlchemy models
│   │   └── schemas.py             # Pydantic request/response schemas
│   │
│   ├── quiz/
│   │   ├── router.py              # /quiz/* endpoints
│   │   ├── service.py             # Question selection, scoring, reward calc
│   │   ├── models.py              # Question, QuizSession models
│   │   └── schemas.py
│   │
│   ├── leaderboard/
│   │   ├── router.py              # /leaderboard/* endpoints
│   │   ├── service.py             # Ranking, pagination
│   │   └── schemas.py
│   │
│   ├── economy/
│   │   ├── router.py              # /mobile/economy/* endpoints
│   │   ├── service.py             # Wallet operations, energy regen
│   │   ├── models.py              # Wallet model
│   │   └── schemas.py
│   │
│   ├── profile/
│   │   ├── router.py              # /profile, /users/* endpoints
│   │   ├── service.py             # Profile CRUD, Synaptix fields
│   │   └── schemas.py
│   │
│   ├── store/
│   │   ├── router.py              # /store/* endpoints
│   │   ├── service.py             # Purchase logic, balance checks
│   │   └── schemas.py
│   │
│   ├── achievements/
│   │   ├── router.py              # Achievement endpoints
│   │   └── service.py
│   │
│   ├── crypto/                    # Crypto economy layer
│   │   ├── router.py              # /crypto/* endpoints
│   │   ├── service.py             # Reward calculation, ledger
│   │   ├── models.py              # CryptoLedger, CryptoWallet
│   │   ├── reward_rules.py        # Configurable reward triggers
│   │   └── schemas.py
│   │
│   ├── analytics/
│   │   ├── router.py              # /analytics/* endpoints
│   │   └── service.py             # Event ingestion, dedup
│   │
│   ├── websocket/                 # Post-alpha
│   │   ├── manager.py             # Connection manager
│   │   └── handlers.py            # WsEnvelope protocol handlers
│   │
│   └── middleware/
│       ├── auth.py                # JWT verification dependency
│       └── cors.py                # CORS configuration
│
├── migrations/                    # Alembic migrations
├── seeds/                         # Question bank, achievements, store items
├── tests/
├── docker-compose.yml
├── Dockerfile
├── requirements.txt
└── .env.example
```

---

## Implementation Order for Alpha

### Sprint 1 (Day 1): Core Auth + Quiz
1. FastAPI project scaffold with PostgreSQL
2. `BE-A1`: Auth endpoints (signup, login, refresh, logout)
3. `BE-A2`: Profile PATCH with Synaptix fields
4. `BE-A3`: Quiz questions endpoint + seed question bank (500+ questions)
5. `BE-A4`: Health check
6. Verify Flutter app can complete: signup → onboarding → quiz → score

### Sprint 2 (Day 2): Economy + Leaderboard
7. `BE-B1`: Leaderboard CRUD + user rank
8. `BE-B2`: Economy state + session start
9. `BE-B3`: Achievements list + unlock
10. `BE-B4`: Store items + purchase
11. End-to-end smoke test: full user journey

### Sprint 3 (Post-Alpha): Multiplayer + Crypto
12. `BE-C1`: Match flow with anti-cheat tokens
13. `BE-C2`: Seasons and tier progression
14. `BE-C5`: WebSocket server for live leaderboard
15. `BE-D1`: Crypto micro-rewards engine
16. `BE-D2`: Weekly prize pools

### Sprint 4 (Post-Alpha): Social + Advanced
17. `BE-C3`: Skill tree API
18. `BE-C4`: Friends system
19. `BE-D3`: Staking (design only)
20. Admin MFA + dashboard endpoints

---

## API Response Format Convention

Per `docs/API_SPEC.md`:

```python
# Success
{"data": {...}}

# List
{"items": [...], "next_cursor": "...", "page": 1, "pageSize": 50, "totalItems": 0, "totalPages": 0}

# Error
{"error": "validation_error", "message": "Human message", "details": {}, "request_id": "uuid"}
```

---

## Environment Variables

```env
# Database
DATABASE_URL=postgresql+asyncpg://synaptix:password@localhost:5432/synaptix_db

# JWT
JWT_SECRET=<random-256-bit-key>
JWT_ALGORITHM=HS256
JWT_ACCESS_TOKEN_EXPIRE_MINUTES=10
JWT_REFRESH_TOKEN_EXPIRE_DAYS=14

# Crypto (post-alpha)
CRYPTO_ENABLED=false
CRYPTO_REWARD_MULTIPLIER=1.0
CRYPTO_BLOCKCHAIN_RPC=
CRYPTO_CONTRACT_ADDRESS=

# General
CORS_ORIGINS=http://localhost:3000,http://localhost:8080
LOG_LEVEL=INFO
```

---

## Frontend ↔ Backend Alignment Checklist

| Frontend Feature | Backend Endpoint | Status |
|-----------------|-----------------|--------|
| Auth (login/signup/refresh/logout) | `/auth/*` | Needs implementation |
| Onboarding profile sync | `PATCH /profile` | Needs Synaptix fields |
| Quiz play | `GET /quiz/play` | Needs question bank |
| Quiz submit + rewards | `POST /quiz/submit` | Needs scoring + reward calc |
| Leaderboard display | `GET /leaderboard` | Needs implementation |
| Economy display (coins/gems) | `GET /mobile/economy/state` | Needs implementation |
| Store browsing + purchase | `GET/POST /store/*` | Needs implementation |
| Achievements display | `GET /users/{id}/achievements` | Needs implementation |
| Featured match (Hub) | `GET /quiz/play` | Shares quiz endpoint |
| Analytics events | `POST /analytics/track` | Needs implementation |
| Multiplayer matches | `/matches/*`, `/matchmaking/*` | Post-alpha |
| WebSocket (live leaderboard) | `ws://` | Post-alpha |
| Crypto rewards | `/crypto/*` | Post-alpha |
| Seasons/tiers | `/seasons/*` | Post-alpha |
| Friends/social | `/users/{id}/friends/*` | Post-alpha |
| Skill tree | `/skills/*` | Post-alpha |
| Admin MFA | `/admin/auth/*` | Post-alpha |
| Guardians/Territory | `/guardians/*`, `/territory/*` | Post-alpha |

---

## Acceptance Criteria for Alpha Backend

The backend is alpha-ready when:

- [ ] User can sign up and receive JWT tokens
- [ ] User can log in with existing credentials
- [ ] Token refresh works (old token revoked, new issued)
- [ ] Profile PATCH accepts and stores Synaptix fields (synaptix_mode, intent, play_style)
- [ ] `GET /quiz/play` returns questions from seeded bank (12 categories, 3 difficulty levels)
- [ ] `POST /quiz/submit` validates answers, calculates score, returns coin/XP/gem rewards
- [ ] `GET /leaderboard` returns sorted entries with pagination
- [ ] `GET /mobile/economy/state` returns player's wallet balance
- [ ] `GET /store/items` returns browsable store catalog
- [ ] `POST /store/purchase` deducts currency and grants item
- [ ] `GET /health` returns 200
- [ ] CORS allows Flutter app origin
- [ ] All endpoints return errors in standard format
- [ ] Question bank seeded with 500+ questions across 12 categories
