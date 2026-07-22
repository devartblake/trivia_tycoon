import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:synaptix/core/dto/powerup_dto.dart';
import 'package:synaptix/core/helpers/quiz_helpers.dart';
import 'package:synaptix/game/models/question_difficulty.dart';
import 'package:synaptix/game/models/question_model.dart';
import 'package:synaptix/game/providers/quiz_providers.dart';
import 'package:synaptix/game/providers/quiz_results_provider.dart';
import 'package:synaptix/game/providers/learning_providers.dart'
    show currentPlayerIdProvider;
import 'package:synaptix/game/providers/personalization_providers.dart';
import 'package:synaptix/game/providers/powerup_providers.dart';
import 'package:synaptix/game/providers/tier_progression_provider.dart';
import 'package:synaptix/core/services/feedback_service.dart';
import 'package:synaptix/core/services/native_platform_service.dart';
import 'package:synaptix/game/services/quiz_category.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';
import 'package:synaptix/ui_components/spin_wheel/core/sound_manager.dart';
import 'package:synaptix/screens/question/widgets/question_renderer.dart';
import 'package:synaptix/screens/question/widgets/question_metadata.dart';
import 'package:synaptix/screens/question/widgets/powerup_tray.dart';
import 'package:synaptix/ui_components/animations/particle_emitter.dart';
import 'package:synaptix/core/design_system/synaptix_scaffold.dart';
import 'package:synaptix/core/design_system/glass_app_bar.dart';
import 'package:synaptix/core/design_system/glow_text.dart';
import 'package:synaptix/core/design_system/holographic_dialog.dart';
import 'package:synaptix/core/design_system/neon_button.dart';
import 'package:synaptix/core/design_system/neural_progress_bar.dart';
import 'package:synaptix/core/design_system/neural_bloom_indicator.dart';

class AdaptedQuestionScreen extends ConsumerStatefulWidget {
  final String? classLevel;
  final String? category;
  final int? questionCount;
  final List<QuestionModel>? initialQuestions;
  final String? displayTitle;
  final bool timedChallenge;

