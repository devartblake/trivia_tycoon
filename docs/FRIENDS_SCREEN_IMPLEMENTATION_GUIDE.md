# Friends Screen Implementation Guide
## Current Status and Remaining Backend Work

## Purpose

This document reflects the **current state of the Friends screen implementation in the repo** as of 2026-04-14.

It replaces the older migration-oriented wording that assumed several tasks were still pending locally. In reality, most of the UI and presence plumbing is already implemented. The main remaining work is backend alignment for authoritative friend data.

---

## Current Status

## Completed in the frontend

- `FriendsScreen` exists and is wired into app navigation.
- `RichPresenceService` is implemented and initialized at app startup.
- `PresenceWebSocketAdapter` is implemented.
- `PresenceStatusIndicator` and `DetailedPresenceCard` are integrated into the Friends experience.
- Friends list items render live presence text through `RichPresenceService`.
- Online friends are derived from actual tracked presence state.
- The screen subscribes to friend presence updates via WebSocket.
- Current user presence can be updated for quiz/match activity.
- Friend detail bottom sheet uses `DetailedPresenceCard`.
- Friend removal has partial backend wiring through `DELETE /friends`.
- Add-friend-by-username search is backend-backed.

## Not yet complete end-to-end

- The main Friends screen still loads friend list, pending requests, and suggestions from the local/mock `friendDiscoveryServiceProvider`.
- Authoritative backend friend list and request-management endpoints are not fully confirmed in the current alpha handoff.
- Runtime validation for the full friend/presence flow is still needed against a live backend/WebSocket environment.

---

## Implemented Files

### Friends UI

- [lib/screens/profile/friends_screen.dart](/c:/Users/lmxbl/StudioProjects/trivia_tycoon/lib/screens/profile/friends_screen.dart:1)

Current implementation includes:

- `RichPresenceService` integration
- online friends section
- real presence text rendering
- `PresenceStatusIndicator`
- `DetailedPresenceCard`
- quiz/match activity updates
- friend actions including remove

### Presence widgets

- [lib/ui_components/presence/presence_status_widget.dart](/c:/Users/lmxbl/StudioProjects/trivia_tycoon/lib/ui_components/presence/presence_status_widget.dart:1)

Current implementation includes:

- `PresenceStatusIndicator`
- `DetailedPresenceCard`

### Presence service

- [lib/core/services/presence/rich_presence_service.dart](/c:/Users/lmxbl/StudioProjects/trivia_tycoon/lib/core/services/presence/rich_presence_service.dart:1)

Current implementation includes:

- presence caching
- presence formatting
- `subscribeToUsers(...)`
- `unsubscribeFromUsers(...)`
- `setGameActivity(...)`
- stream watchers
- WebSocket adapter integration

### Presence WebSocket adapter

- [lib/core/services/presence/presence_websocket_adapter.dart](/c:/Users/lmxbl/StudioProjects/trivia_tycoon/lib/core/services/presence/presence_websocket_adapter.dart:1)

Current implementation includes:

- `hello`
- `presence.update`
- `presence.bulk`
- `presence.subscribe`
- `presence.unsubscribe`

### Startup initialization

- [lib/core/bootstrap/app_init.dart](/c:/Users/lmxbl/StudioProjects/trivia_tycoon/lib/core/bootstrap/app_init.dart:458)

Current implementation includes:

- `RichPresenceService().initialize(useWebSocket: true)`

---

## Backend Status Summary

## Confirmed backend-facing capabilities in current repo/handoffs

- `GET /users/search?handle=`
- `DELETE /friends`
- planned client/doc support for:
  - `GET /users/{id}/friends`
  - `POST /users/{id}/friends/request`
  - `POST /users/{id}/friends/accept`

## Important limitation

The current alpha handoff does **not** clearly confirm that the full friend-flow endpoints are deployed and ready for frontend use.

The current frontend handoff explicitly indicates:

- add-by-username search is backendized
- unfriend is backendized
- friend request create/accept remained local placeholder flow at handoff time

Because of that, the Friends screen cannot yet be marked fully backend-complete.

---

## What Still Uses Local Placeholder Data

The following Friends screen data still comes from local/mock state:

- friend list
- incoming requests
- suggestions

Current source:

