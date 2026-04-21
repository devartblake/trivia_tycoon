# Direct Messaging Backend API Handoff

> **Audience:** Frontend + backend teams  
> **Date:** 2026-04-20  
> **Scope:** Direct-message core only

---

## Status

Direct messaging v1 is now implemented as a REST-owned DM surface with lightweight realtime refresh signaling.

Implemented routes:

- `GET /messages/conversations`
- `POST /messages/conversations/direct`
- `GET /messages/conversations/{conversationId}/messages`
- `POST /messages/conversations/{conversationId}/messages`
- `POST /messages/conversations/{conversationId}/read`
- `GET /messages/unread-count`

Validated on **April 20, 2026** with:

- `dotnet test Tycoon.Backend.Api.Tests\Tycoon.Backend.Api.Tests.csproj --no-build --no-restore --filter "PlayerNotificationsEndpointsTests|MessagesEndpointsTests"`
- Result: `Passed (8/8)`

This is direct conversation support only. Group chat, attachments, reactions, and typing-state backend parity remain out of scope.

---

## Contract Summary

The frontend should treat direct messages as a backend-owned domain for:

- conversation list
- direct conversation creation
- message history
- send message
- mark conversation read
- unread count

### Auth behavior

- bearer auth required for every route
- conversation membership is enforced for history, send, and read operations
- `POST /messages/conversations/direct` is idempotent for the same two participants

### Pagination behavior

`GET /messages/conversations` supports optional query parameters:

- `page`
- `pageSize`

If omitted, the backend defaults to:

- `page = 1`
- `pageSize = 50`

`GET /messages/conversations/{conversationId}/messages` currently returns the full ordered message list for the conversation in v1 and is not paginated yet.

---

## Conversation DTO

Conversation summaries use this canonical shape:

```json
{
  "id": "0a90f4ae-75e7-4f4e-8d77-b9d5ed4dd488",
  "type": "direct",
  "participantIds": [
    "c90af807-b31a-465f-8d04-5e7915b73f18",
    "6f3eb420-4516-4f77-bd79-e9503bfa73cc"
  ],
  "displayTitle": "Sarah Chen",
  "avatarUrl": "https://example.test/avatar.png",
  "lastMessagePreview": "See you soon!",
  "lastMessageTimestamp": "2026-04-20T13:00:00Z",
  "unreadCount": 2,
  "createdAtUtc": "2026-04-20T10:00:00Z",
  "updatedAtUtc": "2026-04-20T13:00:00Z"
}
```

Paginated response envelope:

```json
{
  "items": [],
  "page": 1,
  "pageSize": 50,
  "total": 0,
  "totalPages": 0
}
```

`POST /messages/conversations/direct` request:

```json
{
  "targetPlayerId": "6f3eb420-4516-4f77-bd79-e9503bfa73cc"
}
```

Current creation rules:

- self-DM is rejected
- target player must exist and be active
- repeat creation for the same two players returns the existing conversation

---

## Message DTO

Thread history and send responses use this shape:

```json
{
  "id": "4f31d5f4-4603-4f4f-b286-6c95e73a4a57",
  "conversationId": "0a90f4ae-75e7-4f4e-8d77-b9d5ed4dd488",
  "senderId": "6f3eb420-4516-4f77-bd79-e9503bfa73cc",
  "senderDisplayName": "Sarah Chen",
  "content": "Hey there",
  "type": "text",
  "status": "delivered",
  "createdAtUtc": "2026-04-20T13:05:00Z"
}
```

`POST /messages/conversations/{conversationId}/messages` request:

```json
{
  "content": "Hello!",
  "clientMessageId": "client-123"
}
```

`clientMessageId` behavior:

- optional
- sender-scoped idempotency key
- repeated send with the same `clientMessageId` returns the same stored message instead of duplicating it

Unread count response:

```json
{
  "unreadCount": 5
}
```

Unread state is derived from conversation participant read state, not from a separate denormalized counter table.

---

## Realtime Refresh

