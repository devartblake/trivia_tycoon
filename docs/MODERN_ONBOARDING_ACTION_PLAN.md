# Modern Onboarding System: Actionable Update Plan

## Source Located
The modern onboarding specification file is:
- `docs/MODERN_ONBOARDING_README.md`

---

## What We Need to Fix First (Current Gaps)

1. **Documentation-to-code naming drift**
   - The README references `modern_onboarding_screen.dart` and `modern_onboarding_controller.dart`, while the implemented files are currently `onboarding_screen.dart` and `onboarding_controller.dart`.
   - This makes implementation onboarding and maintenance error-prone.

2. **Onboarding state is fragmented across multiple layers**
   - `OnboardingSettingsService` persists only a single completion flag.
   - `onboarding_providers.dart` includes additional intro/profile states that are currently in-memory placeholders.
   - There are multiple onboarding keys/services in settings-related code paths, increasing risk of inconsistent user routing.

3. **Completion payload is only partially persisted**
   - `OnboardingScreen._handleCompletion()` saves username/age/country, but category persistence is still commented out.
   - Step completion and backend/profile synchronization are therefore incomplete.

4. **No explicit verification matrix for onboarding flow quality**
   - We need deterministic checks for first launch, skip flow, resume flow, back navigation, and post-completion routing.

---

## Implementation Plan (Prioritized)

## Phase 1 — Stabilize contract and naming (1 day)

### Tasks
- [x] Define a single naming convention for the module: keep `OnboardingScreen` and `OnboardingController` for transition stability.
- [x] Update `docs/MODERN_ONBOARDING_README.md` file paths and integration snippets to match the real implementation.
- [x] Add a short architecture section documenting:
  - source of truth for onboarding state
  - persistence mechanism
  - route decision points (`/splash`, `/onboarding`, `/`)

### Acceptance Criteria
- README paths match real files exactly.
- A new engineer can follow docs without guessing file names.

---

## Phase 2 — Consolidate onboarding state model (1–2 days)

### Tasks
- [x] Introduce a single persisted onboarding state object (`OnboardingProgress`) with fields:
  - `completed: bool`
  - `currentStep: int`
  - `username`, `ageGroup`, `country`, `categories`
  - `lastUpdatedAt`
- [x] Refactor `OnboardingSettingsService` to read/write this model instead of only one boolean.
- [x] Replace placeholder `StateProvider` values in `onboarding_providers.dart` with values derived from the persisted model.
- [x] Normalize storage keys to avoid dual keys like `onboarding_completed` vs `onboarding_complete`.

### Acceptance Criteria
- One persisted source of truth is used for onboarding decisions.
- No duplicate onboarding completion keys remain.

---

## Phase 3 — Complete data persistence and submit behavior (1 day)

### Tasks
- [x] Implement category persistence in profile/settings service (uncomment and wire category save path).
- [x] Ensure “Skip” captures explicit partial state (e.g., `completed=false`, `currentStep`, timestamp).
- [x] Add recovery behavior: if user returns and onboarding is incomplete, reopen at the last unfinished step.
- [x] Add defensive validation before completion submit (non-empty required fields or explicit skip policy).

### Acceptance Criteria
- Full profile payload is persisted after completion.
- Resume behavior works for interrupted onboarding sessions.

---

## Phase 4 — Harden routing and guard behavior (1 day)

### Tasks
- [x] Audit splash/router guards to ensure consistent behavior across:
  - logged out
  - logged in + never onboarded
  - logged in + partially onboarded
  - logged in + completed onboarding
- [x] Centralize guard logic so only one place determines onboarding redirect policy.
- [x] Add telemetry/log events for guard decisions for debugging.

### Acceptance Criteria
- Route outcomes are deterministic and consistent for all user states.
- No redirect loops between `/splash`, `/onboarding`, and home.

---

## Phase 5 — Testing and release readiness (1–2 days)

### Tasks
- [x] Add unit tests for onboarding controller step transitions and validation boundaries.
- [x] Add service tests for onboarding persistence serialization/deserialization.
- [x] Add widget/integration tests for:
  - complete flow
  - skip flow
  - relaunch-resume flow
  - post-completion app entry
- [x] Add manual QA checklist in docs with expected outcomes and test accounts.

### Acceptance Criteria
- Automated tests cover critical onboarding transitions.
- QA checklist passes before release.

---

## Suggested Delivery Order
1. Phase 1 (contract/naming)
2. Phase 2 (state consolidation)
3. Phase 3 (data persistence completion)
4. Phase 4 (routing guard hardening)
5. Phase 5 (testing and rollout)

---

## Definition of Done
- Onboarding docs and implementation are aligned.
- One persisted onboarding model drives providers and routing.
- Completion and skip states both persist reliably.
- Categories and profile fields are saved end-to-end.
- Tests verify core flow transitions and prevent regressions.
