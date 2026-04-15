# Friends & Presence Backend Integration Handoff
## Frontend Reference

**Date:** 2026-04-15  
**Backend Branch:** `claude/review-handoff-plan-4DmaL`  
**Responds to:** [friends_backend_handoff_2026-04-14.md](/c:/Users/lmxbl/StudioProjects/trivia_tycoon/docs/friends_backend_handoff_2026-04-14.md:1)

---

## Purpose

This document converts the backend team's raw handoff into a clean frontend reference.

It answers:

- which friends/presence backend capabilities are live
- which fields are stubbed or intentionally limited
- how the frontend should call each endpoint
- what migration assumptions are now safe

---

## Status Summary

| Area | Status |
|------|--------|
| Friend list with profile data + online status | Live |
| Send friend request | Live |
| Incoming friend requests with sender profile | Live |
| Outgoing friend requests | Live |
| Accept friend request | Live |
| Decline friend request | Live |
| Friend suggestions | Live, stubbed |
| Unfriend | Live, legacy route unchanged |
| User search by handle | Live, unchanged |
| Presence WebSocket subscribe / bulk snapshot | Live |
| Presence WebSocket activity updates | Live |
| Presence WebSocket online/offline updates | Live |
| `avatarUrl` | Always `null` |
| `lastSeenUtc` | Always `null` |
| `BLOCKED_USER` / block system | Not implemented |
| `mutualFriendCount` in suggestions | Always `0` |

---

## Key Frontend Implications

### Safe to implement now

- replace mock/local friends list loading with backend calls
- replace local pending request inbox with backend calls
- replace local sent-request tracking with backend calls
- replace local request accept/decline flows with backend calls
- keep using the existing presence WebSocket adapter

### UI constraints to honor

- render placeholder/generated avatars because `avatarUrl` is always `null`
- do not rely on `lastSeenUtc`
- use `isOnline` as the only reliable friend-list online signal
- hide or conditionally suppress mutual friend count in suggestions
- do not build blocking-related flows yet

## Frontend Status Update

As of the latest frontend pass, the following are now implemented against the backend contract:

- backend friends list wiring in `FriendsScreen`
- backend incoming request wiring in `FriendsScreen`
- backend suggestions wiring in `FriendsScreen`
- backend send request wiring in add-by-username flow
- backend accept/decline wiring in `FriendsScreen`
- backend-backed recipient roster in `CreateDMDialog`
- `playerId` query parameter patch for the shared `/ws` connection path used by presence

Still pending on the frontend side:

- live runtime verification against the deployed backend
- final cleanup/deprecation decision for `FriendDiscoveryService`
- analyzer/format/test pass in a Flutter-enabled environment

---

## Auth

All `/users/me/friends/...` endpoints require:

```http
Authorization: Bearer <access_token>
```

Important backend behavior:

- player identity is inferred from the JWT
- do not send `playerId` on `/users/me/friends/...` routes
- invalid or missing token returns `401 UNAUTHORIZED`

Exception:

- the legacy `DELETE /friends` endpoint still requires explicit body fields, including `playerId`

---

## REST Endpoints

All endpoints below are under `/users/me/friends` unless noted otherwise.

## 1. Get Friend List

```http
GET /users/me/friends?page=1&pageSize=50
```

### Response

```json
{
  "page": 1,
  "pageSize": 50,
  "total": 3,
  "items": [
    {
      "friendPlayerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "displayName": "sarah_chen",
      "username": "sarah_chen",
      "avatarUrl": null,
      "isOnline": true,
      "lastSeenUtc": null,
      "sinceUtc": "2026-04-10T08:00:00Z"
    }
  ]
}
```

### Notes

- `isOnline` is true if the friend currently has an open `/ws` connection
- `avatarUrl` is always `null`
- `lastSeenUtc` is always `null`
- `displayName` and `username` are currently the same user handle

---

## 2. Send Friend Request

```http
POST /users/me/friends/request
Content-Type: application/json
```

```json
{
  "targetUserId": "3fa85f64-5717-4562-b3fc-2c963f66afa6"
}
```

### Response

```json
{
  "requestId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
  "fromPlayerId": "...",
  "toPlayerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
  "status": "Pending",
  "createdAtUtc": "2026-04-15T10:00:00Z",
  "respondedAtUtc": null
}
```

### Status values

- `Pending`
- `Accepted`
- `Declined`
- `Cancelled`

### Idempotency behavior

- already friends returns a synthetic `Accepted` response
- existing pending request in either direction returns the existing request

