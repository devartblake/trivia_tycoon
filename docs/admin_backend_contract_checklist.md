# Admin Backend Contract Checklist

This document defines concrete endpoint contracts for the current admin surfaces so frontend and backend can build in parallel.

---

## 0) Conventions (applies to all endpoints)

### Auth & headers
- `Authorization: Bearer <access_token>` required for all `/admin/**` endpoints.
- `Content-Type: application/json` for JSON request bodies.
- Optional: `X-Request-Id` (client-generated UUID for tracing).

### Role enforcement
- Backend must enforce role claims (minimum role: `admin`; finer permissions by scope).
- Frontend role gates are **advisory only**; backend is source of truth.

### Timestamp format
- ISO-8601 UTC strings, e.g. `2026-02-23T14:31:00Z`.

### Pagination format
- Query params: `page` (1-based), `pageSize` (1..200), `sortBy`, `sortOrder` (`asc|desc`).
- Response envelope for collections:

```json
{
  "items": [],
  "page": 1,
  "pageSize": 25,
  "totalItems": 0,
  "totalPages": 0
}
```

### Error envelope

```json
{
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable message",
    "details": {}
  }
}
```

Suggested shared error codes:
- `UNAUTHORIZED` (401)
- `FORBIDDEN` (403)
- `NOT_FOUND` (404)
- `CONFLICT` (409)
- `RATE_LIMITED` (429)
- `VALIDATION_ERROR` (422)
- `INTERNAL_ERROR` (500)

---

## 1) Admin Authentication & Role Claims

## 1.1 Admin login
- **Method/Path**: `POST /admin/auth/login`
- **Purpose**: Authenticate admin user and return tokens + claims.

### Request

```json
{
  "email": "admin@company.com",
  "password": "string",
  "otpCode": "123456"
}
```

`otpCode` optional unless MFA policy requires it.

### Success response (200)

```json
{
  "accessToken": "jwt",
  "refreshToken": "opaque-or-jwt",
  "expiresIn": 3600,
  "tokenType": "Bearer",
  "admin": {
    "id": "adm_123",
    "email": "admin@company.com",
    "displayName": "Admin User",
    "roles": ["admin"],
    "permissions": [
      "users:read",
      "users:write",
      "questions:read",
      "questions:write",
      "events:read",
      "events:write"
    ]
  }
}
```

### Failure responses
- `401 UNAUTHORIZED` invalid credentials.
- `403 FORBIDDEN` valid auth but role not admin.
- `429 RATE_LIMITED` too many attempts.

## 1.2 Refresh token
- **Method/Path**: `POST /admin/auth/refresh`

### Request

```json
{ "refreshToken": "opaque-or-jwt" }
```

### Success (200)

```json
{
  "accessToken": "jwt",
  "expiresIn": 3600,
  "tokenType": "Bearer"
}
```

## 1.3 Current admin profile/claims
- **Method/Path**: `GET /admin/auth/me`

### Success (200)

```json
{
  "id": "adm_123",
  "email": "admin@company.com",
  "displayName": "Admin User",
  "roles": ["admin"],
  "permissions": ["users:read", "users:write"]
}
```

---

## 2) User Management Contracts

## 2.1 List users (search/filter/sort/paginate)
- **Method/Path**: `GET /admin/users`

### Query params
- `q` (string): search by username/email/id
- `status` (enum): `online|offline|away|busy|banned`
- `role` (enum): `user|premium|moderator|admin`
- `ageGroup` (enum): `child|teen|adult`
- `isVerified` (bool)
- `isBanned` (bool)
- `page`, `pageSize`, `sortBy`, `sortOrder`

### Success (200)

```json
{
  "items": [
    {
      "id": "usr_1",
      "username": "john_doe",
      "email": "john@example.com",
      "status": "online",
      "role": "premium",
      "ageGroup": "adult",
      "createdAt": "2026-01-01T00:00:00Z",
      "lastActive": "2026-02-23T14:00:00Z",
      "totalGamesPlayed": 145,
      "totalPoints": 12450,
      "winRate": 0.68,
      "isVerified": true,
      "isBanned": false
    }
  ],
  "page": 1,
  "pageSize": 25,
  "totalItems": 1,
  "totalPages": 1
}
```

## 2.2 Get user detail
- **Method/Path**: `GET /admin/users/{userId}`

### Success (200)

```json
{
  "id": "usr_1",
  "username": "john_doe",
  "email": "john@example.com",
  "status": "online",
  "role": "premium",
  "ageGroup": "adult",
  "createdAt": "2026-01-01T00:00:00Z",
  "lastActive": "2026-02-23T14:00:00Z",
  "totalGamesPlayed": 145,
  "totalPoints": 12450,
  "winRate": 0.68,
  "isVerified": true,
  "isBanned": false,
  "metadata": {
    "country": "US",
    "deviceCount": 2
  }
}
```

## 2.3 Create user
- **Method/Path**: `POST /admin/users`

### Request

```json
{
  "username": "new_user",
  "email": "new_user@example.com",
  "role": "user",
  "ageGroup": "adult",
  "isVerified": false,
  "temporaryPassword": "TempPass123!"
}
```

