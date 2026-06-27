# Architecture & Technical Decisions

This directory contains documentation on system design, architectural decisions, and technical justifications.

## 📋 Files

- **CRITICAL_DECISION_TIER_SYSTEM.md** - Decision framework for tier system implementation

## 🎯 Purpose

Documents in this directory answer the question: **"Why was this designed this way?"**

They capture:
- Decision context and constraints
- Options evaluated and trade-offs
- Final decision and rationale
- Implementation impact

## 📊 Current Decisions

### Tier System: Mock vs Real Backend

**Decision:** Use mock tier system for Phase 2, swap real API when backend ready

**Rationale:**
- Backend endpoints don't exist yet
- Frontend can proceed independently
- 1-hour effort to swap real API when ready
- Reduces risk and unblocks development

**Files:** CRITICAL_DECISION_TIER_SYSTEM.md

---

## 🔑 Key Architectural Patterns

### API Client Architecture
- Consistent error handling with custom exceptions
- Dual-mode support (API first, fallback to assets)
- Full logging for debugging
- Type-safe model serialization
- Clear separation between business logic and HTTP

### State Management
- Riverpod for reactive state
- Providers at multiple layers (data, business, UI)
- Clear data flow from API → Provider → Widget

### Error Handling Strategy
- Custom exceptions per API domain
- Status code-specific handling
- Graceful fallbacks with offline support
- User-friendly error messages

---

**Last Updated:** June 27, 2026
