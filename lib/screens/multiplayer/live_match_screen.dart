import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/multiplayer/widgets/answer_controls.dart';
import 'package:trivia_tycoon/screens/multiplayer/widgets/countdown_timer.dart';
import '../../game/multiplayer/application/state/match_state.dart';
import '../../game/multiplayer/providers/multiplayer_providers.dart';
import 'dialogs/exit_match_confirm.dart';

class LiveMatchScreen extends ConsumerStatefulWidget {
  const LiveMatchScreen({super.key});

  @override
  ConsumerState<LiveMatchScreen> createState() => _LiveMatchScreenState();
}

class _LiveMatchScreenState extends ConsumerState<LiveMatchScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _questionController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _questionAnimation;
  String? selectedAnswer;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );
    _questionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _questionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _questionController,
      curve: Curves.easeOutBack,
    ));

    _pulseController.repeat(reverse: true);
    _questionController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _questionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final match = ref.watch(matchControllerProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (!didPop) {
          final ok = await showExitMatchConfirm(context);
          if (ok == true && context.mounted) {
            context.go('/multiplayer/rooms'); // Return to room lobby instead of main hub
          }
        }
      },
      child: Scaffold(
        backgroundColor: isDark
            ? const Color(0xFF0A0A0F)
            : const Color(0xFFF8F9FC),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(match, theme, isDark, context),
            SliverFillRemaining(
              hasScrollBody: false,
              child: AnimatedBuilder(
                animation: _questionAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _questionAnimation.value,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          if (match.phase == MatchPhase.question)
                            _buildTimerCard(theme, isDark),
                          const SizedBox(height: 24),
                          _buildQuestionCard(match, theme, isDark),
                          const Spacer(),
                          // Use the enhanced AnswerControls widget
                          AnswerControls(
                            answers: const ['A', 'B', 'C', 'D'],
                            selectedAnswer: selectedAnswer,
                            onSelect: (answer) {
                              if (selectedAnswer == null) {
                                setState(() {
                                  selectedAnswer = answer;
                                });
                                final id = match.matchId ?? 'temp';
                                final q = match.questionId ?? 'Q-1';
                                ref.read(matchControllerProvider.notifier).submitAnswer(id, q, answer);
                              }
                            },
                          ),
                          const SizedBox(height: 20),
                        ],
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

  Widget _buildSliverAppBar(dynamic match, ThemeData theme, bool isDark, BuildContext context) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: _getPhaseGradient(match.phase),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Icon(
                          _getPhaseIcon(match.phase),
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _titleForPhase(match.phase),
                              style: theme.textTheme.headlineMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              _getPhaseSubtitle(match.phase),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: IconButton(
          onPressed: () async {
            final ok = await showExitMatchConfirm(context);
            if (ok == true && context.mounted) {
              context.go('/multiplayer/rooms'); // Return to room lobby
            }
          },
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        ),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: IconButton(
            icon: const Icon(Icons.leaderboard_rounded, color: Colors.white),
            onPressed: () {
              _showLeaderboard(context, theme, isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTimerCard(ThemeData theme, bool isDark) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _pulseAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFEF4444).withOpacity(0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.timer_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Use the enhanced CountdownTimer widget
                const CountdownTimer(totalMs: 12000),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuestionCard(dynamic match, ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Question ${match.questionId ?? "1"}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Text(
                  'Multiple Choice',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2A3E)
                  : const Color(0xFFF8F9FC),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'What is the capital of France?',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard(BuildContext context, ThemeData theme, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.leaderboard_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Live Leaderboard',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF1E293B),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: 4, // Mock data
                itemBuilder: (context, index) {
                  final positions = ['1st', '2nd', '3rd', '4th'];
                  final names = ['Player 1', 'Player 2', 'Player 3', 'Player 4'];
                  final scores = [850, 720, 680, 520];
                  final colors = [
                    const Color(0xFFEF4444),
                    const Color(0xFF3B82F6),
                    const Color(0xFF10B981),
                    const Color(0xFFF59E0B),
                  ];

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colors[index].withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: colors[index].withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: colors[index],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              '${index + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                names[index],
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                                ),
                              ),
                              Text(
                                positions[index],
                                style: TextStyle(
                                  fontSize: 12,
                                  color: colors[index],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${scores[index]} pts',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: colors[index],
                          ),
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

  List<Color> _getPhaseGradient(MatchPhase phase) {
    switch (phase) {
      case MatchPhase.question:
        return [const Color(0xFF10B981), const Color(0xFF059669)];
      case MatchPhase.reveal:
        return [const Color(0xFFF59E0B), const Color(0xFFD97706)];
      case MatchPhase.results:
        return [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)];
      case MatchPhase.finished:
        return [const Color(0xFF6366F1), const Color(0xFF4F46E5)];
      case MatchPhase.error:
        return [const Color(0xFFEF4444), const Color(0xFFDC2626)];
      default:
        return [const Color(0xFF6B7280), const Color(0xFF4B5563)];
    }
  }

  IconData _getPhaseIcon(MatchPhase phase) {
    switch (phase) {
      case MatchPhase.question:
        return Icons.quiz_rounded;
      case MatchPhase.reveal:
        return Icons.visibility_rounded;
      case MatchPhase.results:
        return Icons.leaderboard_rounded;
      case MatchPhase.finished:
        return Icons.emoji_events_rounded;
      case MatchPhase.error:
        return Icons.error_rounded;
      default:
        return Icons.hourglass_empty_rounded;
    }
  }

  String _getPhaseSubtitle(MatchPhase phase) {
    switch (phase) {
      case MatchPhase.question:
        return 'Answer quickly to earn points!';
      case MatchPhase.reveal:
        return 'See how you did!';
      case MatchPhase.results:
        return 'Check the leaderboard';
      case MatchPhase.finished:
        return 'Match completed!';
      case MatchPhase.error:
        return 'Something went wrong';
      default:
        return 'Preparing match...';
    }
  }

  String _titleForPhase(MatchPhase p) => switch (p) {
    MatchPhase.idle => 'Match',
    MatchPhase.queued => 'Queued',
    MatchPhase.starting => 'Starting',
    MatchPhase.question => 'Question Time',
    MatchPhase.reveal => 'Answer Reveal',
    MatchPhase.results => 'Results',
    MatchPhase.finished => 'Match Finished',
    MatchPhase.error => 'Error',
  };
}
