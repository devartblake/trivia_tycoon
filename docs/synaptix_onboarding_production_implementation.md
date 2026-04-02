# Synaptix Onboarding Production Implementation Pack
## Based on analysis of uploaded `lib (2).zip`

## 1. Analysis summary

I reviewed the uploaded frontend ZIP and the current onboarding stack is already more advanced than a typical placeholder flow.

### What already exists
- `lib/screens/onboarding/onboarding_screen.dart`
  - multi-step onboarding using `ModernOnboardingController`
  - persisted progress restore
  - completion handling
  - progress bar + skip/back flow
- existing steps:
  - `welcome_step.dart`
  - `username_step.dart`
  - `age_group_step.dart`
  - `country_step.dart`
  - `categories_step.dart`
  - `avatar_step.dart`
  - `completion_step.dart`
- persistence:
  - `OnboardingSettingsService`
  - `OnboardingProgressNotifier`
  - `onboardingCompleteProvider`
- routing:
  - `/onboarding` already exists in `lib/core/navigation/app_router.dart`
- bootstrap:
  - `main.dart` already loads age group and derives `SynaptixMode`
- Synaptix foundation already exists:
  - `lib/synaptix/mode/...`
  - `lib/synaptix/theme/...`
  - `lib/synaptix/widgets/...`
- profile service already has additive keys for:
  - `synaptixMode`
  - `preferredHomeSurface`
  - `reducedMotion`
  - `tonePreference`

## 2. Most important implementation conclusion ✅ FOLLOWED

Do **not** replace the existing onboarding system.

The correct production-ready path is to **evolve the existing onboarding flow** into a Synaptix-first flow by:
- keeping the current controller + persistence pattern
- inserting Synaptix-specific steps
- extending persisted onboarding state
- adding a first-session challenge + reward sequence
- using the existing Synaptix mode system instead of inventing a second one

That is lower risk and fits your current codebase.

---

## 3. Production-ready target onboarding flow ✅ IMPLEMENTED (`0a60048`)

This should become the new Synaptix onboarding order:

1. Welcome
2. Username
3. Age Group
4. Intent Selection
5. Play Style
6. Country
7. Categories
8. Avatar
9. First Session Challenge
10. Reward Reveal
11. Completion / Hub Handoff

### Why this order
- preserve your working identity setup early
- add Synaptix differentiation before the user reaches the end
- move the “experience moment” into onboarding
- land the user in Hub with earned progress rather than only profile completion

---

## 4. Files to keep, extend, or add

## Keep and extend
- `lib/screens/onboarding/onboarding_screen.dart`
- `lib/game/controllers/onboarding_controller.dart`
- `lib/game/providers/onboarding_providers.dart`
- `lib/core/services/settings/onboarding_settings_service.dart`
- `lib/core/services/settings/player_profile_service.dart`

## Add new onboarding steps
- `lib/screens/onboarding/steps/intent_step.dart`
- `lib/screens/onboarding/steps/play_style_step.dart`
- `lib/screens/onboarding/steps/first_session_challenge_step.dart`
- `lib/screens/onboarding/steps/reward_reveal_step.dart`

## Optional helper additions
- `lib/screens/onboarding/models/onboarding_intent.dart`
- `lib/screens/onboarding/models/onboarding_play_style.dart`
- `lib/screens/onboarding/widgets/onboarding_step_shell.dart`

---

## 5. Exact state model additions

## 5.1 Extend `OnboardingProgress`
File:
- `lib/core/services/settings/onboarding_settings_service.dart`

### Add fields
```dart
final String? intent;
final String? playStyle;
final String? synaptixMode;
final bool hasCompletedFirstChallenge;
final bool hasSeenRewardReveal;
```

### Update:
- constructor
- `copyWith`
- `toMap`
- `fromMap`

### Suggested implementation shape
```dart
const OnboardingProgress({
  this.completed = false,
  this.hasSeenIntro = false,
  this.hasCompletedProfile = false,
  this.currentStep = 0,
  this.username,
  this.ageGroup,
  this.country,
  this.categories = const <String>[],
  this.intent,
  this.playStyle,
  this.synaptixMode,
  this.hasCompletedFirstChallenge = false,
  this.hasSeenRewardReveal = false,
  this.lastUpdatedAt,
});
```

