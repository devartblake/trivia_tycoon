import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/providers/multiplayer_quiz_providers.dart';

class MultiplayerResultsScreen extends ConsumerStatefulWidget {
  final String gameMode;

  const MultiplayerResultsScreen({
    super.key,
    required this.gameMode,
  });

  @override
  ConsumerState<MultiplayerResultsScreen> createState() => _MultiplayerResultsScreenState();
}

class _MultiplayerResultsScreenState extends ConsumerState<MultiplayerResultsScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainController;
  late AnimationController _scoreController;
  late AnimationController _confettiController;

  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<int> _scoreCountAnimation;

  @override
  void initState() {
    super.initState();

    _mainController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _scoreController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _confettiController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _slideAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.5, 1.0, curve: Curves.elasticOut),
    ));

    // Start animations
    _mainController.forward();

    // Delay score animation
    Future.delayed(const Duration(milliseconds: 800), () {
      _scoreController.forward();

      // Start confetti if player won
      final quizState = ref.read(multiplayerQuizProvider);
      if (quizState.playerScore > quizState.opponentScore) {
        _confettiController.forward();
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _scoreController.dispose();
    _confettiController.dispose();
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

  String _getResultTitle(int playerScore, int opponentScore) {
    if (playerScore > opponentScore) {
      return 'Victory!';
    } else if (playerScore < opponentScore) {
      return 'Defeat';
    } else {
      return 'Draw';
    }
  }

  Color _getResultColor(int playerScore, int opponentScore) {
    if (playerScore > opponentScore) {
      return Colors.green;
    } else if (playerScore < opponentScore) {
      return Colors.red;
    } else {
      return Colors.blue;
    }
  }

  IconData _getResultIcon(int playerScore, int opponentScore) {
    if (playerScore > opponentScore) {
      return Icons.emoji_events;
    } else if (playerScore < opponentScore) {
      return Icons.sentiment_dissatisfied;
    } else {
      return Icons.handshake;
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(multiplayerQuizProvider);
    final gameColor = _getGameModeColor();
    final resultColor = _getResultColor(quizState.playerScore, quizState.opponentScore);

    // Setup score counting animation
    _scoreCountAnimation = IntTween(
      begin: 0,
      end: quizState.playerScore,
    ).animate(CurvedAnimation(
      parent: _scoreController,
      curve: Curves.easeOut,
    ));

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;
        context.go('/multiplayer');
      },
      child: Scaffold(
        backgroundColor: gameColor.withOpacity(0.1),
        body: Stack(
          children: [
            // Background decorations
            _buildBackgroundDecorations(resultColor),

            // Confetti overlay
            if (quizState.playerScore > quizState.opponentScore)
              _buildConfettiOverlay(),

            // Main content
            SafeArea(
              child: AnimatedBuilder(
                animation: _mainController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, 50 * _slideAnimation.value),
                    child: Opacity(
                      opacity: _fadeAnimation.value,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            const SizedBox(height: 40),

                            // Game mode header
                            _buildGameModeHeader(),

                            const SizedBox(height: 40),

                            // Result badge
                            ScaleTransition(
                              scale: _scaleAnimation,
                              child: _buildResultBadge(resultColor, quizState),
                            ),

                            const SizedBox(height: 40),

                            // Score comparison
                            _buildScoreComparison(quizState),

                            const SizedBox(height: 40),

                            // Match statistics
                            _buildMatchStatistics(quizState),

                            const SizedBox(height: 40),

                            // Action buttons
                            _buildActionButtons(),
                          ],
                        ),
                      ),
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

  Widget _buildBackgroundDecorations(Color resultColor) {
    return Positioned.fill(
      child: CustomPaint(
        painter: ResultBackgroundPainter(
          color: resultColor.withOpacity(0.1),
          animation: _mainController,
        ),
      ),
    );
  }

  Widget _buildConfettiOverlay() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _confettiController,
        builder: (context, child) {
          return CustomPaint(
            painter: ConfettiPainter(
              animation: _confettiController.value,
            ),
          );
        },
      ),
    );
  }

  Widget _buildGameModeHeader() {
    final gameColor = _getGameModeColor();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gameColor.withOpacity(0.1), gameColor.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gameColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getGameModeIcon(), color: gameColor, size: 24),
          const SizedBox(width: 12),
          Text(
            _getGameModeDisplayName(),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: gameColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultBadge(Color resultColor, MultiplayerQuizState quizState) {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            resultColor.withOpacity(0.8),
            resultColor,
          ],
        ),
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: resultColor.withOpacity(0.4),
            blurRadius: 30,
            spreadRadius: 10,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _getResultIcon(quizState.playerScore, quizState.opponentScore),
            color: Colors.white,
            size: 60,
          ),
          const SizedBox(height: 12),
          Text(
            _getResultTitle(quizState.playerScore, quizState.opponentScore),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreComparison(MultiplayerQuizState quizState) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          // Player score
          Expanded(
            child: _buildScoreCard(
              'You',
              quizState.playerScore,
              _getGameModeColor(),
              true,
            ),
          ),

          // VS divider
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            width: 2,
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.grey.shade300,
                  Colors.grey.shade100,
                  Colors.grey.shade300,
                ],
              ),
            ),
          ),

          // Opponent score
          Expanded(
            child: _buildScoreCard(
              quizState.opponentName ?? 'Opponent',
              quizState.opponentScore,
              Colors.grey.shade600,
              false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreCard(String name, int score, Color color, bool isPlayer) {
    return Column(
      children: [
        Text(
          name,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 12),
        AnimatedBuilder(
          animation: isPlayer ? _scoreCountAnimation : _scoreController,
          builder: (context, child) {
            final displayScore = isPlayer
                ? _scoreCountAnimation.value
                : score;
            return Text(
              displayScore.toString(),
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        Text(
          'points',
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade500,
          ),
        ),
      ],
    );
  }

  Widget _buildMatchStatistics(MultiplayerQuizState quizState) {
    final correctAnswers = quizState.playerScore ~/ _getScorePerQuestion();
    final accuracy = (correctAnswers / quizState.totalQuestions * 100).round();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Match Statistics',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Questions',
                  '${correctAnswers}/${quizState.totalQuestions}',
                  Icons.quiz,
                  Colors.blue,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatItem(
                  'Accuracy',
                  '$accuracy%',
                  Icons.percent_rounded,
                  Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        // Play Again button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              // Clear the current quiz state
              ref.read(multiplayerQuizProvider.notifier).forfeitMatch();
              // Navigate back to matchmaking for the same game mode
              context.go('/multiplayer/matchmaking/${widget.gameMode}');
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Play Again'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _getGameModeColor(),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Back to Hub button
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              ref.read(multiplayerQuizProvider.notifier).forfeitMatch();
              context.go('/multiplayer');
            },
            icon: const Icon(Icons.home),
            label: const Text('Back to Hub'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.grey.shade600,
              side: BorderSide(color: Colors.grey.shade400),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _getScorePerQuestion() {
    switch (widget.gameMode) {
      case 'arena':
        return 100;
      case 'teams':
        return 150;
      default:
        return 50;
    }
  }
}

// Custom painter for background decorations
class ResultBackgroundPainter extends CustomPainter {
  final Color color;
  final Animation<double> animation;

  ResultBackgroundPainter({
    required this.color,
    required this.animation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Draw animated background circles
    for (int i = 0; i < 6; i++) {
      final progress = (animation.value + i * 0.2) % 1.0;
      final radius = size.width * 0.3 * progress;
      final opacity = (1.0 - progress) * 0.3;

      paint.color = color.withOpacity(opacity);

      canvas.drawCircle(
        Offset(
          size.width * (0.2 + i * 0.15),
          size.height * (0.3 + (i % 3) * 0.2),
        ),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// Custom painter for confetti effect
class ConfettiPainter extends CustomPainter {
  final double animation;

  ConfettiPainter({required this.animation});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    final colors = [
      Colors.red,
      Colors.blue,
      Colors.green,
      Colors.yellow,
      Colors.purple,
      Colors.orange,
    ];

    for (int i = 0; i < 50; i++) {
      final progress = (animation + i * 0.02) % 1.0;
      final x = size.width * (i % 10) / 10;
      final y = size.height * progress;

      if (progress > 0.9) continue; // Don't draw near bottom

      paint.color = colors[i % colors.length].withOpacity(0.8);

      // Draw confetti pieces as small rectangles
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(progress * 6.28 * 3); // Multiple rotations
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          const Rect.fromLTWH(-3, -8, 6, 16),
          const Radius.circular(2),
        ),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
