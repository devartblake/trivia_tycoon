import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/dto/learning_dto.dart';

void main() {
  // -------------------------------------------------------------------------
  // difficultyLabel
  // -------------------------------------------------------------------------

  group('difficultyLabel', () {
    test('1 → Easy', () => expect(difficultyLabel(1), 'Easy'));
    test('2 → Medium', () => expect(difficultyLabel(2), 'Medium'));
    test('3 → Hard', () => expect(difficultyLabel(3), 'Hard'));
    test('4 → Expert', () => expect(difficultyLabel(4), 'Expert'));
    test('0 → Unknown', () => expect(difficultyLabel(0), 'Unknown'));
    test('5 → Unknown', () => expect(difficultyLabel(5), 'Unknown'));
    test('-1 → Unknown', () => expect(difficultyLabel(-1), 'Unknown'));
  });

  // -------------------------------------------------------------------------
  // difficultyColor
  // -------------------------------------------------------------------------

  group('difficultyColor', () {
    test('1 → Colors.green', () => expect(difficultyColor(1), Colors.green));
    test('3 → Colors.orange', () => expect(difficultyColor(3), Colors.orange));
    test('4 → Colors.red', () => expect(difficultyColor(4), Colors.red));
    test('0 → Colors.grey', () => expect(difficultyColor(0), Colors.grey));
    test('5 → Colors.grey', () => expect(difficultyColor(5), Colors.grey));
  });

  // -------------------------------------------------------------------------
  // ModuleDto
  // -------------------------------------------------------------------------

  group('ModuleDto.fromJson', () {
    Map<String, dynamic> full() => {
          'id': 'm1',
          'title': 'Intro to Science',
          'description': 'Basic science questions',
          'category': 'science',
          'difficulty': 2,
          'lessonCount': 10,
          'rewardXp': 200,
          'rewardCoins': 50,
          'isCompleted': false,
        };

    test('parses id and title', () {
      final m = ModuleDto.fromJson(full());
      expect(m.id, 'm1');
      expect(m.title, 'Intro to Science');
    });

    test('description defaults empty when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('description');
      expect(ModuleDto.fromJson(j).description, '');
    });

    test('category defaults empty when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('category');
      expect(ModuleDto.fromJson(j).category, '');
    });

    test('difficulty defaults 1 when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('difficulty');
      expect(ModuleDto.fromJson(j).difficulty, 1);
    });

    test('lessonCount defaults 0 when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('lessonCount');
      expect(ModuleDto.fromJson(j).lessonCount, 0);
    });

    test('rewardXp defaults 0 when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('rewardXp');
      expect(ModuleDto.fromJson(j).rewardXp, 0);
    });

    test('isCompleted defaults false when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('isCompleted');
      expect(ModuleDto.fromJson(j).isCompleted, isFalse);
    });
  });

  group('ModuleDto computed properties', () {
    test('difficultyText for difficulty=1 is Easy', () {
      final m = ModuleDto.fromJson({'id': 'x', 'title': 'X', 'difficulty': 1});
      expect(m.difficultyText, 'Easy');
    });

    test('difficultyText for difficulty=4 is Expert', () {
      final m = ModuleDto.fromJson({'id': 'x', 'title': 'X', 'difficulty': 4});
      expect(m.difficultyText, 'Expert');
    });

    test('difficultyColour for difficulty=1 is green', () {
      final m = ModuleDto.fromJson({'id': 'x', 'title': 'X', 'difficulty': 1});
      expect(m.difficultyColour, Colors.green);
    });

    test('difficultyColour for difficulty=4 is red', () {
      final m = ModuleDto.fromJson({'id': 'x', 'title': 'X', 'difficulty': 4});
      expect(m.difficultyColour, Colors.red);
    });
  });

  // -------------------------------------------------------------------------
  // LessonOptionDto
  // -------------------------------------------------------------------------

  group('LessonOptionDto', () {
    test('fromJson parses id and text', () {
      final o = LessonOptionDto.fromJson({'id': 'opt1', 'text': 'Paris'});
      expect(o.id, 'opt1');
      expect(o.text, 'Paris');
    });
  });

  // -------------------------------------------------------------------------
  // LessonDto
  // -------------------------------------------------------------------------

  group('LessonDto', () {
    Map<String, dynamic> full() => {
          'lessonId': 'l1',
          'order': 3,
          'questionId': 'q1',
          'questionText': 'What is the capital of France?',
          'questionCategory': 'geography',
          'options': [
            {'id': 'opt1', 'text': 'Paris'},
            {'id': 'opt2', 'text': 'Berlin'},
          ],
          'correctOptionId': 'opt1',
          'explanation': 'Paris is the capital of France.',
        };

    test('fromJson parses lessonId', () {
      expect(LessonDto.fromJson(full()).lessonId, 'l1');
    });

    test('fromJson parses order', () {
      expect(LessonDto.fromJson(full()).order, 3);
    });

    test('fromJson order defaults 0 when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('order');
      expect(LessonDto.fromJson(j).order, 0);
    });

    test('fromJson parses questionText', () {
      expect(LessonDto.fromJson(full()).questionText,
          'What is the capital of France?');
    });

    test('fromJson parses correctOptionId', () {
      expect(LessonDto.fromJson(full()).correctOptionId, 'opt1');
    });

    test('fromJson options deserialized as LessonOptionDto list', () {
      final lesson = LessonDto.fromJson(full());
      expect(lesson.options.length, 2);
      expect(lesson.options.first, isA<LessonOptionDto>());
      expect(lesson.options.first.id, 'opt1');
    });

    test('fromJson empty options list when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('options');
      expect(LessonDto.fromJson(j).options, isEmpty);
    });

    test('fromJson explanation null when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('explanation');
      expect(LessonDto.fromJson(j).explanation, isNull);
    });

    test('fromJson explanation stored when present', () {
      expect(LessonDto.fromJson(full()).explanation,
          'Paris is the capital of France.');
    });
  });

  // -------------------------------------------------------------------------
  // ModuleCompleteResponseDto
  // -------------------------------------------------------------------------

  group('ModuleCompleteResponseDto', () {
    Map<String, dynamic> full() => {
          'moduleId': 'm1',
          'playerId': 'p1',
          'status': 'Completed',
          'rewardXp': 200,
          'rewardCoins': 50,
          'balanceXp': 1200,
          'balanceCoins': 250,
        };

    test('fromJson parses moduleId and playerId', () {
      final d = ModuleCompleteResponseDto.fromJson(full());
      expect(d.moduleId, 'm1');
      expect(d.playerId, 'p1');
    });

    test('fromJson parses status', () {
      expect(ModuleCompleteResponseDto.fromJson(full()).status, 'Completed');
    });

    test('fromJson rewardXp defaults 0 when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('rewardXp');
      expect(ModuleCompleteResponseDto.fromJson(j).rewardXp, 0);
    });

    test('fromJson balanceCoins defaults 0 when absent', () {
      final j = Map<String, dynamic>.from(full())..remove('balanceCoins');
      expect(ModuleCompleteResponseDto.fromJson(j).balanceCoins, 0);
    });

    test('isFirstCompletion true when status is Completed', () {
      expect(ModuleCompleteResponseDto.fromJson(full()).isFirstCompletion,
          isTrue);
    });

    test('isFirstCompletion false for other status', () {
      final j = Map<String, dynamic>.from(full())
        ..['status'] = 'AlreadyCompleted';
      expect(ModuleCompleteResponseDto.fromJson(j).isFirstCompletion, isFalse);
    });

    test('isFirstCompletion false for empty status', () {
      final j = Map<String, dynamic>.from(full())..['status'] = '';
      expect(ModuleCompleteResponseDto.fromJson(j).isFirstCompletion, isFalse);
    });
  });
}
