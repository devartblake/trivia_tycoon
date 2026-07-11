# Feature Access Policy — ban-based, not operator-locked

**Date:** 2026-07-10
**Change:** The operator "feature lock" (global release flags that disabled whole
features for everyone) has been replaced with per-player moderation gating.
Features are now available to all users by default and are only withheld from
**banned/suspended** accounts. Crypto (and real-money purchases) stay gated.

## Before

Each feature group carried an endpoint filter that consulted the operator
`FeatureFlagService` (`social_enabled`, `matchmaking_enabled`,
`notifications_enabled`, `skill_tree_enabled`, `experiments_enabled`,
`tom_personalization_enabled`, `ai_sidecar_enabled`, `game_events_enabled`, …).
If an operator turned a flag off in the admin dashboard, **every** user got
`403 FeatureDisabled`. `/app/config` also defaulted many features **off**, so
the client hid them.

## After

- A single shared filter, `PlayerAccessFilters.RequireNotBanned()`
  (`Synaptix.Backend.Api/Security/PlayerAccessFilters.cs`), gates each feature
  group on the caller's **effective moderation status** via `ModerationService`:
  - `Banned` or `Restricted` → `403 AccountRestricted`
  - `Suspected`, `Normal`, and anonymous/public reads → allowed
  - Policy lives in the testable `PlayerAccessFilters.IsFeatureBlocked(status)`.
- Applied to: friends, party, messages, matchmaking, notifications,
  personalization, skills, experiments, ml, and game-events. The
  `game_events_enabled` check was removed from `EnterGameEvent`.
- `/app/config` now defaults these features **on**: realtime multiplayer,
  matchmaking, tournaments, skill tree, personalization, notifications,
  experiments, AI sidecar (plus the already-on core/wallet/leaderboard/store/
  missions/social).

## Deliberately still gated

- **Crypto** — `crypto_enabled` (default off) + `Crypto:Enabled` config +
  `CryptoSettlementPolicy` admin authorization. Untouched: crypto stays off
  until the feature is finished or for admin users.
- **Real-money store purchases** — `store_purchases_enabled` kept default off
  (payments carry the same caution as crypto for a product with minor users).
  Resolved 2026-07: **stays off** until the real-money flow is verified
  end-to-end with live Apple/Google/Stripe credentials — same posture as crypto.
  Note this flag gates **only** the external-payment paths
  (`EnsurePaymentsEnabledAsync` → IAP receipt validation + Stripe). Coin-based
  in-game store purchases go through a separate `EnsureStoreEnabledAsync` gate
  plus the COPPA/parental eligibility check, and remain available. The client
  models no store-purchase flag; a real-money attempt simply returns
  `403 FeatureDisabled` server-side.
- **Dev tester** — `dev_tester_enabled` stays off in production.
- **Parental-consent / guardian controls** — a *separate*, compliance-critical
  system, unchanged by this work. The ban gate is additive to it.

## Notes

- `FeatureFlagService` is retained: it still backs crypto and the operational
  background jobs (e.g. the game-event scheduler's enable check), which control
  whether work runs — not whether users may access a feature.
- Operators can still ban/suspend individuals through the moderation tools; that
  is now the only lever that removes a feature from a user.
