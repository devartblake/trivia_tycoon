# Synaptix Alpha Go/No-Go Matrix

_Date: 2026-04-01 — Status updated: 2026-04-25_

This matrix maps critical Alpha capabilities to:
1) frontend status,
2) backend status,
3) required test evidence,
4) owner + ETA.

> Status key: **GO** = ready/validated, **HOLD** = partial/in progress, **NO-GO** = missing critical dependency.

| Capability | Frontend Status | Backend Status | Test Evidence Required | Owner | ETA | Decision |
|---|---|---|---|---|---|---|
| Auth + session continuity | ✅ Onboarding + auth flows complete; `POST /auth/signup` missing on backend | Backend: Swagger broken (duplicate route), signup endpoint missing | Login/logout/refresh smoke, token-expiry retry log | FE: Mobile/Web, BE: Auth | — | HOLD |
| Profile sync (`/users/me`) | ✅ Integrated and preferred in client sync path | Backend profile sync fields confirmed; end-to-end not runtime-verified | API contract test + manual profile update + persisted value verification | FE Core + BE API | — | HOLD |
| Onboarding 11-step + handoff | ✅ Complete (`0a60048`); needs runtime validation on device | Backend-driven reward path optional; local-first works | Onboarding restore/handoff runbook + device logs | FE Onboarding | — | HOLD |
| Mode/theme preferences | ✅ Implemented (`synaptixMode`, etc.) | ✅ Preferences endpoints documented complete | Request/response contract capture + integration test | FE Core + BE Preferences | — | HOLD |
| Hub rendering across modes | ✅ Implemented; needs full 3-mode QA pass | Backend not blocking base rendering | Kids/Teen/Adult screenshots + navigation smoke | FE UX | — | HOLD |
| Economy (wallet + state authority) | Local wallet display ready; live sync not confirmed E2E | Authoritative wallet sync endpoint not confirmed connected | Wallet sync test + purchase settlement logs | FE Economy + BE Economy | — | NO-GO |
| Store flows | ✅ Store Hub, Daily Items, Special Offers, Premium, Admin Store screens complete; backend endpoints pending | `GET /store/daily`, `GET /store/special-offers`, player stock sub-object in `/store/catalog` not yet implemented | Purchase E2E test + receipt/audit verification | FE Store + BE Store | — | HOLD |
| Leaderboards/Arena live state | Frontend surfaces present | Leaderboard APIs marked as remaining | Leaderboard API contract tests + live ranking smoke | FE Arena + BE Gameplay | — | HOLD |
| Achievements/milestones | Frontend framing present | Achievements endpoints marked as remaining | CRUD/read path tests + progression event verification | FE Journey + BE Gameplay | — | HOLD |
| Analytics dimensions (`synaptix_mode`, etc.) | ✅ Instrumentation wired (`6485ad9`) | ✅ Backend ingestion dimensions documented complete | Event payload capture + ingestion verification | FE Analytics + BE Analytics | — | HOLD |
| Vocabulary consistency (app/operator) | Largely migrated; final pass still needed | Largely migrated; final pass still needed | Cross-stack copy audit + no old-brand string scan | Product + FE + BE | — | HOLD |
| Crypto economy | UX not started | Crypto ledger/wallet flows open | Crypto contract tests + security review | BE Crypto + FE Economy | — | NO-GO |
| Multiplayer/live systems | Frontend pathways exist; Sprint 2 WebSocket layer not yet built | Multiplayer/matchmaking/WebSocket coverage open | Matchmaking latency tests + WebSocket reliability report | FE Multiplayer + BE Realtime | — | HOLD |
| Build/migration readiness (.NET) | N/A | Build/migration verification explicitly open | `dotnet build` output + EF migration apply log + CI green | BE Platform | — | HOLD |

## Immediate Alpha gating recommendations

- **Must close before Alpha GO:** economy wallet authority (live sync), store backend endpoints (`/store/daily`, `/store/special-offers`, player stock sub-object), auth signup + Swagger fix.
- **Can proceed in parallel:** full mode QA sweep (Kids/Teen/Adult), terminology parity verification, onboarding runtime signoff on device, admin backend smoke run.
- **Likely post-Alpha:** crypto production flows, deep multiplayer/WebSocket depth, leaderboard live integration.

## Change log

| Date | Change |
|---|---|
| 2026-04-25 | Updated all rows to reflect commits through `f206ddc`; store UI complete, backend endpoints still pending |
| 2026-04-01 | Initial matrix created |
