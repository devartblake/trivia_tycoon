import 'package:flutter/material.dart';

import '../../domain/arcade_difficulty.dart';
import '../../domain/arcade_result.dart';
import '../../ui/screens/arcade_game_shell.dart';
import '../../ui/screens/widgets/wallet_counters_row.dart';
import 'pattern_sprint_controller.dart';

class PatternSprintScreen extends StatefulWidget {
  final ArcadeDifficulty difficulty;

  const PatternSprintScreen({
    super.key,
    required this.difficulty,
  });

  @override
  State<PatternSprintScreen> createState() => _PatternSprintScreenState();
}

class _PatternSprintScreenState extends State<PatternSprintScreen> {
  late final PatternSprintController _controller;

  @override
  void initState() {
    super.initState();
    _controller = PatternSprintController(difficulty: widget.difficulty);
    _controller.start((_) {
      if (!mounted) return;
      setState(() {});
      if (_controller.state.isOver) {
        _finish();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final api = ArcadeGameShell.of(context);
    final ArcadeResult result = _controller.toResult();
    await api.completeRun(result);
  }

  @override
  Widget build(BuildContext context) {
    final s = _controller.state;
    final q = s.question;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Pattern Sprint • ${widget.difficulty.label}'),
        actions: [
          const Padding(
            padding: EdgeInsets.only(right: 10),
            child: WalletCountersRow(compact: true),
          ),
          TextButton(
            onPressed: _finish,
            child: const Text('End', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          children: [
            _TopStatsRow(
              remaining: s.remaining,
              score: s.score,
              streak: s.streak,
            ),
            const SizedBox(height: 14),
            _PromptCard(sequence: q.sequence),
            const SizedBox(height: 14),
            _OptionsGrid(
              options: q.options,
              onPick: (value) {
                _controller.answer(value, (_) {
                  if (!mounted) return;
                  setState(() {});
                });
              },
            ),
            const SizedBox(height: 12),
            _BottomMeta(
              correct: s.correct,
              wrong: s.wrong,
              answered: s.questionsAnswered,
              maxStreak: s.maxStreak,
            ),
          ],
        ),
      ),
    );
  }
}

class _TopStatsRow extends StatelessWidget {
  final Duration remaining;
  final int score;
  final int streak;

  const _TopStatsRow({
    required this.remaining,
    required this.score,
    required this.streak,
  });

  @override
  Widget build(BuildContext context) {
    final seconds = remaining.inSeconds.clamp(0, 999);

    return Row(
      children: [
        _StatPill(
          icon: Icons.timer_rounded,
          label: 'Time',
          value: '${seconds}s',
          accent: seconds <= 10 ? Colors.redAccent : Colors.white,
        ),
        const SizedBox(width: 10),
        _StatPill(
          icon: Icons.emoji_events_rounded,
          label: 'Score',
          value: '$score',
          accent: Colors.amberAccent,
        ),
        const SizedBox(width: 10),
        _StatPill(
          icon: Icons.bolt_rounded,
          label: 'Streak',
          value: '$streak',
          accent: Colors.lightBlueAccent,
        ),
      ],
    );
  }
}

class _StatPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  const _StatPill({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.08),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final List<String> sequence;

  const _PromptCard({required this.sequence});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [
            const Color(0xFF2C2C54).withValues(alpha: 0.95),
            const Color(0xFF1B1B2F).withValues(alpha: 0.90),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fill the missing value:',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.75),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: sequence.map((token) {
              final isMissing = token == '?';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: isMissing
                      ? Colors.white.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isMissing
                        ? Colors.amberAccent.withValues(alpha: 0.6)
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  token,
                  style: TextStyle(
                    color: isMissing ? Colors.amberAccent : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _OptionsGrid extends StatelessWidget {
  final List<int> options;
  final ValueChanged<int> onPick;

  const _OptionsGrid({
    required this.options,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        itemCount: options.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 2.3,
        ),
        itemBuilder: (context, i) {
          final value = options[i];
          return ElevatedButton(
            onPressed: () => onPick(value),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.10),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18)),
              side: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            child: Text(
              '$value',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BottomMeta extends StatelessWidget {
  final int correct;
  final int wrong;
  final int answered;
  final int maxStreak;

  const _BottomMeta({
    required this.correct,
    required this.wrong,
    required this.answered,
    required this.maxStreak,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _MiniChip(label: 'Correct', value: '$correct'),
        const SizedBox(width: 8),
        _MiniChip(label: 'Wrong', value: '$wrong'),
        const SizedBox(width: 8),
        _MiniChip(label: 'Answered', value: '$answered'),
        const SizedBox(width: 8),
        _MiniChip(label: 'Max Streak', value: '$maxStreak'),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  final String label;
  final String value;

  const _MiniChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white.withValues(alpha: 0.06),
          border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
