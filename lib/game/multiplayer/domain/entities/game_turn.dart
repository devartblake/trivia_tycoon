/// Describes a single question "turn" window within a match.
class GameTurn {
  /// Server question id for the active turn.
  final String questionId;

  /// When the turn starts (UTC).
  final DateTime startAt;

  /// When the turn ends (UTC).
  final DateTime endAt;

  /// Optional: remaining ms at the time this snapshot was taken (client-side).
  final int? remainingMs;

  const GameTurn({
    required this.questionId,
    required this.startAt,
    required this.endAt,
    this.remainingMs,
  });

  Duration get duration => endAt.difference(startAt);

  GameTurn copyWith({
    String? questionId,
    DateTime? startAt,
    DateTime? endAt,
    int? remainingMs, // pass explicit null to clear
    bool clearRemaining = false,
  }) {
    return GameTurn(
      questionId: questionId ?? this.questionId,
      startAt: startAt ?? this.startAt,
      endAt: endAt ?? this.endAt,
      remainingMs: clearRemaining ? null : (remainingMs ?? this.remainingMs),
    );
  }

  @override
  String toString() =>
      'GameTurn(q: $questionId, startAt: $startAt, endAt: $endAt, remainingMs: $remainingMs)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is GameTurn &&
              runtimeType == other.runtimeType &&
              questionId == other.questionId &&
              startAt == other.startAt &&
              endAt == other.endAt &&
              remainingMs == other.remainingMs;

  @override
  int get hashCode => Object.hash(questionId, startAt, endAt, remainingMs);
}
