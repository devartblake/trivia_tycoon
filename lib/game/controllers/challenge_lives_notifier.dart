import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/settings/general_key_value_storage_service.dart';

// ---------------------------------------------------------------------------
// Challenge lives configuration constants
// ---------------------------------------------------------------------------

/// Number of lives granted at the start of each challenge run.
const int kChallengeLivesPerRun = 3;

/// Number of premium revives allowed per challenge run.
const int kPremiumRevivesPerRun = 1;

// ---------------------------------------------------------------------------
// ChallengeLivesState
// ---------------------------------------------------------------------------

/// Immutable snapshot of challenge-mode lives for the current run.
///
/// Lives are **not** global — they are scoped to an individual challenge run.
/// There is no automatic time-based refill; lives reset at the start of each
/// new run via [ChallengeLivesNotifier.startRun].
class ChallengeLivesState {
  /// Lives remaining in the current run.
  final int current;

  /// Maximum lives per run (always [kChallengeLivesPerRun]).
  final int max;

  /// Number of premium revives consumed in the current run.
  final int premiumRevivesUsed;

  /// Maximum premium revives available per run ([kPremiumRevivesPerRun]).
  final int premiumRevivesAllowed;

  /// Whether a challenge run is currently in progress.
  final bool isRunActive;

  const ChallengeLivesState({
    required this.current,
    required this.max,
    this.premiumRevivesUsed = 0,
    this.premiumRevivesAllowed = kPremiumRevivesPerRun,
    this.isRunActive = false,
  });

  /// Whether a premium revive is still available for this run.
  bool get canRevive => premiumRevivesUsed < premiumRevivesAllowed;

  /// Whether the run is over (no lives left and no revive available).
  ///
  /// Returns `false` when no run is active — game-over only applies in-run.
  bool get isGameOver => isRunActive && current <= 0 && !canRevive;

  ChallengeLivesState copyWith({
    int? current,
    int? max,
    int? premiumRevivesUsed,
    int? premiumRevivesAllowed,
    bool? isRunActive,
  }) {
    return ChallengeLivesState(
      current: current ?? this.current,
      max: max ?? this.max,
      premiumRevivesUsed: premiumRevivesUsed ?? this.premiumRevivesUsed,
      premiumRevivesAllowed:
          premiumRevivesAllowed ?? this.premiumRevivesAllowed,
      isRunActive: isRunActive ?? this.isRunActive,
    );
  }
}

// ---------------------------------------------------------------------------
// ChallengeLivesNotifier
// ---------------------------------------------------------------------------

/// Manages lives for challenge / survival modes.
///
/// Lives are scoped to the current run and do **not** refill automatically over
/// time. The flow is:
///
/// 1. Call [startRun] to begin a new challenge run — this resets lives to
///    [kChallengeLivesPerRun] and clears any used revives.
/// 2. Call [loseLife] each time the player fails a question.
/// 3. If [ChallengeLivesState.canRevive] is `true`, offer the player a premium
///    revive via [useRevive] — this restores lives to [kChallengeLivesPerRun].
/// 4. Call [endRun] when the run concludes (win or game-over).
///
/// High-stakes modes are gated by tickets (handled separately).
/// Global lives do not exist in this system.
class ChallengeLivesNotifier extends StateNotifier<ChallengeLivesState> {
  final GeneralKeyValueStorageService _storage;

  ChallengeLivesNotifier(this._storage)
      : super(const ChallengeLivesState(
          current: kChallengeLivesPerRun,
          max: kChallengeLivesPerRun,
        )) {
    loadRunState();
  }

  // ---------------------------------------------------------------------------
  // Run lifecycle
  // ---------------------------------------------------------------------------

  /// Begin a new challenge run — resets lives and revives to their defaults.
  void startRun() {
    state = const ChallengeLivesState(
      current: kChallengeLivesPerRun,
      max: kChallengeLivesPerRun,
      premiumRevivesUsed: 0,
      premiumRevivesAllowed: kPremiumRevivesPerRun,
      isRunActive: true,
    );
    _saveRunState();
  }

  /// End the current run and reset state to idle.
  void endRun() {
    state = const ChallengeLivesState(
      current: kChallengeLivesPerRun,
      max: kChallengeLivesPerRun,
      isRunActive: false,
    );
    _saveRunState();
  }

  // ---------------------------------------------------------------------------
  // In-run actions
  // ---------------------------------------------------------------------------

  /// Deduct one life from the current run.
  ///
  /// Returns `true` if the player still has lives remaining, `false` if the
  /// player is out of lives (run is over unless a revive is used).
  bool loseLife() {
    if (!state.isRunActive) return false;
    final newCurrent = (state.current - 1).clamp(0, state.max);
    state = state.copyWith(current: newCurrent);
    _saveRunState();
    return newCurrent > 0;
  }

  /// Consume a premium revive, restoring lives to [kChallengeLivesPerRun].
  ///
  /// Returns `true` if a revive was available and applied, `false` otherwise.
  bool useRevive() {
    if (!state.isRunActive || !state.canRevive) return false;
    state = state.copyWith(
      current: kChallengeLivesPerRun,
      premiumRevivesUsed: state.premiumRevivesUsed + 1,
    );
    _saveRunState();
    return true;
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _saveRunState() async {
    await _storage.setInt('challenge_lives_current', state.current);
    await _storage.setBool('challenge_run_active', state.isRunActive);
    await _storage.setInt(
        'challenge_premium_revives_used', state.premiumRevivesUsed);
  }

  /// Restore persisted run state on app restart (e.g., if app was killed mid-run).
  Future<void> loadRunState() async {
    final rawCurrent = await _storage.get('challenge_lives_current');
    final isRunActive = await _storage.getBool('challenge_run_active') ?? false;
    final rawRevivesUsed = await _storage.get('challenge_premium_revives_used');

    final current = rawCurrent is int ? rawCurrent : kChallengeLivesPerRun;
    final revivesUsed = rawRevivesUsed is int ? rawRevivesUsed : 0;

    state = state.copyWith(
      current: current,
      isRunActive: isRunActive,
      premiumRevivesUsed: revivesUsed,
    );
  }
}
