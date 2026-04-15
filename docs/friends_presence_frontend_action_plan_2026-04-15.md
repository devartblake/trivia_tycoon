# Friends & Presence Frontend Action Plan
## Comprehensive Migration Plan

**Date:** 2026-04-15  
**Based on:** [friends_presence_backend_integration_handoff_2026-04-15.md](/c:/Users/lmxbl/StudioProjects/trivia_tycoon/docs/friends_presence_backend_integration_handoff_2026-04-15.md:1)

---

## Status Update

### Completed so far

- Phase 1 is complete:
  - typed social DTOs added
  - backend social service expanded for live friends endpoints
- Phase 2 is complete:
  - `lib/game/providers/friends_providers.dart` added
- Phase 3 is complete:
  - `FriendsScreen` reads migrated to backend friends/request/suggestion sources
- Phase 4 is substantially complete:
  - add-friend-by-username flow migrated to backend request state and mutation
  - accept/decline migrated in `FriendsScreen`
  - unfriend preserved on legacy `DELETE /friends`
- Phase 5 is partially complete:
  - avatar fallback handling added in migrated social surfaces
  - backend-stub `mutualFriendCount` is no longer surfaced in the DM picker
- Phase 6 is complete at the code level:
  - `AppInit.initializeWebSocket()` now appends `?playerId=<guid>`
  - `wsClientProvider` now also appends `?playerId=<guid>` when a stored user id exists
  - existing `presence_websocket_adapter.dart` required no protocol changes
- Phase 7 is partially complete:
  - production-path `FriendDiscoveryService` usage has been removed from:
    - `FriendsScreen`
    - `AddFriendByUsernameScreen`
    - `CreateDMDialog`

### Remaining

- runtime verification of friends + presence against a live backend
- final cleanup/deprecation decision for `FriendDiscoveryService`
- audit any non-screen social/message utilities for assumptions about local friend state
- formatter/analyzer/test pass in a Flutter-enabled environment
- docs/backlog closeout after runtime validation

---

## Goal

Complete the Friends screen migration from local/mock social state to backend-authoritative friends and request flows, while preserving the already-implemented presence UI and WebSocket behavior.

---

## Success Criteria

- Friends screen uses backend friend list instead of `friendDiscoveryServiceProvider`
- Pending requests come from backend
- Sent requests come from backend
- Add friend, accept, decline, and unfriend all reconcile against backend truth
- Suggestions come from backend stub endpoint
- Presence continues to work without regression
- UI hides or gracefully handles all backend stub fields

---

## Implementation Strategy

Do this in phases so the migration stays safe:

1. add typed DTOs and a dedicated backend social service layer
2. expose Riverpod providers for backend-backed friends data
3. migrate `FriendsScreen` read paths
4. migrate mutation flows
5. harden UI for backend field limitations
6. verify WebSocket identity and runtime behavior
7. remove or isolate remaining mock-only usage

---

## Phase 1: Data Contracts and Service Layer

### Task 1. Add typed social DTO models

Create:

- `lib/core/models/social/friend_list_item_dto.dart`
- `lib/core/models/social/friend_request_dto.dart`
- `lib/core/models/social/friend_suggestion_dto.dart`
- `lib/core/models/social/paginated_social_response.dart`

Model requirements:

- `FriendListItemDto`
  - `friendPlayerId`
  - `displayName`
  - `username`
  - `avatarUrl`
  - `isOnline`
  - `lastSeenUtc`
  - `sinceUtc`
- `FriendRequestDto`
  - `requestId`
  - `fromPlayerId`
  - `toPlayerId`
  - `status`
  - `createdAtUtc`
  - `respondedAtUtc`
  - optional sender fields for inbox/sent surfaces
- `FriendSuggestionDto`
  - `id`
  - `displayName`
  - `username`
  - `avatarUrl`
  - `mutualFriendCount`
  - `reason`

Acceptance:

- all DTOs support JSON parsing
- all nullable backend fields are handled safely

### Task 2. Expand backend social service

Update:

- `lib/core/services/social/backend_profile_social_service.dart`

Add methods for:

- `getFriends({int page = 1, int pageSize = 50})`
- `getIncomingFriendRequests({int page = 1, int pageSize = 50})`
- `getSentFriendRequests({int page = 1, int pageSize = 50})`
- `sendFriendRequest(String targetUserId)`
- `acceptFriendRequest(String requestId)`
- `declineFriendRequest(String requestId)`
- `getFriendSuggestions()`

