import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/providers/question_provider_contracts.dart';
import 'package:trivia_tycoon/game/services/quiz_category.dart';

void main() {
  test('normalizeQuestionStats maps alternative totals to questionCount', () {
    final normalized = normalizeQuestionStats({'totalQuestions': 42});
    expect(normalized['questionCount'], 42);
    expect(normalized['source'], 'backend');
  });

  test('normalizeDatasetInfo maps datasetName and version aliases', () {
    final normalized = normalizeDatasetInfo({
      'datasetName': 'science_pack',
      'datasetVersion': 'v2',
      'totalQuestions': 9,
    });

    expect(normalized['name'], 'science_pack');
    expect(normalized['version'], 'v2');
    expect(normalized['questionCount'], 9);
  });

  test('normalizeCategoryStats fills category and defaults difficulty', () {
    final normalized = normalizeCategoryStats({'questionCount': 5}, QuizCategory.science);

    expect(normalized['category'], 'science');
    expect(normalized['difficulty'], 'mixed');
    expect(normalized['questionCount'], 5);
  });

  test('normalizeClassStats enforces availableCategories type', () {
    final normalized = normalizeClassStats({
      'questionCount': '11',
      'availableCategories': [QuizCategory.mathematics, 'invalid'],
    });

    expect(normalized['questionCount'], 11);
    expect(normalized['subjectCount'], 1);
    expect(normalized['availableCategories'], [QuizCategory.mathematics]);
  });
}