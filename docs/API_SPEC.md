Trivia Tycoon — API Spec (v1)
0) Conventions

Base URL: /v1
Auth: Authorization: Bearer <JWT> unless noted as public
Content-Type: application/json
Idempotency: For any unsafe POST/PUT/DELETE, support Idempotency-Key header.
Request IDs: Client sends X-Request-ID (UUID).
Rate limits (default): 60 req/min/user; Retry-After on 429.
Timestamps: RFC3339 UTC. Server time is truth.
Pagination: ?limit=50&cursor=<opaque> → returns { "items": [], "next_cursor": "..." }
Errors:

{
  "error": "validation_error",
  "message": "Field 'tier' must be one of: bronze,silver,gold",
  "details": {"field":"tier"},
  "request_id": "..."
}

1) Health (Phase 0)
GET /health/liveness (public)

200 OK { "status": "ok" }

GET /health/readiness (public)

200 OK { "status": "ok", "postgres": "ok", "redis": "ok" }
503 if any dependency unavailable.

2) Auth (Phase 0)
POST /auth/login

Body:

{ "email": "a@b.com", "password": "secret", "device_id":"ios:abcd" }


200:

{ "access_token": "jwt", "refresh_token":"jwt", "expires_in": 900, "user": { "id":"u_123", "handle":"Nova", "country":"US" } }


401 invalid creds.

POST /auth/refresh

Body: { "refresh_token":"jwt" }
200 same shape as /auth/login.

POST /auth/logout

Body: { "device_id":"ios:abcd" }
204 No Content.

(Optional later: /auth/register, /auth/revoke)

3) Users (Phase 1)
GET /users/me

200:

{ "id":"u_123","handle":"Nova","country":"US","tier":"T4","mmr":1420,"flags":{},"created_at":"..." }

PATCH /users/me

Body (partial):

{ "handle":"NewName","country":"JM" }


200 updated profile.

4) Matches — Async 1v1 Duels (Phase 2)
POST /match/find

Find or create a duel for the user.

Headers: Idempotency-Key, Authorization
Body:

{ "mode":"duel", "tier":"T4", "opponent_id": null }


201 Created:

{
  "match_id":"m_001",
  "state":"matching",            // matching|ready|in_progress|complete|abandoned
  "tier":"T4",
  "mode":"duel",
  "participants":[{"user_id":"u_123"}],
  "created_at":"..."
}


409 if user already in an active match in same mode.
429 if queue rate-limited.

POST /match/{match_id}/ready

Server locks questions & schedules turns. Only when 2 players are present.

Body:

{ "rounds": 5, "pack_id":"gen_qa", "pack_version":"2025.09" }


200:

{
  "match_id":"m_001",
  "turns":[
    {
      "turn_no":1,
      "question_id":"q_98765",
      "options_order":[2,0,3,1],
      "reveal_ts":"2025-09-20T00:00:10Z",
      "deadline_ts":"2025-09-20T00:00:20Z",
      "token":"tok_xxx"          // per-question HMAC: match_id, turn_no, question_id
    }
  ],
  "server_now":"2025-09-20T00:00:05Z"
}


403 if caller not in match. 409 if already readied.

POST /match/{match_id}/answer

Server-authoritative scoring.

Body:

{
  "turn_no":1,
  "question_id":"q_98765",
  "selected_option": 2,
  "token":"tok_xxx",
  "client_ts":"2025-09-20T00:00:12.123Z"
}


200:

{
  "accepted": true,
  "correct": true,
  "score_delta": 10,
  "latency_ms": 420,
  "reject_reason": null,
  "server_now":"2025-09-20T00:00:12.600Z"
}


422 reject reasons: too_fast, after_deadline, bad_token, duplicate, not_your_turn.

GET /match/{match_id}/state

200:

{
  "match_id":"m_001",
  "state":"in_progress",
  "participants":[
    {"user_id":"u_123","score":20,"finished":false},
    {"user_id":"u_999","score":10,"finished":false}
  ],
  "current_turn":2,
  "turns_total":5,
  "next_deadline_ts":"2025-09-20T00:00:35Z",
  "server_now":"2025-09-20T00:00:30Z"
}

POST /match/{match_id}/forfeit

204 No Content → opponent wins, MMR applied.

POST /match/{match_id}/complete (server/internal)

Applies final scoring + MMR.
200:

{
  "result": "win",               // win|loss|draw
  "mmr_delta": +14,
  "final_scores": {"u_123": 42, "u_999": 35},
  "season_points_delta": 20
}

POST /match/{match_id}/rematch (Phase 6)

Body: {} → 201 New match (holds both users for 30s) or 202 Pending if waiting for other player.

POST /match/challenge (Phase 6)

Body: { "opponent_id":"u_555","tier":"T4" } → 201 challenge created / 409 if busy.

5) Leaderboards & Seasons (Phase 3)
GET /seasons/current

200:

{ "season_id":"S2025-09","starts_at":"...","ends_at":"...","ruleset":"standard" }

GET /leaderboards/{season_id}/{tier}

Query: ?cursor=&limit=50&around=me|rank:<n>
200:

{
  "season_id":"S2025-09",
  "tier":"T4",
  "items":[
    {"rank":1,"user_id":"u_A","points":340,"handle":"Alpha","country":"US"},
    {"rank":2,"user_id":"u_B","points":335,"handle":"Bravo","country":"JM"}
  ],
  "next_cursor":"eyJvZmZzZXQiOjUxfQ==",
  "me":{"rank":23,"points":188}
}

POST /leaderboards/recalc (admin, Phase 3)

Body: { "season_id":"S2025-09" } → 202 Accepted (job enqueued).

6) Content (Phase 1, internal-facing)
GET /content/packs

200:

[
  {"pack_id":"gen_qa","version":"2025.09","checksum":"sha256:...","active":true}
]


(No endpoint exposes answers. Questions are referenced by ID only.)

7) Tournaments (Phase 5, later)
GET /tournaments/upcoming

200:

[
  { "id":"t_001","tier":"T4","starts_at":"2025-09-21T20:00:00Z","format":"swiss","capacity":256 }
]

POST /tournaments/{id}/register

201 registered or 409 if full/duplicate.

GET /tournaments/{id}/bracket

200:

{ "id":"t_001","state":"round_3","pairs":[["u_1","u_9"],["u_2","u_8"]],"next_round_eta":"..." }

WebSocket /ws/tournaments/{id} (optional)

Server → Client events: pairings, round_start, round_end, eliminated, winner.

Client → Server: subscribe, ping.

8) Admin & Ops
GET /admin/flags/{user_id} (Phase 4)

Returns anti-cheat/anomaly flags. 200:

{ "user_id":"u_123","flags":[{"code":"too_fast_streak","score":0.82,"since":"..."}] }

POST /admin/flags/{user_id}/clear (Phase 4)

Body: { "code":"too_fast_streak","note":"manual review ok" } → 204.

GET /admin/metrics/snapshot (Phase 7)

200:

{ "matches_active": 82, "queue_wait_ms_p95": 210, "answers_rejected_rate": 0.031 }

9) Security & Anti-cheat (embedded rules)

Per-question token: HMAC over (match_id,turn_no,question_id,issued_at); expires at deadline_ts + 2s.

Timing floors: Reject if submission < min_latency_ms (default 300ms) after reveal_ts.

Duplicate guard: One accepted answer per (match_id,user_id,turn_no).

Clock skew: Record client_ts - server_now each call; maintain moving average per device.

Rate limit: /answer 6 req/10s sliding window.

Audit fields in answers: latency_ms, reject_reason, client_skew_ms.

10) Example Flows
Duel (happy path)

POST /match/find → m_001 (matching)

Second player joins → server pairs; any player calls POST /match/{m}/ready → returns 5 turns with tokens & deadlines

For each turn, player calls POST /match/{m}/answer

Server completes match → POST /match/{m}/complete (internal) applies MMR & season points

Client polls GET /match/{m}/state until state=complete

Forfeit

POST /match/{m}/forfeit → 204 → opponent wins; mmr_delta applied.

11) DTO Reference (selected)

MatchState

{
  "match_id":"string",
  "state":"matching|ready|in_progress|complete|abandoned",
  "mode":"duel",
  "tier":"T4",
  "participants":[{"user_id":"string","score":0,"finished":false}],
  "current_turn":1,
  "turns_total":5,
  "next_deadline_ts":"timestamp",
  "server_now":"timestamp"
}


TurnDescriptor

{
  "turn_no":1,
  "question_id":"string",
  "options_order":[0,1,2,3],
  "reveal_ts":"timestamp",
  "deadline_ts":"timestamp",
  "token":"string"
}


AnswerResult

{
  "accepted": true,
  "correct": true,
  "score_delta": 10,
  "latency_ms": 420,
  "reject_reason": null,
  "server_now":"timestamp"
}

12) Status Codes (summary)

200 OK — read operations; some writes that return data

201 Created — match found/created, registrations, challenges

202 Accepted — long-running admin jobs

204 No Content — forfeit, logout, admin clears

400 Bad Request — invalid inputs

401 Unauthorized — missing/invalid JWT

403 Forbidden — not participant, or admin-only

404 Not Found — entity missing

409 Conflict — already in match/readied/etc.

422 Unprocessable Entity — anti-cheat rejections

429 Too Many Requests — rate limits

500 Server error

13) Headers & Caching

Cache-Control: no-store for match endpoints.

ETag/If-None-Match allowed on leaderboards.

Idempotency-Key required on /match/find, /answer, /forfeit, /rematch, /challenge.

14) Secrets & Config

APP_SECRET (HMAC for per-question tokens)

JWT_SECRET (or private key if RS256)

RATE_LIMIT_* (tunable)

MIN_LATENCY_MS (default 300)

TURN_DURATION_MS (default 8,000)

All come from env + config/app.yaml merge.

15) Test Fixtures (for the other agent)

Seed: 10 users, 2 tiers (T4/T5), content pack gen_qa@2025.09 with 100 dummy question IDs.

Bot users for load tests (u_bot_*) that answer with configurable accuracy and latency.