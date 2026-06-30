# Phase 3: Operator Dashboard Control - Implementation Plan

**Status**: 🟡 READY TO START  
**Date Started**: 2026-06-28  
**Estimated Duration**: 50 hours (3-5 days)  
**Target Completion**: 2026-07-02

---

## Overview

Phase 3 enables operators to control spin wheel and tier system configurations in real-time through a dedicated dashboard. This includes tier management, probability adjustment, event scheduling, and analytics viewing.

### Objectives
1. ✅ Design operator API endpoints (backend)
2. ✅ Implement tier-specific operator controls (backend)
3. ✅ Build operator dashboard UI (frontend)
4. ✅ Integrate analytics visualization
5. ✅ Implement audit logging

### Architecture Diagram

```
┌─────────────────────────────────────────┐
│      Operator Dashboard UI              │
│  (React/Vue/Flutter Web)                │
└────────────────┬────────────────────────┘
                 │
        ┌────────▼─────────┐
        │  Operator API    │
        │  Endpoints       │
        └────────┬─────────┘
                 │
        ┌────────▼──────────────────┐
        │  Backend Services         │
        ├──────────────────────────┤
        │ - Tier Management        │
        │ - Probability Control    │
        │ - Event Scheduler        │
        │ - Analytics Engine       │
        │ - Audit Logger           │
        └────────┬──────────────────┘
                 │
        ┌────────▼──────────┐
        │  Game Services    │
        │  & Database       │
        └───────────────────┘
```

---

## Task 3.1: Operator API Endpoints (Backend)

### Objective
Create RESTful API endpoints for operators to control tier system, probability distribution, and event scheduling.

### Required Endpoints

#### 1. Tier Management

**GET /operator/arcade/tier/:id**
- Retrieve single tier configuration
- Response includes: tier details, rewards, thresholds, operator controls
- Authorization: Admin/Operator role
- Rate limit: 100/minute

```json
{
  "id": "silver-scholar",
  "name": "Silver Scholar",
  "level": 5,
  "enabled": true,
  "minXp": 500,
  "maxXp": 1200,
  "rewards": {
    "badge": "scholar_badge",
    "coinsBonus": 250,
    "gemsBonus": 5
  },
  "requirements": {
    "minPlayCount": 5,
    "minAccuracy": 0.75
  },
  "lastModifiedBy": "admin_001",
  "lastModifiedAt": "2026-06-28T14:30:00Z"
}
```

**PUT /operator/arcade/tier/:id**
- Update tier configuration
- Fields: enabled, minXp, maxXp, rewards, requirements
- Validates changes before applying
- Creates audit log entry
- Response: Updated tier configuration

```json
{
  "minXp": 600,
  "maxXp": 1300,
  "rewards": {
    "badge": "scholar_badge",
    "coinsBonus": 300,
    "gemsBonus": 10
  },
  "enabled": true
}
```

**DELETE /operator/arcade/tier/:id**
- Soft delete tier (mark as disabled)
- Preserves historical data
- Response: 204 No Content

#### 2. Probability Configuration

**GET /operator/arcade/probability-config**
- Retrieve current probability configuration
- Includes: base distribution, modifiers, time-based adjustments
- Authorization: Admin/Operator role

```json
{
  "version": "1.0.0",
  "baseDistribution": {
    "jackpot": 0.02,
    "rare": 0.08,
    "uncommon": 0.30,
    "common": 0.60
  },
  "modifiers": {
    "level_multiplier": 1.15,
    "streak_bonus": 1.25
  },
  "timeBasedAdjustments": [
    {
      "name": "Weekend Bonus",
      "days": ["Saturday", "Sunday"],
      "probabilityMultiplier": 1.5,
      "active": true
    }
  ]
}
```

**PUT /operator/arcade/probability-config**
- Update probability distribution
- Validates that probabilities sum to 1.0
- Creates audit log entry
- Response: Updated configuration

#### 3. Event Scheduling

**POST /operator/arcade/events**
- Schedule promotional events
- Event types: tier promotion, probability boost, reward bonus
- Includes: start/end time, affected tiers, multipliers
- Response: Event ID and configuration

```json
{
  "type": "tier_promotion",
  "name": "Summer Promotion",
  "description": "Double rewards for Silver Scholar tier",
  "affectedTiers": ["silver-scholar", "gold-master"],
  "startTime": "2026-07-01T00:00:00Z",
  "endTime": "2026-07-31T23:59:59Z",
  "multipliers": {
    "rewardMultiplier": 2.0,
    "xpMultiplier": 1.5
  }
}
```

