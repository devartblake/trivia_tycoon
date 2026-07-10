# Champion vs Tier — Weekly 1-vs-99 Spectacle Event

**Date:** 2026-07-10
**Status:** 🚧 Phase 1 (core) implemented on backend branch `claude/season-leaderboard` + this repo. Phases 2–5 proposed.
**Inspiration:** the "1 vs 100" / mob-vs-individual game-show format — high-spectacle tension where one champion faces a crowd, and every fallen challenger swells the prize.

> **Design decisions confirmed by owner (2026-07-10):**
> 1. **Betting → no-loss prediction.** No staked/losable currency. Spectators *predict* the winner; correct picks earn a reward, wrong picks lose nothing. Chosen because the app ships guardian assignment, parental consent and `children`/`adolescence` age groups — a staked wager token is gambling-adjacent for a product with minors and would invite app-store / regional legal review. The spectacle and the monetization come from premium spectating and sponsor-backed jackpots, not from a betting sink.
> 2. **Champion = the tier's current #1**, seeded from the season leaderboard, facing 99 challengers in **live synchronized rounds** (everyone answers the same questions at once over SignalR; a wrong answer eliminates you).
> 3. **One weekly headline event** (the top active tier), not one per tier — concentrates attention, jackpot and sponsor value.
> 4. **Deliver the core first**, then layer the live-round, prediction, spectator and sponsor phases.

---

## 1. What already exists (verified in `TycoonTycoon_Backend`)

The backend already carries a near-complete elimination-event framework. The user's core loop ("#1 fights 99, each elimination grows the jackpot, incentivize rank-climbing") is mostly wiring, not greenfield.

| Asset | Location | Relevance |
|---|---|---|
| `GameEvent` aggregate — `Kind`, `TierId`, `Status` (Scheduled→Open→Live→Closed), `JackpotPool`, `AddToJackpot()`, `MaxParticipants`, entry/revive costs | `Domain/Entities/GameEvent.cs` | The event shell — tier-scoped, kind-keyed, jackpot built in |
| `GameEventParticipant` — `EliminatedAt`, `FinalRank`, `RevivesUsed` | `Domain/Entities/` | Per-player state + elimination tracking |
| `EnterGameEvent` — atomic entry-fee debit via `IPlayerTransactionService`; **`champion_battle` adds the entry fee to the jackpot** | `Application/GameEvents/EnterGameEvent.cs` | Paid entry + jackpot seeding |
| `EliminateParticipant` — marks out, **`champion_battle` adds +50 to the jackpot per elimination**, SignalR elimination broadcast | `Application/GameEvents/EliminateParticipant.cs` | *This is literally "each eliminated player adds to the jackpot pool."* |
| `CloseGameEventAndDistributePrizes` — ranks survivors→eliminated, top-20 prizes, **rank-1 in `champion_battle` takes the whole jackpot**, idempotent claims, per-season event stats | `Application/GameEvents/` | Prize distribution + winner-takes-jackpot |
| `ReviveInGameEvent` — gem-cost revive (Global Crown) | `Application/GameEvents/` | Optional comeback economy |
| `GameEventSchedulerJob` (Hangfire) — opens/starts/auto-closes on time windows | `Application/GameEvents/` | Lifecycle automation |
| Public routes `POST /game-events/enter`, `/revive`, `GET /game-events/{id}`, `/game-events/upcoming`; admin create; season/event leaderboards | `Features/GameEvents/` | Entry + status + listing surface |
| SignalR hubs `MatchHub`, `PresenceHub`, `NotificationHub`, `MatchmakingHub` + `IGameEventNotifier` | `Api/Realtime/` | Real-time channel for live rounds & spectating |
| `PlayerSeasonProfile` (Tier, RankPoints, ordering) + `GET /seasons/{id}/leaderboard` | Seasons domain | Source for seeding the tier champion |

**Gap vs the 1-vs-99 spec:** (a) the champion role is not modelled — `champion_battle` is a symmetric battle-royale where rank-1 = last survivor, not "the tier's #1 defends against a mob"; (b) no prediction mechanic; (c) no premium spectator gate; (d) no sponsor jackpot multiplier; (e) no live synchronized round orchestration.

## 2. Phasing