### Map keys
```dart
'intent': intent,
'play_style': playStyle,
'synaptix_mode': synaptixMode,
'has_completed_first_challenge': hasCompletedFirstChallenge,
'has_seen_reward_reveal': hasSeenRewardReveal,
```

---

## 5.2 Extend onboarding provider update API
File:
- `lib/game/providers/onboarding_providers.dart`

### Add parameters to `updateProgress`
```dart
String? intent,
String? playStyle,
String? synaptixMode,
bool? hasCompletedFirstChallenge,
bool? hasSeenRewardReveal,
```

### Add them to `OnboardingState`
```dart
final String? intent;
final String? playStyle;
final String? synaptixMode;
final bool hasCompletedFirstChallenge;
final bool hasSeenRewardReveal;
```

### Why
This allows the router and UI to reason about deeper onboarding state later without inventing a parallel state container.

---

## 5.3 Extend `ModernOnboardingController`
File:
- `lib/game/controllers/onboarding_controller.dart`

### Keep current structure
Do not replace `userData`.

### Add typed helpers
```dart
String? get username => userData['username'] as String?;
String? get ageGroup => userData['ageGroup'] as String?;
String? get intent => userData['intent'] as String?;
String? get playStyle => userData['playStyle'] as String?;
String? get synaptixMode => userData['synaptixMode'] as String?;
```

### Add convenience method
```dart
void setField(String key, dynamic value) {
  userData[key] = value;
  notifyListeners();
}
```

---

## 6. Exact production step files

## 6.1 `intent_step.dart`
Purpose:
- ask why the user is here
- segment into Train / Compete / Play
- influence shell emphasis and mode suggestion

### Stored value
```dart
'intent': 'train' | 'compete' | 'play'
```

### Suggested UI
- three large cards
- one-tap selection
- continue button enabled after selection

### Mapping
- train -> default home emphasis = Pathways/Journey
- compete -> default home emphasis = Arena
- play -> default home emphasis = Labs

---

## 6.2 `play_style_step.dart`
Purpose:
- collect style signal for personalization and future ToM systems

### Stored value
```dart
'playStyle': 'fast' | 'strategic' | 'explorer'
```

### Suggested copy
- Fast Thinker
- Strategic Mind
- Explorer

### Why
This is strong product differentiation and gives you future adaptive-difficulty hooks without needing backend complexity right away.

---

## 6.3 `first_session_challenge_step.dart`
Purpose:
- replace purely form-based onboarding with a real “experience moment”

### Production rule
This should **not** be a full quiz-system rewrite.
It should be a lightweight controlled challenge:
- 3 questions
- local/adaptive
- fast feedback
- deterministic enough for onboarding reliability

### Stored values
```dart
'firstChallengeScore': 0,
'firstChallengeTotal': 3,
'firstChallengeCompleted': true,
```

### UI requirements
- progress indicator
- answer selection
- immediate reveal
- continue after all questions complete

### Strong recommendation
Use a small local question set embedded in the step initially rather than coupling onboarding to the full question pipeline in the first production pass.

---

## 6.4 `reward_reveal_step.dart`
Purpose:
- give the user a reward before sending them to Hub
- create momentum and ownership

### Show:
- XP earned
- starter credits
- pathway unlocked
- next recommended action

### Stored values
```dart
'starterXP': 100,
'starterCredits': 250,
'starterPathway': 'cognition',
```

### Production rule
This can start as a deterministic reward payload and evolve later into backend-driven grants.

---

## 7. Exact updates to `onboarding_screen.dart`

## 7.1 Increase total steps
Current:
```dart
_controller = ModernOnboardingController(totalSteps: 7);
```

Recommended:
```dart
_controller = ModernOnboardingController(totalSteps: 11);
```

## 7.2 Add imports
```dart
import 'steps/intent_step.dart';
import 'steps/play_style_step.dart';
import 'steps/first_session_challenge_step.dart';
import 'steps/reward_reveal_step.dart';
```

