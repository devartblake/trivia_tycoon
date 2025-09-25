import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/question/widgets/adapted_question_widgets.dart';
import '../../core/helpers/quiz_helpers.dart';
import '../../game/models/question_model.dart';
import '../../game/providers/quiz_providers.dart';
import '../../game/providers/quiz_results_provider.dart';
import '../../game/services/educational_stats_service.dart';
import '../../game/services/quiz_category.dart'; // Import QuizCategory

class AdaptedQuestionScreen extends ConsumerStatefulWidget {
  final String? classLevel;
  final String? category; // Keep as string for route compatibility
  final int? questionCount;

  const AdaptedQuestionScreen({
    super.key,
    this.classLevel,
    this.category,
    this.questionCount,
  });

  @override
  ConsumerState<AdaptedQuestionScreen> createState() => _AdaptedQuestionScreenState();
}

class _AdaptedQuestionScreenState extends ConsumerState<AdaptedQuestionScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  QuizCategory? _resolvedCategory;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // Resolve category string to QuizCategory enum
    _resolvedCategory = _resolveCategoryFromString(widget.category);

    // Start quiz when screen loads with educational parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(adaptedQuizProvider.notifier).startQuizWithCategory(
        questionCount: widget.questionCount ?? 10,
        classLevel: widget.classLevel ?? '1',
        category: _resolvedCategory,
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  /// Resolve category string to QuizCategory enum
  QuizCategory? _resolveCategoryFromString(String? categoryString) {
    if (categoryString == null || categoryString.isEmpty || categoryString.toLowerCase() == 'mixed') {
      return null; // Will use mixed/general approach
    }

    // Try to map string to QuizCategory using the manager
    final resolvedCategory = QuizCategoryManager.fromString(categoryString);
    if (resolvedCategory != null) {
      return resolvedCategory;
    }

    // Fallback mappings for common UI strings
    switch (categoryString.toLowerCase()) {
      case 'math':
      case 'mathematics':
        return QuizCategory.mathematics;
      case 'science':
        return QuizCategory.science;
      case 'history':
        return QuizCategory.history;
      case 'geography':
        return QuizCategory.geography;
      case 'arts':
      case 'art':
        return QuizCategory.arts;
      case 'literature':
      case 'english':
        return QuizCategory.literature;
      case 'technology':
      case 'tech':
        return QuizCategory.technology;
      case 'health':
        return QuizCategory.health;
      case 'sports':
        return QuizCategory.sports;
      case 'entertainment':
        return QuizCategory.entertainment;
      case 'social_studies':
      case 'social':
        return QuizCategory.socialStudies;
      default:
        return QuizCategory.general; // Fallback to general
    }
  }

  /// Get category-based styling and colors
  Color _getCategoryColor() {
    if (_resolvedCategory != null) {
      return _resolvedCategory!.primaryColor;
    }
    return QuizHelpers.getClassColor(widget.classLevel ?? '1');
  }

  Color _getCategoryBackgroundColor() {
    if (_resolvedCategory != null) {
      return _resolvedCategory!.primaryColor.withOpacity(0.1);
    }
    return Colors.grey.shade50;
  }

  String _getCategoryDisplayName() {
    if (_resolvedCategory != null) {
      return _resolvedCategory!.displayName;
    }
    return widget.category ?? 'Mixed';
  }

  IconData _getCategoryIcon() {
    if (_resolvedCategory != null) {
      return _resolvedCategory!.icon;
    }
    return Icons.quiz;
  }

  Future<void> _showEnhancedFeedbackDialog({
    required bool isCorrect,
    required QuestionModel question,
    required int xpGained,
    required bool hasTimeBonus,
    required bool isTimeout,
    required VoidCallback onNext,
  }) async {
    await showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Feedback',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        final dialogColor = isTimeout
            ? Colors.orange.shade700
            : (isCorrect ? Colors.green.shade700 : Colors.red.shade700);

        return Align(
          alignment: Alignment.center,
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: animation,
              child: Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: dialogColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Result icon with animation
                    TweenAnimationBuilder(
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 500),
                      builder: (context, double value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isTimeout
                                  ? Icons.access_time
                                  : (isCorrect ? Icons.check_circle : Icons.cancel),
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    Text(
                      isTimeout ? "Time's Up!" : (isCorrect ? "Correct!" : "Incorrect!"),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Show correct answer if wrong or timeout
                    if (!isCorrect || isTimeout) ...[
                      Text(
                        "Correct answer:",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          question.correctAnswer,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // XP and bonuses (only for correct answers)
                    if (isCorrect && !isTimeout && xpGained > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star, color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "XP Gained: ",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              "+$xpGained",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (hasTimeBonus) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.speed, color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "Time Bonus: 50% Extra!",
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const SizedBox(height: 16),
                    ],

                    // Question explanation (if available)
                    if (question.powerUpHint != null && question.powerUpHint!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.white.withOpacity(0.8),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Explanation:",
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.8),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              question.powerUpHint!,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: dialogColor,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onNext();
                      },
                      child: Text(
                        ref.read(adaptedQuizProvider).isLastQuestion ? "View Results" : "Continue",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
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
    final isTimeout = answer.isEmpty; // Empty string indicates timeout
    final previousXP = state.totalXP;

    notifier.answerQuestion(answer);

    // Get updated state to calculate XP gained
    final updatedState = ref.read(adaptedQuizProvider);
    final xpGained = updatedState.totalXP - previousXP;
    final timeLimit = QuizHelpers.getTimeLimitForClass(state.classLevel);
    final hasTimeBonus = !isTimeout && state.timeRemaining > (timeLimit * 0.7);

    await _showEnhancedFeedbackDialog(
      isCorrect: isCorrect,
      question: currentQuestion,
      xpGained: xpGained,
      hasTimeBonus: hasTimeBonus,
      isTimeout: isTimeout,
      onNext: () {
        final currentState = ref.read(adaptedQuizProvider);

        if (currentState.isLastQuestion) {
          // STOP THE STOPWATCH HERE BEFORE NAVIGATION
          ref.read(adaptedQuizProvider.notifier).completeQuiz();

          // Get the final state with duration
          final finalState = ref.read(adaptedQuizProvider);

          // Create quiz results with all required fields and safe typing
          final quizResults = QuizResults(
            score: finalState.score,
            totalQuestions: finalState.totalQuestions,
            totalXP: finalState.totalXP,
            coins: finalState.coins ?? 0,
            diamonds: finalState.diamonds ?? 0,
            stars: finalState.stars ?? 0,
            classLevel: finalState.classLevel,
            category: _getCategoryDisplayName(), // Use resolved category display name
            categoryScores: Map<String, int>.from(finalState.categoryScores ?? {}),
            achievements: List<String>.from(finalState.achievements ?? []),
            quizDuration: finalState.quizDuration,
          );

          // Store results in provider
          ref.read(quizResultsProvider.notifier).state = quizResults;

          // Navigate to score summary (processing will happen there)
          context.go('/score-summary');
        } else {
          ref.read(adaptedQuizProvider.notifier).nextQuestion();
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
      return Scaffold(
        backgroundColor: _getCategoryBackgroundColor(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: _getCategoryColor()),
              const SizedBox(height: 16),
              Text(
                'Loading ${_getCategoryDisplayName()} questions for Class ${quizState.classLevel}...',
                style: TextStyle(
                  fontSize: 16,
                  color: _getCategoryColor(),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    if (quizState.error != null) {
      return Scaffold(
        backgroundColor: _getCategoryBackgroundColor(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Error loading questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  quizState.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  ref.read(adaptedQuizProvider.notifier).startQuizWithCategory(
                    classLevel: widget.classLevel ?? '1',
                    category: _resolvedCategory,
                    questionCount: widget.questionCount ?? 10,
                  );
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getCategoryColor(),
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (quizState.questions.isEmpty || quizState.currentQuestion == null) {
      return Scaffold(
        backgroundColor: _getCategoryBackgroundColor(),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(_getCategoryIcon(), size: 64, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                'No questions available',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'for ${_getCategoryDisplayName()} - Class ${quizState.classLevel}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = quizState.currentQuestion!;

    return Scaffold(
      backgroundColor: _getCategoryBackgroundColor(),
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_getCategoryIcon(), size: 20, color: _getCategoryColor()),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "${_getCategoryDisplayName()} - Class ${quizState.classLevel}",
                style: TextStyle(color: _getCategoryColor()),
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 2,
        shadowColor: _getCategoryColor().withOpacity(0.2),
        actions: [
          // Enhanced Score Display in AppBar
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
          // XP display with category color
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCategoryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${quizState.totalXP} XP',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getCategoryColor(),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Enhanced Progress Indicator with category theming
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Header Info with category badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Question ${quizState.currentIndex + 1} of ${quizState.totalQuestions}',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _getCategoryColor().withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _getCategoryColor().withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(_getCategoryIcon(), size: 12, color: _getCategoryColor()),
                          const SizedBox(width: 4),
                          Text(
                            'Class ${quizState.classLevel}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _getCategoryColor(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Enhanced Progress Bar with category gradient
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: (quizState.currentIndex + 1) / quizState.totalQuestions,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _resolvedCategory?.gradientColors ?? [
                            _getCategoryColor(),
                            _getCategoryColor().withOpacity(0.7)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Progress Stats
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${((quizState.currentIndex + 1) / quizState.totalQuestions * 100).round()}% Complete',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    if (quizState.score > 0)
                      Text(
                        'Score: ${quizState.scorePercentage.round()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _getCategoryColor(),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Enhanced Timer with category theming
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: QuizHelpers.getTimerColor(quizState.timeRemaining).withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Progress Ring with category color
                    SizedBox(
                      width: 70,
                      height: 70,
                      child: CircularProgressIndicator(
                        value: quizState.timeRemaining / QuizHelpers.getTimeLimitForClass(quizState.classLevel),
                        strokeWidth: 6,
                        color: QuizHelpers.getTimerColor(quizState.timeRemaining),
                        backgroundColor: _getCategoryColor().withOpacity(0.2),
                      ),
                    ),

                    // Time Display
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          quizState.timeRemaining.toString(),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: QuizHelpers.getTimerColor(quizState.timeRemaining),
                          ),
                        ),
                        Text(
                          'sec',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),

                    // Status indicators with enhanced styling
                    if (quizState.isTimerExpired)
                      Positioned(
                        top: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'TIME UP!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                    if (quizState.isPaused && !quizState.isTimerExpired)
                      Positioned(
                        bottom: 8,
                        child: Icon(
                          Icons.pause_circle_filled,
                          color: Colors.orange,
                          size: 16,
                        ),
                      ),

                    if (quizState.hasUsedExtraTime)
                      Positioned(
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: _getCategoryColor(),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'BONUS',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 6,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
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
                      // Enhanced question metadata with category integration
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          QuizHelpers.buildMetadataChip(
                            QuizHelpers.getDisplayTypeName(currentQuestion),
                            QuizHelpers.getDisplayTypeColor(currentQuestion),
                            QuizHelpers.getMediaTypeIcon(currentQuestion),
                          ),
                          QuizHelpers.buildMetadataChip(
                            _getCategoryDisplayName().toUpperCase(),
                            _getCategoryColor(),
                            _getCategoryIcon(),
                          ),
                          QuizHelpers.buildMetadataChip(
                            QuizHelpers.getDifficultyText(currentQuestion.difficulty).toUpperCase(),
                            QuizHelpers.getDifficultyColor(currentQuestion.difficulty),
                            QuizHelpers.getDifficultyIcon(currentQuestion.difficulty),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Audio player (if question has audio)
                      if (currentQuestion.hasAudio)
                        _buildAudioPlayer(quizState, currentQuestion),

                      const SizedBox(height: 8),

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

      // Enhanced power-up buttons with category theming
      floatingActionButton: quizState.showFeedback || quizState.hasUsedPowerUp || quizState.isTimerExpired
          ? null
          : _buildPowerUpButtons(currentQuestion, quizState.classLevel),
    );
  }

  Widget _buildAudioPlayer(quizState, QuestionModel question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCategoryColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getCategoryColor().withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.headphones, color: _getCategoryColor()),
              const SizedBox(width: 8),
              const Text(
                'Audio Question',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (quizState.isAudioPlaying) {
                    ref.read(adaptedQuizProvider.notifier).pauseAudio();
                  } else {
                    ref.read(adaptedQuizProvider.notifier).playAudio();
                  }
                },
                icon: Icon(
                  quizState.isAudioPlaying ? Icons.pause_circle : Icons.play_circle,
                  size: 48,
                  color: _getCategoryColor(),
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LinearProgressIndicator(
                      value: quizState.audioDuration != null
                          ? quizState.audioPosition.inMilliseconds / quizState.audioDuration!.inMilliseconds
                          : 0.0,
                      backgroundColor: _getCategoryColor().withOpacity(0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor()),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap play to hear the audio question',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (question.audioTranscript != null) ...[
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('View Transcript'),
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(question.audioTranscript!),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget? _buildPowerUpButtons(QuestionModel question, String classLevel) {
    final availablePowerUps = QuizHelpers.getAvailablePowerUps(question, classLevel);

    if (availablePowerUps.isEmpty) return null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: availablePowerUps.map((powerUp) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FloatingActionButton.small(
            heroTag: powerUp['type'],
            onPressed: () {
              ref.read(adaptedQuizProvider.notifier).applyPowerUp(powerUp['type']);
            },
            backgroundColor: powerUp['color'],
            child: Icon(powerUp['icon'], color: Colors.white),
          ),
        );
      }).toList(),
    );
  }
}
