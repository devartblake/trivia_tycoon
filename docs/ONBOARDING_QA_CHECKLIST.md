# Onboarding QA Checklist (Phase 5)

## Core Flow
- [ ] New account starts at `/onboarding` and lands on Welcome step.
- [ ] User can proceed through all steps and complete onboarding.
- [ ] Completion persists username, age group, country, and preferred categories.

## Skip & Resume
- [ ] Skip from any step keeps onboarding marked incomplete (`completed=false`).
- [ ] Relaunch after skip resumes at the last saved step.
- [ ] Relaunch after force-close during onboarding resumes at the last saved step.

## Guard/Redirect Behavior
- [ ] Logged-out users are redirected to `/login` from protected routes.
- [ ] Logged-in incomplete users are redirected to `/onboarding` from protected routes.
- [ ] Logged-in completed users are redirected away from onboarding-only routes.

## Regression Checks
- [ ] No redirect loops between `/`, `/onboarding`, and `/home`.
- [ ] Profile selection and avatar selection remain accessible when onboarding is incomplete.
- [ ] Onboarding completion still allows normal access to game/store/profile/leaderboard routes.

## Visual Check
- [ ] Completion step shows celebratory confetti overlay without blocking CTA interaction.


## Test Accounts
- [ ] QA-NewUser-01 (fresh account, no onboarding progress)
- [ ] QA-PartialOnboarding-01 (saved step 3, incomplete)
- [ ] QA-CompletedUser-01 (onboarding completed)
