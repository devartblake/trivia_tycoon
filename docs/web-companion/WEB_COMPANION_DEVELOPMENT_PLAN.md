# Trivia Tycoon — Web Companion App: Full Development Plan

> **Document status:** Planning  
> **Created:** 2026-06-25  
> **Branch:** `claude/react-migration-strategy-o47hu2`  
> **Scope:** React (TypeScript) web companion — not a mobile port, not a full Flutter rewrite

---

## Table of Contents

1. [Strategic Vision](#1-strategic-vision)
2. [The Skill Tree Architecture Decision](#2-the-skill-tree-architecture-decision)
3. [Platform Split — What Lives Where](#3-platform-split--what-lives-where)
4. [Tech Stack](#4-tech-stack)
5. [Monetization Architecture](#5-monetization-architecture)
6. [Exclusive Web Features](#6-exclusive-web-features)
7. [Feature Scope — In vs. Out](#7-feature-scope--in-vs-out)
8. [Technical Architecture](#8-technical-architecture)
9. [Phase-by-Phase Development Plan](#9-phase-by-phase-development-plan)
10. [Timeline Summary](#10-timeline-summary)
11. [Risk Register](#11-risk-register)
12. [Post-Launch Roadmap (v2+)](#12-post-launch-roadmap-v2)

---

## 1. Strategic Vision

### The Two-Platform Ecosystem

The web companion is **not a port** of the mobile app. It is a separate product targeting the same user base at different moments in their day:

| Dimension | Mobile App | Web Companion |
|---|---|---|
| **Session intent** | Quick play, on-the-go (5–15 min) | Deep engagement, desk (20–60 min) |
| **Primary action** | Play quizzes, use skills | Plan, compete, create, manage |
| **Monetization** | IAP via App Store / Google Play (70% revenue) | Direct Stripe payments (97% revenue) |
| **Skill tree role** | Use what's unlocked — read-only active view | Full planning, unlocking, path management |
| **Social role** | Real-time challenges, quick chat | Leagues, tournaments, clan management |
| **Content role** | Consume question packs | Create and publish question packs |
| **Exclusive hook** | Offline play, camera QR, haptics | Competitive leagues, Study Mode, content tools |

Both platforms share the same backend and the same player account. Progress, currency, XP, and unlocked skills synchronize in real time. A player buys a coin bundle on web (better margins, better deal) and spends it in the mobile app minutes later.

### Why This Works

- **Margin**: Web Stripe payments eliminate the 30% platform cut. Every $10 purchase on web generates ~$9.70 in net revenue vs. ~$7.00 via App Store. This funds the exclusive content investment.
- **Retention**: The web experience targets a different engagement loop — deep planning, competitive play, and content creation — reducing churn by giving engaged players more to do.
- **B2B channel**: Quiz Room hosting and Study Mode open an education/corporate market that the mobile app structurally cannot serve.
- **App Store independence**: Pricing changes, new monetization features, and sale events deploy instantly on web. No 7-day review delay, no 30% revenue share.

---

## 2. The Skill Tree Architecture Decision

### Recommendation: Web = Planning Hub, Mobile = Runtime Consumer

The current Flutter skill tree is the most architecturally complex UI in the entire app:
- Full honeycomb hexagon grid (`lib/ui_components/hex_grid/`) with custom `CustomPaint` rendering
- Auto-path planning via `SkillBranchPathPlanner` (DAG traversal, weighted topological sort)
- Branch detail screens with overlay painters (`AutoPathOverlayPainter`)
- 5 skill branches, 28+ skill nodes, unlock dependency graph
- Deep-link routing: `/skills`, `/skill-tree`, `/skill-branch/:branchId?step=&showPath=`
- 23 `StateProvider` buses (`game_bonus_providers.dart`) that feed live effects into `QuestionController`
- Cooldown tracking, persistence via Hive

This is ideal for web — large screen, keyboard/mouse, deliberate planning sessions. It is excessive for mobile during a quiz session.

### The Split

#### Web Companion — Full Skill Tree Management
- Complete honeycomb visualization with hover tooltips, zoom, pan
- Full unlock flow: spend XP/currency, view prerequisites, preview skill effects
- Auto-Path planning: set a goal skill, web computes the optimal unlock path, saves it
- Skill synergy viewer: shows which combinations amplify each other
- Branch-by-branch exploration with detail panels
- "Build Planner": theorycraft skill loadouts before committing XP
- Skill history log: when each node was unlocked, what it cost

#### Mobile App — Simplified Active Skills View
Replace the full skill tree screens on mobile with a single **Active Skills Panel**:
- Shows only currently unlocked and active skills
- Displays cooldown timers for skills on cooldown
- One-tap to equip/unequip skills for the next match
- Deep link to the web companion for full tree management: *"Plan your next unlock → Open Web"*
- No hexagonal rendering, no path planning, no branch navigation

#### Backend Contract (unchanged)
The backend already stores:
- Unlocked node IDs per player
- XP cost records
- Skill effect definitions

Web writes unlocks → backend stores → mobile reads and applies effects. The 23 `StateProvider` buses in `game_bonus_providers.dart` continue to work unchanged on mobile — they consume the same skill state, just without the full planning UI.

### What This Achieves

1. **Mobile app becomes simpler** — removes the most complex UI from Flutter, reduces APK/IPA size, speeds up build times
2. **Web companion has a unique anchor feature** — skill planning is a reason to open the web app even if you primarily play on mobile
3. **Engagement loop**: play on mobile → earn XP → plan upgrades on web → better performance in next mobile session
4. **Reduces Flutter regression risk** — the skill tree has known complexity debt (see `skill_tree_navigation_status.md` Known Issues #1: multiple mutable path fields in `SkillBranchDetailScreen`)

---

## 3. Platform Split — What Lives Where

### Full Feature Matrix

| Feature | Mobile (Flutter) | Web Companion | Notes |
|---|---|---|---|
| Quiz gameplay (solo) | ✅ Full | ✅ Full | Same backend, same question sets |
| Skill tree — full planning | ✅ Current (to be simplified) | ✅ **Web primary** | Mobile keeps read-only active view |
| Skill tree — active skills view | ✅ Simplified (new) | ➖ | Just unlocked + cooldown status |
| XP system | ✅ | ✅ | Shared backend |
| Leaderboard | ✅ | ✅ Full + analytics | Web adds historical charts |
| Profile & stats | ✅ | ✅ Extended | Web adds Knowledge Graph |
| Daily missions | ✅ | ✅ | Shared mission state |
| Store / shop | ✅ IAP | ✅ Stripe direct | Better pricing on web |
| In-app purchases | ✅ Apple/Google | ➖ | Web uses Stripe only |
| Spin wheel rewards | ✅ | ✅ | Same reward pool |
| Achievements / badges | ✅ | ✅ | Shared state |
| Multiplayer — live PvP | ✅ gRPC/SignalR | 🔄 v2 (async first) | Live matchmaking deferred to v2 |
| Multiplayer — async challenges | ✅ | ✅ | Same-set, play-when-ready |
| Friends + presence | ✅ | ✅ | Shared presence via SignalR |
| Direct messages | ✅ | ✅ | Same message thread |
| Group chat | ✅ | 🔄 v2 | Deferred |
| Push notifications | ✅ | ✅ Web Push API | Different delivery, same triggers |
| Onboarding | ✅ Full flow | ✅ Simplified | No biometric, no camera |
| Authentication | ✅ All methods | ✅ Email + Google | No Game Center / Play Games on web |
| Offline play | ✅ Hive-backed | ➖ | Web requires connectivity |
| Camera / QR scanning | ✅ | ➖ | Mobile exclusive |
| Haptic feedback | ✅ | ➖ | Mobile exclusive |
| Deep linking | ✅ | ✅ URL-based | Different scheme |
| Settings / preferences | ✅ | ✅ | Synced via backend |
| Synaptix age modes (theme) | ✅ | ✅ | Same theme system |
| Admin dashboard | ✅ Flutter build | ➖ Deferred | Keep on Flutter for now |
| **Seasonal leagues** | ➖ | ✅ **Web exclusive** | New feature |
| **Tournament brackets** | ➖ | ✅ **Web exclusive** | New feature |
| **Clan / guild system** | ➖ | ✅ **Web exclusive** | New feature |
| **Custom question builder** | ➖ | ✅ **Web exclusive** | New feature |
| **Quiz Room hosting** | ➖ | ✅ **Web exclusive** | New feature |
| **Knowledge Graph** | ➖ | ✅ **Web exclusive** | New feature |
| **Study Mode** | ➖ | ✅ **Web exclusive** | New feature |
| **Streamer Mode** | ➖ | ✅ **Web exclusive** | New feature |
| **Match replay viewer** | ➖ | ✅ **Web exclusive** | New feature |
| **Build Planner (skill theory)** | ➖ | ✅ **Web exclusive** | New feature |
| Mini-games / arcade | ✅ | ➖ Deferred | Low web priority |
| 3D model display | ✅ | ➖ Deferred | Three.js complexity not worth v1 |
| COPPA guardian consent | ✅ Full | ✅ Simplified | Scope to adults-only for web v1 |

---

## 4. Tech Stack

### Core Framework
| Layer | Choice | Rationale |
|---|---|---|
| Framework | **React 18 + TypeScript** | Industry standard, large ecosystem, excellent AI tooling support |
| Build tool | **Vite 5** | Fast HMR, excellent TypeScript support, smaller bundles than CRA |
| Routing | **React Router v6** | Equivalent to GoRouter; nested routes, loaders, protected routes |
| Styling | **Tailwind CSS 3 + shadcn/ui** | Design token-driven, matches Synaptix age-mode theming; shadcn for accessible base components |

### State Management
| Concern | Choice | Flutter Equivalent |
|---|---|---|
| Global app state | **Zustand** | Riverpod `StateNotifierProvider` |
| Server state + caching | **TanStack Query v5** | Riverpod async providers + Hive caching |
| Form state | **React Hook Form** | Manual state in Flutter |
| Game session state | **Zustand slices** | `game_bonus_providers.dart` StateProvider buses |

The 23 `StateProvider` buses in `game_bonus_providers.dart` map to a single Zustand `gameSessionSlice` with typed fields. The architecture is flatter in React — no provider dependency graph needed.

### Networking
| Protocol | Choice | Flutter Equivalent |
|---|---|---|
| REST API | **axios** with interceptors | `synaptix_api_client.dart` (Dio) |
| WebSocket | **native WebSocket + reconnect logic** | `ws_client.dart` |
| SignalR | **@microsoft/signalr** (official JS SDK) | `lib/core/networking/signalr/` |
| gRPC (v2) | **grpc-web** + Envoy proxy | `lib/core/networking/grpc/` |
| Auth signing | Custom axios interceptor | `encrypted_api_client.dart` |

> **gRPC decision**: Live bidirectional multiplayer streams via gRPC-web require an Envoy proxy sidecar on the backend. This is deferred to v2. All v1 real-time features use SignalR, which has a first-class JS SDK.

### Data & Storage
| Need | Choice | Flutter Equivalent |
|---|---|---|
| Local persistence | **Dexie.js** (IndexedDB) | Hive |
| Secure token storage | **Web Crypto API + sessionStorage** | `flutter_secure_storage` |
| Offline queue | **Dexie.js sync queue** | Hive offline cache |

### UI Libraries
| Component | Choice | Flutter Equivalent |
|---|---|---|
| Animations | **Framer Motion** | `flutter_animate` + `AnimationController` |
| Charts | **Recharts** | `fl_chart` |
| Hex grid (skill tree) | **react-konva** + custom SVG | `lib/ui_components/hex_grid/` (CustomPaint) |
| Audio | **Howler.js** | `just_audio` / `flutter_soloud` |
| Loading skeletons | **react-loading-skeleton** | `shimmer` |
| Confetti | **canvas-confetti** | `confetti` package |
| QR (display only) | **qrcode.react** | `qr_flutter` |
| Notifications (UI) | **react-hot-toast** | `awesome_notifications` UI layer |
| Data tables | **TanStack Table v8** | Custom ListView in Flutter |

### Payments & Auth
| Concern | Choice |
|---|---|
| Payments | **Stripe.js + React Stripe Elements** |
| Auth — email/password | Custom JWT flow (same backend) |
| Auth — Google | **@react-oauth/google** |
| Auth — session | JWT in `httpOnly` cookie or Web Crypto-encrypted sessionStorage |

### Development Tools
| Tool | Purpose |
|---|---|
| **ESLint + Prettier** | Code quality |
| **Vitest + React Testing Library** | Unit + component tests |
| **Playwright** | E2E tests (Chromium pre-installed in CI) |
| **Storybook** | Component library documentation |

---

## 5. Monetization Architecture

### Revenue Model

#### Web Pass Subscription (Stripe)
Sold directly — no platform cut. Prices can be adjusted without app store approval.

| Tier | Price | Included |
|---|---|---|
| **Free** | $0 | Core quiz, basic leaderboard, 3 async challenges/day |
| **Web Explorer** | $4.99/month | Unlimited play, web-exclusive cosmetics pack, detailed stats dashboard |
| **Web Pro** | $9.99/month | Everything above + Tournament entry, Study Mode, Custom Question Builder, 2× web currency earnings |
| **Educator** | $19.99/month | Quiz Room hosting (30 students), class analytics, question pack export, white-label room branding |

Annual plans at 20% discount are available at checkout and recommended as default.

#### Web-Exclusive Currency Bundles
Web bundles are priced more favorably than mobile IAP because the 27% margin difference (97% vs 70%) funds better rates:

| Bundle | Mobile Price | Web Price | Bonus |
|---|---|---|---|
| Starter Pack | $1.99 | $1.99 | Same |
| Value Pack | $9.99 | $8.99 | +10% coins |
| Pro Pack | $19.99 | $17.99 | +15% coins + bonus diamonds |
| Mega Pack | $49.99 | $44.99 | +20% coins + exclusive web badge |

**Cross-platform spending loop**: Buy on web (better deal) → use on mobile (anywhere). This incentivizes web-side purchases without fragmenting the economy.

#### Tournament Entry Fees
- Standard tournament: free entry for Web Pro subscribers, $0.99 for Explorer, $1.99 for Free tier
- Premium tournaments: $2.99–$4.99 entry, prize pool distributed as in-game currency
- Educator-hosted tournaments: free to run, entry fees optional (host controls)

#### B2B / Education Licensing
- **School license**: $99/year per classroom (up to 35 students), admin dashboard, progress reports
- **Team license**: $49/month per team of 10 (corporate training use case)
- Contact-sales flow for bulk deals (100+ seats)

### Payment Infrastructure
```
Stripe Customer → Stripe Subscription (Web Pass)
                → Stripe PaymentIntent (one-time purchases)
                → Stripe Checkout (bundles)

Backend webhook → update player entitlements
Backend → grant currency to shared player account
```

The backend already handles currency as a shared account balance. The only change needed is adding a `web_subscription_tier` field to the player model and Stripe customer ID storage.

---

## 6. Exclusive Web Features

These features exist only on web and create deliberate reasons to open the browser even for primarily mobile players.

### 6.1 Competitive League System
**Purpose**: Long-term retention through structured competition.

- **Season length**: 6 weeks
- **Divisions**: Bronze → Silver → Gold → Platinum → Diamond
- **Format**: Each division has up to 30 players; top 5 promote each season, bottom 5 relegate
- **Weekly matches**: 2 scheduled matches per week against division opponents (async format v1)
- **Standings table**: Live division table with W/L/D record, points, question accuracy
- **Season rewards**: Exclusive seasonal cosmetics, large currency payouts, permanent rank badge
- **Backend requirement**: New `leagues` service — assign players to divisions, track match outcomes, handle promotion/relegation at season end

### 6.2 Tournament Bracket System
**Purpose**: High-engagement events that drive weekend traffic spikes.

- **Formats**: Single elimination, double elimination, Swiss (Swiss is best for even skill distribution)
- **Size**: 8, 16, 32, or 64 player brackets
- **Entry**: Fee-based (see monetization) or free-to-enter weekly events
- **Questions**: Tournament-exclusive question packs (harder, curated)
- **Prize pool**: In-game currency + exclusive tournament champion cosmetics
- **Live bracket view**: Bracket diagram updates in real time as matches complete
- **Backend requirement**: New `tournaments` service

### 6.3 Skill Tree — Build Planner & Full Management
**Purpose**: Deep engagement hook that makes web the "home base" for progression planning.

- **Full honeycomb grid**: SVG-based hex grid using react-konva, faithful to the Flutter `hex_grid` visual
- **Drag-to-explore**: Pan and zoom the full tree, hover for skill effect previews
- **Auto-Path planner**: Input a target skill → system computes the cheapest unlock path using the same weighted DAG logic as `SkillBranchPathPlanner`
- **Build Planner mode**: Theorycraft without spending — save named builds, compare costs and effect combinations
- **Skill synergy viewer**: Highlights skills that combine multiplicatively (based on `skill_effect_handler.dart` logic)
- **Unlock history**: Timeline of when each node was unlocked, total XP spent
- **Path share**: Generate a shareable URL for a build plan (drives new user acquisition)

### 6.4 Knowledge Graph
**Purpose**: Turns quiz history into a personalized learning map.

- Visual radar/spider chart: 12 main categories on axes, filled by accuracy score
- Drill-down: click a category → subcategory breakdown → individual question history
- Weak spots panel: 5 categories where accuracy is lowest, with Study Mode links
- Trend line: accuracy improvement over time per category
- Comparison: overlay your graph against friends' graphs or top-10 leaderboard players
- **Data source**: Existing question answer history in backend; just needs a new analytics endpoint

### 6.5 Study Mode
**Purpose**: Positions the app as a learning tool — opens the education market.

- **Practice sessions**: Non-competitive quiz with unlimited time per question
- **Explanation cards**: After each question, detailed explanation of why the answer is correct (requires backend support — new `explanations` field on questions)
- **Flashcard review**: Review questions you previously answered wrong, spaced repetition scheduling (SM-2 algorithm)
- **Category deep-dive**: Study a single category until accuracy reaches a target threshold
- **Progress tracking**: Study streak separate from competitive streak, XP rewards for study sessions
- **Educator integration**: Teachers assign specific question packs; student progress visible in Educator dashboard

### 6.6 Custom Question Pack Builder
**Purpose**: Community-generated content drives session length and organic growth.

- WYSIWYG question editor: question text, 4 answer options, correct answer selection, category tag, difficulty rating, optional image upload
- Pack metadata: title, description, cover image, topic tags, age-appropriateness rating
- Preview mode: play through your own pack before publishing
- Publishing flow: packs go through a lightweight review queue (or AI-assisted content moderation) before appearing publicly
- **Marketplace**: Browse published community packs, sort by rating/plays/new; play any pack in solo or async challenge mode
- **Creator earnings**: Pack creators earn a small currency split for each play of their pack (drives creation incentive)
- **Backend requirement**: New `question_packs` service + moderation queue

### 6.7 Quiz Room Hosting
**Purpose**: Live group trivia for classrooms, teams, and events. The primary B2B feature.

- Host creates a room, gets a 6-digit join code or shareable URL
- Up to 30 participants join via browser (no account required for guests — join as display name)
- Host controls pace: show question → reveal answer → show scores → next question
- Live leaderboard visible to all participants during session
- Host can use their own question packs or any community pack
- End-of-session report: per-player scores, fastest answers, most improved — exportable as PDF/CSV
- Educator plan: persistent rooms (bookmark and reuse), class roster tracking, session history
- **Backend requirement**: New `rooms` service with WebSocket presence for live sync

### 6.8 Competitive Analytics Dashboard
**Purpose**: Gives serious players the depth they can't get on mobile.

- Match history: searchable, filterable table of all past matches (win/loss, opponent, score, category breakdown)
- Response time analytics: are you slow on Science? Fast on Pop Culture? Visualized per category
- Win rate trends: 7-day, 30-day, all-time graphs
- Head-to-head record: track your record vs. specific opponents
- Rating progression chart: your skill rating over time
- Season performance summary: how each competitive season ended

### 6.9 Streamer Mode
**Purpose**: Content creator acquisition channel — streamers are free marketing.

- Toggle in settings: enables a clean, overlay-friendly layout variant
- Minimal UI: large question text, oversized timer, high-contrast answer buttons — easy to read on stream
- Custom stream widget (separate URL/iframe): embeddable current-score + timer widget for OBS/Streamlabs overlays
- Hide-earnings toggle: optionally hide currency and balance from stream view
- Clip-friendly: question reveal → answer reveal → score update animations are deliberately paced for stream reaction content

### 6.10 Web-Exclusive Cosmetics
**Purpose**: Status signaling, drives web adoption.

- **Web Pioneer badge**: given to first 10,000 registered web accounts — permanent, visible on profile everywhere including mobile
- **Seasonal web frames**: exclusive profile frames only obtainable via web seasonal league participation
- **Tournament champion titles**: "Season 3 Diamond Champion" title shown in all platforms
- **Content Creator badge**: awarded to question pack authors with 1,000+ plays
- **Web subscriber cosmetics**: monthly exclusive cosmetic item for active Web Pro subscribers

---

## 7. Feature Scope — In vs. Out

### v1 Launch Scope (Months 1–7)

#### In
- Authentication (email + Google)
- Home dashboard
- Solo quiz gameplay — full question engine, timers, scoring, XP
- Skill tree — full planning hub (web primary)
- Leaderboard — global + tier breakdown
- Profile with Knowledge Graph (basic version)
- Daily missions + streak
- Store with Stripe (Web Pass tiers + currency bundles)
- Daily reward spin wheel
- Achievements / badges
- Async multiplayer challenges
- Friends list + online presence (SignalR)
- Direct messages
- Push notifications (Web Push API)
- Settings + Synaptix age-mode theming
- Seasonal leagues (basic — single active season)
- Study Mode (basic — practice + explanation cards)
- Web-exclusive cosmetics set 1

#### Out of v1 (Deferred to v2+)
- Live real-time PvP matchmaking (gRPC-web)
- Tournament bracket system
- Custom question pack builder + marketplace
- Quiz Room hosting
- Clan / guild system
- Group chat
- Streamer mode
- 3D model display
- Admin dashboard
- Arcade / mini-games
- Match replay viewer
- Full build planner with path sharing
- B2B education licensing flow (Educator tier is available but no dedicated dashboard yet)

---

## 8. Technical Architecture

### Project Structure

```
web-companion/
├── public/
├── src/
│   ├── app/                    # App shell, routing, providers
│   │   ├── App.tsx
│   │   ├── router.tsx          # React Router v6 config
│   │   └── providers.tsx       # QueryClient, auth, theme
│   │
│   ├── core/                   # Infrastructure (mirrors lib/core/)
│   │   ├── api/
│   │   │   ├── client.ts       # Axios instance + interceptors (port of synaptix_api_client.dart)
│   │   │   ├── auth.ts         # JWT handling, refresh logic
│   │   │   └── endpoints.ts    # API route constants
│   │   ├── realtime/
│   │   │   ├── signalr.ts      # SignalR hub connections
│   │   │   └── presence.ts     # Friend presence tracking
│   │   ├── storage/
│   │   │   ├── db.ts           # Dexie.js schema (replaces Hive)
│   │   │   └── secure.ts       # Web Crypto token storage
│   │   ├── env.ts              # import.meta.env config (mirrors lib/core/env.dart)
│   │   └── config.ts           # App constants
│   │
│   ├── stores/                 # Zustand state (replaces Riverpod providers)
│   │   ├── authStore.ts        # auth_providers.dart equivalent
│   │   ├── profileStore.ts     # profile_providers.dart equivalent
│   │   ├── gameSessionStore.ts # game_bonus_providers.dart (23 buses → typed slice)
│   │   ├── uiStore.ts          # Theme, sidebar, modals
│   │   └── index.ts
│   │
│   ├── features/               # Feature modules (each = one major screen/domain)
│   │   ├── auth/
│   │   │   ├── components/
│   │   │   ├── hooks/
│   │   │   └── pages/
│   │   ├── dashboard/          # Home screen
│   │   ├── quiz/               # Question engine
│   │   │   ├── engine/         # Core game loop logic (port of question_controller.dart)
│   │   │   ├── components/
│   │   │   └── hooks/
│   │   ├── skill-tree/         # Full planning hub
│   │   │   ├── hex-grid/       # SVG/Konva hex grid (port of lib/ui_components/hex_grid/)
│   │   │   ├── planner/        # Build planner + auto-path
│   │   │   └── components/
│   │   ├── leaderboard/
│   │   ├── profile/
│   │   │   ├── knowledge-graph/
│   │   │   └── analytics/
│   │   ├── store/              # Stripe-integrated shop
│   │   ├── missions/
│   │   ├── social/
│   │   │   ├── friends/
│   │   │   ├── messages/
│   │   │   └── challenges/
│   │   ├── leagues/            # Web-exclusive
│   │   └── study/              # Web-exclusive
│   │
│   ├── components/             # Shared UI component library
│   │   ├── ui/                 # shadcn/ui base components
│   │   ├── game/               # Game-specific components
│   │   │   ├── QuestionCard/
│   │   │   ├── AnswerButton/
│   │   │   ├── TimerBar/
│   │   │   └── ScoreDisplay/
│   │   ├── layout/
│   │   │   ├── AppShell/
│   │   │   ├── Sidebar/
│   │   │   └── TopBar/
│   │   └── shared/
│   │       ├── XPBar/
│   │       ├── AvatarBadge/
│   │       ├── SpinWheel/
│   │       ├── ConfettiOverlay/
│   │       └── SkeletonLoader/
│   │
│   ├── hooks/                  # Shared React hooks
│   │   ├── useAuth.ts
│   │   ├── useGameSession.ts
│   │   ├── useSignalR.ts
│   │   ├── useWebPush.ts
│   │   └── useStripe.ts
│   │
│   ├── lib/                    # Pure utilities
│   │   ├── crypto.ts           # Port of crypto-related helpers
│   │   ├── xp.ts               # XP calculation (port of xp_service.dart)
│   │   ├── scoring.ts          # Score calculations
│   │   └── skillEffects.ts     # Skill effect application (port of skill_effect_handler.dart)
│   │
│   └── assets/                 # Static assets
│       ├── images/
│       ├── audio/
│       └── icons/
│
├── .env.local
├── .env.staging
├── .env.production
├── vite.config.ts
├── tailwind.config.ts
├── tsconfig.json
└── package.json
```

### State Architecture — Riverpod → Zustand Mapping

The 80+ Riverpod provider files collapse into a smaller number of Zustand stores because TanStack Query handles all async/server state:

```
Riverpod AsyncProvider (API call)    → TanStack Query useQuery
Riverpod StateNotifierProvider       → Zustand store slice
Riverpod Provider (dependency)       → Zustand computed / TanStack Query selector
game_bonus_providers.dart (23 buses) → gameSessionStore typed fields
xp_provider.dart                     → profileStore.xp
auth_providers.dart                  → authStore
theme_notifier.dart                  → uiStore.theme
```

### Environment Configuration

Mirrors the existing multi-environment system in `lib/core/env.dart`:

```typescript
// src/core/env.ts
export const env = {
  apiUrl: import.meta.env.VITE_API_URL,
  wsUrl: import.meta.env.VITE_WS_URL,
  signalrUrl: import.meta.env.VITE_SIGNALR_URL,
  stripePublishableKey: import.meta.env.VITE_STRIPE_KEY,
  complianceUrl: import.meta.env.VITE_COMPLIANCE_URL,
};
```

Files: `.env.local`, `.env.staging`, `.env.production` — same structure as existing Flutter env files.

### Routing Architecture

```typescript
// Mirrors GoRouter structure from lib/core/router/
/                         → Dashboard (auth required)
/login                    → LoginPage
/play                     → QuizLobby
/play/:sessionId          → QuizSession (active game)
/skills                   → SkillTreeHub
/skills/:branchId         → SkillBranchDetail
/skills/planner           → BuildPlanner (web exclusive)
/leaderboard              → LeaderboardPage
/leaderboard/:tier        → TierLeaderboard
/profile                  → MyProfile
/profile/:userId          → PublicProfile
/profile/knowledge-graph  → KnowledgeGraph (web exclusive)
/store                    → Store
/missions                 → Missions
/friends                  → FriendsList
/messages                 → MessagesList
/messages/:threadId       → MessageThread
/challenges               → ChallengesList
/leagues                  → LeagueHub (web exclusive)
/leagues/:seasonId        → SeasonDivision (web exclusive)
/study                    → StudyMode (web exclusive)
/settings                 → Settings
```

---

## 9. Phase-by-Phase Development Plan

> **AI-assisted solo development**: All phases assume 1 human developer + AI pair programming (Claude, Copilot, Cursor). AI handles boilerplate, repetitive patterns, and test generation. Human handles architecture decisions, complex debugging, security review, and QA.

---

### Phase 1 — Foundation (Weeks 1–4)
**Goal**: A running app that can authenticate and make API calls. Nothing is playable yet.

#### Week 1–2: Project Scaffold & Infrastructure
- [ ] Initialize Vite + React + TypeScript project
- [ ] Configure Tailwind CSS + shadcn/ui base components
- [ ] Set up ESLint + Prettier + Husky pre-commit hooks
- [ ] Configure multi-environment `.env` files (local/staging/production)
- [ ] Create `src/core/env.ts` config (mirrors `lib/core/env.dart`)
- [ ] Set up React Router v6 with shell layout (protected + public routes)
- [ ] Set up Zustand store structure (`authStore`, `uiStore`, `profileStore`)
- [ ] Set up TanStack Query with default config (stale times, retry logic)
- [ ] Configure Vitest + React Testing Library

#### Week 3: API Client & Auth
- [ ] Port `synaptix_api_client.dart` → `src/core/api/client.ts` (Axios with interceptors)
- [ ] Implement JWT storage using Web Crypto API (port `flutter_secure_storage` logic)
- [ ] Implement token refresh interceptor (matches existing backend contract)
- [ ] Email/password login + registration flows
- [ ] Google Sign-In via `@react-oauth/google`
- [ ] Auth persistence (remember me, session restore)
- [ ] Protected route guard component

#### Week 4: Dexie.js Storage & SignalR
- [ ] Define Dexie.js schema (port Hive type adapters — player profile, settings, cached leaderboard)
- [ ] Implement `src/core/storage/db.ts` with typed tables
- [ ] Set up SignalR connection using `@microsoft/signalr` (port `lib/core/networking/signalr/`)
- [ ] Implement presence tracking hub
- [ ] Set up Web Push notifications (VAPID key registration, subscription management)
- [ ] Basic app shell layout (sidebar, top bar, content area)

**Phase 1 Deliverable**: Auth flows work, API client connected to staging backend, skeleton app shell renders.

---

### Phase 2 — Core Game & State (Weeks 5–8)
**Goal**: A player can log in and complete a full quiz session.

#### Week 5: Game Session Store & Question Engine
- [ ] Port `game_bonus_providers.dart` (23 StateProviders) → `gameSessionStore.ts` Zustand slice
- [ ] Port `question_controller.dart` → `src/features/quiz/engine/questionEngine.ts`
- [ ] Port `skill_effect_handler.dart` → `src/lib/skillEffects.ts` (28+ skill effects)
- [ ] Port `power_up_effect_applier.dart` → `src/lib/powerUpEffects.ts`
- [ ] Port `xp_service.dart` → `src/lib/xp.ts` + profileStore XP slice
- [ ] Implement score calculation and streak logic

#### Week 6: Quiz UI
- [ ] `QuestionCard` component (question text, category badge, difficulty indicator)
- [ ] `AnswerButton` component (with reveal animation — correct/wrong states using Framer Motion)
- [ ] `TimerBar` component (animated countdown, matches existing visual)
- [ ] `ScoreDisplay` component (live score, streak counter)
- [ ] `QuizSession` page — assembles all components, connects to `questionEngine`
- [ ] Question fetch + session initialization (calls existing backend question endpoints)
- [ ] Session complete flow → score summary → XP awarded

#### Week 7: XP, Missions & Daily Systems
- [ ] XP bar component with glow animation (Framer Motion)
- [ ] Level-up celebration overlay (canvas-confetti)
- [ ] Daily missions panel (fetch, display progress, complete trigger)
- [ ] Streak counter + streak protection display
- [ ] Daily reward spin wheel (port `lib/ui_components/spin_wheel/` using CSS + Framer Motion)

#### Week 8: Leaderboard & Profile Core
- [ ] Global leaderboard page with tier breakdown
- [ ] Auto-scroll to current player's rank
- [ ] Player rank card (avatar, level, XP, tier badge)
- [ ] My Profile page (stats, level, streak, achievement grid)
- [ ] Public profile page (`/profile/:userId`)
- [ ] Avatar display component

**Phase 2 Deliverable**: Full solo quiz gameplay loop is functional end-to-end.

---

### Phase 3 — Skill Tree Hub (Weeks 9–11)
**Goal**: The signature web-exclusive feature — full skill tree planning.

#### Week 9: Hex Grid Foundation
- [ ] Port `lib/ui_components/hex_grid/` hex geometry math to TypeScript utilities
- [ ] Build SVG-based hex grid renderer using react-konva (axial coordinate system)
- [ ] Implement zoom + pan controls (pinch-zoom on trackpad, scroll wheel)
- [ ] Render all 5 skill branches with correct node positions
- [ ] Node state rendering: locked (greyed), available (highlighted), unlocked (glowing)
- [ ] Directed edges between nodes (prerequisite connections)

#### Week 10: Skill Interactions
- [ ] Hover tooltip: skill name, effect description, XP cost, prerequisite chain
- [ ] Click to inspect: right-panel detail view (full skill info, effect preview)
- [ ] Unlock flow: confirm modal → API call → optimistic UI update → XP deduction
- [ ] Insufficient XP state: disable unlock button, show XP needed
- [ ] Port `SkillBranchPathPlanner` DAG traversal → TypeScript (weighted topological sort)
- [ ] Auto-Path UI: select target node → system highlights recommended unlock sequence

#### Week 11: Build Planner
- [ ] Build Planner mode toggle (read-only theorycrafting, no real XP spent)
- [ ] Save named builds to Dexie.js local storage
- [ ] Compare builds side-by-side (cost difference, effect stack comparison)
- [ ] Skill synergy highlighting (show which active combinations are multiplicative)
- [ ] Shareable build URL (encode build state in URL params)
- [ ] Unlock history tab (timeline of unlocked nodes, XP spent per unlock)

**Phase 3 Deliverable**: Skill tree hub is fully functional and differentiated from the mobile experience.

---

### Phase 4 — Monetization & Store (Weeks 12–13)
**Goal**: Revenue-generating features live.

#### Week 12: Stripe Integration
- [ ] Install `@stripe/stripe-js` + `@stripe/react-stripe-js`
- [ ] Web Pass subscription flow (Stripe Checkout for subscription tiers)
- [ ] Currency bundle one-time purchase flow (Stripe PaymentIntent)
- [ ] Backend webhook handler (Stripe → update player entitlements) — coordinate with backend team
- [ ] Subscription management page (current tier, cancel, upgrade/downgrade)
- [ ] Purchase confirmation + currency grant animation

#### Week 13: Store Page
- [ ] Store layout: featured items, currency bundles, Web Pass upsell
- [ ] Currency balance display (coins + diamonds, synced from backend)
- [ ] In-app cosmetics purchase (profile frames, badges — no Stripe, use in-game currency)
- [ ] Web-exclusive bundle labeling ("Best value on Web")
- [ ] Purchase history page

**Phase 4 Deliverable**: Full monetization path live. Players can subscribe and purchase.

---

### Phase 5 — Social & Async Multiplayer (Weeks 14–16)
**Goal**: Social layer complete; players can challenge each other.

#### Week 14: Friends & Presence
- [ ] Friends list with online/offline presence (SignalR real-time updates)
- [ ] Add friend by username / player ID
- [ ] Friend request send/accept/reject flow
- [ ] Friend profile quick-view panel
- [ ] Online friends sidebar widget on dashboard

#### Week 15: Async Challenges
- [ ] Challenge creation: pick opponent, pick category, set round count
- [ ] Challenge notification (Web Push + in-app bell)
- [ ] Accept challenge → play the same question set
- [ ] Challenge result: both scores revealed, winner declared, XP awarded
- [ ] Challenge history / pending challenges inbox

#### Week 16: Messages & Notifications
- [ ] Direct message thread list
- [ ] Message thread view with real-time delivery (SignalR)
- [ ] Notification center (in-app bell, full notification list)
- [ ] Notification preferences settings (which events trigger Web Push)
- [ ] Mark-as-read, clear all

**Phase 5 Deliverable**: Full social loop functional — friends, challenges, messaging.

---

### Phase 6 — Web-Exclusive: Leagues & Study Mode (Weeks 17–19)
**Goal**: Flagship exclusive features ship. These are the primary web differentiators.

#### Week 17: Seasonal League System
- [ ] League hub page (current season info, your division, standings)
- [ ] Division standings table (W/L/D, points, rank within division)
- [ ] Scheduled match view (your upcoming opponents this week)
- [ ] Match challenge initiation (async format — play before deadline)
- [ ] Season countdown timer
- [ ] Promotion/relegation indicators
- [ ] Season rewards preview

#### Week 18: Study Mode
- [ ] Practice mode quiz (unlimited time, no scoring pressure)
- [ ] Explanation card reveal after each question (requires backend `explanations` field)
- [ ] Missed questions bank (Dexie.js local queue)
- [ ] Flashcard review session (SM-2 spaced repetition scheduler)
- [ ] Category selector for targeted study
- [ ] Study streak + study XP rewards
- [ ] Study progress dashboard (accuracy improvement charts)

#### Week 19: Knowledge Graph
- [ ] Radar chart with 12 category axes (Recharts)
- [ ] Per-category drill-down (click → subcategory breakdown → question history)
- [ ] Weak spots panel with Study Mode CTAs
- [ ] Accuracy trend line (30-day rolling average per category)
- [ ] Friend comparison overlay (your graph vs. a friend's)

**Phase 6 Deliverable**: Core web exclusives live. This is what makes the web companion worth opening.

---

### Phase 7 — Polish, Performance & Launch (Week 20–24)
**Goal**: Production-ready, performant, tested.

#### Weeks 20–21: QA & Polish
- [ ] Comprehensive Playwright E2E test suite for golden paths
- [ ] Vitest unit test coverage for all game engine logic (target 80%)
- [ ] Responsive design audit (1280px, 1440px, 1920px breakpoints + tablet 768px)
- [ ] Cross-browser testing (Chrome, Firefox, Safari, Edge)
- [ ] Audio integration (Howler.js for answer sound effects, background music)
- [ ] Framer Motion animation pass (ensure all key interactions have appropriate transitions)
- [ ] Loading state audit (all async operations have skeleton loaders)
- [ ] Error boundary implementation for all feature modules
- [ ] 404 / empty state pages

#### Weeks 22–23: Performance
- [ ] Lighthouse audit — target 90+ performance score
- [ ] Code splitting by route (React.lazy + Suspense)
- [ ] Asset optimization (image compression, WebP conversion, lazy loading)
- [ ] TanStack Query cache tuning (stale times per query type)
- [ ] Bundle analysis (Rollup visualizer) — identify and address large chunks
- [ ] Web Vitals instrumentation (LCP, CLS, FID)
- [ ] CDN configuration for static assets

#### Week 24: Launch Preparation
- [ ] Production environment variables verified
- [ ] Stripe production keys + webhook endpoints configured
- [ ] SignalR production endpoint smoke tests
- [ ] CORS configuration for production domain
- [ ] Cookie/session security audit (httpOnly, SameSite, Secure flags)
- [ ] CSP (Content Security Policy) headers configured
- [ ] Privacy policy + terms of service pages
- [ ] GDPR consent banner (if targeting EU users)
- [ ] Analytics instrumentation (page views, funnel events)
- [ ] CI/CD pipeline (GitHub Actions → build → deploy to hosting)
- [ ] Rollback plan documented

**Phase 7 Deliverable**: Production launch.

---

## 10. Timeline Summary

### With AI-Assisted Solo Development (1 Developer)

| Phase | Duration | Key Milestone |
|---|---|---|
| Phase 1 — Foundation | Weeks 1–4 | Auth working, API connected |
| Phase 2 — Core Game | Weeks 5–8 | Full solo quiz loop playable |
| Phase 3 — Skill Tree Hub | Weeks 9–11 | Signature feature complete |
| Phase 4 — Monetization | Weeks 12–13 | Revenue live |
| Phase 5 — Social | Weeks 14–16 | Friends + challenges complete |
| Phase 6 — Web Exclusives | Weeks 17–19 | Leagues + Study Mode + Knowledge Graph |
| Phase 7 — Launch | Weeks 20–24 | Production launch |

**Total: ~24 weeks (6 months)**

### Effort Breakdown by Category

| Category | AI Acceleration | Estimated Time |
|---|---|---|
| Boilerplate / scaffold | 85% faster | ~1 week |
| UI components (straightforward) | 70% faster | ~3 weeks |
| API client / networking | 55% faster | ~2 weeks |
| State management migration | 60% faster | ~2 weeks |
| Game engine logic | 35% faster | ~3 weeks |
| Skill tree hex grid (complex) | 35% faster | ~3 weeks |
| Stripe / payments | 55% faster | ~1.5 weeks |
| Social / real-time | 40% faster | ~3 weeks |
| Web-exclusive features (new) | 50% faster | ~3 weeks |
| QA / Polish / Launch prep | 50% faster | ~5 weeks |

### Key Dates (Starting 2026-07-01)

| Milestone | Target Date |
|---|---|
| Foundation complete | 2026-07-28 |
| Core quiz loop playable (internal preview) | 2026-08-25 |
| Skill tree hub complete | 2026-09-15 |
| Monetization live (staging) | 2026-09-29 |
| Social + challenges complete | 2026-10-20 |
| Web exclusives complete | 2026-11-10 |
| **Production launch** | **2026-12-08** |

> A December launch captures holiday traffic and positions the platform for New Year engagement campaigns ("new year, new skill tree build").

### First Shippable Build
At the end of Phase 2 (~Week 8 / September 2026), there is a complete, functional web app with:
- Auth, quiz gameplay, leaderboard, profile, XP, missions
This could be released as a private beta / early access for community feedback while Phases 3–7 continue.

---

## 11. Risk Register

| Risk | Likelihood | Impact | Mitigation |
|---|---|---|---|
| **Backend API changes break web client** | Medium | High | Version the API; run web client against staging backend throughout development |
| **gRPC-web proxy not available for live multiplayer** | High | Medium | Explicitly defer live PvP to v2; use SignalR for all v1 real-time needs |
| **Skill tree hex grid math is complex to port** | High | Medium | Allocate 3 weeks; port gradually, test each layer independently |
| **Stripe webhook reliability** | Low | High | Implement idempotent webhook handlers; add webhook event log in admin |
| **Web Push browser support gaps (Safari < 16.4)** | Medium | Low | Gracefully degrade to in-app bell notification only; Web Push is enhancement not requirement |
| **SignalR scaling on web traffic spike** | Low | High | Backend concern, but document and flag to backend team before launch |
| **Explanation cards missing from question data** | High | Medium | Study Mode launches in "practice only" mode (no explanations) if backend field not ready; degrade gracefully |
| **Scope creep from web-exclusive features** | High | Medium | Strictly track v1 scope; all requests for new features go to v2 backlog |
| **Solo dev burnout at 6 months** | Medium | High | Enforce scope discipline; resist adding features mid-phase; build only what's in scope |
| **AI-generated code quality in security-sensitive areas** | Medium | High | Human reviews all auth, crypto, and payment code personally; never ship AI-generated security code without line-by-line audit |

---

## 12. Post-Launch Roadmap (v2+)

These features are scoped out of v1 but have clear paths forward once the foundation is stable:

### v2 (Months 7–10 post-launch)
- **Live real-time PvP** — gRPC-web with Envoy proxy; head-to-head matching
- **Tournament bracket system** — single/double elimination, Swiss format, prize pools
- **Custom question pack builder** — WYSIWYG editor, pack publishing, community marketplace
- **Quiz Room hosting** — live group trivia for classrooms and events, Educator dashboard
- **Group chat** — port from Flutter `group_chat/` feature
- **Match replay viewer** — question-by-question match history with timeline playback

### v3 (Months 11–14 post-launch)
- **Clan / guild system** — team formation, clan leaderboards, team vs. team leagues
- **Streamer Mode** — OBS overlay widget, stream-friendly UI variant
- **Creator earnings** — currency split for popular question pack authors
- **Admin dashboard** — port from Flutter `admin/` module
- **Arcade mini-games** — web-optimized versions of top-performing mini-games
- **B2B education portal** — dedicated teacher/admin interface, class management, LMS integrations

### Mobile App Changes (Parallel Track)
As the web companion ships, the Flutter mobile app should be updated to:
- [ ] Replace full skill tree screens with simplified Active Skills Panel
- [ ] Add "Plan in Web" deep link from the mobile active skills view
- [ ] Add web-exclusive cosmetics display (so they're visible everywhere even if only earnable on web)
- [ ] Update store to surface the "Better deals on web" messaging for currency bundles
- [ ] Add cross-promotion banner: "New: Leagues & Study Mode — web.synaptixplay.com"

---

## Appendix: Flutter → React Quick Reference

| Flutter / Dart | React / TypeScript |
|---|---|
| `StatefulWidget` | Function component + `useState` |
| `ConsumerWidget` (Riverpod) | Component using Zustand `useStore` |
| `AsyncValue<T>` | `{ data, isLoading, error }` from TanStack Query |
| `ref.watch(provider)` | `useQuery()` or `useStore(selector)` |
| `ref.read(provider.notifier)` | `useStore(s => s.action)` |
| `GoRouter` navigation | `useNavigate()` / `<Link>` |
| `BuildContext` | React context / props |
| `CustomPaint` | `<canvas>` / react-konva `<Stage>` |
| `AnimatedContainer` | Framer Motion `<motion.div>` |
| `FutureBuilder` | TanStack Query `useQuery` |
| `StreamBuilder` | `useEffect` + SignalR subscription |
| `Hive.box<T>()` | `db.table<T>` (Dexie.js) |
| `flutter_secure_storage` | Web Crypto API encrypted storage |
| `SharedPreferences` | `localStorage` / Dexie.js settings table |
| `Provider` (DI) | React Context / module singleton |
| `flutter_animate` | Framer Motion variants / transitions |
| `fl_chart` | Recharts |
| `shimmer` | react-loading-skeleton |
| `just_audio` | Howler.js |
| `awesome_notifications` | Web Push API + react-hot-toast |
| `url_launcher` | `window.open()` / `<a target="_blank">` |
| `package_info_plus` | `import.meta.env.VITE_APP_VERSION` |
| `connectivity_plus` | `navigator.onLine` + `online`/`offline` events |
