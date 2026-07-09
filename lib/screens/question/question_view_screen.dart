import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import '../../core/dto/powerup_dto.dart';
import '../../core/helpers/quiz_helpers.dart';
import '../../game/models/question_model.dart';
import '../../game/providers/quiz_providers.dart';
import '../../game/providers/quiz_results_provider.dart';
import '../../game/providers/learning_providers.dart'
    show currentPlayerIdProvider;
import '../../game/providers/personalization_providers.dart';
import '../../game/providers/powerup_providers.dart';
import '../../game/providers/tier_progression_provider.dart';
import '../../game/services/quiz_category.dart';
// New question system components
import 'widgets/question_renderer.dart';
import 'widgets/question_metadata.dart';
import 'widgets/category_header_bar.dart';
import 'widgets/segmented_progress_strip.dart';
import 'widgets/powerup_tray.dart';

class AdaptedQuestionScreen extends ConsumerStatefulWidget {
  final String? classLevel;
  final String? category; // Keep as string for route compatibility
  final int? questionCount;
  final List<QuestionModel>? initialQuestions;
  final String? displayTitle;

  const AdaptedQuestionScreen({
    super.key,
    this.classLevel,
    this.category,
    this.questionCount,
    this.initialQuestions,
    this.displayTitle,
  });

  @override
  ConsumerState<AdaptedQuestionScreen> createState() =>
      _AdaptedQuestionScreenState();
}

