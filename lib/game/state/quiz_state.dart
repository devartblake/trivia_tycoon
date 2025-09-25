import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../services/quiz_category.dart';
import '../models/question_model.dart';
import '../services/question_loader_service.dart';

/// Enhanced quiz state with category enum support
class AdaptedQuizState {
  final List<QuestionModel> questions;
  final int currentIndex;
  final int score;
  final int totalXP;
  final int? coins;
  final int? diamonds;
  final int? stars;
  final String classLevel;
  final QuizCategory? category; // Changed from String to QuizCategory
  final bool isLoading;
  final String? error;
  final String? selectedAnswer;
  final bool showFeedback;
  final int timeRemaining;
  final bool isPaused;
  final bool isTimerExpired;
  final bool hasUsedPowerUp;
  final bool hasUsedExtraTime;
  final bool isAudioPlaying;
  final Duration audioPosition;
  final Duration? audioDuration;
  final Map<String, int>? categoryScores;
  final List<String>? achievements;
  final DateTime? quizStartTime;
  final DateTime? quizEndTime;
  final Stopwatch? stopwatch;

  const AdaptedQuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.totalXP = 0,
    this.coins,
    this.diamonds,
    this.stars,
    this.classLevel = '1',
    this.category,
    this.isLoading = false,
    this.error,
    this.selectedAnswer,
    this.showFeedback = false,
    this.timeRemaining = 30,
    this.isPaused = false,
    this.isTimerExpired = false,
    this.hasUsedPowerUp = false,
    this.hasUsedExtraTime = false,
    this.isAudioPlaying = false,
    this.audioPosition = Duration.zero,
    this.audioDuration,
    this.categoryScores,
    this.achievements,
    this.quizStartTime,
    this.quizEndTime,
    this.stopwatch,
  });

  AdaptedQuizState copyWith({
    List<QuestionModel>? questions,
    int? currentIndex,
    int? score,
    int? totalXP,
    int? coins,
    int? diamonds,
    int? stars,
    String? classLevel,
    QuizCategory? category,
    bool? isLoading,
    String? error,
    String? selectedAnswer,
    bool? showFeedback,
    int? timeRemaining,
    bool? isPaused,
    bool? isTimerExpired,
    bool? hasUsedPowerUp,
    bool? hasUsedExtraTime,
    bool? isAudioPlaying,
    Duration? audioPosition,
    Duration? audioDuration,
    Map<String, int>? categoryScores,
    List<String>? achievements,
    DateTime? quizStartTime,
    DateTime? quizEndTime,
    Stopwatch? stopwatch,
  }) {
    return AdaptedQuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      totalXP: totalXP ?? this.totalXP,
      coins: coins ?? this.coins,
      diamonds: diamonds ?? this.diamonds,
      stars: stars ?? this.stars,
      classLevel: classLevel ?? this.classLevel,
      category: category ?? this.category,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      showFeedback: showFeedback ?? this.showFeedback,
      timeRemaining: timeRemaining ?? this.timeRemaining,
      isPaused: isPaused ?? this.isPaused,
      isTimerExpired: isTimerExpired ?? this.isTimerExpired,
      hasUsedPowerUp: hasUsedPowerUp ?? this.hasUsedPowerUp,
      hasUsedExtraTime: hasUsedExtraTime ?? this.hasUsedExtraTime,
      isAudioPlaying: isAudioPlaying ?? this.isAudioPlaying,
      audioPosition: audioPosition ?? this.audioPosition,
      audioDuration: audioDuration ?? this.audioDuration,
      categoryScores: categoryScores ?? this.categoryScores,
      achievements: achievements ?? this.achievements,
      quizStartTime: quizStartTime ?? this.quizStartTime,
      quizEndTime: quizEndTime ?? this.quizEndTime,
      stopwatch: stopwatch ?? this.stopwatch,
    );
  }

  // Computed properties
  QuestionModel? get currentQuestion =>
      currentIndex < questions.length ? questions[currentIndex] : null;

  int get totalQuestions => questions.length;

  bool get isLastQuestion => currentIndex >= questions.length - 1;

  double get scorePercentage =>
      totalQuestions > 0 ? (score / totalQuestions) * 100 : 0;

  Duration get quizDuration {
    if (quizStartTime == null) return Duration.zero;
    final endTime = quizEndTime ?? DateTime.now();
    return endTime.difference(quizStartTime!);
  }

  String get categoryDisplayName => category?.displayName ?? 'Mixed';
  String get categoryDescription => category?.description ?? 'Mixed category questions';
  Color get categoryColor => category?.primaryColor ?? Colors.grey;
  IconData get categoryIcon => category?.icon ?? Icons.quiz;
}

