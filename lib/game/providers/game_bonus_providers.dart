/// Providers that carry active in-game bonus state.
///
/// Written to by SkillEffectHandler / ProfileService.
/// Read by QuestionController during scoring and timer ticks.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Pending seconds to add to the active question timer.
/// ProfileService.increaseTimer() writes here; QuestionController drains it.
final pendingTimerBonusProvider = StateProvider<int>((ref) => 0);

/// Active streak multiplier set by the skill tree (e.g. streakMult = 1.5).
/// Applied in QuestionController for consecutive correct answers.
final streakMultiplierProvider = StateProvider<double>((ref) => 1.0);

/// Generic score/XP multiplier bonus (e.g. sportsScoreBoost, hardBonus).
/// Stacks multiplicatively with power-up and XP-service multipliers.
final scoreBonusMultiplierProvider = StateProvider<double>((ref) => 1.0);

/// Flag set when an elite skill node grants access to locked game modes.
final eliteAccessUnlockedProvider = StateProvider<bool>((ref) => false);
