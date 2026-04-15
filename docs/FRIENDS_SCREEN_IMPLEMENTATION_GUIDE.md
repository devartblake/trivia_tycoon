# Friends Screen Implementation Guide
## Current Status and Remaining Backend Work

## Purpose

This document reflects the **current state of the Friends screen implementation in the repo** as of 2026-04-15.

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
- Friends list, incoming requests, and suggestions are backend-backed.
- `CreateDMDialog` now uses the backend friends roster instead of the local mock social service.
- The shared `/ws` connection path now appends `?playerId=<guid>` for presence compatibility.

## Not yet complete end-to-end

- Runtime validation for the full friend/presence flow is still needed against a live backend/WebSocket environment.
- `FriendDiscoveryService` still exists in the repo and needs a final deprecation/removal decision.
- A Flutter-enabled formatter/analyzer/test pass is still needed.

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

Backend contracts are now confirmed in:

- [friends_presence_backend_integration_handoff_2026-04-15.md](/c:/Users/lmxbl/StudioProjects/trivia_tycoon/docs/friends_presence_backend_integration_handoff_2026-04-15.md:1)

Confirmed and now wired on the frontend:

- `GET /users/me/friends`
- `GET /users/me/friends/requests`
- `GET /users/me/friends/requests/sent`
- `GET /users/me/friends/suggestions`
- `POST /users/me/friends/request`
- `POST /users/me/friends/requests/{requestId}/accept`
- `POST /users/me/friends/requests/{requestId}/decline`
- legacy `DELETE /friends`

---

## What Still Uses Local Placeholder Data

The main Friends, add-friend, and DM picker production paths are no longer using the local mock social service.

The remaining placeholder concern is repository cleanup:

- [lib/core/services/social/friend_discovery_service.dart](/c:/Users/lmxbl/StudioProjects/trivia_tycoon/lib/core/services/social/friend_discovery_service.dart:1) still exists
- a final decision is still needed on whether to deprecate it, keep it as dev-only fallback, or remove it from production paths entirely

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

- run live validation for friends, requests, suggestions, and presence
- verify that `presence.bulk` and `presence.update` behave correctly across two logged-in users
- confirm that the patched `?playerId=<guid>` WebSocket path works in all target runtimes
- decide whether `FriendDiscoveryService` should be deprecated or removed
- run formatter/analyzer/tests in a Flutter-enabled environment

---

## Verification Checklist

## Static/code-level status

- [x] Friends screen exists
- [x] Presence widgets exist
- [x] Presence WebSocket adapter exists
- [x] Rich presence service exists
- [x] App startup initializes presence service
- [x] Shared `/ws` connection now includes `playerId`
- [x] Friends screen uses `PresenceStatusIndicator`
- [x] Friends screen uses `DetailedPresenceCard`
- [x] Friends screen subscribes to friend presence
- [x] Quiz/match activity updates current user presence
- [x] Friend model exists in the screen implementation
- [x] Friends screen loads backend friend data
- [x] Add-friend flow uses backend request state
- [x] Message recipient picker uses backend friends roster

## Still requires runtime verification

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

The Friends screen and related social entry points are now **mostly complete and backend-wired at the code level**.

The remaining work is no longer contract uncertainty. It is now primarily:

- runtime verification
- cleanup/deprecation of old local mock social infrastructure
- final formatter/analyzer/test validation