/// Enhanced quiz provider with category enum support
class AdaptedQuizNotifier extends StateNotifier<AdaptedQuizState> {
  AdaptedQuizNotifier() : super(const AdaptedQuizState());

  final AdaptedQuestionLoaderService service = AdaptedQuestionLoaderService();
  Timer? _timer;

  /// Start a quiz with category enum support
  Future<void> startQuiz({
    int questionCount = 10,
    String classLevel = '1',
    QuizCategory? category,
    List<int>? difficulties,
    bool includeImages = true,
    bool includeVideos = true,
    bool includeAudio = true,
  }) async {
    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        classLevel: classLevel,
        category: category,
        quizStartTime: DateTime.now(),
        stopwatch: Stopwatch()..start(),
      );

      List<QuestionModel> questions;

      if (category != null) {
        // Load questions for specific category
        questions = await service.startCategoryQuiz(
          category: category,
          questionCount: questionCount,
          difficulties: difficulties,
          includeImages: includeImages,
          includeVideos: includeVideos,
          includeAudio: includeAudio,
        );
      } else {
        // Fallback to class-based quiz
        final classNumber = int.tryParse(classLevel) ?? 1;
        questions = await service.getQuizByClass(
          classNumber,
          questionCount: questionCount,
        );
      }

      if (questions.isEmpty) {
        throw Exception('No questions available for the selected criteria');
      }

      // Initialize category scores map
      final categoryScores = <String, int>{};
      if (category != null) {
        categoryScores[category.name] = 0;
      } else {
        // Initialize scores for all categories present in questions
        for (final question in questions) {
          categoryScores[question.category] = 0;
        }
      }

      state = state.copyWith(
        questions: questions,
        currentIndex: 0,
        score: 0,
        totalXP: 0,
        coins: 0,
        diamonds: 0,
        stars: 0,
        isLoading: false,
        timeRemaining: _getTimeLimitForClass(classLevel),
        categoryScores: categoryScores,
        achievements: <String>[],
      );

      _startTimer();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Start quiz with category enum support (alias for compatibility)
  Future<void> startQuizWithCategory({
    required String classLevel,
    QuizCategory? category,
    int questionCount = 10,
  }) async {
    await startQuiz(
      questionCount: questionCount,
      classLevel: classLevel,
      category: category,
    );
  }

  /// Compatibility method for class-based quiz starting
  Future<void> startQuizByCategory({
    required String classLevel,
    required String category,
    int questionCount = 10,
  }) async {
    await startQuizWithString(
      questionCount: questionCount,
      classLevel: classLevel,
      categoryString: category,
    );
  }

  /// Start a quiz with string category (backward compatibility)
  Future<void> startQuizWithString({
    int questionCount = 10,
    String classLevel = '1',
    String? categoryString,
    List<int>? difficulties,
    bool includeImages = true,
    bool includeVideos = true,
    bool includeAudio = true,
  }) async {
    QuizCategory? category;

    if (categoryString != null && categoryString.toLowerCase() != 'mixed') {
      category = QuizCategoryManager.fromString(categoryString);
    }

    await startQuiz(
      questionCount: questionCount,
      classLevel: classLevel,
      category: category,
      difficulties: difficulties,
      includeImages: includeImages,
      includeVideos: includeVideos,
      includeAudio: includeAudio,
    );
  }

  /// Answer a question
  void answerQuestion(String answer) {
    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) return;

    _stopTimer();

    final isCorrect = currentQuestion.isCorrectAnswer(answer);
    final isTimeout = answer.isEmpty;

    int newScore = state.score;
    int xpGained = 0;
    int coinsGained = 0;
    int diamondsGained = 0;
    int starsGained = 0;

    if (isCorrect && !isTimeout) {
      newScore++;

      // Calculate XP based on difficulty and time
      xpGained = _calculateXP(currentQuestion.difficulty, state.timeRemaining);

      // Calculate rewards
      coinsGained = _calculateCoins(currentQuestion.difficulty);
      if (state.timeRemaining > 20) {
        diamondsGained = 1; // Time bonus
      }
      if (currentQuestion.difficulty >= 3) {
        starsGained = 1; // Difficulty bonus
      }

      // Update category scores
      final updatedCategoryScores = Map<String, int>.from(state.categoryScores ?? {});
      final questionCategory = state.category?.name ?? currentQuestion.category;
      updatedCategoryScores[questionCategory] = (updatedCategoryScores[questionCategory] ?? 0) + 1;

      state = state.copyWith(
        categoryScores: updatedCategoryScores,
      );
    }

