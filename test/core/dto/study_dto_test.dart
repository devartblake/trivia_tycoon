import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/dto/study_dto.dart';

void main() {
  // -------------------------------------------------------------------------
  // StudyOption
  // -------------------------------------------------------------------------

  group('StudyOption', () {
    test('fromJson parses id and text', () {
      final o = StudyOption.fromJson({'id': 'o1', 'text': 'Answer A'});
      expect(o.id, 'o1');
      expect(o.text, 'Answer A');
    });

    test('fromJson id defaults empty when absent', () {
      final o = StudyOption.fromJson({'text': 'X'});
      expect(o.id, '');
    });

    test('fromJson text defaults empty when absent', () {
      final o = StudyOption.fromJson({'id': 'x'});
      expect(o.text, '');
    });
  });

  // -------------------------------------------------------------------------
  // StudySetListItem
  // -------------------------------------------------------------------------

  group('StudySetListItem', () {
    test('fromJson parses id and title', () {
      final s = StudySetListItem.fromJson({
        'id': 'ss1',
        'title': 'Science Basics',
        'kind': 'Category',
        'category': 'science',
      });
      expect(s.id, 'ss1');
      expect(s.title, 'Science Basics');
    });

    test('fromJson description defaults empty when absent', () {
      final s = StudySetListItem.fromJson(
          {'id': 'x', 'title': 'X', 'kind': 'K', 'category': 'C'});
      expect(s.description, '');
    });

    test('fromJson kind defaults Category when absent', () {
      final s =
          StudySetListItem.fromJson({'id': 'x', 'title': 'X', 'category': 'C'});
      expect(s.kind, 'Category');
    });

    test('fromJson questionCount defaults 0 when absent', () {
      final s = StudySetListItem.fromJson(
          {'id': 'x', 'title': 'X', 'kind': 'K', 'category': 'C'});
      expect(s.questionCount, 0);
    });
  });

  // -------------------------------------------------------------------------
  // StudyQuestion
  // -------------------------------------------------------------------------

  group('StudyQuestion', () {
    Map<String, dynamic> _full() => {
          'id': 'sq1',
          'text': 'What is H2O?',
          'category': 'chemistry',
          'difficulty': 'Medium',
          'options': [
            {'id': 'o1', 'text': 'Water'},
            {'id': 'o2', 'text': 'Oxygen'},
          ],
          'correctOptionId': 'o1',
          'explanation': 'H2O is water.',
          'mediaKey': 'media/q1.png',
        };

    test('fromJson parses id, text, category', () {
      final q = StudyQuestion.fromJson(_full());
      expect(q.id, 'sq1');
      expect(q.text, 'What is H2O?');
      expect(q.category, 'chemistry');
    });

    test('fromJson difficulty defaults Easy when absent', () {
      final j = Map<String, dynamic>.from(_full())..remove('difficulty');
      expect(StudyQuestion.fromJson(j).difficulty, 'Easy');
    });

    test('fromJson options deserialized as StudyOption list', () {
      final q = StudyQuestion.fromJson(_full());
      expect(q.options.length, 2);
      expect(q.options.first, isA<StudyOption>());
      expect(q.options.first.id, 'o1');
    });

    test('fromJson empty options when absent', () {
      final j = Map<String, dynamic>.from(_full())..remove('options');
      expect(StudyQuestion.fromJson(j).options, isEmpty);
    });

    test('fromJson correctOptionId null when absent', () {
      final j = Map<String, dynamic>.from(_full())..remove('correctOptionId');
      expect(StudyQuestion.fromJson(j).correctOptionId, isNull);
    });

    test('fromJson explanation null when absent', () {
      final j = Map<String, dynamic>.from(_full())..remove('explanation');
      expect(StudyQuestion.fromJson(j).explanation, isNull);
    });

    test('fromJson mediaKey null when absent', () {
      final j = Map<String, dynamic>.from(_full())..remove('mediaKey');
      expect(StudyQuestion.fromJson(j).mediaKey, isNull);
    });
  });

  // -------------------------------------------------------------------------
  // StudySetDetail
  // -------------------------------------------------------------------------

  group('StudySetDetail', () {
    test('fromJson parses id and title', () {
      final d = StudySetDetail.fromJson({
        'id': 'sd1',
        'title': 'Chemistry 101',
        'kind': 'Category',
        'category': 'chemistry',
        'questions': [],
      });
      expect(d.id, 'sd1');
      expect(d.title, 'Chemistry 101');
    });

    test('fromJson questions deserialized as StudyQuestion list', () {
      final d = StudySetDetail.fromJson({
        'id': 'sd1',
        'title': 'X',
        'kind': 'K',
        'category': 'C',
        'questions': [
          {
            'id': 'sq1',
            'text': 'Q?',
            'category': 'C',
            'options': [],
          },
        ],
      });
      expect(d.questions.length, 1);
      expect(d.questions.first, isA<StudyQuestion>());
    });

    test('fromJson empty questions list when absent', () {
      final d = StudySetDetail.fromJson({
        'id': 'sd1',
        'title': 'X',
        'kind': 'K',
        'category': 'C',
      });
      expect(d.questions, isEmpty);
    });
  });

  // -------------------------------------------------------------------------
  // StudySessionMode enum
  // -------------------------------------------------------------------------

  group('StudySessionMode enum', () {
    test('has 2 values', () {
      expect(StudySessionMode.values.length, 2);
    });

    test('selfTest apiValue is SelfTest', () {
      expect(StudySessionMode.selfTest.apiValue, 'SelfTest');
    });

    test('flashcard apiValue is Flashcard', () {
      expect(StudySessionMode.flashcard.apiValue, 'Flashcard');
    });

    test('both values distinct', () {
      expect(StudySessionMode.values.toSet().length, 2);
    });
  });

  // -------------------------------------------------------------------------
  // FlashcardAction enum
  // -------------------------------------------------------------------------

  group('FlashcardAction enum', () {
    test('has 4 values', () {
      expect(FlashcardAction.values.length, 4);
    });

    test('again apiValue is Again', () {
      expect(FlashcardAction.again.apiValue, 'Again');
    });

    test('hard apiValue is Hard', () {
      expect(FlashcardAction.hard.apiValue, 'Hard');
    });

    test('good apiValue is Good', () {
      expect(FlashcardAction.good.apiValue, 'Good');
    });

    test('easy apiValue is Easy', () {
      expect(FlashcardAction.easy.apiValue, 'Easy');
    });

    test('all values distinct', () {
      expect(FlashcardAction.values.toSet().length, 4);
    });
  });

  // -------------------------------------------------------------------------
  // StudySession
  // -------------------------------------------------------------------------

  group('StudySession', () {
    Map<String, dynamic> _full() => {
          'id': 'sess1',
          'studySetId': 'ss1',
          'mode': 'Flashcard',
          'title': 'Session Title',
          'kind': 'Category',
          'questionCount': 10,
          'answeredCount': 3,
          'correctCount': 2,
          'currentQuestionIndex': 3,
          'isCompleted': false,
          'questionIds': ['q1', 'q2', 'q3'],
          'answeredQuestionIds': ['q1', 'q2'],
        };

    test('fromJson parses id and studySetId', () {
      final s = StudySession.fromJson(_full());
      expect(s.id, 'sess1');
      expect(s.studySetId, 'ss1');
    });

    test('fromJson mode Flashcard → flashcard', () {
      expect(StudySession.fromJson(_full()).mode, StudySessionMode.flashcard);
    });

    test('fromJson mode SelfTest → selfTest', () {
      final j = Map<String, dynamic>.from(_full())..['mode'] = 'SelfTest';
      expect(StudySession.fromJson(j).mode, StudySessionMode.selfTest);
    });

    test('fromJson unknown mode → selfTest', () {
      final j = Map<String, dynamic>.from(_full())..['mode'] = 'Unknown';
      expect(StudySession.fromJson(j).mode, StudySessionMode.selfTest);
    });

    test('fromJson answeredCount defaults 0 when absent', () {
      final j = Map<String, dynamic>.from(_full())..remove('answeredCount');
      expect(StudySession.fromJson(j).answeredCount, 0);
    });

    test('fromJson correctCount defaults 0 when absent', () {
      final j = Map<String, dynamic>.from(_full())..remove('correctCount');
      expect(StudySession.fromJson(j).correctCount, 0);
    });

    test('fromJson isCompleted defaults false when absent', () {
      final j = Map<String, dynamic>.from(_full())..remove('isCompleted');
      expect(StudySession.fromJson(j).isCompleted, isFalse);
    });

    test('fromJson questionIds parsed as list of strings', () {
      final s = StudySession.fromJson(_full());
      expect(s.questionIds, ['q1', 'q2', 'q3']);
    });

    test('fromJson questionIds empty when absent', () {
      final j = Map<String, dynamic>.from(_full())..remove('questionIds');
      expect(StudySession.fromJson(j).questionIds, isEmpty);
    });

    test('fromJson answeredQuestionIds parsed', () {
      final s = StudySession.fromJson(_full());
      expect(s.answeredQuestionIds, ['q1', 'q2']);
    });

    test('fromJson answeredQuestionIds empty when absent', () {
      final j = Map<String, dynamic>.from(_full())
        ..remove('answeredQuestionIds');
      expect(StudySession.fromJson(j).answeredQuestionIds, isEmpty);
    });
  });
}
