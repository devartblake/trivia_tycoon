# Game Balance / Economy System — Implementation Guide

This document describes the server-driven economy system added to Trivia Tycoon,
covering architecture, data flow, UI components, and resilience behaviour.

---

## Overview

All economy values (energy costs, ticket availability, regen interval, pity state)
are authoritative on the **server**. The client fetches them on cold start, on app
resume, and after each match. A local Hive cache ensures the HUD renders
immediately on subsequent launches even before the first network round-trip
completes.

---

## Architecture

```
SynaptixApiClient          ← 7 economy HTTP methods
        │
EconomyNotifier          ← StateNotifier<EconomyState>
   ├── _hydrateCachedState()   cold-start Hive cache read
   ├── fetchState()            server fetch + exponential-back-off retry
   ├── startSession()          session-start discount merge
   ├── enterMode()             policy-enforced match start (409-aware)
   ├── claimTicket()           daily jackpot ticket claim
   ├── reportLoss()            pity loss signal (fire-and-forget)
   └── reportWin()             pity win signal (fire-and-forget)
        │
economy_providers.dart   ← Riverpod provider declarations
        │
UI widgets               ← EconomyHudWidget, ModeEntryCard,
                           JackpotTicketPanel, ReviveSheet
```

---

## Phase F1 — MVP Wiring

### DTOs (`lib/core/dto/economy_dto.dart`)

| Class | Endpoint | Key fields |
|---|---|---|
| `EconomyStateDto` | GET `/mobile/economy/state` | energy, maxEnergy, regenIntervalMinutes, modes, pityActive, dailyTicket* |
| `ModeCostDto` | nested in above | mode, costType, baseCost, adjustedCost, available |
| `SessionStartDto` | POST `/mobile/economy/session/start` | discountApplied, adjustedCosts |
| `DailyTicketClaimDto` | POST `/mobile/economy/daily-jackpot-ticket/claim` | success, ticketsRemaining, denyReason |
| `ReviveQuoteDto` | POST `/mobile/economy/revive/quote` | baseCost, finalCost, almostWinApplied, costCurrency |
| `PityResponseDto` | POST `/mobile/economy/pity/report-loss` and `report-win` | pityActive, lossCount |
| `MatchStartResultDto` | POST `/mobile/matches/start` | started, matchId, denyReason |

All values are server-driven. **Never hardcode economy constants on the client.**

### API Client (`lib/core/networking/tycoon_api_client.dart`)

Seven methods added to `SynaptixApiClient`:

```dart
getEconomyState({required String playerId})
startEconomySession({required String playerId})
claimDailyJackpotTicket({required String playerId})
getReviveQuote({required String playerId, required bool almostWin})
reportPityLoss({required String playerId})
reportPityWin({required String playerId})
startPolicyMatch({required String playerId, required String mode, ...})
```

`startPolicyMatch` catches `HttpException` with `statusCode == 409` and returns
`MatchStartResultDto(started: false, denyReason: ...)` instead of throwing, so
callers can display a friendly denial message without catching raw exceptions.

### State Management

`EconomyState` (immutable) fields:

| Field | Type | Description |
|---|---|---|
| `isLoading` | bool | True during active fetch |
| `error` | String? | Last error message if fetch failed |
| `firstSessionDiscount` | bool | Server signals first-session price reduction |
| `dailyTicketAvailable` | bool | True when a free jackpot ticket can be claimed |
| `dailyTicketsRemaining` | int | Count of remaining claimable tickets today |
| `pityActive` | bool | True when pity protection is boosted |
| `modes` | Map\<String, ModeCostDto\> | Cost/availability per game mode |
| `lastFetched` | DateTime? | Timestamp of last successful fetch |
| `isOffline` | bool (computed) | error ≠ null **and** lastFetched ≠ null |
| `isEmpty` | bool (computed) | modes.isEmpty **and** lastFetched == null |

### Riverpod Providers (`lib/game/providers/economy_providers.dart`)

```dart
economyProvider                          // StateNotifierProvider<EconomyNotifier, EconomyState>
modeCostProvider(String mode)            // ModeCostDto? for a specific mode
economyLoadedProvider                    // true when lastFetched != null
modeDenyReasonProvider(String mode)      // deny reason when mode.available == false
dailyTicketAvailableProvider             // bool
dailyTicketsRemainingProvider            // int
pityActiveProvider                       // bool
```

### Economy HUD (`lib/screens/menu/widgets/economy_hud_widget.dart`)

Compact horizontal bar displayed in the main menu header:

- **`_EnergyPill`** — colour-coded energy bar (green/amber/red) with server-driven
  regen interval text (e.g. "+1 every 30m")
- **`_TicketBadge`** — golden badge showing daily ticket count; hidden when
  `dailyTicketAvailable == false`
- **`_PityHintDot`** — 8 px amber circle with tooltip "Luck boost active"
- **`_OfflineDot`** — cloud-off icon (Phase F3) shown when `isOffline == true`

A 1-minute `Timer.periodic` keeps the regen countdown live without rebuilding
the whole widget tree.

### Mode Entry (`lib/screens/menu/widgets/mode_entry_card.dart`)

Wraps any mode button with:

- **`_CostBadge`** — top-right overlay showing ⚡ energy or 🎫 ticket cost
- **`_DiscountChip`** — shows `-N%` when `adjustedCost < baseCost`
- **`IgnorePointer` + `AnimatedOpacity(0.45)`** when policy blocks entry
- **`_confirmAndEnter()`** — calls `startSession` → `enterMode` → handles 409
  denial with a `SnackBar`

---

## Phase F2 — Safeguards UX

### Daily Ticket Panel (`lib/screens/menu/widgets/jackpot_ticket_panel.dart`)

