# Synaptix Frontend Personalization Implementation Plan

## Objective
Integrate backend personalization safely and transparently.

## Core Principle
Frontend = Renderer
Backend = Decision Maker

## API Integration

> ⚠️ **Path shapes below are superseded.** The live implementation (see `lib/core/networking/synaptix_api_client.dart`) uses the April 30 2026 contract paths: `/personalization/{playerId}/home`, `/personalization/{playerId}/recommendations`, etc. Treat any `/personalization/home/{playerId}` or `/personalization/recommendations/{playerId}` references in this doc as historical only.

Current correct paths (as implemented):
- GET /personalization/{playerId}/profile
- GET /personalization/{playerId}/home
- GET /personalization/{playerId}/recommendations
- POST /personalization/{playerId}/events
- POST /personalization/{playerId}/toggle
- GET /coach/{playerId}/daily-brief
- POST /coach/{playerId}/feedback
- GET /experiments/player/{playerId}

## UI Areas
- Home (recommended mode, category, mission)
- Study/Learning (recommended)
- Missions (tagged)
- Store (suggested items)

## Explainability
- "Why am I seeing this?"
- Show reason for recommendation

## User Controls
- Personalization ON/OFF
- Reset recommendations
- Reduce suggestions
- Notification preferences

## Coach UI
Short actionable prompts

## Recommendation UX
- Accept/Dismiss tracking

## Notifications
- Respect tone
- Respect fatigue

## Error Handling
Fallback to default experience

## Performance
- Cache responses
- Lazy load

## UX Goal
Helpful, not manipulative
