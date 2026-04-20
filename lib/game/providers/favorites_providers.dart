import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/favorite_category_models.dart';
import '../models/favorite_question_models.dart';

/// Provider for favorite categories
final favoriteCategoriesProvider =
    StateNotifierProvider<FavoriteCategoriesNotifier, List<FavoriteCategory>>(
        (ref) {
  return FavoriteCategoriesNotifier();
});

class FavoriteCategoriesNotifier extends StateNotifier<List<FavoriteCategory>> {
  FavoriteCategoriesNotifier() : super([]);

  void loadCategories(List<FavoriteCategory> categories) {
    state = categories;
  }

  void toggleFavorite(String categoryId) {
    state = [
      for (final category in state)
        if (category.id == categoryId)
          category.copyWith(isFavorite: !category.isFavorite)
        else
          category,
    ];
  }

  void removeCategory(String categoryId) {
    state = state.where((cat) => cat.id != categoryId).toList();
  }

  void updateProgress(String categoryId, double progress) {
    state = [
      for (final category in state)
        if (category.id == categoryId)
          category.copyWith(progress: progress)
        else
          category,
    ];
  }
}

/// Provider for favorite questions
final favoriteQuestionsProvider =
    StateNotifierProvider<FavoriteQuestionsNotifier, List<FavoriteQuestion>>(
        (ref) {
  return FavoriteQuestionsNotifier();
});

class FavoriteQuestionsNotifier extends StateNotifier<List<FavoriteQuestion>> {
  FavoriteQuestionsNotifier() : super([]);

  void loadQuestions(List<FavoriteQuestion> questions) {
    state = questions;
  }

  void addQuestion(FavoriteQuestion question) {
    state = [...state, question];
  }

  void toggleFavorite(String questionId) {
    state = [
      for (final question in state)
        if (question.id == questionId)
          question.copyWith(isFavorite: !question.isFavorite)
        else
          question,
    ];
  }

  void removeQuestion(String questionId) {
    state = state.where((q) => q.id != questionId).toList();
  }

  void updateStats(String questionId,
      {int? correctCount, int? incorrectCount}) {
    state = [
      for (final question in state)
        if (question.id == questionId)
          question.copyWith(
            correctCount: correctCount ?? question.correctCount,
            incorrectCount: incorrectCount ?? question.incorrectCount,
          )
        else
          question,
    ];
  }
}

/// Computed provider for favorite count
final favoritesCountProvider = Provider<int>((ref) {
  final categories = ref.watch(favoriteCategoriesProvider);
  final questions = ref.watch(favoriteQuestionsProvider);
  return categories.where((c) => c.isFavorite).length +
      questions.where((q) => q.isFavorite).length;
});

/// Filtered categories by search
final filteredCategoriesProvider =
    Provider.family<List<FavoriteCategory>, String>((ref, searchQuery) {
  final categories = ref.watch(favoriteCategoriesProvider);
  if (searchQuery.isEmpty) return categories;
  return categories
      .where(
          (cat) => cat.name.toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();
});

/// Filtered questions by search
final filteredQuestionsProvider =
    Provider.family<List<FavoriteQuestion>, String>((ref, searchQuery) {
  final questions = ref.watch(favoriteQuestionsProvider);
  if (searchQuery.isEmpty) return questions;
  return questions
      .where((q) =>
          q.questionText.toLowerCase().contains(searchQuery.toLowerCase()))
      .toList();
});
