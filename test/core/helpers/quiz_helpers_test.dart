import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/core/helpers/quiz_helpers.dart';

void main() {
  // -------------------------------------------------------------------------
  // getDifficultyText
  // -------------------------------------------------------------------------

  group('QuizHelpers.getDifficultyText', () {
    test('1 → "easy"', () {
      expect(QuizHelpers.getDifficultyText(1), 'easy');
    });

    test('2 → "medium"', () {
      expect(QuizHelpers.getDifficultyText(2), 'medium');
    });

    test('3 → "hard"', () {
      expect(QuizHelpers.getDifficultyText(3), 'hard');
    });

    test('unknown value → "unknown"', () {
      expect(QuizHelpers.getDifficultyText(99), 'unknown');
      expect(QuizHelpers.getDifficultyText(0), 'unknown');
    });
  });

  // -------------------------------------------------------------------------
  // getDifficultyColor
  // -------------------------------------------------------------------------

  group('QuizHelpers.getDifficultyColor', () {
    test('difficulty 1 → Colors.green', () {
      expect(QuizHelpers.getDifficultyColor(1), Colors.green);
    });

    test('difficulty 2 → Colors.orange', () {
      expect(QuizHelpers.getDifficultyColor(2), Colors.orange);
    });

    test('difficulty 3 → Colors.red', () {
      expect(QuizHelpers.getDifficultyColor(3), Colors.red);
    });

    test('unknown difficulty → Colors.grey', () {
      expect(QuizHelpers.getDifficultyColor(0), Colors.grey);
    });
  });

  // -------------------------------------------------------------------------
  // getDifficultyIcon
  // -------------------------------------------------------------------------

  group('QuizHelpers.getDifficultyIcon', () {
    test('difficulty 1 → Icons.star_outline', () {
      expect(QuizHelpers.getDifficultyIcon(1), Icons.star_outline);
    });

    test('difficulty 2 → Icons.star_half', () {
      expect(QuizHelpers.getDifficultyIcon(2), Icons.star_half);
    });

    test('difficulty 3 → Icons.star', () {
      expect(QuizHelpers.getDifficultyIcon(3), Icons.star);
    });

    test('unknown difficulty → Icons.help_outline', () {
      expect(QuizHelpers.getDifficultyIcon(0), Icons.help_outline);
    });
  });

  // -------------------------------------------------------------------------
  // getTimerColor
  // -------------------------------------------------------------------------

  group('QuizHelpers.getTimerColor', () {
    test('≤5 seconds → Colors.red', () {
      expect(QuizHelpers.getTimerColor(5), Colors.red);
      expect(QuizHelpers.getTimerColor(1), Colors.red);
    });

    test('6-10 seconds → Colors.orange', () {
      expect(QuizHelpers.getTimerColor(6), Colors.orange);
      expect(QuizHelpers.getTimerColor(10), Colors.orange);
    });

    test('>10 seconds → Colors.green', () {
      expect(QuizHelpers.getTimerColor(11), Colors.green);
      expect(QuizHelpers.getTimerColor(30), Colors.green);
    });
  });

  // -------------------------------------------------------------------------
  // getTimeLimitForClass
  // -------------------------------------------------------------------------

  group('QuizHelpers.getTimeLimitForClass', () {
    test('kindergarten → 45', () {
      expect(QuizHelpers.getTimeLimitForClass('kindergarten'), 45);
    });

    test('"k" → 45', () {
      expect(QuizHelpers.getTimeLimitForClass('k'), 45);
    });

    test('"1" → 40', () {
      expect(QuizHelpers.getTimeLimitForClass('1'), 40);
    });

    test('"2" → 35', () {
      expect(QuizHelpers.getTimeLimitForClass('2'), 35);
    });

    test('"3" → 30', () {
      expect(QuizHelpers.getTimeLimitForClass('3'), 30);
    });

    test('"6" → 25', () {
      expect(QuizHelpers.getTimeLimitForClass('6'), 25);
    });

    test('"9" → 20', () {
      expect(QuizHelpers.getTimeLimitForClass('9'), 20);
    });

    test('"12" → 20', () {
      expect(QuizHelpers.getTimeLimitForClass('12'), 20);
    });

    test('unknown class → default 30', () {
      expect(QuizHelpers.getTimeLimitForClass('university'), 30);
      expect(QuizHelpers.getTimeLimitForClass(''), 30);
    });
  });

  // -------------------------------------------------------------------------
  // getCategoryColor — returns a valid non-null Color for all branches
  // -------------------------------------------------------------------------

  group('QuizHelpers.getCategoryColor', () {
    test('science → Colors.blue.shade600', () {
      expect(QuizHelpers.getCategoryColor('science'), Colors.blue.shade600);
    });

    test('math (alias) → Colors.purple.shade600', () {
      expect(QuizHelpers.getCategoryColor('math'), Colors.purple.shade600);
    });

    test('technology → Colors.indigo.shade600', () {
      expect(QuizHelpers.getCategoryColor('technology'), Colors.indigo.shade600);
    });

    test('unknown category → Colors.grey.shade600', () {
      expect(QuizHelpers.getCategoryColor('unknown_xyz'), Colors.grey.shade600);
    });

    test('case-insensitive: "Science" matches "science"', () {
      expect(
        QuizHelpers.getCategoryColor('Science'),
        QuizHelpers.getCategoryColor('science'),
      );
    });
  });

  // -------------------------------------------------------------------------
  // getCategoryBackgroundColor — lighter complement of getCategoryColor
  // -------------------------------------------------------------------------

  group('QuizHelpers.getCategoryBackgroundColor', () {
    test('science → Colors.blue.shade50', () {
      expect(
        QuizHelpers.getCategoryBackgroundColor('science'),
        Colors.blue.shade50,
      );
    });

    test('unknown → Colors.grey.shade50', () {
      expect(
        QuizHelpers.getCategoryBackgroundColor('nope'),
        Colors.grey.shade50,
      );
    });
  });

  // -------------------------------------------------------------------------
  // getClassColor
  // -------------------------------------------------------------------------

  group('QuizHelpers.getClassColor', () {
    test('kindergarten → Colors.pink', () {
      expect(QuizHelpers.getClassColor('kindergarten'), Colors.pink);
    });

    test('"k" → Colors.pink', () {
      expect(QuizHelpers.getClassColor('k'), Colors.pink);
    });

    test('"12" → Colors.deepPurple', () {
      expect(QuizHelpers.getClassColor('12'), Colors.deepPurple);
    });

    test('unknown → Colors.grey', () {
      expect(QuizHelpers.getClassColor('university'), Colors.grey);
    });
  });
}
