import 'package:flutter/material.dart';
import '../../domain/arcade_difficulty.dart';
import '../../domain/arcade_result.dart';
import '../../ui/screens/arcade_game_shell.dart';
import '../../ui/screens/widgets/wallet_counters_row.dart';
import 'quick_math_controller.dart';

class QuickMathRushScreen extends StatefulWidget {
  final ArcadeDifficulty difficulty;

  const QuickMathRushScreen({
    super.key,
    required this.difficulty,
  });

  @override
  State<QuickMathRushScreen> createState() => _QuickMathRushScreenState();
}

class _QuickMathRushScreenState extends State<QuickMathRushScreen> {
  late final QuickMathController _controller;

  @override
  void initState() {
    super.initState();
    _controller = QuickMathController(difficulty: widget.difficulty);
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
    final seconds = s.remaining.inSeconds.clamp(0, 999);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Quick Math Rush • ${widget.difficulty.label}'),
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
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          children: [
            Row(
              children: [
                _pill(Icons.timer_rounded, 'Time', '${seconds}s',
                    accent: seconds <= 10 ? Colors.redAccent : Colors.white),
                const SizedBox(width: 10),
                _pill(Icons.emoji_events_rounded, 'Score', '${s.score}',
                    accent: Colors.amberAccent),
                const SizedBox(width: 10),
                _pill(Icons.bolt_rounded, 'Streak', '${s.streak}',
                    accent: Colors.lightBlueAccent),
              ],
            ),
            const SizedBox(height: 12),

            // Pace bar (optional “rush” feel)
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: s.paceProgress.clamp(0.0, 1.0),
                minHeight: 10,
                backgroundColor: Colors.white.withValues(alpha: 0.10),
              ),
            ),
            const SizedBox(height: 16),

            // Prompt card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: Colors.white.withValues(alpha: 0.08),
                border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
              ),
              child: Column(
                children: [
                  Text(
                    q.prompt,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Answer quickly to build streak multipliers.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.70),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Options
            Expanded(
              child: GridView.builder(
                physics: const NeverScrollableScrollPhysics(),
                itemCount: q.options.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 2.3,
                ),
                itemBuilder: (context, i) {
                  final value = q.options[i];
                  return ElevatedButton(
                    onPressed: () {
                      _controller.answer(value, (_) {
                        if (!mounted) return;
                        setState(() {});
                      });
                      if (_controller.state.isOver) {
                        _finish();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.10),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18)),
                      side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.12)),
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
            ),
            const SizedBox(height: 12),

            Row(
              children: [
                _mini('Correct', '${s.correct}'),
                const SizedBox(width: 8),
                _mini('Wrong', '${s.wrong}'),
                const SizedBox(width: 8),
                _mini('Answered', '${s.answered}'),
                const SizedBox(width: 8),
                _mini('Max Streak', '${s.maxStreak}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(IconData icon, String label, String value,
      {required Color accent}) {
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
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mini(String label, String value) {
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