| Phase | Scope | Effort | Depends on |
|---|---|---|---|
| **1 — Core (this session)** | `champion_vs_tier` kind; champion seeded from tier #1 at Open; jackpot (entry + per-elim, ×multiplier); asymmetric win/prize at close; status DTO exposes champion/jackpot/multiplier; admin-create validation; client entry card | ~1 day | existing GameEvents framework |
| **2 — Live rounds (done)** | ✅ Backend: `ChampionRound`/`ChampionRoundAnswer` + `ChampionMatchOrchestrator` (start → broadcast → answer window → resolve → next/close), **dual driver** (Hangfire schedule + hosted `ChampionRoundWatchdog` redundancy sweep), REST answer endpoint, SignalR round contracts, scheduler Start hook. ✅ **Champion duels** (`ChampionDuel`): champion-initiated 1v1 cull, capped per match, loser eliminated, dethrone ends the match. ✅ **Replay-on-join**: `GET /game-events/{id}/live` snapshot. ✅ Client: round + duel + snapshot DTOs, hub streams, `ChampionLiveScreen` seeds from the snapshot on join, **champion "call out a challenger" roster picker → duel, duelist answer view, spectator duel banner, duels-remaining counter**, `GET /game-events/{id}/participants` roster. Phase 2 complete. | ~3–4 days | Phase 1 + NotificationHub |
| **3 — No-loss prediction (done)** | ✅ `ChampionPrediction` entity + migration; `POST /game-events/{id}/predict` ("will the champion defend?", Open-window only) + `GET /prediction`; `ChampionPredictionService` splits a fixed coin pool among correct predictors at close (resolved from `EndMatchAsync`, idempotent), plus flat XP; no stake lost. Client: `ChampionPrediction` model, `getPrediction`/`submitPrediction`, and a `ChampionPredictionPanel` on the card (Yes/No pick, live tally bar, locked/result states). | ~1.5 days | Phase 1 |
| **4 — Premium spectator** | Entitlement-gated live spectator channel (read-only round feed, elimination cam, jackpot ticker) via SignalR; `PlayerEntitlement` check | ~2 days | Phase 2 |
| **5 — Sponsor jackpot multiplier** | Admin sets a sponsor + `JackpotMultiplier` per event; multiplier applied to the final jackpot (column shipped in Phase 1); sponsor attribution surfaced to spectators | ~1 day | Phase 1 |

## 3. Phase 1 (core) — as built

### Domain
- `GameEvent` gains `ChampionPlayerId` (`Guid?`) and `JackpotMultiplier` (`decimal`, default `1.0`), plus `SeedChampion()` / `SetJackpotMultiplier()` and a `FeedsJackpot` helper that covers both `champion_battle` and the new `champion_vs_tier` (replacing scattered string checks).
- New kind constant `champion_vs_tier`; admin-create accepts it.
- Migration `AddChampionVsTierEventFields` adds the two columns to `game_events`.

### Champion seeding (at Open)
When the scheduler transitions a `champion_vs_tier` event Scheduled→Open, `TierChampionSeeder` finds the tier's #1 in the active season (`PlayerSeasonProfile` where `Tier == ev.TierId`, ordered `RankPoints DESC, Wins DESC, MatchesPlayed ASC, PlayerId`), records `ChampionPlayerId`, and enrols them as a participant (entry fee waived — the champion is invited, not a paying challenger). Idempotent: re-running Open never double-seeds.

### Jackpot
`champion_vs_tier` feeds the jackpot exactly like `champion_battle`: entry fees + `+50` per elimination. At close the pool is scaled by `JackpotMultiplier` (default 1.0 → no change until a sponsor sets it in Phase 5).

### Win condition & prize (asymmetric)
At close, for `champion_vs_tier`:
- **Champion survived** (not eliminated) → champion is rank 1 and takes the (multiplied) jackpot: the tier defended its crown.
- **Champion was dethroned** (eliminated) → the last surviving challenger is rank 1 and takes the jackpot.

Everyone else is ranked survivors-first then by elimination recency (existing behaviour); top-20 still get the standard XP/coin bonuses.

### Client
`ApiService` gains real-contract `getUpcomingGameEvents()` / `getGameEventStatus()` / `enterGameEvent()` and a `ChampionEvent` model matching the backend `GameEventStatusDto` (now including `kind`, `championPlayerId`, `jackpotMultiplier`). A **Champion vs Tier hub card** shows the weekly event: jackpot pool, champion handle, alive count, and an Enter button (or a "You are the Champion" state).

## 4. Monetization mapping (spectacle → product)

| TV concept | Trivia Tycoon translation | Phase |
|---|---|---|
| High-spectacle 1-vs-100 tension | Live synchronized rounds, champion vs 99, elimination cam | 2 |
| Premium spectator mode | Entitlement-gated live spectator feed | 4 |
| Betting tokens | **No-loss prediction** — pick the winner, earn on a correct call, risk nothing | 3 |
| Sponsor-backed jackpot multiplier | Admin sponsor + `JackpotMultiplier` on the pool | 5 |
| Leaderboard position = event power | Tier #1 *is* the champion; climbing rank earns the spotlight | 1 |

## 5. Risks / decisions still open
1. **Champion no-show / absent tier #1** — if the seeded champion never joins the live match, Phase 2 must define a forfeit (challenger wins by default) vs auto-play. Phase 1 seeds regardless; the live layer decides.
2. **Prediction reward source** (Phase 3) — fixed reward pool vs a slice of the jackpot. Fixed pool keeps it non-zero-sum and clearly non-gambling.
3. **Spectator scale** (Phase 4) — a marquee event could draw many spectators; the SignalR fan-out and entitlement checks need a load pass.
4. **Sponsor multiplier ceiling** (Phase 5) — cap the multiplier so a sponsor can't mint an unbounded coin sink.
