/// High-level match phases used by the live match UI.
enum MatchPhase {
  idle,        // not in a match
  queued,      // matchmaking queue, pre-room
  starting,    // countdown / intro
  question,    // question live
  reveal,      // reveal correct answer
  results,     // post-match summary
  finished,    // finalized, exiting
  error,       // an error occurred
}

/// Snapshot of the player's current match context.
class MatchState {
  /// Current match identifier, if in a match.
  final String? matchId;

  /// Current high-level phase.
  final MatchPhase phase;

  /// Current question id if applicable (question/reveal phases).
  final String? questionId;

  /// Remaining time (ms) when the controller chooses to track it client-side.
  final int? remainingMs;

  /// Optional content for user-facing error/state messaging.
  final String? message;

  const MatchState({
    this.matchId,
    this.phase = MatchPhase.idle,
    this.questionId,
    this.remainingMs,
    this.message,
  });

  const MatchState.idle()
      : matchId = null,
        phase = MatchPhase.idle,
        questionId = null,
        remainingMs = null,
        message = null;

  MatchState copyWith({
    String? matchId,
    MatchPhase? phase,
    String? questionId,
    int? remainingMs,          // pass explicit null to clear
    bool clearRemaining = false,
    String? message,           // pass explicit null to clear
    bool clearMessage = false,
  }) {
    return MatchState(
      matchId: matchId ?? this.matchId,
      phase: phase ?? this.phase,
      questionId: questionId ?? this.questionId,
      remainingMs: clearRemaining ? null : (remainingMs ?? this.remainingMs),
      message: clearMessage ? null : (message ?? this.message),
    );
  }

  @override
  String toString() =>
      'MatchState(matchId: $matchId, phase: $phase, questionId: $questionId, '
          'remainingMs: $remainingMs, message: $message)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MatchState &&
              runtimeType == other.runtimeType &&
              matchId == other.matchId &&
              phase == other.phase &&
              questionId == other.questionId &&
              remainingMs == other.remainingMs &&
              message == other.message;

  @override
  int get hashCode =>
      Object.hash(matchId, phase, questionId, remainingMs, message);
}
