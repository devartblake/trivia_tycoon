# Trivia Tycoon Update Checklist

**Last updated:** 2026-04-17  
**Purpose:** High-level project status snapshot for the latest frontend migration and verification work. This file replaces the older auth-only checklist, which is no longer an accurate picture of what remains.

---

## Current Status

### Recently completed

- Friends/social frontend migration is in place:
  - backend-backed friends list, requests, suggestions, and unfriend flow
  - `/users/search` and `DELETE /friends` now covered by the frontend auth allowlist
  - `/ws?playerId=<guid>` alignment added for presence compatibility
- Main menu currency display is improved:
  - backend wallet balances now sync into the menu coin/gem display
  - duplicate green energy strip below `CurrencyDisplay` was removed
- Question gameplay is backend-first:
  - retrieval prefers `GET /questions/set`
  - per-answer validation uses `POST /questions/check`
  - end-of-quiz reconciliation uses `POST /questions/check-batch`
- Question source observability is in place:
  - visible backend-vs-local-fallback banner on `QuestionScreen`
  - stronger `QuestionHubService` logging for backend vs fallback source usage
- Local question asset handling is improved:
  - `question_paths_index.json` is now used through an index-backed local question asset loader
  - local fallback questions and answers are randomized consistently
- Category/class/daily quiz launch paths are repaired:
  - category, class, and daily screens now launch curated question sets directly into gameplay
  - `/quiz/play` now respects launch payloads instead of always dropping users into generic mode selection
- Backend handoff documentation for the full question flow is now available:
  - [`question_flow_frontend_backend_handoff_2026-04-15.md`](question_flow_frontend_backend_handoff_2026-04-15.md)

### Still in progress or still needing verification

- Live backend verification for friends/presence flows across two authenticated users/devices
- Live verification that `/users/search` and `DELETE /friends` succeed with auth headers in target backend environments
- Live verification that question gameplay remains on backend data in normal environments and only falls back locally when expected
- Flutter-enabled formatter/analyzer/test pass
- Backend confirmation of the intended question contracts, especially:
  - `/questions/set`
  - `/quiz/categories`
  - `/quiz/classes/{classId}/stats`
  - `/questions/check`
  - `/questions/check-batch`

### Broader backlog still remaining

- Portable avatar/object-storage upload flow
- Crypto economy player surfaces
- ML enhancement signal consumption
- Runtime validation on device/simulator for the broader Synaptix surface

---

## Priority Checklist

## 1. Question flow alignment

- [x] Backend-first retrieval wired through repository/hub
- [x] Local question asset index loader added
- [x] Local question/answer randomization added
- [x] Category quiz launch fixed
- [x] Class quiz launch fixed
- [x] Daily quiz launch fixed
- [x] Backend/frontend question handoff markdown created
- [ ] Backend team confirms canonical question endpoint set
- [ ] Backend team confirms class stats response always includes `availableCategories`
- [ ] Backend team confirms answer validation response fields and envelope stability
- [ ] Runtime QA verifies fallback banner only appears during actual endpoint failures

## 2. Friends / presence alignment

- [x] Frontend migrated off primary mock friends flows
- [x] `/users/search` auth allowlist fix completed
- [x] `DELETE /friends` auth allowlist fix completed
- [x] WebSocket `playerId` query-string alignment completed
- [ ] Two-account/device runtime verification completed
- [ ] Backend team confirms final friends/search/unfriend contracts
- [ ] Decision made on `FriendDiscoveryService` cleanup/deprecation

## 3. Economy / menu validation

- [x] Main menu coin/gem display syncs from backend player wallet data
- [x] Duplicate green energy HUD removed
- [ ] Runtime QA confirms displayed balances match backend balances after login/resume/refresh
- [ ] Broader player wallet/history flows implemented

## 4. Verification / release hygiene

- [ ] Run `flutter analyze`
- [ ] Run targeted Flutter tests for question flow
- [ ] Run targeted Flutter tests for social/profile integration
- [ ] Run broader app smoke tests in a Flutter-enabled environment

---

## Recommended Next Steps

1. Use [`question_flow_frontend_backend_handoff_2026-04-15.md`](question_flow_frontend_backend_handoff_2026-04-15.md) with the backend team to lock the question contracts.
2. Run live verification for category/class/daily quiz flows and confirm the question source banner stays on backend in healthy environments.
3. Run live verification for friends/presence and close the remaining social runtime checklist items.
4. Finish a Flutter-enabled analyze/test pass so the current frontend state is validated beyond code inspection.

---

## Canonical Status References

- [`CHANGELOG.md`](../CHANGELOG.md)
- [`REMAINING_TASKS.md`](REMAINING_TASKS.md)
- [`question_flow_frontend_backend_handoff_2026-04-15.md`](question_flow_frontend_backend_handoff_2026-04-15.md)
- [`friends_social_presence_frontend_backend_verification_2026-04-15.md`](friends_social_presence_frontend_backend_verification_2026-04-15.md)
- [`question_backend_frontend_integration_audit_2026-04-09.md`](question_backend_frontend_integration_audit_2026-04-09.md)
