# Seasonal Events & Tie-breaker — Backend Route Plan

**Date:** 2026-07-09
**Status:** ✅ Phases A–E implemented (2026-07-10) on backend branch `claude/season-leaderboard` + this repo. §5 decisions (confirmed by owner): balanced point formula with a 50/day solo cap; tie detection at rank 1 + promotion cutoffs only; 24h snapshot deferral with real stakes; auto-scheduling at close with admin override. Implementation notes vs. this plan: match-point accrual already existed (`SubmitMatch` + `RankedSeasonOptions`, win 30 + correct/2 — kept as-is rather than the proposed 25/10/5, since it is live behavior and already satisfies "multiplayer out-earns solo"); the solo daily cap is computed from the `SeasonPointTransaction` ledger (no schema change); tiebreaker resolution also has an admin lever (`POST /admin/seasons/tiebreakers/{id}/resolve`).
**Motivation:** Four client methods (`submitScore`, `getSeasonLeaderboard`, `resetPlayerSeasonPoints`, `scheduleTiebreakerQuiz`) were part of the seasonal-events and multiplayer tie-breaker design but call routes that never shipped. They are currently `@Deprecated` in `ApiService`. This plan restores the features properly — server-authoritative, on the data model the backend already has.

---

## 1. What the backend already has (verified)

| Asset | Location | Relevance |
|---|---|---|
| `Season` entity + lifecycle (`Activate`, `Close`) | `Domain/Entities/Season.cs` | Season windows exist |
| `PlayerSeasonProfile` — **RankPoints**, Wins/Losses/Draws, MatchesPlayed, Tier (1..N), TierRank (1..100) | `Domain/Entities/PlayerSeasonProfile.cs` | The leaderboard data already accrues |
| `SeasonPointTransaction` | `Domain/Entities/` | Auditable point ledger |
| `SeasonRankSnapshotRow` | `Domain/Entities/` | End-of-season standings snapshots |
| `SeasonRewardRule` / `SeasonRewardClaim` | `Domain/Entities/` | Reward distribution |
| `SeasonEndedEvent` / `SeasonStartedEvent` | `Domain/Events/` | Hook points for tie detection |
| `SeasonService.CloseAsync` — closes a season, optionally creates the next one and **carries over a % of RankPoints per player** | `Application/Seasons/SeasonService.cs` | Supersedes client-side resets |
| Public routes: `GET /api/v1/seasons/active`, `GET /api/v1/seasons/state/{playerId}`, `/seasons/rewards/*` | `Features/Seasons/` | Player state exists; standings don't |
| Admin routes: `POST /admin/seasons/{id}/close` (+ lifecycle/rewards) — mounted at `/admin`, **outside `/api/v1`** | `Features/AdminSeasons/` | Operator lifecycle exists |

**Conclusion:** the client's DIY season-end logic (`seasonal_competition_service.dart` fetching a leaderboard, resetting player points, and scheduling tiebreakers *from the device*) was designed before the backend grew this domain. Points, resets, and season lifecycle are now server concerns; what's genuinely missing is **a public leaderboard read** and **the tie-breaker mechanic**.

## 2. Gap analysis per deprecated client method

| Client method | Verdict | Replacement |
|---|---|---|
| `getSeasonLeaderboard(seasonId)` | **Missing route — build it** (§3.1) | `GET /api/v1/seasons/{seasonId}/leaderboard` (+ `/seasons/active/leaderboard` alias) |
| `submitScore(playerName, score)` | **Superseded — do not rebuild.** Client-pushed scores are a cheating vector. Rank points must accrue server-side where results are already graded | Award `SeasonPointTransaction`s inside `POST /quiz/complete`, `POST /matches/submit`, and the check-batch XP path (§3.2) |
| `resetPlayerSeasonPoints(playerId)` | **Superseded** by `SeasonService.CloseAsync` carryover; add a moderation-only per-player reset for support cases (§3.3) | `POST /admin/seasons/{seasonId}/players/{playerId}/reset` |
| `scheduleTiebreakerQuiz(players, time)` | **Missing feature — build it server-side** (§3.4). Tie detection belongs in season close, not in whichever client happens to be open | Tiebreaker entity + admin/auto scheduling + player-facing routes |

## 3. Proposed backend work

### 3.1 Season leaderboard (public, small — unblocks the client immediately)

```
GET /api/v1/seasons/{seasonId:guid}/leaderboard?page=1&pageSize=50
GET /api/v1/seasons/active/leaderboard?page=1&pageSize=50   (alias resolving the active season)
```

- Source: `PlayerSeasonProfiles` for the season, ordered by `RankPoints DESC`, tiebreak `Wins DESC, MatchesPlayed ASC, PlayerId` (stable).
- Join `Users` for handle/avatar. Optional auth: when a JWT is present, include the caller's own `rank` even if off-page (same pattern as the arcade leaderboard's rank computation).
- Response DTO (new, in `Synaptix.Shared.Contracts`):

```json
{
  "seasonId": "…", "seasonNumber": 7, "page": 1, "pageSize": 50, "total": 1234, "totalPages": 25,
  "items": [
    { "rank": 1, "playerId": "…", "handle": "quizqueen", "avatarUrl": null,
      "rankPoints": 4200, "wins": 61, "losses": 12, "draws": 2, "tier": 5, "tierRank": 1 }
  ],
  "me": { "rank": 231, "rankPoints": 890 }
}
```

