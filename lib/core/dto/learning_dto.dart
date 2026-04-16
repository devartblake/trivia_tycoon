import 'package:flutter/material.dart';

/// Difficulty integer → human-readable label.
/// Matches the backend enum: 1=Easy, 2=Medium, 3=Hard, 4=Expert.
String difficultyLabel(int difficulty) {
  switch (difficulty) {
    case 1:
      return 'Easy';
    case 2:
      return 'Medium';
    case 3:
      return 'Hard';
    case 4:
      return 'Expert';
    default:
      return 'Unknown';
  }
}

/// UI colour suggestion per difficulty level.
Color difficultyColor(int difficulty) {
  switch (difficulty) {
    case 1:
      return Colors.green;
    case 2:
      return Colors.yellow.shade700;
    case 3:
      return Colors.orange;
    case 4:
      return Colors.red;
    default:
      return Colors.grey;
  }
}

// ---------------------------------------------------------------------------
// Module
// ---------------------------------------------------------------------------

class ModuleDto {
  final String id;
  final String title;
  final String description;
  final String category;
  final int difficulty;
  final int lessonCount;
  final int rewardXp;
  final int rewardCoins;
  final bool isCompleted;

  const ModuleDto({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.difficulty,
    required this.lessonCount,
    required this.rewardXp,
    required this.rewardCoins,
    required this.isCompleted,
  });

  String get difficultyText => difficultyLabel(difficulty);
  Color get difficultyColour => difficultyColor(difficulty);

  factory ModuleDto.fromJson(Map<String, dynamic> j) => ModuleDto(
        id: j['id'] as String,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        category: j['category'] as String? ?? '',
        difficulty: j['difficulty'] as int? ?? 1,
        lessonCount: j['lessonCount'] as int? ?? 0,
        rewardXp: j['rewardXp'] as int? ?? 0,
        rewardCoins: j['rewardCoins'] as int? ?? 0,
        isCompleted: j['isCompleted'] as bool? ?? false,
      );
}

// ---------------------------------------------------------------------------
// Lesson option
// ---------------------------------------------------------------------------

class LessonOptionDto {
  final String id;
  final String text;

  const LessonOptionDto({required this.id, required this.text});

  factory LessonOptionDto.fromJson(Map<String, dynamic> j) => LessonOptionDto(
        id: j['id'] as String,
        text: j['text'] as String,
      );
}

// ---------------------------------------------------------------------------
// Lesson
// ---------------------------------------------------------------------------

class LessonDto {
  final String lessonId;
  final int order;
  final String questionId;
  final String questionText;
  final String questionCategory;
  final List<LessonOptionDto> options;
  final String correctOptionId;
  final String? explanation;

  const LessonDto({
    required this.lessonId,
    required this.order,
    required this.questionId,
    required this.questionText,
    required this.questionCategory,
    required this.options,
    required this.correctOptionId,
    this.explanation,
  });

  factory LessonDto.fromJson(Map<String, dynamic> j) => LessonDto(
        lessonId: j['lessonId'] as String,
        order: j['order'] as int? ?? 0,
        questionId: j['questionId'] as String? ?? '',
        questionText: j['questionText'] as String,
        questionCategory: j['questionCategory'] as String? ?? '',
        options: (j['options'] as List<dynamic>? ?? [])
            .map((o) => LessonOptionDto.fromJson(o as Map<String, dynamic>))
            .toList(growable: false),
        correctOptionId: j['correctOptionId'] as String,
        explanation: j['explanation'] as String?,
      );
}

// ---------------------------------------------------------------------------
// Module completion response
// ---------------------------------------------------------------------------

class ModuleCompleteResponseDto {
  final String moduleId;
  final String playerId;
  final String status;
  final int rewardXp;
  final int rewardCoins;
  final int balanceXp;
  final int balanceCoins;

  const ModuleCompleteResponseDto({
    required this.moduleId,
    required this.playerId,
    required this.status,
    required this.rewardXp,
    required this.rewardCoins,
    required this.balanceXp,
    required this.balanceCoins,
  });

  bool get isFirstCompletion => status == 'Completed';

  factory ModuleCompleteResponseDto.fromJson(Map<String, dynamic> j) =>
      ModuleCompleteResponseDto(
        moduleId: j['moduleId'] as String,
        playerId: j['playerId'] as String,
        status: j['status'] as String,
        rewardXp: j['rewardXp'] as int? ?? 0,
        rewardCoins: j['rewardCoins'] as int? ?? 0,
        balanceXp: j['balanceXp'] as int? ?? 0,
        balanceCoins: j['balanceCoins'] as int? ?? 0,
      );
}
