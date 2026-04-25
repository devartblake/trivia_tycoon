# Remaining Tasks — Trivia Tycoon / Synaptix

_Last updated: 2026-04-25_  
_Supersedes the 2026-04-18 version — reflects all commits through `f206ddc` (main merge)._

---

## ✅ Recently Completed (since 2026-04-18)

| Item | Commit |
|---|---|
| Store Stock System — Phase 1–3 widgets + providers | `572bb07` |
| Store Stock System — Phase 4–5 admin controls | `ea4a686` |
| 3D Avatar purchase path (presigned URL, install, equip) | `5cf2138` |
| Daily Items Screen + StoreSpecialScreen + GoRouter wiring | `78eeece` |
| Admin store GoRouter routes (5 routes) + dashboard tile | `ea4a686` |
| CountryStep RenderFlex overflow fix (keyboard layout) | `21c5c4e` |
| Skill tree nodes not rendering (JSON format mismatch fix) | `bf4a2c9` |
| Flutter Web CORS fix — fixed port 63033 | `2389347` |
| Android Studio run configs + `.gitignore` exception | `ba300aa` |
| `StoreStockState` missing import fix in `daily_items_screen.dart` | `4ea28b8` |
| Collection images renamed + quiz route fix | `fc024a2` |

---

## 🔴 P0 — Release Blockers (must close before Alpha GO)

### Backend endpoints not yet implemented

| Endpoint | Needed by | Notes |
|---|---|---|
| `GET /store/daily` | `DailyItemsScreen` | Global restock timer; Sidecar cron drives `nextResetAt` |
| `GET /store/special-offers` | `StoreSpecialScreen` | Replaces removed `/store/offers` |
| `GET /store/catalog/{playerId}` — `stock` sub-object | All store cards | `StoreStockState` + `StoreAvailabilityState` per item |
| `POST /store/avatars/{avatarId}/purchase` | `TryNowWidget` buy flow | Deducts coins, marks owned |
| `GET /v1/assets/avatars/{avatarId}` | `AvatarAssetService` | MinIO presigned URL for GLB archive |
| `GET /v1/assets/audio/{category}/{filename}` | `AudioAssetService` | MinIO presigned URL for music/SFX — frontend done, backend pending |
| `POST /auth/signup` | Onboarding auth | Missing endpoint (duplicate auth systems) |

> Full backend contracts in `docs/premium_store_backend_handoff_2026-04-20.md`,
> `docs/store_stock_flutter_ui_and_admin_controls.md`, and the plan at
> `.claude/plans/replicated-greeting-robin.md`.

### Economy / wallet authority

- [ ] Live wallet sync — frontend displays coin balance from local state; authoritative `GET /wallet/{playerId}` or `GET /users/me` balance field not confirmed connected end-to-end
- [ ] Purchase settlement audit path — receipt/event log per transaction not verified

### Auth

- [ ] Swagger broken — duplicate `GET /users/me` route (`IMPLEMENTATION_CHECKLIST.md` §1) — 5-min backend fix
- [ ] Three duplicate auth systems on backend — quick-fix or 4-hour refactor still outstanding

---

## 🟠 P1 — High Priority (needed for stable Alpha)

### Flutter frontend

| Task | File(s) | Notes |
|---|---|---|
| Wire `AvatarStoreRemoteSource` | `lib/game/providers/avatar_package_providers.dart`, `lib/core/services/store/avatar_store_remote_source.dart` (new) | `serverAvatarPackagesProvider` currently returns `[]`; needs `GET /store/catalog?category=avatar` |
| Web platform: 19 files with `dart:io` imports | Various | Screens will throw on Flutter Web; audit and guard with `kIsWeb` |
| Sprint 2 networking layer | `http_client.dart`, `ws_client.dart`, `ws_reliability.dart`, `tycoon_api_client_enhanced.dart` | `MASTER_ROADMAP.md` Sprint 2 — add `web_socket_channel`/`uuid` deps, 3 Riverpod providers, test HTTP + WebSocket |
| SFX asset files | `assets/audio/sfx/` | Bundled SFX directory missing expected files |
| Sound cues | UI polish | Sound cues not yet wired (noted in `synaptix_next_steps.md`) |

### QA / verification

- [ ] Friends/presence live verification across two authenticated accounts
- [ ] Admin backend live smoke run — last run returned 403 (`admin_backend_smoke_checks.md`)
- [ ] Admin backend contract finalization — refresh endpoint (Option A vs B), pagination envelope key confirmation
- [ ] `flutter analyze` clean pass
- [ ] `flutter test` — currently ~4.1% coverage; must reach at least basic smoke level before Alpha

---

## 🟡 P2 — Alpha+ / Near-term

| Task | Notes |
|---|---|
| Portable avatar upload | Backend upload flow + stable MinIO object URL in profile |
| Crypto economy surfaces | UX not started; backend ledger/wallet flows open; post-Alpha per Go/No-Go matrix |
| ML signal consumption | Recommendation signals documented but not consumed in frontend |
| Biometric authentication | `P2_P3_IMPLEMENTATION_ROADMAP.md` P3 — `local_auth` package, ~1 hour |
| Analytics / crash reporting | Firebase or Sentry setup, ~1 hour |
| Unit test coverage to 40% | ~4.1% today |

---

## 🟢 P3 — Post-Alpha Enhancements

- [ ] Multiplayer / matchmaking WebSocket integration
- [ ] Leaderboard live ranking API integration
- [ ] Achievements/milestones CRUD + progression events
- [ ] Crypto production flows + security review
- [ ] Deep mode QA sweep (Kids / Teen / Adult all 3 modes)
- [ ] Vocabulary consistency final cross-stack audit

---

## 🧪 QA Signoff Checklist (before Alpha GO)

- [ ] App launch → auth → onboarding → hub renders correctly
- [ ] Arena / Labs / Pathways / Journey / Circles / Command navigation all smoke
- [ ] Mode selection persists across sessions
- [ ] Wallet balance visible and correct after purchase
- [ ] Daily items screen shows countdown + correct items
- [ ] Admin login → inventory → stock policies → flash sales all accessible
- [ ] No "Trivia Tycoon" strings visible in Synaptix-branded flows
- [ ] Flutter Web on port 63033 — preflight returns `Access-Control-Allow-Origin`
- [ ] Synaptix runtime validation on physical device (blocked until device available)

---

## 📋 Backend Handoff Docs

| Document | Coverage |
|---|---|
| `premium_store_backend_handoff_2026-04-20.md` | Premium store, rewards, claim endpoints |
| `store_stock_flutter_ui_and_admin_controls.md` | Player stock state, admin controls, all admin store endpoints |
| `avatar_purchase_backend_handoff_2026-04-21.md` | 3D avatar catalog, purchase, MinIO presigned URL |
| `admin_backend_contract_checklist.md` | All admin endpoints — auth, users, questions, events, notifications |
| `messaging_backend_handoff_2026-04-20.md` | Messaging endpoints |
| `notifications_backend_handoff_2026-04-20.md` | Notifications endpoints |
| `friends_presence_backend_integration_handoff_2026-04-15.md` | Friends + presence |
