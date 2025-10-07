
enum PVPChallengeStatus {
  pending,
  accepted,
  declined,
  expired,
  completed,
  cancelled;

  String get displayName {
    switch (this) {
      case PVPChallengeStatus.pending:
        return 'Pending';
      case PVPChallengeStatus.accepted:
        return 'Accepted';
      case PVPChallengeStatus.declined:
        return 'Declined';
      case PVPChallengeStatus.expired:
        return 'Expired';
      case PVPChallengeStatus.completed:
        return 'Completed';
      case PVPChallengeStatus.cancelled:
        return 'Cancelled';
    }
  }

  bool get isActive => this == PVPChallengeStatus.accepted;
  bool get isPending => this == PVPChallengeStatus.pending;
  bool get isFinished => [completed, declined, expired, cancelled].contains(this);
}

class PVPChallenge {
  final String id;
  final String challengerId;
  final String challengerName;
  final String opponentId;
  final String opponentName;
  final String category;
  final int questionCount;
  final String difficulty;
  final int wager; // Coins wagered
  final PVPChallengeStatus status;
  final DateTime createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime expiresAt;
  final String? challengerScore;
  final String? opponentScore;
  final String? winnerId;

  const PVPChallenge({
    required this.id,
    required this.challengerId,
    required this.challengerName,
    required this.opponentId,
    required this.opponentName,
    required this.category,
    required this.questionCount,
    required this.difficulty,
    this.wager = 0,
    this.status = PVPChallengeStatus.pending,
    required this.createdAt,
    this.acceptedAt,
    this.completedAt,
    required this.expiresAt,
    this.challengerScore,
    this.opponentScore,
    this.winnerId,
  });

  bool get hasWager => wager > 0;
  bool get isExpired => DateTime.now().isAfter(expiresAt) && !status.isFinished;
  Duration get timeRemaining => expiresAt.difference(DateTime.now());

  String? getWinnerName() {
    if (winnerId == null) return null;
    return winnerId == challengerId ? challengerName : opponentName;
  }

  PVPChallenge copyWith({
    String? id,
    String? challengerId,
    String? challengerName,
    String? opponentId,
    String? opponentName,
    String? category,
    int? questionCount,
    String? difficulty,
    int? wager,
    PVPChallengeStatus? status,
    DateTime? createdAt,
    DateTime? acceptedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
    String? challengerScore,
    String? opponentScore,
    String? winnerId,
  }) {
    return PVPChallenge(
      id: id ?? this.id,
      challengerId: challengerId ?? this.challengerId,
      challengerName: challengerName ?? this.challengerName,
      opponentId: opponentId ?? this.opponentId,
      opponentName: opponentName ?? this.opponentName,
      category: category ?? this.category,
      questionCount: questionCount ?? this.questionCount,
      difficulty: difficulty ?? this.difficulty,
      wager: wager ?? this.wager,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      challengerScore: challengerScore ?? this.challengerScore,
      opponentScore: opponentScore ?? this.opponentScore,
      winnerId: winnerId ?? this.winnerId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'challengerId': challengerId,
      'challengerName': challengerName,
      'opponentId': opponentId,
      'opponentName': opponentName,
      'category': category,
      'questionCount': questionCount,
      'difficulty': difficulty,
      'wager': wager,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      if (acceptedAt != null) 'acceptedAt': acceptedAt!.toIso8601String(),
      if (completedAt != null) 'completedAt': completedAt!.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      if (challengerScore != null) 'challengerScore': challengerScore,
      if (opponentScore != null) 'opponentScore': opponentScore,
      if (winnerId != null) 'winnerId': winnerId,
    };
  }

  factory PVPChallenge.fromJson(Map<String, dynamic> json) {
    return PVPChallenge(
      id: json['id'] as String,
      challengerId: json['challengerId'] as String,
      challengerName: json['challengerName'] as String,
      opponentId: json['opponentId'] as String,
      opponentName: json['opponentName'] as String,
      category: json['category'] as String,
      questionCount: json['questionCount'] as int,
      difficulty: json['difficulty'] as String,
      wager: json['wager'] as int? ?? 0,
      status: PVPChallengeStatus.values.byName(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      acceptedAt: json['acceptedAt'] != null
          ? DateTime.parse(json['acceptedAt'] as String)
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      challengerScore: json['challengerScore'] as String?,
      opponentScore: json['opponentScore'] as String?,
      winnerId: json['winnerId'] as String?,
    );
  }
}

class PVPChallengeResult {
  final String challengeId;
  final String winnerId;
  final String? winnerName;
  final int challengerScore;
  final int opponentScore;
  final int coinsWon;
  final DateTime completedAt;

  const PVPChallengeResult({
    required this.challengeId,
    required this.winnerId,
    this.winnerName,
    required this.challengerScore,
    required this.opponentScore,
    this.coinsWon = 0,
    required this.completedAt,
  });

  bool isDraw() => challengerScore == opponentScore;
  int get scoreDifference => (challengerScore - opponentScore).abs();
}
