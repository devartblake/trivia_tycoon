
# Synaptix Next Steps Implementation

## 1. Flutter Onboarding System ✅ COMPLETE (`0a60048`)

### Screens ✅
- SplashScreen ✅ — `main_splash.dart` (rebranded)
- IntentSelectionScreen ✅ — `intent_step.dart`
- ModeSelectionScreen ✅ — `age_group_step.dart` (auto-maps SynaptixMode)
- ProfileSetupScreen ✅ — `username_step.dart` + `avatar_step.dart`
- FirstChallengeScreen ✅ — `first_session_challenge_step.dart`
- RewardScreen ✅ — `reward_reveal_step.dart`
- HubScreen ✅ — `game_menu_screen.dart`

### Providers ✅
- synaptixModeProvider ✅ — `lib/synaptix/mode/synaptix_mode_provider.dart`
- onboardingProgressProvider ✅ — `lib/game/providers/onboarding_providers.dart`
- playerProfileServiceProvider ✅ — `lib/game/providers/riverpod_providers.dart`

### Flow Logic ✅
- onboarding_complete flag ✅ — `onboarding_settings_service.dart`
- route guards via GoRouter ✅ — `app_router.dart`

---

## 2. Monetization Economy (USD + Crypto) — Partially Implemented

### USD Layer ✅
- Coins: gameplay currency ✅ (WalletService + Hive persistence)
- Gems: premium ✅ (WalletService + Hive persistence)

### Crypto Layer — Not Started
- Micro rewards per activity
- Weekly prize pools
- Optional staking later

### Backend (FastAPI) — Not Started
- Wallet service
- Reward distribution service
- Transaction ledger

---

## 3. UI Polish System ✅ Mostly Complete (`3f4c65b`)

### Design Language ✅
- Neon glass UI ✅
- Frosted cards ✅
- Glow accents ✅

### Motion System ✅
- Micro animations ✅
- Button feedback ✅
- Progress animations ✅

### Feedback System — Partially Complete
- Haptics ✅ (metallic buttons)
- Sound cues — not yet implemented
- Visual pulses ✅ (pulse animation on play button)

---

## Final Goal
A unified system:
- Engaging onboarding ✅
- Scalable economy — partially (USD layer done, crypto/backend pending)
- High-end visual identity ✅
