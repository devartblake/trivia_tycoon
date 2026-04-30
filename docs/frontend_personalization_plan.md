# Synaptix Frontend Personalization Implementation Plan

## Objective
Integrate backend personalization safely and transparently.

## Core Principle
Frontend = Renderer
Backend = Decision Maker

## API Integration
- GET /personalization/home/{playerId}
- GET /personalization/recommendations/{playerId}
- GET /coach/{playerId}/daily-brief
- POST accept/dismiss

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
