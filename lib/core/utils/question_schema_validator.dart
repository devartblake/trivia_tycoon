class QuestionSchemaValidator {
  static bool isValid(Map<String, dynamic> json) {
    // Required fields
    final requiredFields = [
      'id', 'question', 'correctAnswer', 'answers', 'type',
      'quizFormat', 'difficulty', 'category'
    ];

    for (var field in requiredFields) {
      if (!json.containsKey(field)) return false;
    }

    if (json['answers'] is! List || (json['answers'] as List).isEmpty) return false;
    if (!['text', 'image', 'video', 'audio'].contains(json['type'])) return false;
    if (!['multiple_choice', 'true_false', 'fill_in_the_blanks', 'drag_drop', 'sorting', 'labeling', 'match_pair']
        .contains(json['quizFormat'])) {
      return false;
    }

    return true;
  }
}