### Success (201)

```json
{
  "id": "usr_999",
  "createdAt": "2026-02-23T14:31:00Z"
}
```

## 2.4 Update user
- **Method/Path**: `PATCH /admin/users/{userId}`

### Request (partial)

```json
{
  "username": "updated_name",
  "role": "moderator",
  "isVerified": true
}
```

### Success (200)

```json
{
  "id": "usr_1",
  "updatedAt": "2026-02-23T14:31:00Z"
}
```

## 2.5 Ban user
- **Method/Path**: `POST /admin/users/{userId}/ban`

### Request

```json
{
  "reason": "Abusive behavior",
  "until": "2026-03-01T00:00:00Z"
}
```

### Success (200)

```json
{
  "id": "usr_1",
  "isBanned": true,
  "bannedUntil": "2026-03-01T00:00:00Z"
}
```

## 2.6 Unban user
- **Method/Path**: `POST /admin/users/{userId}/unban`

### Success (200)

```json
{
  "id": "usr_1",
  "isBanned": false
}
```

## 2.7 Delete user
- **Method/Path**: `DELETE /admin/users/{userId}`

### Success
- `204 No Content`

## 2.8 User activity log
- **Method/Path**: `GET /admin/users/{userId}/activity`

### Query params
- `from`, `to`, `type`, `page`, `pageSize`

### Success (200)

```json
{
  "items": [
    {
      "id": "evt_1",
      "type": "LOGIN",
      "description": "User signed in",
      "createdAt": "2026-02-23T10:00:00Z",
      "metadata": {}
    }
  ],
  "page": 1,
  "pageSize": 50,
  "totalItems": 1,
  "totalPages": 1
}
```

---

## 3) Question Bank Contracts

## 3.1 List questions
- **Method/Path**: `GET /admin/questions`

### Query params
- `q`, `category`, `tag` (repeatable), `page`, `pageSize`, `sortBy`, `sortOrder`

### Success (200)

```json
{
  "items": [
    {
      "id": "q_1",
      "question": "What is 2+2?",
      "options": ["1", "2", "3", "4"],
      "correctIndex": 3,
      "category": "math",
      "tags": ["easy"],
      "difficulty": "easy",
      "updatedAt": "2026-02-23T14:00:00Z"
    }
  ],
  "page": 1,
  "pageSize": 25,
  "totalItems": 1,
  "totalPages": 1
}
```

## 3.2 Create question
- **Method/Path**: `POST /admin/questions`

### Request

```json
{
  "question": "What is 2+2?",
  "options": ["1", "2", "3", "4"],
  "correctIndex": 3,
  "category": "math",
  "tags": ["easy"],
  "difficulty": "easy"
}
```

### Success (201)

```json
{ "id": "q_1" }
```

## 3.3 Update question
- **Method/Path**: `PATCH /admin/questions/{questionId}`

### Success (200)

```json
{ "id": "q_1", "updatedAt": "2026-02-23T14:31:00Z" }
```

## 3.4 Delete question
- **Method/Path**: `DELETE /admin/questions/{questionId}`

### Success
- `204 No Content`

## 3.5 Bulk upload/replace questions
- **Method/Path**: `POST /admin/questions/bulk`

### Request

```json
{
  "mode": "upsert",
  "questions": [
    {
      "id": "q_1",
      "question": "What is 2+2?",
      "options": ["1", "2", "3", "4"],
      "correctIndex": 3,
      "category": "math",
      "tags": ["easy"]
    }
  ]
}
```

`mode`: `upsert|replace`.

### Success (200)

```json
{
  "received": 100,
  "created": 80,
  "updated": 20,
  "failed": 0,
  "errors": []
}
```

## 3.6 Bulk export questions
- **Method/Path**: `GET /admin/questions/export`
- **Response**: JSON array or downloadable file.

---

## 4) Event Queue Admin Contracts

## 4.1 Upload failed/queued events
- **Method/Path**: `POST /admin/event-queue/upload`

### Request

```json
{
  "source": "mobile_admin",
  "exportedAt": "2026-02-23T14:31:00Z",
  "playerId": "player_123",
  "events": [
    {
      "eventId": "e_1",
      "eventType": "spin_completed",
      "occurredAt": "2026-02-23T14:00:00Z",
      "payload": {"score": 100},
      "retryCount": 2
    }
  ]
}
```

### Success (200)

```json
{
  "accepted": 10,
  "rejected": 0,
  "duplicates": 1,
  "results": [
    {
      "eventId": "e_1",
      "status": "accepted"
    }
  ]
}
```

## 4.2 Trigger server-side reprocessing (optional)
- **Method/Path**: `POST /admin/event-queue/reprocess`

### Request

```json
{
  "scope": "failed_only",
  "limit": 1000
}
```

### Success (202)

```json
{
  "jobId": "job_123",
  "status": "queued"
}
```

---

## 5) Notification Admin Contracts (if moving beyond local-only)

> Current implementation is largely local-device notification scheduling. If you need centralized admin notifications, use these endpoints.

## 5.1 List channels
- **Method/Path**: `GET /admin/notifications/channels`