Keep:

- `removeFriend(...)`
- `searchUsers(...)`

Service behavior requirements:

- parse backend error envelope
- surface backend `code` and `message`
- normalize list/pagination payloads

Acceptance:

- all live endpoints represented in one frontend social API service

---

## Phase 2: Riverpod Provider Layer

### Task 3. Add dedicated friends providers

Create:

- `lib/game/providers/friends_providers.dart`

Add providers for:

- backend social service provider reuse
- friends list provider
- incoming requests provider
- sent requests provider
- suggestions provider
- async mutation notifiers or controller providers for:
  - send request
  - accept request
  - decline request
  - unfriend

Recommended provider shape:

- `FutureProvider` or `AsyncNotifier` for fetches
- `Notifier` or service wrapper for mutations and invalidation

Acceptance:

- `FriendsScreen` can read all backend social data through providers only
- provider invalidation is defined after each mutation

---

## Phase 3: Friends Screen Read Migration

### Task 4. Replace local friend loading

Update:

- `lib/screens/profile/friends_screen.dart`

Replace:

- `_loadFriends()` local friend discovery path
- `_loadRequests()` local friend discovery path
- `_loadSuggestions()` local friend discovery path

Use:

- backend providers/service methods

Frontend mapping rules:

- `friendPlayerId` -> local `Friend.id`
- `displayName` or `username` -> `Friend.name`
- `username` -> `Friend.username`
- `avatarUrl` nullable -> generated fallback avatar in UI

Acceptance:

- Friends screen no longer depends on `friendDiscoveryServiceProvider` for main data surfaces

### Task 5. Add sent requests state where useful

Update:

- `lib/screens/profile/friends_screen.dart`
- `lib/screens/profile/enhanced/add_friends_screen.dart`

Use backend sent-request data to:

- prevent duplicate request UX
- show accurate pending/requested state
- reconcile idempotent request responses

Acceptance:

- duplicate request handling is server-truth-based instead of local heuristic-only

---

## Phase 4: Mutation Migration

### Task 6. Send friend request through backend

Update:

- `lib/screens/profile/enhanced/add_friends_screen.dart`
- any dialog or add-friend flow using local discovery service

Required UX behavior:

- send `targetUserId`
- on success, refresh sent requests and relevant friend/suggestion surfaces
- if backend returns existing or accepted synthetic response, show correct success state

Acceptance:

- friend requests are backend-authored

### Task 7. Accept and decline through backend

Update:

- `lib/screens/profile/friends_screen.dart`
- notification or friend-request UI surfaces if they trigger local acceptance today

Required behavior:

- accept -> `POST /users/me/friends/requests/{requestId}/accept`
- decline -> `POST /users/me/friends/requests/{requestId}/decline`
- invalidate:
  - incoming requests
  - friends list
  - suggestions if relevant

Acceptance:

- request inbox reconciles with backend after action

### Task 8. Preserve unfriend on legacy route

Update if needed:

- `lib/core/services/social/backend_profile_social_service.dart`
- `lib/screens/profile/friends_screen.dart`

Important detail:

- keep `DELETE /friends`
- include both:
  - `playerId`
  - `friendPlayerId`

Acceptance:

- remove friend flow continues to work against backend

---

## Phase 5: UI Hardening for Backend Limitations

### Task 9. Avatar fallback strategy

Update:

- `lib/screens/profile/friends_screen.dart`
- `lib/screens/profile/enhanced/add_friends_screen.dart`
- any shared avatar widget used in social surfaces

Rules:

- if `avatarUrl == null`, render generated initials/avatar
- do not show broken network images

Acceptance:

- all friend/request/suggestion items render cleanly with null avatar URLs

### Task 10. Hide unsupported last-seen behavior

Update:

- presence detail UI
- friend list secondary text logic if needed

Rules:

- do not render persistent last-seen from friend list
- use `isOnline` only
- if transient WebSocket `lastSeen` exists, treat it as optional and best-effort only

Acceptance:

- no misleading stale timestamp UI

### Task 11. Hide stub mutual friend count

Update:

- suggestions UI in `friends_screen.dart` or related widgets

Rules:

- show mutual count only when `mutualFriendCount > 0`
- otherwise omit it entirely

Acceptance:

- UI does not display meaningless `0 mutual friends`

