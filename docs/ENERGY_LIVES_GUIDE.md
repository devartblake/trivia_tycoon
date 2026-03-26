# Energy & Lives System Guide

This document describes the **energy** and **lives** systems in Trivia Tycoon,
including default values, gating rules, and where to modify them.

---

## Energy System

### Purpose
Energy gates access to **all match types** in the core game. The player must
spend energy to start a match; matches cannot be entered if energy is
insufficient.

### Default Configuration

| Setting | Value | Location |
|---|---|---|
| Maximum energy | 20 | `kEnergyMax` in `energy_notifier.dart` |
| Starting energy | 20 (full) | `EnergyNotifier` constructor |
| Refill rate | +1 per 10 minutes | `kEnergyRefillInterval` in `energy_notifier.dart` |
| Casual match cost | 3 | `kEnergyCasualCost` in `energy_notifier.dart` |
| Ranked match cost | 4 | `kEnergyRankedCost` in `energy_notifier.dart` |
| Practice mode cost | 1 | `kEnergyPracticeCost` in `energy_notifier.dart` |

### Gating Logic

Before starting a match, check the `EnergyNotifier` getters:

```dart
final energyNotifier = ref.read(energyProvider.notifier);

// Check before starting
if (energyNotifier.canPlayCasual) {
  energyNotifier.useCasualEnergy();
  // ... start casual match
}

if (energyNotifier.canPlayRanked) {
  energyNotifier.useRankedEnergy();
  // ... start ranked match
}

if (energyNotifier.canPlayPractice) {
  energyNotifier.usePracticeEnergy();
  // ... start practice session
}
```

### Modifying Values
To change energy defaults, edit the constants at the top of
`lib/game/controllers/energy_notifier.dart`:

```dart
const int kEnergyMax = 20;              // ← change max here
const Duration kEnergyRefillInterval = Duration(minutes: 10); // ← refill rate
const int kEnergyCasualCost = 3;        // ← casual match cost
const int kEnergyRankedCost = 4;        // ← ranked match cost
const int kEnergyPracticeCost = 1;      // ← practice cost (set to 0 for free)
```

### Persistence
Energy state is persisted via Hive (`GeneralKeyValueStorageService`) under the
keys `energy_current`, `energy_max`, and `energy_last_refill`. The notifier
restores these values on app start and applies any offline refill credit.

---

## Lives System (Challenge Mode)

### Purpose
Lives are **not** global. They exist only within a **challenge / survival mode
run**. There is no time-based global refill for lives; they reset at the start
of each new run.

### Default Configuration

| Setting | Value | Location |
|---|---|---|
| Lives per run | 3 | `kChallengeLivesPerRun` in `challenge_lives_notifier.dart` |
| Premium revives per run | 1 | `kPremiumRevivesPerRun` in `challenge_lives_notifier.dart` |

### Run Lifecycle

```dart
final livesNotifier = ref.read(livesProvider.notifier);

// 1. Start a new challenge run (resets to 3 lives, clears used revives)
livesNotifier.startRun();

// 2. Deduct a life when the player fails a question
final stillAlive = livesNotifier.loseLife();
if (!stillAlive) {
  // Check if a premium revive is available
  if (ref.read(livesProvider).canRevive) {
    // Offer revive UI, then:
    livesNotifier.useRevive(); // restores lives to 3, uses the premium revive
  } else {
    // Game over
  }
}

// 3. End the run (win or game-over)
livesNotifier.endRun();
```

### State Properties

```dart
final state = ref.watch(livesProvider);

state.current              // lives remaining in current run
state.max                  // max lives per run (kChallengeLivesPerRun)
state.isRunActive          // true while a challenge run is in progress
state.canRevive            // true if a premium revive is still available
state.isGameOver           // true when current == 0 && !canRevive
state.premiumRevivesUsed   // revives consumed in this run (0 or 1)
```

### Modifying Values
To change challenge defaults, edit the constants at the top of
`lib/game/controllers/challenge_lives_notifier.dart`:

```dart
const int kChallengeLivesPerRun = 3;   // ← lives per run
const int kPremiumRevivesPerRun = 1;   // ← premium revives per run
```

### No Global Lives
Global lives (a refilling pool unrelated to any game mode) **do not exist** in
this system. The `livesProvider` exclusively manages challenge-mode run lives.
The lives counter shown in the main menu reflects the lives capacity per run
(e.g., `3/3` at rest, `2/3` mid-run).

---

## Mode Gating Summary

| Game Mode | Gated By |
|---|---|
| Casual match | Energy (`kEnergyCasualCost = 3`) |
| Ranked match | Energy (`kEnergyRankedCost = 4`) |
| Practice mode | Energy (`kEnergyPracticeCost = 1`) |
| High-stakes / tournament | Tickets (separate system, TBD) |
| Challenge / survival run | Lives (`kChallengeLivesPerRun = 3` per run) |

---

## Provider Reference

| Provider | Type | File |
|---|---|---|
| `energyProvider` | `StateNotifierProvider<EnergyNotifier, EnergyState>` | `profile_providers.dart` |
| `livesProvider` | `StateNotifierProvider<ChallengeLivesNotifier, ChallengeLivesState>` | `profile_providers.dart` |
| `energyRefillTimeProvider` | `StateProvider<Duration>` | `profile_providers.dart` |

---

## Files

| File | Responsibility |
|---|---|
| `lib/game/controllers/energy_notifier.dart` | `EnergyState`, `EnergyNotifier`, energy constants |
| `lib/game/controllers/challenge_lives_notifier.dart` | `ChallengeLivesState`, `ChallengeLivesNotifier`, lives constants |
| `lib/game/controllers/energy_lives_notifier.dart` | Barrel re-export (backward compat) |
| `lib/game/providers/profile_providers.dart` | Provider definitions |
| `test/game/providers/energy_lives_providers_test.dart` | Unit tests |
