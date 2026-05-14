import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/models/question_validation_models.dart';
import 'package:trivia_tycoon/game/models/question_model.dart';

// Minimal valid QuestionModel for constructing submissions
QuestionModel _makeQuestion({String id = 'q1'}) =>
    QuestionModel.fromJson({
      'id': id,
      'question': 'What is 2+2?',
      'correctAnswer': '4',
      'answers': ['2', '4', '6', '8'],
      'type': 'text',
      'quizFormat': 'multiple_choice',
      'difficulty': 'easy',
      'category': 'math',
    });

void main() {
  // -------------------------------------------------------------------------
  // QuestionAnswerSubmission
  // -------------------------------------------------------------------------

  group('QuestionAnswerSubmission', () {
    test('stores selectedAnswer', () {
      final q = _makeQuestion();
      final s = QuestionAnswerSubmission(question: q, selectedAnswer: '4');
      expect(s.selectedAnswer, '4');
    });

    test('stores question reference', () {
      final q = _makeQuestion(id: 'q2');
      final s = QuestionAnswerSubmission(question: q, selectedAnswer: '6');
      expect(s.question, same(q));
    });

    test('question id is accessible via stored question', () {
      final q = _makeQuestion(id: 'qTest');
      final s = QuestionAnswerSubmission(question: q, selectedAnswer: '2');
      expect(s.question.id, 'qTest');
    });

    test('selectedAnswer preserved for wrong answer', () {
      final q = _makeQuestion();
      final s = QuestionAnswerSubmission(question: q, selectedAnswer: '99');
      expect(s.selectedAnswer, '99');
    });

    test('two submissions with same data are const-constructible', () {
      final q = _makeQuestion();
      final s = QuestionAnswerSubmission(question: q, selectedAnswer: 'A');
      expect(s, isA<QuestionAnswerSubmission>());
    });
  });

  // -------------------------------------------------------------------------
  // QuestionAnswerCheckResult
  // -------------------------------------------------------------------------

  group('QuestionAnswerCheckResult construction', () {
    test('stores questionId', () {
      const r = QuestionAnswerCheckResult(
        questionId: 'q1',
        selectedAnswer: '4',
        isCorrect: true,
      );
      expect(r.questionId, 'q1');
    });

    test('stores selectedAnswer', () {
      const r = QuestionAnswerCheckResult(
        questionId: 'q1',
        selectedAnswer: 'B',
        isCorrect: false,
      );
      expect(r.selectedAnswer, 'B');
    });

    test('stores isCorrect true', () {
      const r = QuestionAnswerCheckResult(
        questionId: 'q1',
        selectedAnswer: '4',
        isCorrect: true,
      );
      expect(r.isCorrect, isTrue);
    });

    test('stores isCorrect false', () {
      const r = QuestionAnswerCheckResult(
        questionId: 'q1',
        selectedAnswer: '2',
        isCorrect: false,
      );
      expect(r.isCorrect, isFalse);
    });

    test('source defaults to backend', () {
      const r = QuestionAnswerCheckResult(
        questionId: 'q1',
        selectedAnswer: '4',
        isCorrect: true,
      );
      expect(r.source, 'backend');
    });

    test('metadata defaults to empty map', () {
      const r = QuestionAnswerCheckResult(
        questionId: 'q1',
        selectedAnswer: '4',
        isCorrect: true,
      );
      expect(r.metadata, isEmpty);
    });

    test('correctAnswer defaults null', () {
      const r = QuestionAnswerCheckResult(
        questionId: 'q1',
        selectedAnswer: '4',
        isCorrect: true,
      );
      expect(r.correctAnswer, isNull);
    });
  });

  group('QuestionAnswerCheckResult optional fields', () {
    test('explicit source is stored', () {
      const r = QuestionAnswerCheckResult(
        questionId: 'q1',
        selectedAnswer: '4',
        isCorrect: true,
        source: 'local',
      );
      expect(r.source, 'local');
    });

    test('explicit correctAnswer is stored', () {
      const r = QuestionAnswerCheckResult(
        questionId: 'q1',
        selectedAnswer: '2',
        isCorrect: false,
        correctAnswer: '4',
      );
      expect(r.correctAnswer, '4');
    });

    test('explicit metadata is stored', () {
      const r = QuestionAnswerCheckResult(
        questionId: 'q1',
        selectedAnswer: '4',
        isCorrect: true,
        metadata: {'score': 10},
      );
      expect(r.metadata['score'], 10);
    });

    test('multiple fields set together', () {
      const r = QuestionAnswerCheckResult(
        questionId: 'q5',
        selectedAnswer: 'A',
        isCorrect: false,
        correctAnswer: 'C',
        source: 'cache',
        metadata: {'streak': 2},
      );
      expect(r.questionId, 'q5');
      expect(r.isCorrect, isFalse);
      expect(r.correctAnswer, 'C');
      expect(r.source, 'cache');
      expect(r.metadata['streak'], 2);
    });
  });
}
