import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/question/widgets/adapted_question_widgets.dart';
import '../../game/data/question_loader_service.dart';
import '../../game/models/question_model.dart';
// Provider for the question loader service
final adaptedQuestionLoaderProvider = Provider<AdaptedQuestionLoaderService>((ref) {
  return AdaptedQuestionLoaderService();
});

// Provider for current quiz state using your QuestionModel
final adaptedQuizProvider = StateNotifierProvider<AdaptedQuizStateNotifier, AdaptedQuizState>((ref) {
  return AdaptedQuizStateNotifier(ref.read(adaptedQuestionLoaderProvider));
});

class AdaptedQuizState {
  final List<QuestionModel> questions;
  final int currentIndex;
  final int score;
  final int totalQuestions;
  final String? selectedAnswer;
  final bool showFeedback;
  final bool isLoading;
  final String? error;
  final int totalXP;
  final Map<String, int> categoryScores;

  const AdaptedQuizState({
    this.questions = const [],
    this.currentIndex = 0,
    this.score = 0,
    this.totalQuestions = 0,
    this.selectedAnswer,
    this.showFeedback = false,
    this.isLoading = false,
    this.error,
    this.totalXP = 0,
    this.categoryScores = const {},
  });

  AdaptedQuizState copyWith({
    List<QuestionModel>? questions,
    int? currentIndex,
    int? score,
    int? totalQuestions,
    String? selectedAnswer,
    bool? showFeedback,
    bool? isLoading,
    String? error,
    int? totalXP,
    Map<String, int>? categoryScores,
  }) {
    return AdaptedQuizState(
      questions: questions ?? this.questions,
      currentIndex: currentIndex ?? this.currentIndex,
      score: score ?? this.score,
      totalQuestions: totalQuestions ?? this.totalQuestions,
      selectedAnswer: selectedAnswer ?? this.selectedAnswer,
      showFeedback: showFeedback ?? this.showFeedback,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      totalXP: totalXP ?? this.totalXP,
      categoryScores: categoryScores ?? this.categoryScores,
    );
  }

  QuestionModel? get currentQuestion {
    if (currentIndex >= 0 && currentIndex < questions.length) {
      return questions[currentIndex];
    }
    return null;
  }

  bool get isLastQuestion => currentIndex >= questions.length - 1;

  double get scorePercentage {
    if (totalQuestions == 0) return 0.0;
    return (score / totalQuestions) * 100;
  }
}

class AdaptedQuizStateNotifier extends StateNotifier<AdaptedQuizState> {
  final AdaptedQuestionLoaderService _questionLoader;

  AdaptedQuizStateNotifier(this._questionLoader) : super(const AdaptedQuizState());