## 7.3 New PageView order
Recommended children:
```dart
children: [
  WelcomeStep(controller: _controller),
  UsernameStep(controller: _controller),
  AgeGroupStep(controller: _controller),
  IntentStep(controller: _controller),
  PlayStyleStep(controller: _controller),
  CountryStep(controller: _controller),
  CategoriesStep(controller: _controller),
  AvatarStep(controller: _controller),
  FirstSessionChallengeStep(controller: _controller),
  RewardRevealStep(controller: _controller),
  CompletionStep(
    controller: _controller,
    onComplete: _handleCompletion,
  ),
],
```

## 7.4 Extend restore logic
When restoring persisted progress, include:
```dart
if (progress.intent != null) 'intent': progress.intent,
if (progress.playStyle != null) 'playStyle': progress.playStyle,
if (progress.synaptixMode != null) 'synaptixMode': progress.synaptixMode,
if (progress.hasCompletedFirstChallenge) 'firstChallengeCompleted': true,
if (progress.hasSeenRewardReveal) 'hasSeenRewardReveal': true,
```

## 7.5 Extend persist snapshot
Pass through:
```dart
intent: _controller.userData['intent'] as String?,
playStyle: _controller.userData['playStyle'] as String?,
synaptixMode: _controller.userData['synaptixMode'] as String?,
hasCompletedFirstChallenge: _controller.userData['firstChallengeCompleted'] == true,
hasSeenRewardReveal: _controller.userData['hasSeenRewardReveal'] == true,
```

---

## 8. Exact completion handling changes

File:
- `lib/screens/onboarding/onboarding_screen.dart`

Current completion already:
- saves profile values
- syncs username/profile
- marks onboarding complete
- routes to `/home`

### Extend it to also save Synaptix preferences
After ageGroup save:
```dart
final synaptixMode = _controller.userData['synaptixMode'] as String?;
final intent = _controller.userData['intent'] as String?;

if (synaptixMode != null) {
  await profileService.saveSynaptixMode(synaptixMode);
}

if (intent != null) {
  final preferredHomeSurface = switch (intent) {
    'compete' => 'arena',
    'train' => 'pathways',
    'play' => 'labs',
    _ => 'home',
  };
  await profileService.savePreferredHomeSurface(preferredHomeSurface);
}
```

### Seed starter economy if you want production-readiness
If a wallet/settings service already exists, apply starter rewards here.
If not, persist a light onboarding reward flag and let a later service consume it.

---

## 9. Exact age-group -> Synaptix mode integration

You already have:
- `SynaptixModeNotifier`
- `synaptixModeProvider`
- `main.dart` bootstrap mapping

### Use it directly in onboarding
In `AgeGroupStep`, after selecting age group:
```dart
final mode = SynaptixModeNotifier.mapAgeGroupToMode(_selectedAgeGroup!);
widget.controller.updateUserData({
  'ageGroup': _selectedAgeGroup,
  'synaptixMode': mode.name,
});
```

### Why
This avoids creating a second mode-mapping path.

---

## 10. Router and flow logic

Your router already has:
- `/onboarding`
- onboarding providers
- auth state
- home route

### Production-ready recommendation
Do not create a new onboarding router.

Instead:
- keep `/onboarding`
- keep `onboardingCompleteProvider`
- ensure app redirect logic sends unfinished users to onboarding
- ensure completed users are not sent back unless reset manually

### Redirect rule target
If not logged in:
- go to `/login`

If logged in but onboarding incomplete:
- go to `/onboarding`

If onboarding complete:
- allow `/home`

---

## 11. Production-ready step shell standard

To make the new steps consistent, create:
- `lib/screens/onboarding/widgets/onboarding_step_shell.dart`

### Responsibilities
- common padding
- title
- subtitle
- hero icon slot
- bottom CTA slot

### Suggested API
```dart
class OnboardingStepShell extends StatelessWidget {
  final Widget hero;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget? footer;
}
```

### Why
Your current steps are visually good but repetitive. A step shell reduces drift and makes the expanded flow feel more polished.

