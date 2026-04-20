import 'package:flutter/material.dart';

class FavoriteQuestion {
  final String id;
  final String questionText;
  final String category;
  final IconData categoryIcon;
  final Color categoryColor;
  final String difficulty;
  final int correctCount;
  final int incorrectCount;
  final DateTime addedDate;
  final bool isFavorite;

  FavoriteQuestion({
    required this.id,
    required this.questionText,
    required this.category,
    required this.categoryIcon,
    required this.categoryColor,
    required this.difficulty,
    required this.correctCount,
    required this.incorrectCount,
    required this.addedDate,
    this.isFavorite = false,
  });

  FavoriteQuestion copyWith({
    String? id,
    String? questionText,
    String? category,
    IconData? categoryIcon,
    Color? categoryColor,
    String? difficulty,
    int? correctCount,
    int? incorrectCount,
    DateTime? addedDate,
    bool? isFavorite,
  }) {
    return FavoriteQuestion(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      category: category ?? this.category,
      categoryIcon: categoryIcon ?? this.categoryIcon,
      categoryColor: categoryColor ?? this.categoryColor,
      difficulty: difficulty ?? this.difficulty,
      correctCount: correctCount ?? this.correctCount,
      incorrectCount: incorrectCount ?? this.incorrectCount,
      addedDate: addedDate ?? this.addedDate,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  double get accuracy {
    final total = correctCount + incorrectCount;
    return total > 0 ? correctCount / total : 0.0;
  }
}