  /// Start a new quiz with specified parameters
  Future<void> startQuiz({
    int questionCount = 10,
    List<String>? categories,
    List<dynamic>? difficulties,
    List<String>? types,
    List<String>? tags,
    bool includeImages = true,
    bool includeVideos = true,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final questions = await _questionLoader.getMixedQuiz(
        questionCount: questionCount,
        categories: categories,
        difficulties: difficulties,
        types: types,
        tags: tags,
        includeImages: includeImages,
        includeVideos: includeVideos,
      );

      state = state.copyWith(
        questions: questions,
        totalQuestions: questions.length,
        currentIndex: 0,
        score: 0,
        totalXP: 0,
        categoryScores: {},
        isLoading: false,
        selectedAnswer: null,
        showFeedback: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Answer the current question
  void answerQuestion(String answer) {
    if (state.currentQuestion == null || state.showFeedback) return;

    final question = state.currentQuestion!;
    final isCorrect = question.isCorrectAnswer(answer);

    // Calculate score and XP
    int newScore = state.score;
    int xpGained = 0;

    if (isCorrect) {
      newScore++;

      // Base XP based on difficulty
      int baseXP = question.difficulty * 10; // 10 for easy, 20 for medium, 30 for hard

      // Apply multiplier if present
      if (question.multiplier != null) {
        xpGained = baseXP * question.multiplier!;
      } else {
        xpGained = baseXP;
      }
    }

    // Update category scores
    final newCategoryScores = Map<String, int>.from(state.categoryScores);
    if (isCorrect) {
      newCategoryScores[question.category] = (newCategoryScores[question.category] ?? 0) + 1;
    }

    state = state.copyWith(
      selectedAnswer: answer,
      showFeedback: true,
      score: newScore,
      totalXP: state.totalXP + xpGained,
      categoryScores: newCategoryScores,
    );
  }

  /// Apply power-up to current question
  void applyPowerUp(String powerUpType) {
    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) return;

    switch (powerUpType.toLowerCase()) {
      case 'hint':
      // Show hint
        final updatedQuestion = currentQuestion.copyWith(showHint: true);
        final updatedQuestions = List<QuestionModel>.from(state.questions);
        updatedQuestions[state.currentIndex] = updatedQuestion;

        state = state.copyWith(questions: updatedQuestions);
        break;

      case 'eliminate':
      // Reduce options to 2 (correct + 1 incorrect)
        final correctAnswer = currentQuestion.correctAnswer;
        final incorrectOptions = currentQuestion.options
            .where((option) => option != correctAnswer)
            .toList();

        if (incorrectOptions.isNotEmpty) {
          incorrectOptions.shuffle();
          final reducedOptions = [correctAnswer, incorrectOptions.first];
          reducedOptions.shuffle();

          final updatedQuestion = currentQuestion.copyWith(reducedOptions: reducedOptions);
          final updatedQuestions = List<QuestionModel>.from(state.questions);
          updatedQuestions[state.currentIndex] = updatedQuestion;

          state = state.copyWith(questions: updatedQuestions);
        }
        break;

      case 'shield':
      // Apply shield protection
        final updatedQuestion = currentQuestion.copyWith(isShielded: true);
        final updatedQuestions = List<QuestionModel>.from(state.questions);
        updatedQuestions[state.currentIndex] = updatedQuestion;

        state = state.copyWith(questions: updatedQuestions);
        break;

      case 'time_boost':
      // Apply time boost
        final updatedQuestion = currentQuestion.copyWith(isBoostedTime: true);
        final updatedQuestions = List<QuestionModel>.from(state.questions);
        updatedQuestions[state.currentIndex] = updatedQuestion;

        state = state.copyWith(questions: updatedQuestions);
        break;
    }
  }

  /// Move to the next question
  void nextQuestion() {
    if (state.currentIndex < state.questions.length - 1) {
      state = state.copyWith(
        currentIndex: state.currentIndex + 1,
        selectedAnswer: null,
        showFeedback: false,
      );
    }
  }

  /// Reset the quiz
  void resetQuiz() {
    state = const AdaptedQuizState();
  }
}

class AdaptedQuestionScreen extends ConsumerStatefulWidget {
  const AdaptedQuestionScreen({super.key});

  @override
  ConsumerState<AdaptedQuestionScreen> createState() => _AdaptedQuestionScreenState();
}

class _AdaptedQuestionScreenState extends ConsumerState<AdaptedQuestionScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Start quiz when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adaptedQuizProvider.notifier).startQuiz(questionCount: 10);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _showFeedbackDialog({
    required bool isCorrect,
    required QuestionModel question,
    required int xpGained,
    required VoidCallback onNext,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Feedback',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 1),
                end: Offset.zero,
              ).animate(animation),
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isCorrect ? Icons.check_circle : Icons.cancel,
                      color: Colors.white,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      isCorrect ? "Correct!" : "Oops!",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (isCorrect && xpGained > 0)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '+$xpGained XP',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (question.multiplier != null && isCorrect)
                      Text(
                        '${question.multiplier}x Multiplier Applied!',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 12,
                        ),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: isCorrect ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onNext();
                      },
                      child: const Text("Next Question"),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleAnswer(String answer) async {
    final notifier = ref.read(adaptedQuizProvider.notifier);
    final state = ref.read(adaptedQuizProvider);

    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) return;

    final isCorrect = currentQuestion.isCorrectAnswer(answer);

    // Calculate XP gained
    int xpGained = 0;
    if (isCorrect) {
      int baseXP = currentQuestion.difficulty * 10;
      xpGained = currentQuestion.multiplier != null ? baseXP * currentQuestion.multiplier! : baseXP;
    }

    notifier.answerQuestion(answer);

    await _showFeedbackDialog(
      isCorrect: isCorrect,
      question: currentQuestion,
      xpGained: xpGained,
      onNext: () {
        final currentState = ref.read(adaptedQuizProvider);

        if (currentState.isLastQuestion) {
          // Navigate to score summary
          context.go('/score-summary', extra: {
            'score': currentState.score,
            'money': currentState.score * 10, // 10 money per correct answer
            'diamonds': currentState.score > (currentState.totalQuestions * 0.8) ? 5 : 0, // 5 diamonds for 80%+ score
            'total': currentState.totalQuestions,
            'percentage': currentState.scorePercentage.round(),
            'totalXP': currentState.totalXP,
            'categoryScores': currentState.categoryScores,
          });
        } else {
          notifier.nextQuestion();
          _pageController.nextPage(
            duration: const Duration(milliseconds: 500),
            curve: Curves.easeInOut,
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(adaptedQuizProvider);

    if (quizState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading questions...'),
            ],
          ),
        ),
      );
    }

