
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

# 2. ONBOARDING + FIRST SESSION FLOW ✅ IMPLEMENTED (`0a60048`)

## Stage 1: Identity Hook ✅
- “Welcome to Synaptix” — `welcome_step.dart`
- CTA: Begin

## Stage 2: Intent Selection ✅
- Train Mind / Compete / Play — `intent_step.dart`
- Maps to preferred home surface

## Stage 3: Mode Assignment ✅
- Kids / Teen / Adult — `age_group_step.dart`
- Drives UI + difficulty via SynaptixModeNotifier

## Stage 4: Cognitive Profile ✅
- Category preference — `categories_step.dart`
- Play style — `play_style_step.dart`

## Stage 5: First Challenge ✅
- 3 local questions — `first_session_challenge_step.dart`

## Stage 6: Reward Injection ✅
- 100 XP + 250 Coins — `reward_reveal_step.dart`
- Pathway unlocked (Cognition)

## Stage 7: Hub Landing ✅
- Synaptix Hub — `game_menu_screen.dart`
- Arena / Labs / Pathways via hub cards

## Stage 8: Retention Hook
- Bonus challenge — not yet implemented
- Streak system — not yet implemented

### Core Loop
Play → Reward → Unlock → Progress → Repeat

---

# 3. SYSTEM ARCHITECTURE (FRONTEND) ✅ IMPLEMENTED

## Key Providers ✅
- synaptixModeProvider — `lib/synaptix/mode/synaptix_mode_provider.dart`
- onboardingProgressProvider — `lib/game/providers/onboarding_providers.dart`
- playerProfileServiceProvider — `lib/game/providers/riverpod_providers.dart`

## Screens ✅
- SplashScreen — existing `main_splash.dart` (rebranded to Synaptix)
- IntentSelectionScreen — `intent_step.dart` (onboarding step 3)
- ModeSelectionScreen — `age_group_step.dart` (onboarding step 2, auto-maps mode)
- ProfileSetupScreen — `username_step.dart` + `avatar_step.dart`
- FirstChallengeScreen — `first_session_challenge_step.dart` (onboarding step 8)
- RewardScreen — `reward_reveal_step.dart` (onboarding step 9)
- HubScreen — `game_menu_screen.dart` (Synaptix Hub)

## Routing ✅
- GoRouter with onboarding guard — `app_router.dart`
- onboarding_complete flag — `onboarding_settings_service.dart`

---

# 4. CORE FEATURES (REBRAND SYSTEM) ✅ IMPLEMENTED (`d41391e`)

| System | Function | Status |
|------|--------|--------|
| Arena | Leaderboards & competition | ✅ Rebranded |
| Labs | Practice & mini-games | ✅ Rebranded |
| Pathways | Skill progression | ✅ Rebranded |
| Journey | Player identity | ✅ Rebranded |
| Circles | Social system | ✅ Rebranded |
| Command | Admin dashboard | ✅ Rebranded |

---

# 5. MONETIZATION ECONOMY

## USD Layer — Partially Implemented
- Coins → gameplay currency ✅ (WalletService with Hive persistence)
- Gems → premium boosts ✅ (WalletService with Hive persistence)

## Crypto Layer — Not Started
- Micro rewards (engagement)
- Weekly prize pools
- Optional staking (future)

## Backend (FastAPI) — Not Started
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

# 7. ANALYTICS SYSTEM ✅ IMPLEMENTED (`6485ad9`)

## Event Structure ✅
- synaptix_mode
- surface
- entry_point

## Key Events ✅
- hub_opened → `synaptix_hub_card_tapped`
- arena_entered → `synaptix_surface_opened` (arena)
- labs_played → `synaptix_surface_opened` (labs)
- pathway_progress → `synaptix_surface_opened` (pathways)
- `synaptix_mode_changed`, `synaptix_mode_mapped`
- `synaptix_hub_featured_match_tapped`, `synaptix_hub_action_tapped`

---

# 8. UI POLISH SYSTEM — Partially Implemented

## Design Language ✅
- Neon glass UI ✅ (GlassCard pattern in Hub)
- Frosted cards ✅ (glassmorphic featured match, daily quest)
- Glow accents ✅ (emerald glow on buttons, progress bars)

## Motion ✅
- Micro animations ✅ (pulse on featured match, ticker scroll)
- Transitions ✅ (onboarding page transitions, fade/slide)
- Progress feedback ✅ (progress bar animations, XP counters)

## Feedback — Partially Implemented
- Haptics ✅ (metallic buttons: `HapticFeedback.lightImpact()`)
- Sound cues — not yet implemented
- Visual pulses ✅ (pulse animation on play button)

---

# 9. INTERNAL SOFT LAUNCH PLAN

## Version
Synaptix v0.9.0-internal

## Validation
- Onboarding works ✅ (11-step flow with persistence)
- Hub works ✅ (premium dark design with all widgets)
- All surfaces load ✅ (Arena, Labs, Pathways, Journey, Circles, Command)
- Analytics firing ✅ (surface opened, mode changed, hub interactions)

## Acceptance Criteria
- No major bugs ✅ (Phase 7 data integrity fixes applied)
- Clear branding ✅ (FE-D2 stabilization pass complete)
- Stable navigation ✅ (all routes wired, guards in place)

---

# 10. PACKET SYSTEM SUMMARY

| Packet | Purpose | Status |
|------|--------|--------|
| A | Branding | ✅ Complete |
| B | Mode + Hub | ✅ Complete |
| C | Feature surfaces | ✅ Complete |
| D | Analytics + Stability | ✅ Complete |
| E | Optional technical rename | Deferred |

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

1. ✅ Implement Flutter onboarding system (full code) — `0a60048`
2. Build monetization backend (FastAPI) — not started
3. ✅ Implement UI polish system (animations + design system) — `3f4c65b` (partial — sound cues remaining)
4. Prepare beta launch — in progress (alpha demo phase)
5. Scale growth engine — not started

---

# FINAL NOTE

Synaptix is a platform.

Execution quality—not features—will determine success.
