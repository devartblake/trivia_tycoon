import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trivia_tycoon/game/models/favorite_category_models.dart';
import 'package:trivia_tycoon/game/models/favorite_question_models.dart';
import 'package:trivia_tycoon/game/models/word_search_model.dart';
import 'package:trivia_tycoon/game/models/skill_tree_category_colors.dart';
import 'package:trivia_tycoon/game/models/skill_tree_graph.dart';

void main() {
  // -------------------------------------------------------------------------
  // FavoriteCategory
  // -------------------------------------------------------------------------

  group('FavoriteCategory constructor', () {
    test('stores all required fields', () {
      final cat = FavoriteCategory(
        id: 'cat1',
        name: 'Science',
        icon: Icons.science,
        color: Colors.blue,
        questionCount: 10,
        progress: 0.5,
      );
      expect(cat.id, 'cat1');
      expect(cat.name, 'Science');
      expect(cat.icon, Icons.science);
      expect(cat.color, Colors.blue);
      expect(cat.questionCount, 10);
      expect(cat.progress, 0.5);
    });

    test('isFavorite defaults to false', () {
      final cat = FavoriteCategory(
        id: 'x',
        name: 'Math',
        icon: Icons.calculate,
        color: Colors.red,
        questionCount: 5,
        progress: 0.0,
      );
      expect(cat.isFavorite, isFalse);
    });

    test('isFavorite can be set to true', () {
      final cat = FavoriteCategory(
        id: 'y',
        name: 'History',
        icon: Icons.history,
        color: Colors.amber,
        questionCount: 3,
        progress: 1.0,
        isFavorite: true,
      );
      expect(cat.isFavorite, isTrue);
    });
  });

  group('FavoriteCategory.copyWith', () {
    final original = FavoriteCategory(
      id: 'orig',
      name: 'Original',
      icon: Icons.star,
      color: Colors.green,
      questionCount: 8,
      progress: 0.25,
    );

    test('copyWith isFavorite updates only that field', () {
      final updated = original.copyWith(isFavorite: true);
      expect(updated.isFavorite, isTrue);
      expect(updated.id, original.id);
      expect(updated.name, original.name);
    });

    test('copyWith questionCount updates only that field', () {
      final updated = original.copyWith(questionCount: 20);
      expect(updated.questionCount, 20);
      expect(updated.progress, original.progress);
    });

    test('copyWith without args preserves all fields', () {
      final copy = original.copyWith();
      expect(copy.id, original.id);
      expect(copy.progress, original.progress);
    });
  });

  // -------------------------------------------------------------------------
  // FavoriteQuestion
  // -------------------------------------------------------------------------

  group('FavoriteQuestion constructor', () {
    final date = DateTime(2024, 6, 15);

    test('stores all required fields', () {
      final q = FavoriteQuestion(
        id: 'q1',
        questionText: 'What is H2O?',
        category: 'science',
        categoryIcon: Icons.science,
        categoryColor: Colors.blue,
        difficulty: 'easy',
        correctCount: 3,
        incorrectCount: 1,
        addedDate: date,
      );
      expect(q.id, 'q1');
      expect(q.questionText, 'What is H2O?');
      expect(q.category, 'science');
      expect(q.difficulty, 'easy');
      expect(q.correctCount, 3);
      expect(q.incorrectCount, 1);
      expect(q.addedDate, date);
    });

    test('isFavorite defaults to false', () {
      final q = FavoriteQuestion(
        id: 'q2',
        questionText: 'Q?',
        category: 'math',
        categoryIcon: Icons.calculate,
        categoryColor: Colors.purple,
        difficulty: 'medium',
        correctCount: 0,
        incorrectCount: 0,
        addedDate: date,
      );
      expect(q.isFavorite, isFalse);
    });
  });

  group('FavoriteQuestion.accuracy', () {
    final date = DateTime(2024, 1, 1);

    test('accuracy = correctCount / (correct + incorrect)', () {
      final q = FavoriteQuestion(
        id: 'q',
        questionText: 'Q?',
        category: 'science',
        categoryIcon: Icons.science,
        categoryColor: Colors.blue,
        difficulty: 'hard',
        correctCount: 3,
        incorrectCount: 1,
        addedDate: date,
      );
      expect(q.accuracy, closeTo(0.75, 1e-9));
    });

    test('accuracy is 0.0 when no answers attempted', () {
      final q = FavoriteQuestion(
        id: 'q',
        questionText: 'Q?',
        category: 'math',
        categoryIcon: Icons.calculate,
        categoryColor: Colors.purple,
        difficulty: 'easy',
        correctCount: 0,
        incorrectCount: 0,
        addedDate: date,
      );
      expect(q.accuracy, 0.0);
    });

    test('accuracy is 1.0 when all correct', () {
      final q = FavoriteQuestion(
        id: 'q',
        questionText: 'Q?',
        category: 'math',
        categoryIcon: Icons.calculate,
        categoryColor: Colors.purple,
        difficulty: 'medium',
        correctCount: 5,
        incorrectCount: 0,
        addedDate: date,
      );
      expect(q.accuracy, closeTo(1.0, 1e-9));
    });
  });

  group('FavoriteQuestion.copyWith', () {
    final date = DateTime(2024, 3, 10);
    final original = FavoriteQuestion(
      id: 'q_orig',
      questionText: 'Original?',
      category: 'history',
      categoryIcon: Icons.history,
      categoryColor: Colors.orange,
      difficulty: 'hard',
      correctCount: 2,
      incorrectCount: 3,
      addedDate: date,
    );

    test('copyWith difficulty updates only that field', () {
      final updated = original.copyWith(difficulty: 'easy');
      expect(updated.difficulty, 'easy');
      expect(updated.category, original.category);
      expect(updated.correctCount, original.correctCount);
    });

    test('copyWith isFavorite toggles flag', () {
      final updated = original.copyWith(isFavorite: true);
      expect(updated.isFavorite, isTrue);
    });
  });

  // -------------------------------------------------------------------------
  // WordPosition
  // -------------------------------------------------------------------------

  group('WordPosition constructor', () {
    test('stores all fields', () {
      final pos = WordPosition(
        word: 'CAT',
        originalWord: 'CAT',
        positions: [Point<int>(0, 0), Point<int>(0, 1), Point<int>(0, 2)],
        color: Colors.red,
      );
      expect(pos.word, 'CAT');
      expect(pos.originalWord, 'CAT');
      expect(pos.positions.length, 3);
      expect(pos.color, Colors.red);
    });

    test('word and originalWord can differ (reversed words)', () {
      final pos = WordPosition(
        word: 'TAC',
        originalWord: 'CAT',
        positions: [Point<int>(0, 2), Point<int>(0, 1), Point<int>(0, 0)],
        color: Colors.blue,
      );
      expect(pos.word, 'TAC');
      expect(pos.originalWord, 'CAT');
    });
  });

  // -------------------------------------------------------------------------
  // SkillTreeCategoryColors
  // -------------------------------------------------------------------------

  group('SkillTreeCategoryColors.getColor', () {
    test('returns Color for known category (xp)', () {
      final color = SkillTreeCategoryColors.getColor(SkillCategory.xp);
      expect(color, isA<Color>());
    });

    test('returns Colors.grey for unknown category', () {
      expect(
        SkillTreeCategoryColors.getColor(SkillCategory.unknown),
        Colors.grey,
      );
    });

    test('categoryColors map has entries for all non-general categories', () {
      for (final cat in SkillCategory.values) {
        final color = SkillTreeCategoryColors.getColor(cat);
        expect(color, isA<Color>(), reason: 'missing color for $cat');
      }
    });

    test('different categories return different colors (at least some)', () {
      final xpColor = SkillTreeCategoryColors.getColor(SkillCategory.xp);
      final combatColor =
          SkillTreeCategoryColors.getColor(SkillCategory.combat);
      expect(xpColor, isNot(combatColor));
    });
  });
}