### Success (200)

```json
[
  {
    "key": "admin_basic",
    "name": "Admin Basic",
    "description": "General admin notifications",
    "importance": "high",
    "enabled": true
  }
]
```

## 5.2 Upsert channel
- **Method/Path**: `PUT /admin/notifications/channels/{key}`

### Request

```json
{
  "name": "System Alerts",
  "description": "Critical system alerts",
  "importance": "max",
  "enabled": true
}
```

## 5.3 Send broadcast notification now
- **Method/Path**: `POST /admin/notifications/send`

### Request

```json
{
  "title": "Maintenance notice",
  "body": "Servers will restart at 02:00 UTC",
  "channelKey": "admin_basic",
  "audience": {
    "segment": "all_users"
  },
  "payload": {
    "type": "maintenance"
  }
}
```

### Success (202)

```json
{
  "jobId": "push_job_123",
  "estimatedRecipients": 12000
}
```

## 5.4 Schedule notification
- **Method/Path**: `POST /admin/notifications/schedule`

### Request

```json
{
  "title": "Weekend promo",
  "body": "Double rewards are live!",
  "channelKey": "admin_promos",
  "scheduledAt": "2026-02-28T12:00:00Z",
  "repeat": {
    "type": "none"
  },
  "audience": {
    "segment": "active_7d"
  }
}
```

### Success (201)

```json
{ "scheduleId": "sch_123" }
```

## 5.5 List scheduled notifications
- **Method/Path**: `GET /admin/notifications/scheduled`

### Success (200)

```json
{
  "items": [
    {
      "scheduleId": "sch_123",
      "title": "Weekend promo",
      "channelKey": "admin_promos",
      "scheduledAt": "2026-02-28T12:00:00Z",
      "status": "scheduled"
    }
  ],
  "page": 1,
  "pageSize": 25,
  "totalItems": 1,
  "totalPages": 1
}
```

## 5.6 Cancel scheduled notification
- **Method/Path**: `DELETE /admin/notifications/scheduled/{scheduleId}`
- **Success**: `204 No Content`

## 5.7 Templates
- `GET /admin/notifications/templates`
- `POST /admin/notifications/templates`
- `PATCH /admin/notifications/templates/{templateId}`
- `DELETE /admin/notifications/templates/{templateId}`

### Template payload example

```json
{
  "name": "promo_default",
  "title": "{{campaignName}}",
  "body": "{{body}}",
  "channelKey": "admin_promos",
  "variables": ["campaignName", "body"]
}
```

## 5.8 Notification history
- **Method/Path**: `GET /admin/notifications/history`
- Supports `from`, `to`, `channelKey`, `status`, `page`, `pageSize`.

---

## 6) Config Contracts (only if config must be server-managed)

## 6.1 Get admin app config
- **Method/Path**: `GET /admin/config`

### Success (200)

```json
{
  "apiBaseUrl": "https://api.example.com",
  "enableLogging": false,
  "featureFlags": {
    "adminEventUpload": true
  }
}
```

## 6.2 Update admin app config
- **Method/Path**: `PATCH /admin/config`

### Request

```json
{
  "enableLogging": true
}
```

### Success (200)

```json
{ "updatedAt": "2026-02-23T14:31:00Z" }
```

---

## 7) Parallel Work Plan (Frontend vs Backend)

## 7.1 Frontend checklist
- [ ] Replace hardcoded admin login with `/admin/auth/login`.
- [ ] Store and refresh tokens via `/admin/auth/refresh`.
- [ ] Drive role gate from `/admin/auth/me` claims (replace local always-true admin).
- [ ] Replace mock user list/detail/actions with `/admin/users*` APIs.
- [ ] Wire user activity log endpoint.
- [ ] Move question sync to `/admin/questions*` endpoints with auth headers.
- [ ] Wire event queue upload to `/admin/event-queue/upload`.
- [ ] If central notifications are desired, wire `/admin/notifications*` endpoints.
- [ ] Standardize API error handling to shared error envelope.

## 7.2 Backend checklist
- [ ] Implement auth endpoints with JWT + refresh and role claims.
- [ ] Enforce permission scopes on all `/admin/**` routes.
- [ ] Implement users list/detail/create/update/ban/unban/delete + activity.
- [ ] Implement question CRUD + bulk upsert/replace/export.
- [ ] Implement event queue upload dedupe and per-event result reporting.
- [ ] (Optional) Implement centralized notifications channels/templates/scheduling/history.
- [ ] (Optional) Implement server-backed admin config.
- [ ] Return consistent pagination and error envelopes.
- [ ] Add audit logs for every mutating admin action.

---

## 8) Open decisions to finalize before implementation

- [ ] MFA required for admin login? (Y/N)
- [ ] Token lifetime + refresh rotation policy.
- [ ] Canonical enum values for `UserStatus`, `UserRole`, `AgeGroup`.
- [ ] Question bulk mode default: `upsert` vs `replace`.
- [ ] Event deduplication key (`eventId` only vs hash).
- [ ] Whether notification admin remains local-only or becomes server-managed.
- [ ] Whether config settings are device-local or global server state.