class _AdaptedQuestionScreenState extends ConsumerState<AdaptedQuestionScreen>
    with SingleTickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _animationController;
  QuizCategory? _resolvedCategory;

  /// Idempotency/scoping key for server-side powerup consumption this session.
  final String _powerupEventId = const Uuid().v4();

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
      final notifier = ref.read(adaptedQuizProvider.notifier);
      final initialQuestions = widget.initialQuestions;
      if (initialQuestions != null && initialQuestions.isNotEmpty) {
        notifier.startQuizWithQuestions(
          questions: initialQuestions,
          classLevel: widget.classLevel ?? '1',
          category: _resolvedCategory,
        );
      } else {
        notifier.startQuizWithCategory(
          questionCount: widget.questionCount ?? 10,
          classLevel: widget.classLevel ?? '1',
          category: _resolvedCategory,
        );
      }
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
    if (categoryString == null ||
        categoryString.isEmpty ||
        categoryString.toLowerCase() == 'mixed') {
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

  /// Dark neutral canvas (Trivia-Crack style): makes the white question card
  /// and answer pills pop, with a whisper of the category color blended in.
  Color _getCategoryBackgroundColor() {
    const canvas = Color(0xFF3E4348);
    if (_resolvedCategory != null) {
      return Color.alphaBlend(
        _resolvedCategory!.primaryColor.withValues(alpha: 0.06),
        canvas,
      );
    }
    return canvas;
  }

  String _getCategoryDisplayName() {
    if (widget.displayTitle != null && widget.displayTitle!.trim().isNotEmpty) {
      return widget.displayTitle!;
    }
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
    required String correctAnswer,
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
                      color: Colors.black.withValues(alpha: 0.3),
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
                              color: Colors.white.withValues(alpha: 0.2),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isTimeout
                                  ? Icons.access_time
                                  : (isCorrect
                                      ? Icons.check_circle
                                      : Icons.cancel),
                              color: Colors.white,
                              size: 48,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    Text(
                      isTimeout
                          ? "Time's Up!"
                          : (isCorrect ? "Correct!" : "Incorrect!"),
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
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          correctAnswer,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 6),
                            Text(
                              "XP Gained: ",
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.speed,
                                  color: Colors.white, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                "Time Bonus: 50% Extra!",
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
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
                    if (question.powerUpHint != null &&
                        question.powerUpHint!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.lightbulb_outline,
                                  color: Colors.white.withValues(alpha: 0.8),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Explanation:",
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.8),
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
                                color: Colors.white.withValues(alpha: 0.9),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        Navigator.pop(context);
                        onNext();
                      },
                      child: Text(
                        ref.read(adaptedQuizProvider).isLastQuestion
                            ? "View Results"
                            : "Continue",
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

    final isTimeout = answer.isEmpty; // Empty string indicates timeout
    final previousXP = state.totalXP;

    final evaluation = await notifier.answerQuestion(answer);
    final isCorrect = evaluation.isCorrect;

    // Fire behaviour event (fire-and-forget)
    ref.read(currentPlayerIdProvider).whenData((playerId) {
      if (playerId != null && playerId.isNotEmpty) {
        ref.read(personalizationServiceProvider).fireQuestionAnswered(
              playerId: playerId,
              category: currentQuestion.category,
              difficulty: currentQuestion.difficulty.toString(),
              mode: state.classLevel,
              correct: isCorrect,
              timeMs: state.timeRemaining > 0
                  ? ((QuizHelpers.getTimeLimitForClass(state.classLevel) -
                              state.timeRemaining) *
                          1000)
                      .toInt()
                  : 0,
              questionId: currentQuestion.id,
            );
      }
    });

    // Get updated state to calculate XP gained
    final updatedState = ref.read(adaptedQuizProvider);
    final xpGained = updatedState.totalXP - previousXP;
    final timeLimit = QuizHelpers.getTimeLimitForClass(state.classLevel);
    final hasTimeBonus = !isTimeout && state.timeRemaining > (timeLimit * 0.7);

    await _showEnhancedFeedbackDialog(
      isCorrect: isCorrect,
      question: currentQuestion,
      correctAnswer: evaluation.correctAnswer ?? currentQuestion.correctAnswer,
      xpGained: xpGained,
      hasTimeBonus: hasTimeBonus,
      isTimeout: isTimeout,
      onNext: () async {
        final currentState = ref.read(adaptedQuizProvider);

        if (currentState.isLastQuestion) {
          final reconciledState = await ref
              .read(adaptedQuizProvider.notifier)
              .reconcileAuthoritativeResults();

          // The backend may have awarded tier XP for this session during
          // reconciliation — refetch tier progress so the UI reflects it.
          if (reconciledState.serverXpAward != null) {
            ref.invalidate(playerTierProgressProvider);
          }

          // STOP THE STOPWATCH HERE BEFORE NAVIGATION
          ref.read(adaptedQuizProvider.notifier).completeQuiz();

          // Get the final state with duration
          final finalState = ref.read(adaptedQuizProvider);

          // Fire match_completed behaviour event (fire-and-forget)
          ref.read(currentPlayerIdProvider).whenData((playerId) {
            if (playerId != null && playerId.isNotEmpty) {
              ref.read(personalizationServiceProvider).fireMatchCompleted(
                playerId: playerId,
                mode: finalState.classLevel,
                category: _getCategoryDisplayName(),
                metadata: {
                  'score': reconciledState.score,
                  'totalQuestions': finalState.totalQuestions,
                },
              );
            }
          });

          // Create quiz results with all required fields and safe typing
          final quizResults = QuizResults(
            score: reconciledState.score,
            totalQuestions: finalState.totalQuestions,
            totalXP: finalState.totalXP,
            coins: finalState.coins ?? 0,
            diamonds: finalState.diamonds ?? 0,
            stars: finalState.stars ?? 0,
            classLevel: finalState.classLevel,
            category:
                _getCategoryDisplayName(), // Use resolved category display name
            categoryScores: Map<String, int>.from(
              reconciledState.categoryScores ?? {},
            ),
            achievements: List<String>.from(finalState.achievements ?? []),
            quizDuration: finalState.quizDuration,
            answerSubmissions: reconciledState.answerSubmissions
                .map((submission) => <String, dynamic>{
                      'questionId': submission.question.id,
                      'selectedOptionId': submission.question
                          .optionIdForAnswer(submission.selectedAnswer),
                      if (submission.answerTimeMs != null)
                        'answerTimeMs': submission.answerTimeMs,
                    })
                .toList(growable: false),
          );

          // Store results in provider
          ref.read(quizResultsProvider.notifier).state = quizResults;

          // Navigate to score summary (processing will happen there)
          if (!mounted) return;
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
              const CircularProgressIndicator(color: Colors.white),
              const SizedBox(height: 16),
              Text(
                'Loading ${_getCategoryDisplayName()} questions for Class ${quizState.classLevel}...',
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.white.withValues(alpha: 0.85),
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
              Icon(Icons.error, size: 64, color: Colors.red.shade300),
              const SizedBox(height: 16),
              Text(
                'Error loading questions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.red.shade300,
                ),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  quizState.error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  final notifier = ref.read(adaptedQuizProvider.notifier);
                  final initialQuestions = widget.initialQuestions;
                  if (initialQuestions != null && initialQuestions.isNotEmpty) {
                    notifier.startQuizWithQuestions(
                      questions: initialQuestions,
                      classLevel: widget.classLevel ?? '1',
                      category: _resolvedCategory,
                    );
                  } else {
                    notifier.startQuizWithCategory(
                      classLevel: widget.classLevel ?? '1',
                      category: _resolvedCategory,
                      questionCount: widget.questionCount ?? 10,
                    );
                  }
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
              Icon(_getCategoryIcon(),
                  size: 64, color: Colors.white.withValues(alpha: 0.4)),
              const SizedBox(height: 16),
              Text(
                'No questions available',
                style: TextStyle(
                  fontSize: 18,
                  color: Colors.white.withValues(alpha: 0.85),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'for ${_getCategoryDisplayName()} - Class ${quizState.classLevel}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.6),
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
      appBar: CategoryHeaderBar(
        color: _getCategoryColor(),
        icon: _getCategoryIcon(),
        title: _getCategoryDisplayName(),
        subtitle: 'Class ${quizState.classLevel}',
        timeRemaining: quizState.timeRemaining,
        timerExpired: quizState.isTimerExpired,
        isPaused: quizState.isPaused,
        score: quizState.score,
        xp: quizState.totalXP,
      ),
      body: Column(
        children: [
          // Segmented per-question progress strip
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: SegmentedProgressStrip(
              total: quizState.totalQuestions,
              currentIndex: quizState.currentIndex,
              activeColor: _getCategoryColor(),
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
                          // Use new QuestionMetadata component with type-safe difficulty
                          Expanded(
                            child: QuestionMetadata(
                              question: currentQuestion,
                              showDifficultyBadge: true,
                              showTags: true,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Audio player (if question has audio)
                      if (currentQuestion.hasAudio)
                        _buildAudioPlayer(quizState, currentQuestion),

                      const SizedBox(height: 8),

                      // Dynamic question widget based on type (using new type-safe renderer)
                      QuestionRenderer(
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

      // Fixed bottom power-up tray (Trivia-Crack style)
      bottomNavigationBar: PowerupTray(
        powerUps:
            QuizHelpers.getAvailablePowerUps(currentQuestion, quizState.classLevel),
        enabled: !(quizState.showFeedback ||
            quizState.hasUsedPowerUp ||
            quizState.isTimerExpired),
        onActivate: _activatePowerUp,
      ),
    );
  }

  Widget _buildAudioPlayer(quizState, QuestionModel question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getCategoryColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getCategoryColor().withValues(alpha: 0.3)),
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
                  quizState.isAudioPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
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
                          ? quizState.audioPosition.inMilliseconds /
                              quizState.audioDuration!.inMilliseconds
                          : 0.0,
                      backgroundColor:
                          _getCategoryColor().withValues(alpha: 0.2),
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_getCategoryColor()),
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

  /// Maps a local quiz powerup type to the backend inventory type, or null when
  /// the powerup has no server-tracked equivalent (e.g. hint, shield).
  PowerupType? _mapToBackendPowerup(String type) {
    switch (type) {
      case 'eliminate':
        return PowerupType.fiftyFifty;
      case 'time_boost':
        return PowerupType.extraTime;
      default:
        return null;
    }
  }

  /// Consumes the powerup from the player's server inventory (when it has a
  /// backend equivalent) before applying the local effect. Server denials
  /// (out of stock / cooldown) block activation; offline/unmapped powerups fall
  /// through to the existing local-only behaviour so solo play never breaks.
  Future<void> _activatePowerUp(String type) async {
    final backendType = _mapToBackendPowerup(type);
    final playerId = ref.read(currentPlayerIdProvider).valueOrNull;

    if (backendType != null && playerId != null && playerId.isNotEmpty) {
      final result = await ref
          .read(powerupInventoryProvider(playerId).notifier)
          .use(eventId: _powerupEventId, type: backendType);

      // result == null → request failed; don't punish the player, apply locally.
      if (result != null &&
          result.status != 'Used' &&
          result.status != 'Duplicate') {
        if (!mounted) return;
        final msg = switch (result.status) {
          'Insufficient' => 'Out of that powerup.',
          'Cooldown' => 'That powerup is on cooldown.',
          _ => 'Powerup unavailable.',
        };
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
        return;
      }
    }

    ref.read(adaptedQuizProvider.notifier).applyPowerUp(type);
  }
}
