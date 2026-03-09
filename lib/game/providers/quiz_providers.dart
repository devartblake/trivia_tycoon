import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../services/quiz_category.dart';
import 'question_providers.dart' as question_data;
import '../state/quiz_state.dart'; // Use your existing quiz_state.dart

// Main quiz provider - uses your existing quiz_state.dart implementation
final adaptedQuizProvider = StateNotifierProvider<AdaptedQuizNotifier, AdaptedQuizState>((ref) {
  return AdaptedQuizNotifier();
});

// Helper providers for computed values
final currentQuestionProvider = Provider<QuestionModel?>((ref) {
  final state = ref.watch(adaptedQuizProvider);
  return state.currentQuestion;
});

final quizProgressProvider = Provider<double>((ref) {
  final state = ref.watch(adaptedQuizProvider);
  if (state.totalQuestions == 0) return 0.0;
  return (state.currentIndex + 1) / state.totalQuestions;
});

final isQuizCompleteProvider = Provider<bool>((ref) {
  final state = ref.watch(adaptedQuizProvider);
  return state.isLastQuestion && state.showFeedback;
});

// Timer color helper
final timerColorProvider = Provider<Color>((ref) {
  final state = ref.watch(adaptedQuizProvider);
  final timeRemaining = state.timeRemaining;

  if (timeRemaining > 20) return Colors.green;
  if (timeRemaining > 10) return Colors.orange;
  return Colors.red;
});

// Category-specific providers
final availableQuizCategoriesProvider = FutureProvider<List<QuizCategory>>((ref) async {
  return ref.watch(question_data.quizCategoriesProvider.future);
});

final categoryQuestionCountProvider = FutureProvider.family<int, QuizCategory>((ref, category) async {
  final stats = await ref.watch(question_data.categoryStatsProvider(category).future);
  return (stats['questionCount'] as num?)?.toInt() ?? 0;
});

final categoryDifficultyProvider = FutureProvider.family<String, QuizCategory>((ref, category) async {
  final stats = await ref.watch(question_data.categoryStatsProvider(category).future);
  return (stats['difficulty']?.toString() ?? 'mixed').toLowerCase();
});

// Class-specific providers
final classQuestionCountProvider = FutureProvider.family<int, String>((ref, classId) async {
  final stats = await ref.watch(question_data.classStatsProvider(classId).future);
  return (stats['questionCount'] as num?)?.toInt() ?? 0;
});

final classSubjectCountProvider = FutureProvider.family<int, String>((ref, classId) async {
  final stats = await ref.watch(question_data.classStatsProvider(classId).future);
  return (stats['subjectCount'] as num?)?.toInt() ?? 0;
});

// Service status provider
final serviceStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final questionStats = await ref.watch(question_data.questionStatsProvider.future);
  final datasetInfo = await ref.watch(question_data.datasetInfoProvider.future);

  return {
    'isHealthy': true,
    'source': 'repository',
    'questionStats': questionStats,
    'datasetInfo': datasetInfo,
  };
});