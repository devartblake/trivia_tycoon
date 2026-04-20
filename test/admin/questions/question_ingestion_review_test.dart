import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/admin/questions/question_ingestion_review.dart';

void main() {
  test('parseQuestionValidationIssues handles string/map/mixed payloads', () {
    final issues = parseQuestionValidationIssues([
      'invalid category',
      {
        'field': 'difficulty',
        'message': 'must be between 1-3',
        'code': 'range_error'
      },
      42,
    ]);

    expect(issues.length, 3);
    expect(issues.first.displayText, 'invalid category');
    expect(issues[1].displayText, 'difficulty: must be between 1-3');
    expect(issues[2].message, '42');
  });

  test(
      'summarizeValidationIssues counts duplicate-like and field-scoped issues',
      () {
    final issues = [
      const QuestionValidationIssue(message: 'question already exists'),
      const QuestionValidationIssue(message: 'bad value', field: 'difficulty'),
      const QuestionValidationIssue(
          message: 'duplicate row', code: 'duplicate_question'),
    ];

    final summary = summarizeValidationIssues(issues);

    expect(summary.total, 3);
    expect(summary.duplicateLike, 2);
    expect(summary.fieldScoped, 1);
  });
}
