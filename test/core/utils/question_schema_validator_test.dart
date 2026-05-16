import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/utils/question_schema_validator.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Map<String, dynamic> _validJson() => {
      'id': 'q1',
      'question': 'What is 2+2?',
      'correctAnswer': '4',
      'answers': ['1', '2', '3', '4'],
      'type': 'text',
      'quizFormat': 'multiple_choice',
      'difficulty': 1,
      'category': 'math',
    };

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('QuestionSchemaValidator.isValid', () {
    // --- valid ---

    test('fully populated valid JSON returns true', () {
      expect(QuestionSchemaValidator.isValid(_validJson()), isTrue);
    });

    test('all valid type values are accepted', () {
      for (final type in ['text', 'image', 'video', 'audio']) {
        final json = {..._validJson(), 'type': type};
        expect(QuestionSchemaValidator.isValid(json), isTrue,
            reason: 'type "$type" should be valid');
      }
    });

    test('all valid quizFormat values are accepted', () {
      final formats = [
        'multiple_choice',
        'true_false',
        'fill_in_the_blanks',
        'drag_drop',
        'sorting',
        'labeling',
        'match_pair',
      ];
      for (final fmt in formats) {
        final json = {..._validJson(), 'quizFormat': fmt};
        expect(QuestionSchemaValidator.isValid(json), isTrue,
            reason: 'quizFormat "$fmt" should be valid');
      }
    });

    // --- required fields ---

    test('missing "id" returns false', () {
      final json = _validJson()..remove('id');
      expect(QuestionSchemaValidator.isValid(json), isFalse);
    });

    test('missing "question" returns false', () {
      final json = _validJson()..remove('question');
      expect(QuestionSchemaValidator.isValid(json), isFalse);
    });

    test('missing "correctAnswer" returns false', () {
      final json = _validJson()..remove('correctAnswer');
      expect(QuestionSchemaValidator.isValid(json), isFalse);
    });

    test('missing "answers" returns false', () {
      final json = _validJson()..remove('answers');
      expect(QuestionSchemaValidator.isValid(json), isFalse);
    });

    test('missing "type" returns false', () {
      final json = _validJson()..remove('type');
      expect(QuestionSchemaValidator.isValid(json), isFalse);
    });

    test('missing "quizFormat" returns false', () {
      final json = _validJson()..remove('quizFormat');
      expect(QuestionSchemaValidator.isValid(json), isFalse);
    });

    test('missing "difficulty" returns false', () {
      final json = _validJson()..remove('difficulty');
      expect(QuestionSchemaValidator.isValid(json), isFalse);
    });

    test('missing "category" returns false', () {
      final json = _validJson()..remove('category');
      expect(QuestionSchemaValidator.isValid(json), isFalse);
    });

    // --- answers validation ---

    test('empty answers list returns false', () {
      final json = {..._validJson(), 'answers': []};
      expect(QuestionSchemaValidator.isValid(json), isFalse);
    });

    test('answers not a List returns false', () {
      final json = {..._validJson(), 'answers': 'not-a-list'};
      expect(QuestionSchemaValidator.isValid(json), isFalse);
    });

    // --- invalid enum values ---

    test('invalid "type" returns false', () {
      final json = {..._validJson(), 'type': 'unknown_type'};
      expect(QuestionSchemaValidator.isValid(json), isFalse);
    });

    test('invalid "quizFormat" returns false', () {
      final json = {..._validJson(), 'quizFormat': 'not_a_format'};
      expect(QuestionSchemaValidator.isValid(json), isFalse);
    });
  });
}
