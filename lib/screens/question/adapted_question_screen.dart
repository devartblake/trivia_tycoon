import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/game/providers/multi_profile_providers.dart';
import 'package:trivia_tycoon/screens/question/widgets/adapted_question_widgets.dart';
import '../../game/models/question_model.dart';
import '../../game/providers/quiz_providers.dart';
import '../../game/providers/quiz_results_provider.dart';
import '../../game/services/quiz_category.dart';

class AdaptedQuestionScreen extends ConsumerStatefulWidget {
  final String? classLevel;
  final String? category;
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
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    // Start the quiz with provided parameters
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startQuiz();
    });

    _animationController.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _startQuiz() {
    // Use your existing quiz provider to start a quiz
    ref.read(adaptedQuizProvider.notifier).startQuizWithCategory(
      questionCount: widget.questionCount ?? 10,
      classLevel: widget.classLevel ?? '6',
      category: widget.category != null ? _stringToQuizCategory(widget.category!) : null,
    );
  }

  // Helper method to convert string to QuizCategory enum
  QuizCategory? _stringToQuizCategory(String category) {
    switch (category.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return QuizCategory.mathematics;
      case 'science':
        return QuizCategory.science;
      case 'history':
        return QuizCategory.history;
      case 'geography':
        return QuizCategory.geography;
      case 'literature':
      case 'english':
        return QuizCategory.literature;
      case 'arts':
        return QuizCategory.arts;
      case 'technology':
        return QuizCategory.technology;
      case 'sports':
        return QuizCategory.sports;
      default:
        return null;
    }
  }

  Color _getCategoryColor() {
    if (widget.category != null) {
      return _getCategoryColorByName(widget.category!);
    }
    return _getClassColorByLevel(widget.classLevel ?? '6');
  }

  Color _getCategoryColorByName(String category) {
    switch (category.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return const Color(0xFF3B82F6);
      case 'science':
        return const Color(0xFF10B981);
      case 'history':
        return const Color(0xFFDC2626);
      case 'geography':
        return const Color(0xFF059669);
      case 'literature':
      case 'english':
        return const Color(0xFF7C3AED);
      case 'arts':
        return const Color(0xFFEC4899);
      case 'technology':
        return const Color(0xFF0891B2);
      case 'sports':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF6366F1);
    }
  }

  Color _getClassColorByLevel(String level) {
    final levelInt = int.tryParse(level) ?? 6;
    switch (levelInt) {
      case 1:
      case 2:
        return const Color(0xFF10B981);
      case 3:
      case 4:
        return const Color(0xFF3B82F6);
      case 5:
      case 6:
        return const Color(0xFF8B5CF6);
      case 7:
      case 8:
        return const Color(0xFFEC4899);
      case 9:
      case 10:
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF6366F1);
    }
  }

  String _getDisplayTitle() {
    if (widget.category != null && widget.category!.toLowerCase() != 'mixed') {
      return '${widget.category} Quiz';
    }
    return 'Class ${widget.classLevel ?? '6'} Quiz';
  }

  IconData _getCategoryIcon() {
    if (widget.category == null || widget.category!.toLowerCase() == 'mixed') {
      return Icons.school;
    }

    switch (widget.category!.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return Icons.calculate;
      case 'science':
        return Icons.science;
      case 'history':
        return Icons.history_edu;
      case 'geography':
        return Icons.public;
      case 'literature':
      case 'english':
        return Icons.menu_book;
      case 'arts':
        return Icons.palette;
      case 'technology':
        return Icons.computer;
      case 'sports':
        return Icons.sports;
      default:
        return Icons.quiz;
    }
  }

  Future<void> _showFeedbackDialog({
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
    final isTimeout = answer.isEmpty;
    final previousXP = state.totalXP;

    notifier.answerQuestion(answer);

    // Get updated state to calculate XP gained
    final updatedState = ref.read(adaptedQuizProvider);
    final xpGained = updatedState.totalXP - previousXP;
    final timeLimit = _getTimeLimitForClassLevel(state.classLevel);
    final hasTimeBonus = !isTimeout && state.timeRemaining > (timeLimit * 0.7);

    await _showFeedbackDialog(
      isCorrect: isCorrect,
      question: currentQuestion,
      xpGained: xpGained,
      hasTimeBonus: hasTimeBonus,
      isTimeout: isTimeout,
      onNext: () async {
        final currentState = ref.read(adaptedQuizProvider);

        if (currentState.isLastQuestion) {
          // Complete the quiz
          ref.read(adaptedQuizProvider.notifier).completeQuiz();

          // Get the final state with duration
          final finalState = ref.read(adaptedQuizProvider);

          // Create quiz results
          final quizResults = QuizResults(
            score: finalState.score,
            totalQuestions: finalState.totalQuestions,
            totalXP: finalState.totalXP,
            coins: finalState.coins ?? 0,
            diamonds: finalState.diamonds ?? 0,
            stars: finalState.stars ?? 0,
            classLevel: finalState.classLevel,
            category: _getDisplayTitle(),
            categoryScores: Map<String, int>.from(finalState.categoryScores ?? {}),
            achievements: List<String>.from(finalState.achievements ?? []),
            quizDuration: finalState.quizDuration,
          );

          // Store results in provider
          ref.read(quizResultsProvider.notifier).state = quizResults;

          // Save to the active profile
          await quizResults.saveToActiveProfile(ref);

          // Navigate to score summary
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

  int _getTimeLimitForClassLevel(String classLevel) {
    final level = int.tryParse(classLevel) ?? 6;
    if (level <= 3) return 45; // Elementary - more time
    if (level <= 6) return 35; // Primary - medium time
    if (level <= 8) return 30; // Middle school - standard time
    return 25; // High school - less time
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(adaptedQuizProvider);
    final categoryColor = _getCategoryColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (quizState.isLoading) {
      return Scaffold(
        backgroundColor: categoryColor.withOpacity(0.1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: categoryColor),
              const SizedBox(height: 16),
              Text(
                'Loading ${_getDisplayTitle()}...',
                style: TextStyle(
                  fontSize: 16,
                  color: categoryColor,
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
        backgroundColor: categoryColor.withOpacity(0.1),
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
                onPressed: () => _startQuiz(),
                icon: const Icon(Icons.refresh),
                label: const Text('Try Again'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: categoryColor,
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
        backgroundColor: categoryColor.withOpacity(0.1),
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
                'for ${_getDisplayTitle()}',
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

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;

        final shouldLeave = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Quiz?'),
            content: const Text('Your progress will be lost if you leave now.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Leave'),
              ),
            ],
          ),
        );

        if (shouldLeave == true && context.mounted) {
          context.pop();
        }
      },
      child: Scaffold(
        backgroundColor: categoryColor.withOpacity(0.1),
        appBar: AppBar(
          title: Row(
            children: [
              Icon(_getCategoryIcon(), size: 20, color: categoryColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getDisplayTitle(),
                  style: TextStyle(color: categoryColor, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: categoryColor.withOpacity(0.2),
          actions: [
            // Score Display
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
                    color: categoryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${quizState.totalXP} XP',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: categoryColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: Column(
              children: [
                // Progress and Timer Section
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
                      // Progress info
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
                              color: categoryColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: categoryColor.withOpacity(0.3),
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_getCategoryIcon(), size: 12, color: categoryColor),
                                const SizedBox(width: 4),
                                Text(
                                  widget.classLevel != null
                                      ? 'Class ${widget.classLevel}'
                                      : (widget.category ?? 'Quiz'),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: categoryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 12),

                      // Progress Bar
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
                              color: categoryColor,
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
                              'Accuracy: ${quizState.scorePercentage.round()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: categoryColor,
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Timer
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
                            color: _getTimerColor(quizState.timeRemaining).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 70,
                            height: 70,
                            child: CircularProgressIndicator(
                              value: quizState.timeRemaining / _getTimeLimitForClassLevel(quizState.classLevel),
                              strokeWidth: 6,
                              color: _getTimerColor(quizState.timeRemaining),
                              backgroundColor: categoryColor.withOpacity(0.2),
                            ),
                          ),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                quizState.timeRemaining.toString(),
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: _getTimerColor(quizState.timeRemaining),
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
                        ],
                      ),
                    ),
                  ),
                ),

                // Main Question Content
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
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _buildMetadataChip(
                                  _getDisplayTypeName(currentQuestion),
                                  _getDisplayTypeColor(currentQuestion),
                                  _getMediaTypeIcon(currentQuestion),
                                ),
                                _buildMetadataChip(
                                  _getDifficultyText(currentQuestion.difficulty).toUpperCase(),
                                  _getDifficultyColor(currentQuestion.difficulty),
                                  _getDifficultyIcon(currentQuestion.difficulty),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // Question Widget
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
          ),
        ),
      ),
    );
  }

  Widget _buildMetadataChip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTimerColor(int timeRemaining) {
    if (timeRemaining <= 5) return Colors.red;
    if (timeRemaining <= 10) return Colors.orange;
    return Colors.green;
  }

  String _getDisplayTypeName(QuestionModel question) {
    if (question.hasImage) return 'Image';
    if (question.hasVideo) return 'Video';
    if (question.hasAudio) return 'Audio';
    switch (question.type) {
      case 'multiple_choice':
        return 'Multiple Choice';
      case 'true_false':
        return 'True/False';
      case 'fill_in_blank':
        return 'Fill in Blank';
      case 'matching':
        return 'Matching';
      case 'short_answer':
        return 'Short Answer';
      case 'essay':
        return 'Essay';
      default:
        return 'Question';
    }
  }

  Color _getDisplayTypeColor(QuestionModel question) {
    if (question.hasImage) return Colors.purple;
    if (question.hasVideo) return Colors.red;
    if (question.hasAudio) return Colors.orange;
    switch (question.type) {
      case 'multiple_choice':
        return Colors.blue;
      case 'true_false':
        return Colors.green;
      case 'fill_in_blank':
        return Colors.teal;
      case 'matching':
        return Colors.indigo;
      case 'short_answer':
        return Colors.amber;
      case 'essay':
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  IconData _getMediaTypeIcon(QuestionModel question) {
    if (question.hasImage) return Icons.image;
    if (question.hasVideo) return Icons.video_library;
    if (question.hasAudio) return Icons.volume_up;
    switch (question.type) {
      case 'multiple_choice':
        return Icons.radio_button_checked;
      case 'true_false':
        return Icons.check_box;
      case 'fill_in_blank':
        return Icons.edit;
      case 'matching':
        return Icons.connect_without_contact;
      case 'short_answer':
        return Icons.short_text;
      case 'essay':
        return Icons.article;
      default:
        return Icons.quiz;
    }
  }

  String _getDifficultyText(int difficulty) {
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
        return 'Medium';
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
      case 4:
        return Colors.purple;
      default:
        return Colors.orange;
    }
  }

  IconData _getDifficultyIcon(int difficulty) {
    switch (difficulty) {
      case 1:
        return Icons.sentiment_satisfied;
      case 2:
        return Icons.sentiment_neutral;
      case 3:
        return Icons.sentiment_dissatisfied;
      case 4:
        return Icons.psychology;
      default:
        return Icons.sentiment_neutral;
    }
  }
}