### Task 12. Remove or gate block-related UX

Search and update any social UI that assumes:

- block
- unblock
- blocked-user errors

Acceptance:

- no visible block UX unless explicitly feature-flagged

---

## Phase 6: Presence Runtime Alignment

### Task 13. Verify WebSocket URL includes `playerId`

Inspect and update:

- `lib/core/bootstrap/app_init.dart`
- `lib/core/networking/ws_client.dart`
- any config or URL builder involved in `/ws` connection

Requirement:

- connection must be `ws://<host>/ws?playerId=<guid>`

Important:

- presence will silently not function correctly if `playerId` is omitted

Acceptance:

- runtime logs show presence events after connect

### Task 14. Confirm no adapter protocol changes needed

Verify:

- `lib/core/services/presence/presence_websocket_adapter.dart`

Check:

- `hello`
- `presence.bulk`
- `presence.update`
- `presence.subscribe`
- `presence.unsubscribe`

Acceptance:

- no protocol patch required beyond any URL/playerId alignment

---

## Phase 7: Cleanup and Mock Isolation

### Task 15. Reduce friendDiscoveryServiceProvider usage

Search and assess:

- `lib/core/services/social/friend_discovery_service.dart`
- all imports/usages of `friendDiscoveryServiceProvider`

Goal:

- remove it from production Friends screen path
- keep only for any local-only feature not yet backendized

Acceptance:

- Friends screen no longer depends on mock friend roster logic

### Task 16. Decide whether to deprecate or retain local service

Document one of:

- retain for dev/demo fallback only
- mark deprecated
- remove from production path entirely

Suggested doc update targets:

- `docs/FRIENDS_SCREEN_IMPLEMENTATION_GUIDE.md`
- `docs/REMAINING_TASKS.md`
- `CHANGELOG.md`

---

## Remaining Work Checklist

- [ ] Run live validation for:
  - `/users/me/friends`
  - `/users/me/friends/requests`
  - `/users/me/friends/requests/sent`
  - `/users/me/friends/suggestions`
- [ ] Validate end-to-end friend request flow across two accounts/devices
- [ ] Validate presence updates after login with the patched `?playerId=` WebSocket URL
- [ ] Confirm offline/online transitions and `presence.bulk` behavior at runtime
- [ ] Decide whether `FriendDiscoveryService` should be deprecated, dev-only, or removed
- [ ] Audit message/social bridge utilities for any remaining local-friend assumptions
- [ ] Run formatter/analyzer/tests in a Flutter-enabled environment
- [ ] Update remaining docs/changelog after runtime verification

---

## Testing Plan

## API / state verification

1. Login with valid JWT and load Friends screen.
2. Verify `GET /users/me/friends` populates list.
3. Verify `GET /users/me/friends/requests` populates inbox.
4. Verify `GET /users/me/friends/requests/sent` populates sent state.
5. Verify `GET /users/me/friends/suggestions` populates suggestions.

## Mutation verification

1. Send friend request to another user.
2. Verify sent requests updates immediately.
3. Accept request from second account/device.
4. Verify both friend lists update after refresh/invalidation.
5. Decline request and verify inbox updates.
6. Unfriend and verify removal from list.

## Presence verification

1. Connect two users with valid WebSocket `playerId` query strings.
2. Verify initial `presence.bulk` snapshot is received.
3. Start quiz on one device and verify friend sees `presence.update`.
4. Start match/lobby flow and verify activity text updates.
5. Disconnect one client and verify offline update.

## UI edge-case verification

1. All avatars null -> placeholders render correctly.
2. Suggestions with `mutualFriendCount == 0` -> mutual count hidden.
3. `lastSeenUtc == null` -> no broken last-seen text.
4. Conflict errors -> user sees clear fallback messaging from backend `message`.

---

## Suggested Execution Order

### Fastest low-risk path

1. DTO models
2. backend social service methods
3. friends providers
4. Friends screen read migration
5. send/accept/decline migration
6. UI hardening for avatar/last-seen/mutuals
7. WebSocket URL `playerId` verification
8. cleanup of mock usage
9. docs/changelog update

---

## Final Deliverables

When this migration is complete, we should have:

- backend-authoritative friends roster
- backend-authoritative request inbox and sent state
- backend-authoritative social mutations
- preserved real-time presence
- no user-visible dependency on mock friend data
- docs updated to reflect true status
