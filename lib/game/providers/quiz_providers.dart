import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/question_model.dart';
import '../services/question_loader_service.dart';
import '../services/quiz_category.dart';
import '../state/quiz_state.dart'; // Use your existing quiz_state.dart

// Provider for the question loader service
final adaptedQuestionLoaderProvider = Provider<AdaptedQuestionLoaderService>((ref) {
  return AdaptedQuestionLoaderService();
});

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
  final service = ref.read(adaptedQuestionLoaderProvider);
  return await service.getAvailableQuizCategories();
});

final categoryQuestionCountProvider = FutureProvider.family<int, QuizCategory>((ref, category) async {
  final service = ref.read(adaptedQuestionLoaderProvider);
  return await service.getQuizCategoryQuestionCount(category);
});

final categoryDifficultyProvider = FutureProvider.family<String, QuizCategory>((ref, category) async {
  final service = ref.read(adaptedQuestionLoaderProvider);
  return await service.getQuizCategoryDifficulty(category);
});

// Class-specific providers
final classQuestionCountProvider = FutureProvider.family<int, String>((ref, classId) async {
  final service = ref.read(adaptedQuestionLoaderProvider);
  return await service.getClassQuestionCount(classId);
});

final classSubjectCountProvider = FutureProvider.family<int, String>((ref, classId) async {
  final service = ref.read(adaptedQuestionLoaderProvider);
  return await service.getClassSubjectCount(classId);
});

// Service status provider
final serviceStatusProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final service = ref.read(adaptedQuestionLoaderProvider);
  return await service.getServiceStatus();
});