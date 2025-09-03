class PlayerProgress {
  final int score;
  final int streak;

  PlayerProgress({required this.score, required this.streak});

  factory PlayerProgress.fromJson(Map<String, dynamic> json) {
    return PlayerProgress(
      score: json['score'] ?? 0,
      streak: json['streak'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'score': score,
      'streak': streak,
    };
  }
}