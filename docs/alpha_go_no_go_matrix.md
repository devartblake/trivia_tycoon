# Synaptix Alpha Go/No-Go Matrix

_Date: 2026-04-01_

This matrix maps critical Alpha capabilities to:
1) frontend status,
2) backend status,
3) required test evidence,
4) owner + ETA.

> Status key: **GO** = ready/validated, **HOLD** = partial/in progress, **NO-GO** = missing critical dependency.

| Capability | Frontend Status | Backend Status | Test Evidence Required | Owner | ETA | Decision |
|---|---|---|---|---|---|---|
| Auth + session continuity | Implemented in app flows; needs runtime reconfirmation in final pass | Alpha backend auth implementation still listed as remaining | Login/logout/refresh smoke, token-expiry retry log, auth integration test report | FE: Mobile/Web, BE: Auth | TBD | HOLD |
| Profile sync (`/users/me`) | Integrated and preferred in client sync path | Backend profile sync fields still listed as work in alpha gameplay backend | API contract test + manual profile update + persisted value verification | FE Core + BE API | TBD | HOLD |
| Onboarding 11-step + handoff | Implemented; still needs runtime validation | Backend-driven reward path optional; local-first works | Onboarding restore/handoff runbook + device logs + QA checklist signoff | FE Onboarding | TBD | HOLD |
| Mode/theme preferences | Implemented (`synaptixMode`, etc.) | Preferences endpoints documented complete | Request/response contract capture + integration test + dashboard verification | FE Core + BE Preferences | TBD | HOLD |
| Hub rendering across modes | Implemented; needs full 3-mode QA pass | Backend not blocking base rendering | Kids/Teen/Adult screenshots + navigation smoke + regression checklist | FE UX | TBD | HOLD |
| Economy (wallet + state authority) | Local wallet/presentation ready; live integration pending | Authoritative economy sync still open | Wallet sync test plan + reward reconciliation tests + purchase settlement logs | FE Economy + BE Economy | TBD | NO-GO |
| Store flows | UI/path present; backend authority pending | Store endpoints listed as remaining | Purchase E2E test + failure/retry behavior + receipt/audit verification | FE Store + BE Store | TBD | NO-GO |
| Leaderboards/Arena live state | Frontend surfaces present | Leaderboard APIs marked as remaining in alpha gameplay backend | Leaderboard API contract tests + live ranking smoke + load test summary | FE Arena + BE Gameplay | TBD | HOLD |
| Achievements/milestones | Frontend framing present | Achievements endpoints marked as remaining | CRUD/read path tests + progression event verification | FE Journey + BE Gameplay | TBD | HOLD |
| Analytics dimensions (`synaptix_mode`, etc.) | Instrumentation planned/partially wired; verification still needed | Backend ingestion dimensions documented complete | Event payload capture + ingestion verification + dashboard parity check | FE Analytics + BE Analytics | TBD | HOLD |
| Vocabulary consistency (app/operator) | Largely migrated; final pass still needed | Largely migrated; final pass still needed | Cross-stack copy audit + no old-brand string scan + reviewer signoff | Product + FE + BE | TBD | HOLD |
| Crypto economy | UX not started for production path | Crypto ledger/wallet flows still open | Crypto contract tests + security review + withdrawal/prize pool test plan | BE Crypto + FE Economy | TBD | NO-GO |
| Multiplayer/live systems | Frontend pathways exist; backend integration incomplete | Multiplayer/matchmaking/WebSocket coverage listed as open | Matchmaking latency tests + websocket reliability report + user journey QA | FE Multiplayer + BE Realtime | TBD | HOLD |
| Build/migration readiness (.NET) | N/A | Build/migration verification explicitly open | `dotnet build` output + EF migration apply log + CI green run | BE Platform | TBD | HOLD |

## Immediate Alpha gating recommendations

- **Must close before Alpha GO:** economy authority, store settlement, baseline auth/profile/leaderboard API readiness.
- **Can proceed in parallel:** full mode QA sweep, terminology parity verification, onboarding runtime signoff.
- **Likely post-Alpha:** crypto production flows, deep multiplayer feature depth, Packet E technical renames.