---

## 12. First-session challenge content seed

For production reliability, use a local onboarding question list in the first pass.

### Example structure
```dart
const onboardingQuestions = [
  {
    'question': 'Which planet is known as the Red Planet?',
    'answers': ['Earth', 'Mars', 'Venus', 'Jupiter'],
    'correctIndex': 1,
  },
  {
    'question': 'How many sides does a hexagon have?',
    'answers': ['5', '6', '7', '8'],
    'correctIndex': 1,
  },
  {
    'question': 'Which animal is known for its memory in many stories?',
    'answers': ['Elephant', 'Fox', 'Rabbit', 'Wolf'],
    'correctIndex': 0,
  },
];
```

### Why not full question service immediately
- lower onboarding failure risk
- no network dependency
- deterministic QA
- easier to style for kids/teen/adult later

---

## 13. Reward reveal model

Suggested deterministic starter rewards:
```dart
const starterReward = {
  'xp': 100,
  'credits': 250,
  'pathway': 'cognition',
};
```

### UI elements
- animated XP counter
- credits earned
- “Your first path is unlocked”
- CTA:
  - “Enter Synaptix Hub”

### Mode-aware copy
Kids:
- “You unlocked your first path!”

Teen:
- “You’ve entered the Arena.”

Adult:
- “Your Synaptix journey begins now.”

---

## 14. File-by-file implementation order

Another AI should implement the onboarding conversion in this exact order:

1. ✅ extend `OnboardingProgress` — added 5 new fields (intent, playStyle, synaptixMode, hasCompletedFirstChallenge, hasSeenRewardReveal)
2. ✅ extend onboarding providers — `updateOnboardingProgress` accepts new fields
3. ✅ extend `ModernOnboardingController` — typed getters + `setField()` helper
4. ✅ add `intent_step.dart` — Train Mind / Compete / Play
5. ✅ add `play_style_step.dart` — Fast Thinker / Strategic Mind / Explorer
6. ✅ add `first_session_challenge_step.dart` — 3-question local mini-quiz
7. ✅ add `reward_reveal_step.dart` — animated 100 XP + 250 coins + pathway unlock
8. ✅ add `onboarding_step_shell.dart` — shared layout shell
9. ✅ update `onboarding_screen.dart` — 11 steps, new imports, extended persist/restore
10. ✅ update completion handler — saves synaptixMode, maps intent → preferredHomeSurface, seeds starter economy
11. ✅ router redirect behavior — existing guards preserved, `/onboarding` route unchanged
12. run onboarding persistence restore test — needs runtime testing
13. run first-session challenge test — needs runtime testing
14. run completion -> `/home` handoff test — needs runtime testing

---

## 15. Acceptance criteria

This onboarding conversion is successful only if:

- ✅ the existing onboarding route remains stable — `/onboarding` route unchanged
- ✅ onboarding progress still restores correctly — extended persist/restore logic
- ✅ age group correctly maps to Synaptix mode — wired in `age_group_step.dart`
- ✅ intent and play style are persisted — added to `OnboardingProgress.toMap/fromMap`
- ✅ user completes a real first-session challenge — 3-question local quiz
- ✅ reward reveal happens before home handoff — step 9 of 11 (before CompletionStep)
- ✅ `/home` is reached only after onboarding completion — existing guard preserved
- ✅ no old onboarding state flags are broken — backward-compatible fields with defaults

---

## 16. Recommended follow-up after implementation

Once this onboarding implementation is in place, the next sequential path should be:

1. design the monetization economy in full detail (USD + crypto backend) — not started
2. ✅ design the full UI polish system (neon glass, motion, feedback) — implemented in `3f4c65b` (sound cues remaining)
3. only after those are defined, widen the internal soft launch validation — alpha demo phase in progress

---

## 17. Final recommendation

Because your ZIP already contains a mature onboarding scaffold, the fastest production-ready route is:

- **evolve, do not replace**
- add Synaptix-specific segmentation and reward logic
- keep the persistence and router architecture you already have
- make first-session gameplay the centerpiece of onboarding