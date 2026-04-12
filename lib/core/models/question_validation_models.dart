import '../../game/models/question_model.dart';

class QuestionAnswerSubmission {
  const QuestionAnswerSubmission({
    required this.question,
    required this.selectedAnswer,
  });

  final QuestionModel question;
  final String selectedAnswer;
}

class QuestionAnswerCheckResult {
  const QuestionAnswerCheckResult({
    required this.questionId,
    required this.selectedAnswer,
    required this.isCorrect,
    this.correctAnswer,
    this.source = 'backend',
    this.metadata = const <String, dynamic>{},
  });

  final String questionId;
  final String selectedAnswer;
  final bool isCorrect;
  final String? correctAnswer;
  final String source;
  final Map<String, dynamic> metadata;
}
