/// Providers that carry active in-game bonus state.
///
/// Written to by SkillEffectHandler / ProfileService.
/// Read by QuestionController during scoring and timer ticks.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

// ---------------------------------------------------------------------------
// Previously implemented (retained)
// ---------------------------------------------------------------------------

/// Pending seconds to add to the active question timer.
final pendingTimerBonusProvider = StateProvider<int>((ref) => 0);

/// Active streak multiplier set by the skill tree (e.g. streakMult = 1.1).
final streakMultiplierProvider = StateProvider<double>((ref) => 1.0);

/// Generic score/XP multiplier bonus (e.g. sportsScoreBoost, hardBonus).
final scoreBonusMultiplierProvider = StateProvider<double>((ref) => 1.0);

/// Flag set when an elite skill node grants access to locked game modes.
final eliteAccessUnlockedProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Group 1 — low-hanging fruit
// ---------------------------------------------------------------------------

/// Accuracy bonus rate (e.g. 0.05 = +5% XP when accuracy ≥ 70%).
final accuracyBonusProvider = StateProvider<double>((ref) => 0.0);

// ---------------------------------------------------------------------------
// Group 2 — streak + timer + access
// ---------------------------------------------------------------------------

/// Question-level consecutive-correct streak counter.
/// Initialised from startingStreak, incremented on correct, reset on wrong.
final streakCountProvider = StateProvider<int>((ref) => 0);

/// Number of streak-protection shields remaining (consumed on wrong answer).
final streakShieldProvider = StateProvider<int>((ref) => 0);

/// When true the active question's countdown is frozen.
final timerFrozenProvider = StateProvider<bool>((ref) => false);

/// When true the player may select the category for the next question.
final selectableCategoryProvider = StateProvider<bool>((ref) => false);

/// Elite-branch flags.
final masterKnowledgeUnlockedProvider = StateProvider<bool>((ref) => false);
final masterTacticsUnlockedProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Group 3 — question manipulation
// ---------------------------------------------------------------------------

/// Eliminate one wrong answer on the next/current question.
final pendingEliminateOneProvider = StateProvider<bool>((ref) => false);

/// Eliminate half the wrong answers on the next/current question.
final pendingEliminateHalfProvider = StateProvider<bool>((ref) => false);

/// Show the hint passively on every question (extraHints skill).
final pendingShowHintProvider = StateProvider<bool>((ref) => false);

/// Allow one retry if the player answers incorrectly (consumed on use).
final pendingRetryProvider = StateProvider<bool>((ref) => false);

/// Cumulative probability that a wrong answer is auto-corrected (0.0–0.95).
final autoCorrectChanceProvider = StateProvider<double>((ref) => 0.0);

/// When true: correct → 2× score, wrong → score reset to 0.
final doubleOrNothingProvider = StateProvider<bool>((ref) => false);

/// Seconds added to the timer whenever the player reveals a hint.
final hintSpeedBonusProvider = StateProvider<int>((ref) => 0);

// ---------------------------------------------------------------------------
// Group 4 — UI / visibility (multiplayer stealth)
// ---------------------------------------------------------------------------

/// Show a decoy/fake score to opponents.
final fakeScoreActiveProvider = StateProvider<bool>((ref) => false);

/// Hide own progress from opponents.
final hideProgressActiveProvider = StateProvider<bool>((ref) => false);

/// Trigger visual glitch effect on opponents' screens.
final glitchScreensActiveProvider = StateProvider<bool>((ref) => false);

// ---------------------------------------------------------------------------
// Group 5 — complex / system-level
// ---------------------------------------------------------------------------

/// Category-specific bonus: {category: String, bonus: double}.
/// Null when no category bonus is active.
final categoryBonusProvider =
    StateProvider<Map<String, dynamic>?>((ref) => null);

/// Trigger a random chaos event every N questions (0 = disabled).
final periodicChaosIntervalProvider = StateProvider<int>((ref) => 0);

/// When true a random positive effect is applied at game start.
final randomBenefitActiveProvider = StateProvider<bool>((ref) => false);

/// Time-limited speed bonus multiplier (applied alongside speedDuration).
final speedBonusMultiplierProvider = StateProvider<double>((ref) => 1.0);
