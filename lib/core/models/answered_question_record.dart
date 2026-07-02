class AnsweredQuestionRecord {
  final String prompt;
  final String yourAnswer;
  final String correctAnswer;
  final bool isCorrect;

  const AnsweredQuestionRecord({
    required this.prompt,
    required this.yourAnswer,
    required this.correctAnswer,
    required this.isCorrect,
  });

  Map<String, dynamic> toJson() => {
        'prompt': prompt,
        'yourAnswer': yourAnswer,
        'correctAnswer': correctAnswer,
        'isCorrect': isCorrect,
      };

  static AnsweredQuestionRecord fromJson(Map<String, dynamic> json) {
    return AnsweredQuestionRecord(
      prompt: json['prompt'] as String? ?? '',
      yourAnswer: json['yourAnswer'] as String? ?? '',
      correctAnswer: json['correctAnswer'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }
}