- [lib/core/services/social/friend_discovery_service.dart](/c:/Users/lmxbl/StudioProjects/trivia_tycoon/lib/core/services/social/friend_discovery_service.dart:1)

Important note:

- this service still calls `_loadMockData()`
- it still manages local in-memory friendships
- it still provides local pending requests and suggestions

That means presence rendering is real-time, but the underlying friend roster is not yet guaranteed to be backend-authoritative.

---

## What Is Working Today

### Presence subscription

The Friends screen subscribes to presence updates for loaded friends.

Current pattern:

```dart
void _subscribeToFriends() {
  if (_friends.isEmpty) return;

  final friendIds = _friends.map((f) => f.id).toList();
  _presenceService.subscribeToUsers(friendIds);
}
```

### Presence-driven friend status

The screen renders status text from the presence service.

Current pattern:

```dart
final presence = _presenceService.getUserPresence(friend.id);
final presenceText = presence != null
    ? _presenceService.getFormattedPresence(friend.id)
    : 'Offline';
```

### Detailed presence view

Friend details are shown through `DetailedPresenceCard`.

Current pattern:

```dart
showModalBottomSheet(
  context: context,
  builder: (context) => DetailedPresenceCard(
    presence: presence,
    userName: friend.name,
    userAvatar: friend.avatar,
  ),
);
```

### Current user activity updates

The frontend already updates current user activity for quiz/match flows.

Current pattern:

```dart
_presenceService.setGameActivity(
  gameType: 'quiz',
  gameMode: 'solo',
  gameState: GameState.playing,
);
```

and

```dart
_presenceService.setGameActivity(
  gameType: 'match',
  gameMode: 'pvp',
  gameState: GameState.lobby,
);
```

---

## Remaining Work

## Backend confirmation or implementation needed

To complete the Friends screen properly, the backend team still needs to confirm or provide:

- `GET /users/{id}/friends`
- `POST /users/{id}/friends/request`
- `POST /users/{id}/friends/accept`
- pending friend requests list endpoint
- decline friend request endpoint
- optional suggestions endpoint if suggestions remain in scope
- final error-code contract for duplicate/self/already-friends cases
- confirmation that WebSocket presence payloads match the frontend implementation

Detailed backend handoff note:

- [docs/friends_backend_handoff_2026-04-14.md](/c:/Users/lmxbl/StudioProjects/trivia_tycoon/docs/friends_backend_handoff_2026-04-14.md:1)

## Frontend code changes still needed after backend confirms

- replace `friendDiscoveryServiceProvider` usage in `FriendsScreen`
- load friends from backend source of truth
- load pending requests from backend
- accept/decline requests against backend
- decide whether suggestions should come from backend or be hidden for alpha

---

## Verification Checklist

## Static/code-level status

- [x] Friends screen exists
- [x] Presence widgets exist
- [x] Presence WebSocket adapter exists
- [x] Rich presence service exists
- [x] App startup initializes presence service
- [x] Friends screen uses `PresenceStatusIndicator`
- [x] Friends screen uses `DetailedPresenceCard`
- [x] Friends screen subscribes to friend presence
- [x] Quiz/match activity updates current user presence
- [x] Friend model exists in the screen implementation

## Still requires runtime verification

- [ ] Friends screen loads real backend friend data
- [ ] Online friends count matches backend/user reality
- [ ] Friend status shows live activity from server events
- [ ] Logs show successful presence subscriptions in a live session
- [ ] Logs show incoming `presence.update` messages in a live session
- [ ] Add-friend, accept-request, and remove-friend flows all reconcile against backend truth
- [ ] No runtime contract mismatches with backend payloads

---

## Recommended Next Step

Do not replace the local friend discovery path blindly.

First:

1. get backend confirmation on the friend endpoints and payloads
2. confirm whether pending requests and suggestions are in current alpha scope
3. then swap `FriendsScreen` over to backend-backed friend data

This keeps the already-good presence implementation intact while avoiding a partial migration onto uncertain backend contracts.

---

## Bottom Line

The Friends screen is **mostly complete on the frontend from a UI and presence perspective**.

It is **not yet fully complete as a product feature** because the main roster/request data path still depends on local placeholder data and the full backend friend contract is not yet confirmed in the current alpha handoff.