**GET /operator/arcade/events**
- List all scheduled events (active and past)
- Supports filtering by date range, tier, type
- Response: Array of events with full details

**DELETE /operator/arcade/events/:id**
- Cancel scheduled event
- Response: 204 No Content

#### 4. Analytics & Monitoring

**GET /operator/arcade/analytics**
- Retrieve aggregated analytics data
- Time period support (24h, 7d, 30d, custom)
- Metrics: win rates, progression rates, anomalies
- Response: Comprehensive analytics object

```json
{
  "period": "24h",
  "fromDate": "2026-06-27T14:30:00Z",
  "toDate": "2026-06-28T14:30:00Z",
  "totalSpins": 15420,
  "tierStats": {
    "bronze-rookie": {
      "playerCount": 450,
      "avgXpGain": 125,
      "progressionRate": 0.45
    }
  },
  "anomalies": [
    {
      "type": "unusual_win_rate",
      "tier": "gold-master",
      "expectedRate": 0.08,
      "actualRate": 0.15,
      "severity": "high"
    }
  ]
}
```

**GET /operator/arcade/audit-log**
- Retrieve audit trail of all operator actions
- Supports filtering by operator, action, date range
- Response: Array of audit entries

```json
{
  "timestamp": "2026-06-28T14:30:00Z",
  "operator": "admin_001",
  "action": "tier_update",
  "resourceId": "silver-scholar",
  "changes": {
    "minXp": { "old": 500, "new": 600 },
    "maxXp": { "old": 1200, "new": 1300 }
  },
  "ipAddress": "192.168.1.100",
  "result": "success"
}
```

### Implementation Status

| Endpoint | Status | Priority | Effort |
|----------|--------|----------|--------|
| GET /operator/arcade/tier/:id | 🔴 Not Started | HIGH | 2h |
| PUT /operator/arcade/tier/:id | 🔴 Not Started | HIGH | 3h |
| GET /operator/arcade/probability-config | 🔴 Not Started | HIGH | 1h |
| PUT /operator/arcade/probability-config | 🔴 Not Started | HIGH | 2h |
| POST /operator/arcade/events | 🔴 Not Started | MEDIUM | 2h |
| GET /operator/arcade/events | 🔴 Not Started | MEDIUM | 1h |
| DELETE /operator/arcade/events/:id | 🔴 Not Started | MEDIUM | 1h |
| GET /operator/arcade/analytics | 🔴 Not Started | HIGH | 3h |
| GET /operator/arcade/audit-log | 🔴 Not Started | HIGH | 2h |

**Total Effort**: 17 hours (Backend)

---

## Task 3.2: Tier-Specific Operator Controls (Backend)

### Objective
Implement granular control for tier-specific settings and rules.

### Features

#### 1. Tier Enable/Disable
- Instantly disable tier for players
- Backfill players to next active tier
- Preserve historical progression
- Audit log entry created

#### 2. Tier Threshold Adjustment
- Modify min/max XP requirements
- Rebalance progression curve
- Validate no gaps or overlaps
- Notify affected players (optional)

