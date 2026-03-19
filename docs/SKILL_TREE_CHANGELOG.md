# Skill Tree & Game Loop — Implementation Changelog
> Session: 2026-03-17 | Branch: `claude/review-repository-CjAuu`
 
---

## Overview

This document records every change made across four implementation tasks:

1. [Power-up & skill tree effect wiring + persistence fixes](#1-power-up--skill-tree-effect-wiring--persistence)
2. [28 missing skill effect implementations (all 5 groups)](#2-28-missing-skill-effects--all-5-groups)
3. [Honeycomb skill tree UI refinement](#3-honeycomb-skill-tree-ui-refinement)

---

## 1. Power-up & Skill Tree Effect Wiring + Persistence

### `lib/game/services/xp_service.dart`

**What changed:** `_playerXP` was in-memory only (`// TODO: persist`). Added Hive-backed persistence via `GeneralKeyValueStorageService`.

**Key additions:**
- Optional `GeneralKeyValueStorageService? _storage` constructor field
- `_loadFromStorage()` — fire-and-forget async load on construction (mirroring `CoinBalanceNotifier` pattern)
- `addXP`, `deductXP`, `resetXP` all call `_storage?.setInt('playerXP', _playerXP)` after mutation

---

### `lib/game/providers/xp_provider.dart`

**What changed:** `xpServiceProvider` now reads `generalKeyValueStorageProvider` and injects it into `XPService`.

```dart
final xpServiceProvider = Provider<XPService>((ref) {
  final storage = ref.read(generalKeyValueStorageProvider);
  return XPService(storage: storage);
});
```
 
---

### `lib/game/services/profile_service.dart`

**What changed:** `unlockedCategories` was in-memory only; `increaseTimer()` and `addScoreBonus()` were no-ops.

**Key additions:**
- `_loadFromStorage()` — loads `'unlockedCategories'` from Hive on construction
- `unlockCategory()` — persists updated list via `_storage.setStringList(...)`
- `increaseTimer(seconds)` → now routes to `ref.read(pendingTimerBonusProvider.notifier).state += seconds`
- `addScoreBonus(multiplier)` → now routes to `scoreBonusMultiplierProvider` (multiplicative)
- Imports: added `game_bonus_providers.dart` and `core_providers.dart`

---

### `lib/game/providers/game_bonus_providers.dart` *(new file)*

Created a shared `StateProvider` bus between `SkillEffectHandler` (writer) and `QuestionController` (reader).

**Original 4 providers:**
| Provider | Type | Purpose |
|----------|------|---------|
| `pendingTimerBonusProvider` | `StateProvider<int>` | Seconds to add to next question timer |
| `streakMultiplierProvider` | `StateProvider<double>` | Streak score multiplier |
| `scoreBonusMultiplierProvider` | `StateProvider<double>` | Global score multiplier |
| `eliteAccessUnlockedProvider` | `StateProvider<bool>` | Elite mode gate |

**19 new providers added (see section 2 for full list).**
 
---

### `lib/game/controllers/question_controller.dart`

**Scoring pipeline wired in `_evaluateAnswer()`:**
1. Auto-correct chance roll (`autoCorrectChanceProvider`)
2. Retry-on-wrong gate — returns early, resets `selectedAnswer`, restarts timer
3. Streak shield consumption (`streakShieldProvider`)
4. Score: `basePoints × powerUpMult × skillBonus × streakMult × speedBonus × categoryBonus`
5. Accuracy bonus (if `state.accuracy >= 0.7`)
6. Double-or-nothing roll
7. XP award via `xpService.addXP(scorePoints)`
8. Streak count update
9. Periodic chaos check

**Timer wired in `_startTimer()`:**
- Drains `pendingTimerBonusProvider` before each decrement
- Skips decrement entirely when `timerFrozenProvider` is `true`

**New helper `_applyPendingQuestionEffects(index)`:**
- Drains `pendingEliminateHalfProvider` — removes half wrong answers from options
- Drains `pendingEliminateOneProvider` — removes one wrong answer
- Drains `pendingShowHintProvider` — sets `showHint: true` on question

**New helpers `_triggerRandomBenefit()` and `_triggerPeriodicChaos()`:**
- Random benefit (at game start): one of timeBonusSec / bonusXP / streakBoost / scoreMultiplier
- Periodic chaos (every N correct answers): one of -5s timer / halve streak / reduce score bonus

---

## 2. 28 Missing Skill Effects — All 5 Groups

### `lib/game/state/question_state.dart`

**Additions:**
- `final int streakCount` — current correct streak
- `final int correctCount` — total correct answers this session
- `final int totalAnswered` — total answers this session
- `double get accuracy` — `correctCount / totalAnswered` (0.0 when no answers)
- Updated `initial()` factory and `copyWith`

---

### `lib/game/services/skill_cooldown_service.dart`

**Additions:**
- `void reduceCooldown(String skillId, Duration reduction)` — shrinks a specific skill's remaining cooldown
- `void applyGlobalReduction(Duration reduction)` — shrinks all active cooldowns simultaneously

---

### `lib/game/providers/game_bonus_providers.dart` — 19 new providers

**Group 1 (XP/Score):**
| Provider | Type | Effect |
|----------|------|--------|
| `accuracyBonusProvider` | `StateProvider<double>` | Bonus multiplier applied when accuracy ≥ 70% |

**Group 2 (Streak / Timer / Access):**
| Provider | Type | Effect |
|----------|------|--------|
| `streakCountProvider` | `StateProvider<int>` | Synced streak count |
| `streakShieldProvider` | `StateProvider<int>` | Charges that absorb a streak break |
| `timerFrozenProvider` | `StateProvider<bool>` | Halts timer decrement |
| `selectableCategoryProvider` | `StateProvider<bool>` | Player chooses category each question |
| `masterKnowledgeUnlockedProvider` | `StateProvider<bool>` | Master knowledge mode gate |
| `masterTacticsUnlockedProvider` | `StateProvider<bool>` | Master tactics mode gate |

**Group 3 (Question Manipulation):**
| Provider | Type | Effect |
|----------|------|--------|
| `pendingEliminateOneProvider` | `StateProvider<bool>` | Remove one wrong answer next question |
| `pendingEliminateHalfProvider` | `StateProvider<bool>` | Remove half wrong answers next question |
| `pendingShowHintProvider` | `StateProvider<bool>` | Auto-show hint next question |
| `pendingRetryProvider` | `StateProvider<bool>` | Grant one retry on wrong answer |
| `autoCorrectChanceProvider` | `StateProvider<double>` | % chance wrong answer is corrected |
| `doubleOrNothingProvider` | `StateProvider<bool>` | 2× score or reset to 0 |
| `hintSpeedBonusProvider` | `StateProvider<int>` | Bonus seconds when hint is used |

**Group 4 (UI/Stealth):**
| Provider | Type | Effect |
|----------|------|--------|
| `fakeScoreActiveProvider` | `StateProvider<bool>` | Show fake score to opponents |
| `hideProgressActiveProvider` | `StateProvider<bool>` | Hide progress bar from opponents |
| `glitchScreensActiveProvider` | `StateProvider<bool>` | Briefly glitch opponent displays |

**Group 5 (Complex):**
| Provider | Type | Effect |
|----------|------|--------|
| `categoryBonusProvider` | `StateProvider<Map<String, dynamic>?>` | Specific category multiplier data |
| `periodicChaosIntervalProvider` | `StateProvider<int>` | Chaos triggers every N questions |
| `randomBenefitActiveProvider` | `StateProvider<bool>` | Random benefit triggered at game start |
| `speedBonusMultiplierProvider` | `StateProvider<double>` | Speed-based score multiplier |
 
---

### `lib/game/logic/skill_effect_handler.dart`

**Architecture addition:** `Map<String, num> _currentEffects` scratch-pad field populated before the effect loop so any case can peek at sibling keys (e.g., `speedDuration` readable during `speedBonus` case).

**28 new `_applyEffect` cases:**

| Key | Action |
|-----|--------|
| `streakMult` | Multiplies `streakMultiplierProvider` |
| `sportsScoreBoost` | Multiplies `scoreBonusMultiplierProvider` |
| `hardBonus` | Multiplies `scoreBonusMultiplierProvider` |
| `eliteAccess` | Sets `eliteAccessUnlockedProvider` true |
| `accuracyBonus` | Sets `accuracyBonusProvider` |
| `streakProtection` | Sets `streakShieldProvider` |
| `startingStreak` | Sets `streakCountProvider` |
| `streakBoost` | Adds to `streakCountProvider` |
| `freezeTimer` | Sets `timerFrozenProvider` true |
| `selectableCategory` | Sets `selectableCategoryProvider` true |
| `masterKnowledge` | Sets `masterKnowledgeUnlockedProvider` true |
| `masterTactics` | Sets `masterTacticsUnlockedProvider` true |
| `eliminateOneWrong` | Sets `pendingEliminateOneProvider` true |
| `eliminateHalfWrong` | Sets `pendingEliminateHalfProvider` true |
| `extraHints` | Sets `pendingShowHintProvider` true |
| `retryWrongAnswer` | Sets `pendingRetryProvider` true |
| `autoCorrectChance` | Sets `autoCorrectChanceProvider` |
| `doubleOrNothing` | Sets `doubleOrNothingProvider` true |
| `hintSpeedBonus` | Sets `hintSpeedBonusProvider` |
| `fakeScore` | Sets `fakeScoreActiveProvider` true |
| `hideProgress` | Sets `hideProgressActiveProvider` true |
| `glitchScreens` | Sets `glitchScreensActiveProvider` true + `Future.delayed` reset |
| `globalScoreBonus` | Multiplies `scoreBonusMultiplierProvider` + timed reset via `Future.delayed` |
| `categoryBonus` | Sets `categoryBonusProvider` map |
| `allCategoryBonus` | Multiplies `scoreBonusMultiplierProvider` (all categories) |
| `periodicChaos` | Sets `periodicChaosIntervalProvider` |
| `randomBenefit` | Sets `randomBenefitActiveProvider` true |
| `speedBonus` | Sets `speedBonusMultiplierProvider` + timed reset via `Future.delayed` using `speedDuration` sibling key |
| `speedDuration` / `duration` | `break` — administrative sibling keys, handled by parent case |
 
---

## 3. Honeycomb Skill Tree UI Refinement

### New Files

#### `lib/screens/skills_tree/widgets/skill_effect_labels.dart`

Pure static utility class. Maps all 28+ effect keys to emoji + human-readable strings.

```dart
SkillEffectLabels.label('timeBonusSec', 5) // → '⏱ +5s per question'
SkillEffectLabels.label('streakMult', 1.5) // → '🔥 ×1.5 streak multiplier'
SkillEffectLabels.isHidden('duration')      // → true (filters admin keys)
```

Administrative keys (`duration`, `speedDuration`, `cooldownSec`) return `''` so callers can filter with `.isEmpty`.
 
---

#### `lib/screens/skills_tree/widgets/skill_node_detail_sheet.dart`

Rich `DraggableScrollableSheet` modal bottom sheet (`initialChildSize: 0.55`, `maxChildSize: 0.92`).

**Visual sections (top → bottom):**
1. Drag handle pill
2. Header — `SkillNodeWidget(size: medium)` mini-preview + title + category chip
3. Meta row — tier dot-row (filled/empty circles) + PASSIVE/ACTIVE tag
4. Description text
5. **EFFECTS** section — one row per visible effect, staggered `flutter_animate` slideX+fadeIn
6. **REQUIRES** section (if any) — prerequisite nodes with ✅/🔒 icons + tier label
7. Cost + action button row

**6-state action button:**
| State | Label | Condition |
|-------|-------|-----------|
| `alreadyUnlocked` (passive) | `✓ Unlocked` | `node.unlocked && effectTrigger != 'active'` |
| `canUse` (active) | `▶ Use Skill` | `node.unlocked && effectTrigger == 'active' && !onCooldown` |
| `canUnlock` | `Unlock — N XP` | prereqs met + `playerXP >= node.cost` |
| `insufficientXP` | `Need N XP` | prereqs met + `playerXP < node.cost` |
| `prereqLocked` | `Requires: [Name]` | missing prereq |
| `onCooldown` | `Cooling down MM:SS` | active skill on cooldown |

**Animations:**
- Sheet entrance: `.slideY(begin: 0.15).fadeIn(duration: 250.ms)`
- Effect rows: staggered `.slideX(begin: 0.08).fadeIn(delay: idx * 50ms)`

**Static show helper:**
```dart
await SkillNodeDetailSheet.show(context, ref, node);
```
 
---

### Modified Files

#### `lib/screens/skills_tree/widgets/skill_tree_view.dart`

**Tap flow:**
- `_handleTapDown` — selects node + calls `SkillNodeDetailSheet.show()`
- `_handleTap` — now empty (unlock moved to detail sheet button)
- `SkillNodeWidget.onTap` lambda — selects + shows sheet
- Removed double-tap-to-unlock gesture

**`_TopBar` — converted to `ConsumerWidget`:**
- Reads `playerXPProvider` for live `⭐ N XP` display
- Shows `X / Y unlocked` progress
- Respec moved to `PopupMenuButton` `⋮` with confirmation `AlertDialog`
- Zoom controls retained, grouped right

**`_EdgesPainter` — full edge lines:**
- Both nodes unlocked → bright category-tinted solid line (opacity 0.55, strokeWidth 2.0)
- Parent unlocked, child not → dashed amber line (opacity 0.45, strokeWidth 1.5) via `_drawDashed()` helper
- Both locked → dim white solid line (opacity 0.10, strokeWidth 1.0)

**`SkillNodeFilterMode` enum (new, in this file):**
```dart
enum SkillNodeFilterMode { all, unlocked, available, locked }
```
Extension provides `.label`, `.icon`, `.color` for each mode.

**Filter prop:**
- `SkillTreeView(filterMode: SkillNodeFilterMode.all)` — new named param
- `_applyFilter()` trims `allPositions` map before rendering; edges always use unfiltered positions

---

#### `lib/screens/skills_tree/widgets/skill_node_widget.dart`

**Three visual states:**
| State | Border | Icon | Shadow |
|-------|--------|------|--------|
| Unlocked | glow (0.5α) | `check_circle` green | category glow |
| Available | amber `#FFB300` (0.8α) | `lock_open` amber | amber pulse |
| Locked | muted category tint | `lock` white24 | dark |

**Amber pulse animation (available nodes only):**
```dart
.animate(onPlay: (c) => c.repeat(reverse: true))
.custom(duration: 1200.ms, curve: Curves.easeInOut, builder: ...)
// → BoxShadow with color: amber.withOpacity(0.35 * animValue)
```

Added `import 'package:flutter_animate/flutter_animate.dart'`.
 
---

#### `lib/screens/skills_tree/skill_tree_screen.dart`

**`_filterMode` state:**
```dart
SkillNodeFilterMode _filterMode = SkillNodeFilterMode.all;
```
Passed to `SkillTreeView(filterMode: _filterMode)`.

**`_showGroupFilter()` — live implementation:**
- `StatefulBuilder` inside sheet so radio selection is immediate
- Per-mode node counts computed from `ref.read(skillTreeProvider).graph`
- `ListTile` per `SkillNodeFilterMode` with `Radio`, icon, label, count subtitle
- Selecting a mode updates `_filterMode` on parent via `setState` + pops sheet

Added imports: `'../../game/providers/skill_tree_provider.dart'`
 
---

## Files Changed Summary

| File | Type | Description |
|------|------|-------------|
| `lib/game/services/xp_service.dart` | Modified | Hive persistence for `_playerXP` |
| `lib/game/providers/xp_provider.dart` | Modified | Inject storage into `XPService` |
| `lib/game/services/profile_service.dart` | Modified | Hive persistence + route `increaseTimer`/`addScoreBonus` |
| `lib/game/providers/game_bonus_providers.dart` | New | 23 `StateProvider` buses for skill effects |
| `lib/game/state/question_state.dart` | Modified | Add `streakCount`, `correctCount`, `totalAnswered`, `accuracy` |
| `lib/game/services/skill_cooldown_service.dart` | Modified | Add `reduceCooldown`, `applyGlobalReduction` |
| `lib/game/logic/skill_effect_handler.dart` | Modified | 28 new effect cases + `_currentEffects` scratch-pad |
| `lib/game/controllers/question_controller.dart` | Modified | Full scoring pipeline + timer integration + new helpers |
| `lib/screens/skills_tree/widgets/skill_effect_labels.dart` | New | Human-readable effect key → emoji/string map |
| `lib/screens/skills_tree/widgets/skill_node_detail_sheet.dart` | New | Rich modal bottom sheet for skill node detail |
| `lib/screens/skills_tree/widgets/skill_tree_view.dart` | Modified | Modal tap, TopBar XP, full edges, filter prop |
| `lib/screens/skills_tree/widgets/skill_node_widget.dart` | Modified | Amber available state + pulse animation |
| `lib/screens/skills_tree/skill_tree_screen.dart` | Modified | Live filter mode state + `_showGroupFilter` impl |
 
---

## Architecture Notes

### Provider bus pattern
`SkillEffectHandler` writes to `StateProvider`s in `game_bonus_providers.dart`; `QuestionController` reads from the same providers. This avoids a circular dependency between the two controllers while keeping effects decoupled from game logic.

### Sibling key access
`SkillEffectHandler._currentEffects` is populated before the effect loop so that cases like `speedBonus` can read `speedDuration` from the same effect map without modifying the method signature.

### Timed effect expiry
`globalScoreBonus` and `speedBonus` use `Future.delayed` to revert their provider state after the effect duration. This is intentional — effects are managed purely in-memory and reset themselves without requiring a separate timer service.

### Persistence pattern
Follows the existing `CoinBalanceNotifier` pattern: fire-and-forget `_loadFromStorage()` from the constructor; `Future`-returning persist calls that are not awaited at call sites (fire-and-forget writes).