    state = state.copyWith(
      score: newScore,
      totalXP: state.totalXP + xpGained,
      coins: (state.coins ?? 0) + coinsGained,
      diamonds: (state.diamonds ?? 0) + diamondsGained,
      stars: (state.stars ?? 0) + starsGained,
      selectedAnswer: answer,
      showFeedback: true,
    );
  }

  /// Move to next question
  void nextQuestion() {
    if (state.isLastQuestion) {
      completeQuiz();
      return;
    }

    state = state.copyWith(
      currentIndex: state.currentIndex + 1,
      selectedAnswer: null,
      showFeedback: false,
      timeRemaining: _getTimeLimitForClass(state.classLevel),
      hasUsedPowerUp: false,
      isTimerExpired: false,
    );

    _startTimer();
  }

  /// Complete the quiz
  void completeQuiz() {
    _stopTimer();

    final endTime = DateTime.now();
    final stopwatch = state.stopwatch;
    stopwatch?.stop();

    // Calculate achievements based on performance
    final achievements = _calculateAchievements();

    state = state.copyWith(
      quizEndTime: endTime,
      achievements: achievements,
    );
  }

  /// Calculate achievements based on quiz performance
  List<String> _calculateAchievements() {
    final achievements = <String>[];
    final scorePercentage = state.scorePercentage;

    // Score-based achievements
    if (scorePercentage >= 100) {
      achievements.add('Perfect Score');
    } else if (scorePercentage >= 90) {
      achievements.add('Excellent Performance');
    } else if (scorePercentage >= 80) {
      achievements.add('Great Job');
    } else if (scorePercentage >= 70) {
      achievements.add('Good Work');
    }

    // Category-specific achievements
    if (state.category != null) {
      achievements.add('${state.category!.displayName} Expert');
    }

    // XP-based achievements
    if (state.totalXP >= 500) {
      achievements.add('XP Master');
    } else if (state.totalXP >= 300) {
      achievements.add('XP Champion');
    }

    // Speed achievements
    final avgTimePerQuestion = state.quizDuration.inSeconds / state.totalQuestions;
    if (avgTimePerQuestion < 15) {
      achievements.add('Speed Demon');
    }

    return achievements;
  }

  /// Apply power-up
  void applyPowerUp(String powerUpType) {
    switch (powerUpType) {
      case 'hint':
      // Show hint for current question
        break;
      case 'time':
      // Add extra time
        state = state.copyWith(
          timeRemaining: state.timeRemaining + 15,
          hasUsedExtraTime: true,
        );
        break;
      case 'skip':
      // Skip current question
        nextQuestion();
        break;
    }

    state = state.copyWith(hasUsedPowerUp: true);
  }

  /// Audio controls
  void playAudio() {
    state = state.copyWith(isAudioPlaying: true);
  }

  void pauseAudio() {
    state = state.copyWith(isAudioPlaying: false);
  }

  /// Timer management
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state.timeRemaining <= 0) {
        timer.cancel();
        state = state.copyWith(isTimerExpired: true);
        // Auto-answer with empty string (timeout)
        answerQuestion('');
      } else if (!state.isPaused) {
        state = state.copyWith(timeRemaining: state.timeRemaining - 1);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void pauseTimer() {
    state = state.copyWith(isPaused: true);
  }

  void resumeTimer() {
    state = state.copyWith(isPaused: false);
  }

  /// Helper methods
  int _getTimeLimitForClass(String classLevel) {
    final level = int.tryParse(classLevel) ?? 1;
    if (level <= 2) return 45; // More time for younger students
    if (level <= 5) return 35;
    if (level <= 8) return 30;
    return 25; // Less time for older students
  }

  int _calculateXP(int difficulty, int timeRemaining) {
    int baseXP = difficulty * 10; // 10, 20, 30 for easy, medium, hard

    // Time bonus (up to 50% more XP)
    if (timeRemaining > 20) {
      baseXP = (baseXP * 1.5).round();
    } else if (timeRemaining > 10) {
      baseXP = (baseXP * 1.25).round();
    }

    return baseXP;
  }

  int _calculateCoins(int difficulty) {
    return difficulty * 5; // 5, 10, 15 coins
  }

  @override
  void dispose() {
    _timer?.cancel();
    state.stopwatch?.stop();
    super.dispose();
  }
}

/// Provider for the adapted quiz
final adaptedQuizProvider = StateNotifierProvider<AdaptedQuizNotifier, AdaptedQuizState>((ref) {
  return AdaptedQuizNotifier();
});

/// Provider for available quiz categories
final availableQuizCategoriesProvider = FutureProvider<List<QuizCategory>>((ref) async {
  final service = AdaptedQuestionLoaderService();
  return await service.getAvailableQuizCategories();
});