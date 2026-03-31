
# SYNAPTIX MASTER PLAYBOOK
## End-to-End Product, UX, Growth, and Architecture System

---

# 1. PRODUCT VISION

Synaptix is not a trivia app.

It is:
> A cognitive competition platform combining progression, identity, and economy.

Core pillars:
- 🧠 Cognitive Growth (Pathways)
- 🏆 Competitive Ranking (Arena)
- 🎮 Practice & Exploration (Labs)
- 👤 Identity & Progress (Journey)
- 👥 Social Layer (Circles)
- 🛠 Admin System (Command)

---

# 2. ONBOARDING + FIRST SESSION FLOW

## Stage 1: Identity Hook
- “Welcome to Synaptix”
- CTA: Begin

## Stage 2: Intent Selection
- Train Mind → Adult bias
- Compete → Teen bias
- Play → Kids bias

## Stage 3: Mode Assignment
- Kids / Teen / Adult
- Drives UI + difficulty

## Stage 4: Cognitive Profile
- Category preference
- Play style

## Stage 5: First Challenge
- 3–5 adaptive questions

## Stage 6: Reward Injection
- XP
- Coins
- Rank seed

## Stage 7: Hub Landing
- Synaptix Hub
- Arena / Labs / Pathways

## Stage 8: Retention Hook
- Bonus challenge
- Streak system

### Core Loop
Play → Reward → Unlock → Progress → Repeat

---

# 3. SYSTEM ARCHITECTURE (FRONTEND)

## Key Providers
- synaptixModeProvider
- onboardingStateProvider
- playerProfileProvider

## Screens
- SplashScreen
- IntentSelectionScreen
- ModeSelectionScreen
- ProfileSetupScreen
- FirstChallengeScreen
- RewardScreen
- HubScreen

## Routing
- GoRouter with onboarding guard
- onboarding_complete flag

---

# 4. CORE FEATURES (REBRAND SYSTEM)

| System | Function |
|------|--------|
| Arena | Leaderboards & competition |
| Labs | Practice & mini-games |
| Pathways | Skill progression |
| Journey | Player identity |
| Circles | Social system |
| Command | Admin dashboard |

---

# 5. MONETIZATION ECONOMY

## USD Layer
- Coins → gameplay currency
- Gems → premium boosts

## Crypto Layer
- Micro rewards (engagement)
- Weekly prize pools
- Optional staking (future)

## Backend (FastAPI)
- Wallet service
- Reward engine
- Transaction ledger

---

# 6. GROWTH STRATEGY (10K → 100K)

## Phase 1 (0–10K)
- Referral system (QR-based)
- Crypto micro rewards
- Invite loops

## Phase 2 (10K–50K)
- TikTok / Shorts content
- Influencer seeding
- Competitive clips

## Phase 3 (50K–100K)
- Tournaments
- Crypto prize pools
- Guild / Circles system

---

# 7. ANALYTICS SYSTEM

## Event Structure
- synaptix_mode
- surface
- entry_point

## Key Events
- hub_opened
- arena_entered
- labs_played
- pathway_progress

---

# 8. UI POLISH SYSTEM

## Design Language
- Neon glass UI
- Frosted cards
- Glow accents

## Motion
- Micro animations
- Transitions
- Progress feedback

## Feedback
- Haptics
- Sound cues
- Visual pulses

---

# 9. INTERNAL SOFT LAUNCH PLAN

## Version
Synaptix v0.9.0-internal

## Validation
- Onboarding works
- Hub works
- All surfaces load
- Analytics firing

## Acceptance Criteria
- No major bugs
- Clear branding
- Stable navigation

---

# 10. PACKET SYSTEM SUMMARY

| Packet | Purpose |
|------|--------|
| A | Branding |
| B | Mode + Hub |
| C | Feature surfaces |
| D | Analytics + Stability |
| E | Optional technical rename |

---

# 11. PHASE 8 DECISION

Default:
❌ Defer technical rename

Reason:
- High risk
- Low user value

---

# 12. FINAL SYSTEM LOOP

User Journey:
Discover → Onboard → Play → Progress → Compete → Earn → Share → Repeat

---

# 13. NEXT EXECUTION PATH

1. Implement Flutter onboarding system (full code)
2. Build monetization backend (FastAPI)
3. Implement UI polish system (animations + design system)
4. Prepare beta launch
5. Scale growth engine

---

# FINAL NOTE

Synaptix is a platform.

Execution quality—not features—will determine success.