#### 3. Tier Reward Modification
- Adjust coin/gem rewards
- Modify badge/achievement
- Change unlock requirements
- Prospective changes only (don't retroactive)

#### 4. Promotional Events
- Temporary reward multipliers
- Time-limited tier access
- Special unlock requirements
- Scheduled notifications

#### 5. Player Backfill Logic
```
When tier is disabled:
  For each player in that tier:
    Find next enabled tier above current
    Move player to that tier
    Adjust XP if needed
    Create backfill audit entry
    Notify player (optional)
```

### Implementation Status

| Feature | Status | Priority | Effort |
|---------|--------|----------|--------|
| Tier enable/disable | 🔴 Not Started | HIGH | 3h |
| Threshold adjustment | 🔴 Not Started | HIGH | 3h |
| Reward modification | 🔴 Not Started | HIGH | 2h |
| Promotional events | 🔴 Not Started | MEDIUM | 3h |
| Player backfill | 🔴 Not Started | HIGH | 4h |

**Total Effort**: 15 hours (Backend)

---

## Task 3.3: Operator Dashboard UI (Frontend)

### Objective
Build comprehensive operator control dashboard for real-time system management.

### Dashboard Layout

#### 1. Main Dashboard
- Header: Operator name, role, last login
- Status cards: Active players, tier distribution, anomalies
- Quick action buttons
- Navigation sidebar

#### 2. Tier Management Panel
- Tier list with current settings
- Expand to edit tier details
- Enable/disable toggle
- Modification history
- Validation feedback

```
┌─────────────────────────────────────┐
│ Tier Management                     │
├─────────────────────────────────────┤
│ Bronze Rookie (Enabled) [Edit]      │
│ Silver Scholar (Enabled) [Edit]     │
│ Gold Master (Disabled) [Edit]       │
│ Platinum Elite (Enabled) [Edit]     │
└─────────────────────────────────────┘
```

#### 3. Tier Edit Modal
- Tier name (readonly)
- Min/Max XP sliders
- Reward configuration
- Unlock requirements
- Save/Cancel buttons
- Change preview

#### 4. Probability Adjustment Panel
- Base distribution visual (pie chart)
- Slider controls for each rarity
- Live probability preview
- Time-based adjustment list
- Add/edit/remove adjustments

#### 5. Event Scheduler
- Calendar view of events
- Quick add event form
- Event list with actions
- Event details modal
- Recurring event support (optional)

#### 6. Analytics Dashboard
- Time period selector (24h, 7d, 30d)
- Tier performance cards
- Win rate chart
- Progression velocity
- Anomaly alerts
- Export report button

#### 7. Audit Log Viewer
- Table of recent actions
- Filters: operator, action, date range
- Sortable columns
- Detail modal for each action
- Export capability

### Page Structure

```
Operator Dashboard
├── Header (Logo, Operator Name, Logout)
├── Sidebar Navigation
│   ├── Dashboard
│   ├── Tier Management
│   ├── Probability Control
│   ├── Event Scheduler
│   ├── Analytics
│   └── Audit Log
└── Main Content Area
    ├── Page Title
    ├── Filters/Controls
    └── Content Panel
        ├── Data Grid/Form
        ├── Action Buttons
        └── Status Messages
```

### Implementation Status

| Component | Status | Priority | Effort |
|-----------|--------|----------|--------|
| Main dashboard | 🔴 Not Started | HIGH | 4h |
| Tier management | 🔴 Not Started | HIGH | 6h |
| Probability control | 🔴 Not Started | HIGH | 4h |
| Event scheduler | 🔴 Not Started | MEDIUM | 5h |
| Analytics dashboard | 🔴 Not Started | HIGH | 6h |
| Audit log viewer | 🔴 Not Started | MEDIUM | 3h |
| Notifications | 🔴 Not Started | MEDIUM | 2h |

**Total Effort**: 30 hours (Frontend)

---

## Implementation Timeline

### Day 1 (Today)
**Target**: Backend API endpoint design

- [ ] Finalize API specifications
- [ ] Design database schema updates
- [ ] Create API documentation
- [ ] Setup endpoint scaffolding
- **Effort**: 6 hours

### Day 2
**Target**: Backend API implementation

- [ ] Implement tier management endpoints (3h)
- [ ] Implement probability config endpoints (2h)
- [ ] Implement analytics endpoints (2h)
- **Effort**: 7 hours

### Day 3
**Target**: Event scheduling and audit logging

- [ ] Implement event scheduler endpoints (3h)
- [ ] Implement audit logging (2h)
- [ ] Implement tier-specific controls (3h)
- **Effort**: 8 hours

### Day 4-5
**Target**: Frontend dashboard UI

- [ ] Dashboard layout & components (6h)
- [ ] Tier management panel (6h)
- [ ] Probability control panel (4h)
- [ ] Analytics dashboard (6h)
- [ ] Audit log viewer (4h)
- [ ] Integration testing (4h)
- **Effort**: 30 hours

---

## Dependencies & Blockers

### Dependencies
- ✅ Phase 2 API infrastructure (complete)
- ✅ Caching system (complete)
- ⏳ Authentication/Authorization system (needs review)
- ⏳ Role-based access control (needs implementation)

### Potential Blockers
- 🔴 Backend developer availability (not in scope for this agent)
- 🟡 Authorization system complexity
- 🟡 Real-time WebSocket integration (optional)
- 🟡 Database migration for audit log

---

## Success Criteria

### API Level
- [ ] All 9 endpoints implemented
- [ ] Proper authorization on all endpoints
- [ ] Audit logging on all mutations
- [ ] Input validation on all endpoints
- [ ] Error handling with proper HTTP codes
- [ ] Rate limiting (100/min)
- [ ] Performance < 500ms for most requests

### Dashboard Level
- [ ] All 7 components implemented
- [ ] Responsive design (mobile, tablet, desktop)
- [ ] Real-time updates (WebSocket optional)
- [ ] Confirmation modals for destructive actions
- [ ] Proper error messages
- [ ] Loading states
- [ ] Accessibility (WCAG 2.1 AA)

### Overall
- [ ] Full test coverage (backend & frontend)
- [ ] Documentation complete
- [ ] Security review passed
- [ ] Performance tested
- [ ] Production ready

---

## Technology Decisions

### Frontend Framework
**Options**:
1. Flutter Web (consistent with app)
2. React (most common for dashboards)
3. Vue.js (lightweight, learning curve)

**Recommended**: React or Flutter Web depending on team preference

### Real-time Updates
**WebSocket** (optional):
- Automatic notification of configuration changes
- Real-time analytics updates
- Event notifications
- Can be added in future phase

### Data Visualization
**Libraries**:
- Charts: Chart.js, Recharts, or similar
- Tables: React Table, DataGrid
- Forms: React Hook Form, Formik

---

## Risk Assessment

### Low Risk ✅
- API endpoint design (straightforward REST)
- Dashboard UI (standard components)
- Audit logging (proven pattern)

### Medium Risk 🟡
- Authorization/permissions (complexity depends on existing system)
- Real-time updates (WebSocket infrastructure)
- Performance at scale (large analytics datasets)

### High Risk 🔴
- None identified

---

## Testing Strategy

### Backend Testing
- Unit tests for each endpoint
- Integration tests for workflows
- Authorization tests
- Performance tests
- Audit log verification

### Frontend Testing
- Component tests
- Integration tests
- E2E tests for critical flows
- Accessibility tests

### Manual Testing
- Operator workflows
- Error scenarios
- Performance under load
- Browser compatibility

---

## Deliverables

### Backend
- [ ] API endpoints (9 endpoints)
- [ ] Database schema updates
- [ ] Authorization system
- [ ] Audit logging system
- [ ] Analytics engine
- [ ] Event scheduler

### Frontend
- [ ] Dashboard layout
- [ ] Tier management UI
- [ ] Probability control UI
- [ ] Event scheduler UI
- [ ] Analytics dashboard
- [ ] Audit log viewer
- [ ] API integration

### Documentation
- [ ] API documentation
- [ ] Dashboard user guide
- [ ] Operator handbook
- [ ] Security guidelines

---

## Readiness Checklist

### Prerequisites Met
- ✅ Phase 2 API infrastructure complete
- ✅ Caching system working
- ✅ Frontend base UI framework ready
- ⏳ Authentication system available
- ⏳ Database ready for schema updates

### Before Starting
- [ ] Authorization system designed
- [ ] Database schema planned
- [ ] Frontend framework chosen
- [ ] Mockups/designs reviewed
- [ ] Team assignments confirmed

---

## Next Steps

1. **Immediate** (Before coding)
   - Finalize API specifications
   - Design authorization rules
   - Plan database schema
   - Review UI mockups
   - Assign tasks

2. **Backend Development** (Days 1-3)
   - Implement API endpoints
   - Add authorization checks
   - Setup audit logging
   - Create tests

3. **Frontend Development** (Days 4-5)
   - Build dashboard UI
   - Integrate with API
   - Add real-time updates
   - Comprehensive testing

4. **Deployment** (Day 5+)
   - Security review
   - Performance testing
   - Production deployment
   - Operator training

---

## Resources Needed

### Backend
- Backend developer(s)
- Database access
- API documentation template
- Testing framework

### Frontend
- Frontend developer(s)
- UI/UX designer
- Component library
- Testing tools

### DevOps
- Deployment pipeline
- Staging environment
- Monitoring/alerting
- Backup/recovery plan

---

**Phase 3 Status**: 🟡 READY TO START  
**Estimated Duration**: 50 hours (3-5 days)  
**Target Completion**: 2026-07-02  
**Team Required**: Backend + Frontend developers  
**Blocker**: Backend API endpoint implementation

