# Architecture & Technical Decisions

This directory contains documentation on system design, architectural decisions, and technical justifications.

## Files

- **CRITICAL_DECISION_TIER_SYSTEM.md** - Historical decision record for the earlier tier-backend blocker, now superseded by the July 3, 2026 endpoint verification

## Purpose

Documents in this directory answer: **"Why was this designed this way?"**

They capture:

- Decision context and constraints
- Options evaluated and trade-offs
- Final decision and rationale
- Implementation impact
- Later verification updates when the system changes

## Current Decisions

### Tier System: Real Backend With Fallback

**Decision:** Use the real backend progression API for Phase 2, with mock fallback retained for offline/error handling.

**Current backend endpoints:**

```text
GET  /api/v1/progression/tiers
GET  /api/v1/progression/player/{userId:guid}
POST /api/v1/progression/xp/award
```

**Rationale:**

- Backend progression endpoints now exist and are mapped in `TycoonTycoon_Backend`.
- Frontend providers can use the authenticated HTTP client and configured API base URL.
- Mock fallback still protects development/offline flows.
- The earlier "mock until backend ready" decision is historical, not current.

**Files:** CRITICAL_DECISION_TIER_SYSTEM.md

---

## Key Architectural Patterns

### API Client Architecture

- Consistent error handling with custom exceptions
- API-first clients with graceful fallback where useful
- Shared authenticated HTTP client from provider layer
- Configured API base URL via `EnvConfig.apiV1BaseUrl`
- Type-safe model serialization
- Clear separation between business logic and HTTP

### State Management

- Riverpod for reactive state
- Providers at multiple layers: data, business, UI
- Clear data flow from API to provider to widget

### Error Handling Strategy

- Custom exceptions per API domain
- Status-code-specific handling
- Graceful fallbacks with offline support
- User-friendly error messages

---

**Last Updated:** July 3, 2026