- Closed seasons should serve from `SeasonRankSnapshotRow` (immutable final standings) and live seasons from profiles.
- **Client migration:** un-deprecate `getSeasonLeaderboard`, point it at the new route, map to `SeasonPlayer`; `arcade_providers.dart:114` and `seasonal_competition_service.dart` work again unchanged in shape.
- Effort: **~½ day** backend + tests, ~1 hour client.

### 3.2 Season point accrual (replaces `submitScore`)

- Add a `SeasonPointsService.AwardAsync(playerId, points, reason, sourceId)` that upserts the active-season `PlayerSeasonProfile`, appends a `SeasonPointTransaction` (idempotent on `sourceId`), and recomputes Tier/TierRank lazily.
- Call it from the three places results are already graded server-side:
  - `POST /quiz/complete` (solo quizzes — `sourceId = eventId`),
  - `POST /matches/submit` (multiplayer — winner/loser/draw points),
  - the `check-batch` quiz XP path (`sourceId = quizSessionId`) — same idempotency key as the XP award.
- Point formula is config (start simple: solo = correct-answers; match win/draw/loss = 25/10/5), stored in `AdminAppConfig` so operators can tune without deploys.
- **No public "submit points" endpoint** — `submitScore` stays deprecated and is deleted from the client once accrual ships.
- Effort: **~1–1.5 days** backend + tests.

### 3.3 Moderation reset (replaces `resetPlayerSeasonPoints`)

```
POST /admin/seasons/{seasonId:guid}/players/{playerId:guid}/reset   (admin group, RequireAdminOpsKey)
```

- Zeroes the profile's RankPoints and writes a negative `SeasonPointTransaction` (`reason: "moderation_reset"`) so the ledger stays truthful.
- Full-season resets remain `POST /admin/seasons/{id}/close` with `carryoverPercent: 0`.
- The client method is deleted — this is an operator action (belongs in the operator dashboard, not the game client).
- Effort: **~½ day**.

### 3.4 Tie-breaker mechanic (replaces `scheduleTiebreakerQuiz`)

New entity `SeasonTiebreaker`:

```csharp
Guid Id; Guid SeasonId; string Scope;              // "top1" | "tier-promotion" | custom
Guid[] PlayerIds; DateTimeOffset ScheduledAtUtc;
string Status;                                      // Scheduled | InProgress | Completed | Cancelled | Expired
Guid? MatchId; Guid? WinnerPlayerId;
```

Flow:
1. **Detection** — in `SeasonService.CloseAsync` (or a `SeasonEndedEvent` handler): before snapshotting final standings, detect ties on `RankPoints` at reward-boundary positions (rank 1, tier promotion cutoffs from `SeasonRewardRule`). For each tie group, create a `SeasonTiebreaker` scheduled (default) 24h out, and **defer those players' final snapshot rows** until it resolves.
2. **Scheduling/notification** — on creation, push a player notification (existing `PlayerNotifications` feature) + expose it to the client.
3. **Play** — at the scheduled time the players enter a ranked head-to-head via the existing matches flow (`POST /matches/start` with `mode: "tiebreaker"`, `tiebreakerId`); `POST /matches/submit` resolution sets `WinnerPlayerId` and finalizes the deferred snapshot rows/reward claims.
4. **Expiry** — a background job (Hangfire is already in the stack — the CI logs show its server) marks no-shows: absent players lose the tiebreak; all-absent ⇒ resolve by the standard deterministic tiebreak (Wins, then earliest to reach the point total via the transaction ledger).

Routes:

```
GET  /api/v1/seasons/tiebreakers/mine                          (auth — player's pending/active tiebreakers)
GET  /api/v1/seasons/{seasonId:guid}/tiebreakers               (public, read-only status)
POST /admin/seasons/{seasonId:guid}/tiebreakers                (manual scheduling: {playerIds[], scheduledAtUtc, scope})
POST /admin/seasons/tiebreakers/{id:guid}/cancel
```

- **Client migration:** `scheduleTiebreakerQuiz` is deleted (operator/auto concern). The client instead polls `GET /seasons/tiebreakers/mine` (or receives the notification) and deep-links into the match screen — UI work that fits the Sprint 3 social/multiplayer block.
- Effort: **~3–4 days** backend (entity + migration + detection + endpoints + job + tests), **~1–2 days** client (tiebreaker banner/lobby entry + match mode plumbing).

## 4. Sequencing & dependencies

| Phase | Item | Effort | Depends on |
|---|---|---|---|
| A (now) | §3.1 leaderboard routes + client re-wire | ~1 day total | nothing |
| B | §3.2 point accrual in quiz/match completion | ~1.5 days | none (idempotency keys already exist) |
| C | §3.3 moderation reset (admin) | ~½ day | none |
| D | §3.4 tie-breaker entity/detection/routes/job | ~3–4 days backend | B (points must accrue for ties to be real) |
| E | Client tiebreaker UX (banner, lobby, match mode) | ~1–2 days | D |

Phase A alone revives the season leaderboard screens; B makes standings real; D/E deliver the tie-breaker mechanic you remember from the original design — but server-authoritative this time.

## 5. Risks / decisions to confirm

1. **Point formula ownership** — proposed as `AdminAppConfig`-tunable; confirm initial values.
2. **Tie scope** — plan detects ties at rank 1 and tier-promotion boundaries only; detecting *every* equal-points pair would spam tiebreakers.
3. **Snapshot deferral** — holding reward claims for tied positions until the tiebreaker resolves delays end-of-season payouts for those players by up to the 24h window + expiry; acceptable?
4. **`/admin` mount** — admin season routes live outside `/api/v1` with the ops-key guard; the game client should never call them (the old client methods did — that's part of why they're deprecated).