### Errors

| Scenario | HTTP | Code |
|----------|------|------|
| Self-request | 409 | `CONFLICT` |
| Validation issue | 422 | `VALIDATION_ERROR` |

---

## 3. Incoming Friend Requests

```http
GET /users/me/friends/requests?page=1&pageSize=50
```

Returns pending incoming requests only, newest first.

### Response

```json
{
  "page": 1,
  "pageSize": 50,
  "total": 2,
  "items": [
    {
      "requestId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
      "fromPlayerId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "senderDisplayName": "mike_johnson",
      "senderUsername": "mike_johnson",
      "senderAvatarUrl": null,
      "toPlayerId": "...",
      "status": "Pending",
      "createdAtUtc": "2026-04-15T09:30:00Z",
      "respondedAtUtc": null
    }
  ]
}
```

---

## 4. Sent Friend Requests

```http
GET /users/me/friends/requests/sent?page=1&pageSize=50
```

Returns outgoing requests of any status, ordered by pending first and then newest.

Response shape matches the incoming requests DTO shape.

---

## 5. Accept Friend Request

```http
POST /users/me/friends/requests/{requestId}/accept
```

No request body.

### Response

Returns updated `FriendRequestDto` with:

```json
{
  "status": "Accepted"
}
```

### Errors

| Scenario | HTTP | Code |
|----------|------|------|
| Request not found | 404 | `NOT_FOUND` |
| Acting user is not recipient | 409 | `CONFLICT` |
| Request not pending | 409 | `CONFLICT` |

---

## 6. Decline Friend Request

```http
POST /users/me/friends/requests/{requestId}/decline
```

No request body.

### Response

Returns updated `FriendRequestDto` with:

```json
{
  "status": "Declined"
}
```

### Errors

Same shape as the accept endpoint.

---

## 7. Remove Friend

Legacy route, unchanged:

```http
DELETE /friends
Content-Type: application/json
```

```json
{
  "playerId": "<current-user-id>",
  "friendPlayerId": "<friend-id>"
}
```

### Response

`204 No Content`

### Important note

This is the only social endpoint in this flow that still requires explicit `playerId` in the body.

---

## 8. Friend Suggestions

```http
GET /users/me/friends/suggestions
```

### Response

```json
[
  {
    "id": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "displayName": "emma_davis",
    "username": "emma_davis",
    "avatarUrl": null,
    "mutualFriendCount": 0,
    "reason": "New to Synaptix"
  }
]
```

### Current backend behavior

- returns up to 5 recently joined active users
- excludes users already friended by the caller
- `mutualFriendCount` is always `0`
- `reason` is always `"New to Synaptix"`

### Frontend recommendation

Hide mutual friend count unless it is greater than `0`.

---

## Presence WebSocket Protocol

The presence system uses the raw WebSocket endpoint, not `/ws/presence`.

### Connection URL

```text
ws://<host>/ws?playerId=<your-player-id-guid>
```

### Important requirement

`playerId` in the query string is required for presence behavior.

If omitted:

- the socket still opens
- presence events are not sent or received

JWT-based player identification during WebSocket upgrade is not implemented yet.

---

## On Connect

Immediately after connect:

```json
{
  "op": "hello",
  "ts": 1744751234567
}
```

If `playerId` is valid, the backend also sends:

```json
{
  "op": "presence.bulk",
  "ts": 1744751234568,
  "data": {
    "presences": [
      {
        "userId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "status": "online",
        "activity": "Playing Quiz",
        "lastSeen": "2026-04-15T10:00:00Z"
      }
    ]
  }
}
```

Important nuance:

- initial bulk snapshot includes online friends only
- if no friends are online, `presences` is an empty array

---

## Subscribe

```json
{
  "op": "presence.subscribe",
  "ts": 1744751234569,
  "data": {
    "userIds": [
      "3fa85f64-5717-4562-b3fc-2c963f66afa6",
      "7c9e6679-7425-40de-944b-e07fc1f90ae7"
    ]
  }
}
```

### Response

```json
{
  "op": "presence.bulk",
  "ts": 1744751234570,
  "data": {
    "presences": [
      {
        "userId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
        "status": "online",
        "activity": null,
        "lastSeen": "2026-04-15T10:00:00Z"
      },
      {
        "userId": "7c9e6679-7425-40de-944b-e07fc1f90ae7",
        "status": "offline",
        "activity": null,
        "lastSeen": "2026-04-15T10:00:00Z"
      }
    ]
  }
}
```

---

## Update My Presence