  const AdaptedQuestionScreen({
    super.key,
    this.classLevel,
    this.category,
    this.questionCount,
    this.initialQuestions,
    this.displayTitle,
    this.timedChallenge = false,
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
  bool _showSuccessParticles = false;
  final String _powerupEventId = const Uuid().v4();

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _resolvedCategory = _resolveCategoryFromString(widget.category);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final notifier = ref.read(adaptedQuizProvider.notifier);
      final initialQuestions = widget.initialQuestions;
      if (initialQuestions != null && initialQuestions.isNotEmpty) {
        notifier.startQuizWithQuestions(
          questions: initialQuestions,
          classLevel: widget.classLevel ?? '1',
          category: _resolvedCategory,
          timedChallenge: widget.timedChallenge,
        );
      } else {
        notifier.startQuizWithCategory(
          questionCount: widget.questionCount ?? 10,
          classLevel: widget.classLevel ?? '1',
          category: _resolvedCategory,
          timedChallenge: widget.timedChallenge,
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

  QuizCategory? _resolveCategoryFromString(String? categoryString) {
    if (categoryString == null ||
        categoryString.isEmpty ||
        categoryString.toLowerCase() == 'mixed') return null;
    final resolvedCategory = QuizCategoryManager.fromString(categoryString);
    if (resolvedCategory != null) return resolvedCategory;
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
        return QuizCategory.general;
    }
  }

  Color _getCategoryColor() {
    if (_resolvedCategory != null) return _resolvedCategory!.primaryColor;
    return QuizHelpers.getClassColor(widget.classLevel ?? '1');
  }

  String _getCategoryDisplayName() {
    if (widget.displayTitle != null && widget.displayTitle!.trim().isNotEmpty)
      return widget.displayTitle!;
    if (_resolvedCategory != null) return _resolvedCategory!.displayName;
    return widget.category ?? 'Mixed';
  }

  IconData _getCategoryIcon() => _resolvedCategory?.icon ?? Icons.quiz;

  Future<void> _showEnhancedFeedbackDialog({
    required bool isCorrect,
    required QuestionModel question,
    required String correctAnswer,
    required int xpGained,
    required bool hasTimeBonus,
    required bool isTimeout,
    required VoidCallback onNext,
  }) async {
    final dialogColor = isTimeout
        ? Colors.orange.shade700
        : (isCorrect ? Colors.green.shade700 : Colors.red.shade700);
    await HolographicDialog.show(
      context: context,
      glowColor: dialogColor,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
                        shape: BoxShape.circle),
                    child: Icon(
                        isTimeout
                            ? Icons.access_time
                            : (isCorrect ? Icons.check_circle : Icons.cancel),
                        color: Colors.white,
                        size: 48),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            GlowText(
                isTimeout
                    ? "Time's Up!"
                    : (isCorrect ? "Correct!" : "Incorrect!"),
                style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 8),
            if (!isCorrect || isTimeout) ...[
              const Text("Correct answer:",
                  style: TextStyle(color: Colors.white70, fontSize: 14)),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8)),
                child: Text(correctAnswer,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center),
              ),
              const SizedBox(height: 16),
            ],
            if (isCorrect && !isTimeout && xpGained > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text("XP Gained: ",
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 12)),
                    Text("+$xpGained",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              if (hasTimeBonus) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20)),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.speed, color: Colors.cyanAccent, size: 16),
                      SizedBox(width: 6),
                      Text("Time Bonus: 50% Extra!",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
            ],
            NeonButton(
              color: dialogColor,
              onPressed: () {
                Navigator.pop(context);
                onNext();
              },
              child: Text(ref.read(adaptedQuizProvider).isLastQuestion
                  ? "VIEW RESULTS"
                  : "CONTINUE"),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAnswer(String answer) async {
    final notifier = ref.read(adaptedQuizProvider.notifier);
    final state = ref.read(adaptedQuizProvider);
    final currentQuestion = state.currentQuestion;
    if (currentQuestion == null) return;
    final isTimeout = answer.isEmpty;
    final previousXP = state.totalXP;
    final evaluation = await notifier.answerQuestion(answer);
    final isCorrect = evaluation.isCorrect;
    if (!mounted) return;
    if (isCorrect) {
      FeedbackService.instance.haptic(NativeHapticPattern.success, context);
      soundManager.playUISound('success', context);
    } else if (!isTimeout) {
      FeedbackService.instance.haptic(NativeHapticPattern.error, context);
      soundManager.playUISound('error', context);
    }
    ref.read(currentPlayerIdProvider).whenData((playerId) {
      if (playerId != null && playerId.isNotEmpty) {
        ref.read(personalizationServiceProvider).fireQuestionAnswered(
              playerId: playerId,
              category: currentQuestion.category,
              difficulty: currentQuestion.difficulty.toString(),
              mode: state.classLevel,
              correct: isCorrect,
              timeMs: state.timeRemaining > 0
                  ? ((state.questionTimeLimit - state.timeRemaining) * 1000)
                      .toInt()
                  : 0,
              questionId: currentQuestion.id,
            );
      }
    });
    final updatedState = ref.read(adaptedQuizProvider);
    final xpGained = updatedState.totalXP - previousXP;
    if (isCorrect) {
      setState(() => _showSuccessParticles = true);
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) setState(() => _showSuccessParticles = false);
      });
    }
    final timeLimit = state.questionTimeLimit;
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
          if (reconciledState.serverXpAward != null)
            ref.invalidate(playerTierProgressProvider);
          ref.read(adaptedQuizProvider.notifier).completeQuiz();
          final finalState = ref.read(adaptedQuizProvider);
          ref.read(currentPlayerIdProvider).whenData((playerId) {
            if (playerId != null && playerId.isNotEmpty) {
              ref.read(personalizationServiceProvider).fireMatchCompleted(
                playerId: playerId,
                mode: finalState.classLevel,
                category: _getCategoryDisplayName(),
                metadata: {
                  'score': reconciledState.score,
                  'totalQuestions': finalState.totalQuestions
                },
              );
            }
          });
          final quizResults = QuizResults(
            score: reconciledState.score,
            totalQuestions: finalState.totalQuestions,
            totalXP: finalState.totalXP,
            coins: finalState.coins ?? 0,
            diamonds: finalState.diamonds ?? 0,
            stars: finalState.stars ?? 0,
            classLevel: finalState.classLevel,
            category: _getCategoryDisplayName(),
            categoryScores:
                Map<String, int>.from(reconciledState.categoryScores ?? {}),
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
          ref.read(quizResultsProvider.notifier).state = quizResults;
          if (!mounted) return;
          context.go('/score-summary');
        } else {
          ref.read(adaptedQuizProvider.notifier).nextQuestion();
          _pageController.nextPage(
              duration: const Duration(milliseconds: 500),
              curve: Curves.easeInOut);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(adaptedQuizProvider);
    final themeExtension = Theme.of(context).extension<SynaptixTheme>();
    if (quizState.isLoading) {
      return SynaptixScaffold(
          body: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            const NeuralBloomIndicator(),
            const SizedBox(height: 16),
            Text('Loading ${_getCategoryDisplayName()} questions...',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
                textAlign: TextAlign.center),
          ])));
    }
    if (quizState.error != null) {
      return SynaptixScaffold(
          body: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            const Icon(Icons.error, size: 64, color: Colors.redAccent),
            const SizedBox(height: 16),
            const GlowText('Error loading questions',
                style: TextStyle(fontSize: 18, color: Colors.redAccent)),
            const SizedBox(height: 8),
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(quizState.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white60))),
            const SizedBox(height: 24),
            NeonButton(
                onPressed: () {
                  final notifier = ref.read(adaptedQuizProvider.notifier);
                  final initialQuestions = widget.initialQuestions;
                  if (initialQuestions != null && initialQuestions.isNotEmpty) {
                    notifier.startQuizWithQuestions(
                        questions: initialQuestions,
                        classLevel: widget.classLevel ?? '1',
                        category: _resolvedCategory,
                        timedChallenge: widget.timedChallenge);
                  } else {
                    notifier.startQuizWithCategory(
                        classLevel: widget.classLevel ?? '1',
                        category: _resolvedCategory,
                        questionCount: widget.questionCount ?? 10,
                        timedChallenge: widget.timedChallenge);
                  }
                },
                child: const Text('TRY AGAIN')),
          ])));
    }
    if (quizState.questions.isEmpty || quizState.currentQuestion == null) {
      return SynaptixScaffold(
          body: Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
            Icon(_getCategoryIcon(), size: 64, color: Colors.white24),
            const SizedBox(height: 16),
            const GlowText('No questions available',
                style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text('for ${_getCategoryDisplayName()}',
                style: const TextStyle(fontSize: 14, color: Colors.white60)),
          ])));
    }
    final currentQuestion = quizState.currentQuestion!;
    return SynaptixScaffold(
      appBar: GlassAppBar(
        color: _getCategoryColor(),
        leading: IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).pop()),
        title: GlowText(_getCategoryDisplayName()),
        actions: [
          Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2))),
                child: Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 16),
                  const SizedBox(width: 4),
                  Text('${quizState.totalXP}',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold))
                ]),
              )),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: kToolbarHeight + 20),
          Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: NeuralProgressBar(
                  total: quizState.totalQuestions,
                  current: quizState.currentIndex,
                  color: _getCategoryColor())),
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
                        if (currentQuestion.difficulty ==
                            QuestionDifficulty.boss) ...[
                          const _BossBanner(),
                          const SizedBox(height: 12)
                        ],
                        QuestionMetadata(
                            question: currentQuestion,
                            showDifficultyBadge: true,
                            showTags: true),
                        const SizedBox(height: 16),
                        if (currentQuestion.hasAudio)
                          _buildAudioPlayer(quizState, currentQuestion),
                        const SizedBox(height: 8),
                        ParticleEmitter(
                            trigger: _showSuccessParticles,
                            color: themeExtension?.accentGlow ?? Colors.amber,
                            child: QuestionRenderer(
                                question: currentQuestion,
                                onAnswerSelected: _handleAnswer,
                                showFeedback: quizState.showFeedback,
                                selectedAnswer: quizState.selectedAnswer)),
                      ]));
            },
          )),
        ],
      ),
      bottomNavigationBar: PowerupTray(
          powerUps: QuizHelpers.getAvailablePowerUps(
              currentQuestion, quizState.classLevel),
          enabled: !(quizState.showFeedback ||
              quizState.hasUsedPowerUp ||
              quizState.isTimerExpired),
          onActivate: _activatePowerUp),
    );
  }

  Widget _buildAudioPlayer(quizState, QuestionModel question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: _getCategoryColor().withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border:
              Border.all(color: _getCategoryColor().withValues(alpha: 0.3))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(Icons.headphones, color: _getCategoryColor()),
          const SizedBox(width: 8),
          const Text('Audio Question',
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16))
        ]),
        const SizedBox(height: 12),
        Row(children: [
          IconButton(
              onPressed: () {
                if (quizState.isAudioPlaying)
                  ref.read(adaptedQuizProvider.notifier).pauseAudio();
                else
                  ref.read(adaptedQuizProvider.notifier).playAudio();
              },
              icon: Icon(
                  quizState.isAudioPlaying
                      ? Icons.pause_circle
                      : Icons.play_circle,
                  size: 48,
                  color: _getCategoryColor())),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                LinearProgressIndicator(
                    value: quizState.audioDuration != null
                        ? quizState.audioPosition.inMilliseconds /
                            quizState.audioDuration!.inMilliseconds
                        : 0.0,
                    backgroundColor: _getCategoryColor().withValues(alpha: 0.2),
                    valueColor:
                        AlwaysStoppedAnimation<Color>(_getCategoryColor())),
                const SizedBox(height: 4),
                const Text('Tap play to hear the audio question',
                    style: TextStyle(fontSize: 12, color: Colors.white60))
              ])),
        ]),
        if (question.audioTranscript != null) ...[
          const SizedBox(height: 12),
          ExpansionTile(
              title: const Text('View Transcript',
                  style: TextStyle(color: Colors.white70)),
              children: [
                Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(question.audioTranscript!,
                        style: const TextStyle(color: Colors.white60)))
              ])
        ],
      ]),
    );
  }

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

  Future<void> _activatePowerUp(String type) async {
    final backendType = _mapToBackendPowerup(type);
    final playerId = ref.read(currentPlayerIdProvider).valueOrNull;
    if (backendType != null && playerId != null && playerId.isNotEmpty) {
      final result = await ref
          .read(powerupInventoryProvider(playerId).notifier)
          .use(eventId: _powerupEventId, type: backendType);
      if (result != null &&
          result.status != 'Used' &&
          result.status != 'Duplicate') {
        if (!mounted) return;
        final msg = switch (result.status) {
          'Insufficient' => 'Out of that powerup.',
          'Cooldown' => 'That powerup is on cooldown.',
          _ => 'Powerup unavailable.'
        };
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), behavior: SnackBarBehavior.floating));
        return;
      }
    }
    ref.read(adaptedQuizProvider.notifier).applyPowerUp(type);
  }
}

class _BossBanner extends StatelessWidget {
  const _BossBanner();
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          gradient: const LinearGradient(
              colors: [Color(0xFF7F1D1D), Color(0xFFB91C1C)]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF87171))),
      child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.whatshot_rounded, color: Color(0xFFFDE68A), size: 20),
        SizedBox(width: 8),
        Text('BOSS QUESTION — 5× XP',
            style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
        SizedBox(width: 8),
        Icon(Icons.whatshot_rounded, color: Color(0xFFFDE68A), size: 20)
      ]),
    );
  }
}