    if (quizState.error != null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text('Error: ${quizState.error}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  ref.read(adaptedQuizProvider.notifier).startQuiz();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (quizState.questions.isEmpty || quizState.currentQuestion == null) {
      return const Scaffold(
        body: Center(
          child: Text('No questions available'),
        ),
      );
    }

    final currentQuestion = quizState.currentQuestion!;

    return Scaffold(
      appBar: AppBar(
        title: Text("Question ${quizState.currentIndex + 1} of ${quizState.totalQuestions}"),
        actions: [
          // Score display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Score: ${quizState.score}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ),
          ),
          // XP display
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.purple.shade100,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${quizState.totalXP} XP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple.shade700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Progress indicator
          LinearProgressIndicator(
            value: (quizState.currentIndex + 1) / quizState.totalQuestions,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),

          // Main content
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quizState.questions.length,
              itemBuilder: (context, index) {
                if (index != quizState.currentIndex) return const SizedBox();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question metadata
                      Row(
                        children: [
                          // Question type indicator
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getDisplayTypeColor(currentQuestion),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              _getDisplayTypeName(currentQuestion),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),

                          const SizedBox(width: 8),

                          // Category
                          Icon(Icons.category, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            currentQuestion.category.toUpperCase(),
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Difficulty
                          Icon(_getDifficultyIcon(currentQuestion.difficulty),
                              size: 16, color: _getDifficultyColor(currentQuestion.difficulty)),
                          const SizedBox(width: 4),
                          Text(
                            _getDifficultyText(currentQuestion.difficulty).toUpperCase(),
                            style: TextStyle(
                              color: _getDifficultyColor(currentQuestion.difficulty),
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Dynamic question widget based on type
                      AdaptedQuestionWidget.create(
                        question: currentQuestion,
                        onAnswerSelected: _handleAnswer,
                        showFeedback: quizState.showFeedback,
                        selectedAnswer: quizState.selectedAnswer,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),

      // Power-up buttons
      floatingActionButton: quizState.showFeedback ? null : _buildPowerUpButtons(currentQuestion),
    );
  }

  Color _getDisplayTypeColor(QuestionModel question) {
    if (question.imageUrl?.isNotEmpty == true) {
      return Colors.green;
    } else if (question.videoUrl?.isNotEmpty == true) {
      return Colors.purple;
    } else {
      return Colors.blue;
    }
  }

  String _getDisplayTypeName(QuestionModel question) {
    if (question.imageUrl?.isNotEmpty == true) {
      return 'Image';
    } else if (question.videoUrl?.isNotEmpty == true) {
      return 'Video';
    } else {
      return 'Text';
    }
  }

  IconData _getDifficultyIcon(int difficulty) {
    switch (difficulty) {
      case 1:
        return Icons.star_outline;
      case 2:
        return Icons.star_half;
      case 3:
        return Icons.star;
      default:
        return Icons.help_outline;
    }
  }

  Color _getDifficultyColor(int difficulty) {
    switch (difficulty) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getDifficultyText(int difficulty) {
    switch (difficulty) {
      case 1:
        return 'easy';
      case 2:
        return 'medium';
      case 3:
        return 'hard';
      default:
        return 'unknown';
    }
  }

  Widget? _buildPowerUpButtons(QuestionModel question) {
    // Only show power-up buttons if they haven't been used
    final availablePowerUps = <String>[];

    if (!question.showHint && question.powerUpHint?.isNotEmpty == true) {
      availablePowerUps.add('hint');
    }
    if (question.reducedOptions == null && question.options.length > 2) {
      availablePowerUps.add('eliminate');
    }
    if (!question.isShielded) {
      availablePowerUps.add('shield');
    }
    if (!question.isBoostedTime) {
      availablePowerUps.add('time_boost');
    }

    if (availablePowerUps.isEmpty) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: availablePowerUps.map((powerUp) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FloatingActionButton.small(
            heroTag: powerUp,
            onPressed: () {
              ref.read(adaptedQuizProvider.notifier).applyPowerUp(powerUp);
            },
            backgroundColor: _getPowerUpColor(powerUp),
            child: Icon(_getPowerUpIcon(powerUp), color: Colors.white),
          ),
        );
      }).toList(),
    );
  }

  Color _getPowerUpColor(String powerUpType) {
    switch (powerUpType) {
      case 'hint':
        return Colors.orange;
      case 'eliminate':
        return Colors.red;
      case 'shield':
        return Colors.green;
      case 'time_boost':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getPowerUpIcon(String powerUpType) {
    switch (powerUpType) {
      case 'hint':
        return Icons.lightbulb;
      case 'eliminate':
        return Icons.clear;
      case 'shield':
        return Icons.shield;
      case 'time_boost':
        return Icons.speed;
      default:
        return Icons.help;
    }
  }
}