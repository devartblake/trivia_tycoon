import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/question/widgets/adapted_question_widgets.dart';
import '../../core/helpers/quiz_helpers.dart';
import '../../game/models/question_model.dart';
import '../../game/models/versus_models.dart';
import '../../game/providers/multiplayer_quiz_providers.dart';
import '../../game/services/quiz_category.dart';
import '../../ui_components/multiplayer/versus/versus_banner.dart';

class MultiplayerQuestionScreen extends ConsumerStatefulWidget {
  final String gameMode;

  const MultiplayerQuestionScreen({
    super.key,
    required this.gameMode,
  });

  @override
  ConsumerState<MultiplayerQuestionScreen> createState() => _MultiplayerQuestionScreenState();
}

class _MultiplayerQuestionScreenState extends ConsumerState<MultiplayerQuestionScreen>
    with TickerProviderStateMixin {
  late PageController _pageController;
  late AnimationController _answerAnimationController;
  late AnimationController _progressAnimationController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _answerAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Start the multiplayer quiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(multiplayerQuizProvider.notifier).startMultiplayerQuiz(widget.gameMode);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _answerAnimationController.dispose();
    _progressAnimationController.dispose();
    super.dispose();
  }

  Color _getGameModeColor() {
    switch (widget.gameMode) {
      case 'arena':
        return const Color(0xFFEF5350);
      case 'teams':
        return const Color(0xFFAB47BC);
      default:
        return Colors.blue;
    }
  }

  String _getGameModeDisplayName() {
    switch (widget.gameMode) {
      case 'arena':
        return 'Treasure Mine';
      case 'teams':
        return 'Survival Arena';
      default:
        return widget.gameMode.toUpperCase();
    }
  }

  IconData _getGameModeIcon() {
    switch (widget.gameMode) {
      case 'arena':
        return Icons.diamond;
      case 'teams':
        return Icons.sports_martial_arts;
      default:
        return Icons.quiz;
    }
  }

  void _handleAnswer(String answer) async {
    final notifier = ref.read(multiplayerQuizProvider.notifier);
    final state = ref.read(multiplayerQuizProvider);

    if (state.waitingForOpponent || state.currentQuestion == null) return;

    // Submit answer and wait for opponent
    notifier.submitAnswer(answer);

    // Show feedback after both players have answered
    _showMultiplayerFeedback();
  }

  void _showMultiplayerFeedback() {
    final state = ref.read(multiplayerQuizProvider);
    if (state.currentQuestion == null) return;

    showGeneralDialog(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'Round Results',
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _MultiplayerFeedbackDialog(
          gameMode: widget.gameMode,
          question: state.currentQuestion!,
          playerAnswer: state.playerAnswer,
          opponentAnswer: state.opponentAnswer,
          playerScore: state.playerScore,
          opponentScore: state.opponentScore,
          isCorrect: state.isPlayerCorrect,
          isOpponentCorrect: state.isOpponentCorrect,
          onContinue: () {
            Navigator.pop(context);
            if (state.isGameComplete) {
              _navigateToResults();
            } else {
              ref.read(multiplayerQuizProvider.notifier).nextQuestion();
              _pageController.nextPage(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeInOut,
              );
            }
          },
        );
      },
    );
  }

  void _navigateToResults() {
    context.go('/multiplayer/results/${widget.gameMode}');
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(multiplayerQuizProvider);
    final gameColor = _getGameModeColor();

    if (quizState.isLoading) {
      return Scaffold(
        backgroundColor: gameColor.withOpacity(0.1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: gameColor),
              const SizedBox(height: 16),
              Text(
                'Synchronizing with opponent...',
                style: TextStyle(
                  fontSize: 16,
                  color: gameColor,
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
        backgroundColor: gameColor.withOpacity(0.1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error, size: 64, color: Colors.red.shade400),
              const SizedBox(height: 16),
              Text(
                'Connection Error',
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => context.go('/multiplayer'),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back to Hub'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade600,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      ref.read(multiplayerQuizProvider.notifier)
                          .startMultiplayerQuiz(widget.gameMode);
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: gameColor,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = quizState.currentQuestion;
    if (currentQuestion == null) {
      return Scaffold(
        backgroundColor: gameColor.withOpacity(0.1),
        body: const Center(
          child: Text('No questions available'),
        ),
      );
    }

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Leave Match?'),
            content: const Text('Leaving now will forfeit the match. Are you sure?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Stay'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(multiplayerQuizProvider.notifier).forfeitMatch();
                  context.go('/multiplayer');
                },
                child: const Text('Leave'),
              ),
            ],
          ),
        );
      },
      child: Scaffold(
        backgroundColor: gameColor.withOpacity(0.1),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          title: Row(
            children: [
              Icon(_getGameModeIcon(), size: 20, color: gameColor),
              const SizedBox(width: 8),
              Text(
                _getGameModeDisplayName(),
                style: TextStyle(color: gameColor, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: Colors.white,
          elevation: 2,
          shadowColor: gameColor.withOpacity(0.2),
          actions: [
            // Question counter
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: gameColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${quizState.currentIndex + 1}/${quizState.totalQuestions}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: gameColor,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            // Versus Banner showing scores
            VersusBanner(
              config: VersusConfig(
                mode: widget.gameMode == 'teams' ? VersusMode.teamVteam : VersusMode.oneVone,
                left: Participant(
                  id: 'player_${DateTime.now().millisecondsSinceEpoch}',
                  displayName: 'You',
                  subtitle: 'Score: ${quizState.playerScore}',
                  avatarUrl: null,
                  color: gameColor,
                ),
                right: Participant(
                  id: 'opponent_${DateTime.now().millisecondsSinceEpoch}',
                  displayName: quizState.opponentName ?? 'Opponent',
                  subtitle: 'Score: ${quizState.opponentScore}',
                  avatarUrl: null,
                  color: gameColor == const Color(0xFFEF5350)
                      ? const Color(0xFF4ECDC4)
                      : const Color(0xFF66BB6A),
                ),
              ),
              height: 120,
            ),

            // Timer section
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
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Player status
                  _buildPlayerStatus(
                    'You',
                    quizState.hasPlayerAnswered,
                    gameColor,
                    true,
                  ),

                  // Timer in center
                  Container(
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
                        SizedBox(
                          width: 70,
                          height: 70,
                          child: CircularProgressIndicator(
                            value: quizState.timeRemaining / 30.0, // 30 second timer
                            strokeWidth: 6,
                            color: QuizHelpers.getTimerColor(quizState.timeRemaining),
                            backgroundColor: gameColor.withOpacity(0.2),
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
                      ],
                    ),
                  ),

                  // Opponent status
                  _buildPlayerStatus(
                    quizState.opponentName ?? 'Opponent',
                    quizState.hasOpponentAnswered,
                    gameColor == const Color(0xFFEF5350)
                        ? const Color(0xFF4ECDC4)
                        : const Color(0xFF66BB6A),
                    false,
                  ),
                ],
              ),
            ),

            // Waiting indicator
            if (quizState.waitingForOpponent)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Waiting for opponent to answer...',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

            // Main question content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 1, // Only show current question
                itemBuilder: (context, index) {
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
                            QuizHelpers.buildMetadataChip(
                              QuizHelpers.getDisplayTypeName(currentQuestion),
                              QuizHelpers.getDisplayTypeColor(currentQuestion),
                              QuizHelpers.getMediaTypeIcon(currentQuestion),
                            ),
                            QuizHelpers.buildMetadataChip(
                              _getGameModeDisplayName().toUpperCase(),
                              gameColor,
                              _getGameModeIcon(),
                            ),
                            QuizHelpers.buildMetadataChip(
                              QuizHelpers.getDifficultyText(currentQuestion.difficulty).toUpperCase(),
                              QuizHelpers.getDifficultyColor(currentQuestion.difficulty),
                              QuizHelpers.getDifficultyIcon(currentQuestion.difficulty),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Dynamic question widget
                        AdaptedQuestionWidget.create(
                          question: currentQuestion,
                          onAnswerSelected: quizState.hasPlayerAnswered ? null : _handleAnswer,
                          showFeedback: false,
                          selectedAnswer: quizState.playerAnswer,
                          isMultiplayer: true,
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
    );
  }

  Widget _buildPlayerStatus(String name, bool hasAnswered, Color color, bool isPlayer) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: hasAnswered ? color.withOpacity(0.2) : Colors.grey.shade200,
            shape: BoxShape.circle,
            border: Border.all(
              color: hasAnswered ? color : Colors.grey.shade400,
              width: 2,
            ),
          ),
          child: Icon(
            hasAnswered ? Icons.check : Icons.person,
            color: hasAnswered ? color : Colors.grey.shade600,
            size: 24,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: hasAnswered ? color : Colors.grey.shade600,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (hasAnswered)
          Text(
            'Answered',
            style: TextStyle(
              fontSize: 10,
              color: color,
            ),
          ),
      ],
    );
  }
}

class _MultiplayerFeedbackDialog extends StatefulWidget {
  final String gameMode;
  final QuestionModel question;
  final String? playerAnswer;
  final String? opponentAnswer;
  final int playerScore;
  final int opponentScore;
  final bool isCorrect;
  final bool isOpponentCorrect;
  final VoidCallback onContinue;

  const _MultiplayerFeedbackDialog({
    required this.gameMode,
    required this.question,
    required this.playerAnswer,
    required this.opponentAnswer,
    required this.playerScore,
    required this.opponentScore,
    required this.isCorrect,
    required this.isOpponentCorrect,
    required this.onContinue,
  });

  @override
  State<_MultiplayerFeedbackDialog> createState() => _MultiplayerFeedbackDialogState();
}

class _MultiplayerFeedbackDialogState extends State<_MultiplayerFeedbackDialog>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0)
        .animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.bounceOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getResultColor() {
    if (widget.isCorrect && !widget.isOpponentCorrect) return Colors.green;
    if (!widget.isCorrect && widget.isOpponentCorrect) return Colors.red;
    if (widget.isCorrect && widget.isOpponentCorrect) return Colors.blue;
    return Colors.orange; // Both wrong
  }

  String _getResultText() {
    if (widget.isCorrect && !widget.isOpponentCorrect) return 'You Win This Round!';
    if (!widget.isCorrect && widget.isOpponentCorrect) return 'Opponent Wins!';
    if (widget.isCorrect && widget.isOpponentCorrect) return 'Both Correct!';
    return 'Both Incorrect!';
  }

  IconData _getResultIcon() {
    if (widget.isCorrect && !widget.isOpponentCorrect) return Icons.emoji_events;
    if (!widget.isCorrect && widget.isOpponentCorrect) return Icons.sentiment_dissatisfied;
    if (widget.isCorrect && widget.isOpponentCorrect) return Icons.handshake;
    return Icons.help_outline;
  }

  @override
  Widget build(BuildContext context) {
    final resultColor = _getResultColor();

    return Align(
      alignment: Alignment.center,
      child: Material(
        color: Colors.transparent,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: resultColor,
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
                // Result icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getResultIcon(),
                    color: Colors.white,
                    size: 48,
                  ),
                ),

                const SizedBox(height: 16),

                Text(
                  _getResultText(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 16),

                // Correct answer
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Correct Answer:',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.question.correctAnswer,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Score comparison
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildScoreDisplay('You', widget.playerScore, widget.isCorrect),
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.white.withOpacity(0.3),
                    ),
                    _buildScoreDisplay('Opponent', widget.opponentScore, widget.isOpponentCorrect),
                  ],
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: resultColor,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: widget.onContinue,
                  child: const Text(
                    'Continue',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildScoreDisplay(String label, int score, bool wasCorrect) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              wasCorrect ? Icons.check_circle : Icons.cancel,
              color: Colors.white,
              size: 16,
            ),
            const SizedBox(width: 4),
            Text(
              score.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}