`AnimatedSwitcher` toggles between a claim button and a "claimed" state. Calls
`EconomyNotifier.claimTicket()` and shows the result inline.

### Revive Sheet (`lib/screens/menu/widgets/revive_sheet.dart`)

Bottom sheet with:

- `ReviveSheet.show(context, {required bool almostWin})` — static helper
  returning `Future<bool>` (true = player accepted revive)
- Fetches `ReviveQuoteDto` in `initState`; shows a loading skeleton during fetch
  and an error state with retry on failure
- Strikes through `baseCost` when `hasDiscount == true` to show the discount

### Pity Signal Integration (`lib/game/logic/quiz_completion_handler.dart`)

`ProfileDataUpdater._reportPity()` is called as the final step of
`updateAfterQuiz()`. It resolves the current player ID, determines win/loss from
`QuizResults`, and fires `reportWin` or `reportLoss` on `EconomyNotifier`. Both
calls are fire-and-forget (`catchError` swallows all errors so the game flow is
never blocked).

---

## Phase F3 — Polish & Resilience

### Exponential Back-off Retry (`economy_notifier.dart`)

`fetchState()` retries up to `maxRetries` times (default: 3):

| Attempt | Delay before retry |
|---|---|
| 0 | none (first try) |
| 1 | 2 s |
| 2 | 4 s |
| 3 | 8 s |

Only **transient** errors trigger a retry:
- `SocketException` / `timeout` / `connection` in the error message
- HTTP 5xx status codes (detected via regex in `_isTransientError`)

HTTP 4xx errors are permanent and break the retry loop immediately.

On exhaustion: `state.error` is set (preserving `lastFetched` and `modes` from
the last successful fetch), making `isOffline` true.

### Cold-Start Cache Hydration

`EconomyNotifier._hydrateCachedState()` is called in the constructor. It reads
the last-serialised `EconomyStateDto` JSON from `GeneralKeyValueStorageService`
under the key `economy_last_state_json` and applies it before any network fetch.
This means the HUD has data to display immediately on launch.

The cache is overwritten on every successful `fetchState()` call.

### App-Resume Re-fetch (`lib/screens/menu/main_menu_screen.dart`)

```dart
AppLifecycleListener(
  onResume: () => _fetchEconomy(),
)
```

`_fetchEconomy()` calls `ref.read(economyProvider.notifier).fetchState(playerId)`
so data is refreshed after the app returns from background.

### Analytics Events

| Event | Fired when |
|---|---|
| `economy_state_loaded` | Successful `fetchState()` |
| `economy_state_load_failed` | All retries exhausted in `fetchState()` |
| `mode_entry_attempted` | `enterMode()` returns `started == true` |
| `mode_entry_blocked` | `enterMode()` returns `started == false` (409) |
| `daily_ticket_claimed` | `claimTicket()` success |
| `daily_ticket_denied` | `claimTicket()` denied by server |
| `pity_state_changed` | `reportLoss()` or `reportWin()` responds |

---

## Energy Sync

`EnergyNotifier.syncWithServer(int serverEnergy, int serverMax, Duration serverInterval)`
is called from `EconomyNotifier._applyDto()` whenever economy state is applied
(both from cache and from network). This keeps:

- The displayed energy count in sync with the server value
- The regen timer period updated to the server-configured interval

---

## Integration Tests (`test/game/controllers/economy_notifier_test.dart`)

Test groups:

| Group | What is tested |
|---|---|
| `ModeCostDto parsing` | effectiveCost, hasDiscount, defaults |
| `EconomyStateDto parsing` | full payload, defaults, round-trip toJson/fromJson |
| `ReviveQuoteDto parsing` | hasDiscount, defaults |
| `DailyTicketClaimDto parsing` | success / denied with reason |
| `PityResponseDto parsing` | pityActive, lossCount |
| `SessionStartDto parsing` | discountApplied, adjustedCosts |
| `EconomyState computed properties` | isOffline scenarios, isEmpty scenarios |
| `SynaptixApiClient.startPolicyMatch` | 200 → started=true, 409 → started=false, 500/400 rethrow |
| `EconomyNotifier.fetchState` | success, cache write, analytics, retry count, 4xx no-retry, isOffline |
| `EconomyNotifier.claimTicket` | state update, zero-remaining, denied analytics |
| `EconomyNotifier.reportLoss` | pityActive update, silent failure |
| `EconomyNotifier.startSession` | adjustedCosts merge, null on failure |
| `EconomyNotifier.enterMode` | mode_entry_attempted / mode_entry_blocked analytics |

---

## File Index

| File | Role |
|---|---|
| `lib/core/dto/economy_dto.dart` | All 7 economy DTOs |
| `lib/core/networking/tycoon_api_client.dart` | HTTP methods for economy endpoints |
| `lib/game/controllers/economy_notifier.dart` | State notifier + retry/cache logic |
| `lib/game/controllers/energy_notifier.dart` | `syncWithServer()` added |
| `lib/game/providers/economy_providers.dart` | Riverpod provider declarations |
| `lib/game/providers/riverpod_providers.dart` | Exports economy_providers.dart |
| `lib/screens/menu/widgets/economy_hud_widget.dart` | HUD: energy, tickets, pity, offline |
| `lib/screens/menu/widgets/mode_entry_card.dart` | Mode button with cost/discount/block |
| `lib/screens/menu/widgets/jackpot_ticket_panel.dart` | Daily ticket claim UI |
| `lib/screens/menu/widgets/revive_sheet.dart` | Revive bottom sheet |
| `lib/screens/menu/main_menu_screen.dart` | AppLifecycleListener + HUD placement |
| `lib/game/logic/quiz_completion_handler.dart` | Pity signal after quiz |
| `test/game/controllers/economy_notifier_test.dart` | Integration + unit tests |