```json
{
  "op": "presence.update",
  "ts": 1744751234571,
  "data": {
    "status": "inGame",
    "activity": "Playing Quiz",
    "gameActivity": {
      "gameType": "quiz",
      "gameMode": "solo",
      "currentLevel": "Medium",
      "score": 1200,
      "gameState": "playing",
      "startTime": "2026-04-15T10:00:00Z",
      "metadata": {
        "category": "Science"
      }
    }
  }
}
```

### Accepted `status` values

- `online`
- `inGame`
- `offline`

### Notes

- `gameActivity` is optional
- omit it or pass `null` when not in a game

---

## Unsubscribe

```json
{
  "op": "presence.unsubscribe",
  "ts": 1744751234572,
  "data": {
    "userIds": [
      "3fa85f64-5717-4562-b3fc-2c963f66afa6"
    ]
  }
}
```

This is currently a backend no-op. It is safe for the frontend to keep sending it.

---

## Friend Presence Update

```json
{
  "op": "presence.update",
  "ts": 1744751234573,
  "data": {
    "userId": "3fa85f64-5717-4562-b3fc-2c963f66afa6",
    "status": "online",
    "activity": "In Match",
    "gameActivity": {
      "gameType": "match",
      "gameMode": "pvp",
      "gameState": "lobby",
      "startTime": "2026-04-15T10:00:00Z",
      "metadata": {
        "opponentName": "Sarah"
      }
    },
    "lastSeen": "2026-04-15T10:00:35Z"
  }
}
```

On disconnect:

- `status` becomes `"offline"`
- `activity` becomes `null`
- `gameActivity` becomes `null`

---

## Error Envelope

All REST errors use:

```json
{
  "error": {
    "code": "NOT_FOUND",
    "message": "Friend request not found."
  }
}
```

### Confirmed error codes

| Code | HTTP | Scenario |
|------|------|----------|
| `UNAUTHORIZED` | 401 | Missing or invalid JWT |
| `NOT_FOUND` | 404 | Request ID does not exist |
| `CONFLICT` | 409 | Self-request, wrong recipient, non-pending state |
| `VALIDATION_ERROR` | 422 | Empty GUIDs or malformed input |

### Not yet implemented as distinct codes

- `ALREADY_FRIENDS`
- `DUPLICATE_REQUEST`
- `SELF_FRIEND_REQUEST`
- `BLOCKED_USER`

For now, these collapse into `CONFLICT` with a human-readable message.

---

## Known Backend Limitations

## Avatar system

- not implemented
- all avatar URLs are `null`

Frontend guidance:

- generate avatar initials/placeholders from username

## Persistent last seen

- not implemented
- `lastSeenUtc` in friend list is always `null`

Frontend guidance:

- use `isOnline`
- treat `lastSeen` inside presence events as transient session data only

## Blocking

- not implemented

Frontend guidance:

- do not show blocking UI
- gate any block-related UX behind feature flags

## Mutual friend count

- not implemented beyond stub `0`

Frontend guidance:

- hide the field unless greater than `0`

## Third-party friend lists

- `/users/{userId}/friends` is not exposed
- only `/users/me/friends` is available

Frontend guidance:

- only support current-user friend graph from backend

## Cleaner unfriend route

- `/users/me/friends/{friendId}` `DELETE` is not implemented
- keep using legacy `DELETE /friends`

---

## Backend-Recommended Frontend Migration

Replace `friendDiscoveryServiceProvider` with:

1. friend list -> `GET /users/me/friends?page=1&pageSize=50`
2. pending inbox -> `GET /users/me/friends/requests?page=1&pageSize=50`
3. sent requests -> `GET /users/me/friends/requests/sent?page=1&pageSize=50`
4. send request -> `POST /users/me/friends/request`
5. accept -> `POST /users/me/friends/requests/{requestId}/accept`
6. decline -> `POST /users/me/friends/requests/{requestId}/decline`
7. unfriend -> legacy `DELETE /friends`
8. suggestions -> `GET /users/me/friends/suggestions`
9. presence -> `ws://<host>/ws?playerId=<guid>`

### Important note from backend

The existing `presence_websocket_adapter.dart` should require no protocol changes. The current server protocol matches it closely enough for migration.

---

## Bottom Line

The backend now provides enough API surface to replace the mock/local friends flow in the frontend.

The main frontend caveats are:

- continue using placeholder avatars
- do not depend on persistent last-seen
- hide mutual count in suggestions
- keep unfriend on the legacy route
- include `playerId` in the WebSocket URL
