class QuestionValidationIssue {
  const QuestionValidationIssue({
    required this.message,
    this.field,
    this.code,
  });

  final String message;
  final String? field;
  final String? code;

  String get displayText {
    if (field != null && field!.isNotEmpty) {
      return '$field: $message';
    }
    return message;
  }

  bool get isDuplicateLike {
    final normalized = (code ?? message).toLowerCase();
    return normalized.contains('duplicate') ||
        normalized.contains('dedupe') ||
        normalized.contains('already exists') ||
        normalized.contains('conflict');
  }
}

class QuestionValidationSummary {
  const QuestionValidationSummary({
    required this.total,
    required this.duplicateLike,
    required this.fieldScoped,
  });

  final int total;
  final int duplicateLike;
  final int fieldScoped;
}

List<QuestionValidationIssue> parseQuestionValidationIssues(dynamic value) {
  if (value is! List) return const <QuestionValidationIssue>[];

  return value.map((issue) {
    if (issue is String) {
      return QuestionValidationIssue(message: issue);
    }

    if (issue is Map) {
      final map = Map<String, dynamic>.from(issue);
      return QuestionValidationIssue(
        field: map['field']?.toString(),
        code: map['code']?.toString(),
        message: map['message']?.toString() ?? map['error']?.toString() ?? issue.toString(),
      );
    }

    return QuestionValidationIssue(message: issue.toString());
  }).toList();
}

QuestionValidationSummary summarizeValidationIssues(List<QuestionValidationIssue> issues) {
  return QuestionValidationSummary(
    total: issues.length,
    duplicateLike: issues.where((i) => i.isDuplicateLike).length,
    fieldScoped: issues.where((i) => i.field != null && i.field!.isNotEmpty).length,
  );
}