DM history remains REST-owned in v1. Realtime is only a refresh signal.

Current backend behavior:

- when a message is sent, the backend emits a refresh event over `/ws/notify`
- the event is sent to the recipient player group
- the event is also sent back to the sender player group for cross-device refresh

Current lightweight player event:

- `DirectMessagesUpdated`

Message payload shape:

```json
{
  "playerId": "00000000-0000-0000-0000-000000000000",
  "conversationId": "11111111-1111-1111-1111-111111111111",
  "unreadCount": 1,
  "reason": "message_sent",
  "occurredAtUtc": "2026-04-20T13:05:00Z"
}
```

Frontend guidance:

- use websocket events as a signal to refetch conversation list or thread data
- do not treat the websocket message as the source of truth for the full message body
- keep thread hydration and read-state refresh anchored on the REST endpoints above

---

## Frontend Integration Notes

- DM creation flows from friends/search should call `POST /messages/conversations/direct`
- conversation list screens should hydrate from `GET /messages/conversations`
- thread screens should hydrate from `GET /messages/conversations/{conversationId}/messages`
- message send should call `POST /messages/conversations/{conversationId}/messages`
- thread open/read completion should call `POST /messages/conversations/{conversationId}/read`
- app-level unread badges should use `GET /messages/unread-count`

The current frontend can keep temporary local typing indicators as UI-only state, but that is not part of the backend contract.

---

## Error Handling

Messaging uses the shared backend-standard nested error envelope:

```json
{
  "error": {
    "code": "FORBIDDEN",
    "message": "Conversation does not belong to the authenticated user.",
    "details": {}
  }
}
```

Current common error codes:

- `UNAUTHORIZED`
- `VALIDATION_ERROR`
- `SELF_DM_NOT_ALLOWED`
- `FORBIDDEN`
- `NOT_FOUND`

Frontend should parse:

- `error.code`
- `error.message`
- `error.details`

---

## Current Limits

Messaging v1 intentionally does not yet include:

- group chat
- message attachments/uploads
- reactions
- typing-state backend events
- edit/delete message endpoints
- paginated thread history

Those are follow-up features on top of the current direct-message baseline rather than blockers for the current frontend integration.

---

## Frontend Implementation Status - April 20, 2026

### Completed

- Added `DirectMessageService` for the v1 direct-message REST routes:
  - `GET /messages/conversations`
  - `POST /messages/conversations/direct`
  - `GET /messages/conversations/{conversationId}/messages`
  - `POST /messages/conversations/{conversationId}/messages`
  - `POST /messages/conversations/{conversationId}/read`
  - `GET /messages/unread-count`
- Updated `Conversation` and `Message` model parsing to tolerate the backend DTO field names in this handoff.
- Replaced normal DM conversation hydration with backend-backed providers.
- Replaced normal DM thread hydration with backend-backed providers.
- Message send now calls the backend send route and invalidates thread, conversation, and unread-count providers.
- Thread open/read behavior now calls the backend read route and invalidates thread, conversation, and unread-count providers.
- Create-DM flows from friends and create-DM dialog now await `POST /messages/conversations/direct`.
- App-level message badges now read from `GET /messages/unread-count`.
- Added frontend service tests that verify conversation list, direct-conversation creation, message history, send payloads, and DTO parsing.

### Remaining Frontend Work

- Run Flutter tests once `flutter`/`dart` are available on PATH.
- Validate against the real backend that conversation creation is idempotent for repeat DM creation.
- Validate real backend behavior for unauthorized conversation access, self-DM rejection, and missing target players.
- Add widget/integration tests for message list loading/error states, thread loading/error states, send success/failure, and read-state clearing.
- Hook websocket `DirectMessagesUpdated` refresh events into conversation/thread invalidation once the exact frontend event handler contract is confirmed.
- Replace or remove remaining local-only transitional message features that are outside DM v1, including typing simulation, reactions, attachments, online groups, and group chat placeholders.
- Add paginated thread-history UI when the backend moves message history from full-list v1 responses to paginated responses.
