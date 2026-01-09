import 'package:flutter/material.dart';
import '../../domain/arcade_difficulty.dart';
import '../../domain/arcade_result.dart';
import '../../ui/screens/arcade_game_shell.dart';
import '../../ui/screens/widgets/wallet_counters_row.dart';
import 'memory_flip_controller.dart';

class MemoryFlipScreen extends StatefulWidget {
  final ArcadeDifficulty difficulty;

  const MemoryFlipScreen({
    super.key,
    required this.difficulty,
  });

  @override
  State<MemoryFlipScreen> createState() => _MemoryFlipScreenState();
}

class _MemoryFlipScreenState extends State<MemoryFlipScreen> {
  late final MemoryFlipController _controller;

  // Simple icon palette (original, no external assets)
  static const _icons = <IconData>[
    Icons.favorite_rounded,
    Icons.star_rounded,
    Icons.bolt_rounded,
    Icons.sports_esports_rounded,
    Icons.catching_pokemon_rounded,
    Icons.lightbulb_rounded,
    Icons.rocket_launch_rounded,
    Icons.lock_rounded,
    Icons.music_note_rounded,
    Icons.emoji_events_rounded,
    Icons.auto_awesome_rounded,
    Icons.wb_sunny_rounded,
    Icons.nightlight_round,
    Icons.public_rounded,
    Icons.extension_rounded,
    Icons.local_fire_department_rounded,
    Icons.psychology_alt_rounded,
    Icons.shield_rounded,
    Icons.shopping_bag_rounded,
    Icons.diamond_rounded,
  ];

  IconData _iconForId(int id) => _icons[id % _icons.length];

  @override
  void initState() {
    super.initState();
    _controller = MemoryFlipController(difficulty: widget.difficulty);
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
    final seconds = s.remaining.inSeconds.clamp(0, 999);

    final crossAxisCount = _inferColumns(s.cards.length);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text('Memory Flip • ${widget.difficulty.label}'),
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
                _pill(Icons.grid_view_rounded, 'Pairs', '${s.matches}/${s.totalPairs}',
                    accent: Colors.lightBlueAccent),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: GridView.builder(
                itemCount: s.cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1,
                ),
                itemBuilder: (context, i) {
                  final c = s.cards[i];
                  final faceUp = c.isFaceUp || c.isMatched;

                  return _MemoryTile(
                    faceUp: faceUp,
                    matched: c.isMatched,
                    locked: s.inputLocked,
                    icon: _iconForId(c.id),
                    onTap: () async {
                      await _controller.flip(i, (_) {
                        if (!mounted) return;
                        setState(() {});
                      });
                      if (!mounted) return;
                      if (_controller.state.isOver) {
                        _finish();
                      }
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _mini('Moves', '${s.moves}'),
                const SizedBox(width: 8),
                _mini('Misses', '${s.misses}'),
                const SizedBox(width: 8),
                _mini('Status', s.inputLocked ? 'Resolving…' : 'Ready'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  int _inferColumns(int totalCards) {
    // Keep it visually clean across different grid sizes
    if (totalCards <= 12) return 4; // 3x4 layout but 4 columns is good for compact tiles
    if (totalCards <= 16) return 4;
    if (totalCards <= 20) return 5;
    return 6;
  }

  Widget _pill(IconData icon, String label, String value, {required Color accent}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withOpacity(0.08),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Row(
          children: [
            Icon(icon, color: accent, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.70),
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
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.10)),
        ),
        child: Column(
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white.withOpacity(0.70),
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

class _MemoryTile extends StatelessWidget {
  final bool faceUp;
  final bool matched;
  final bool locked;
  final IconData icon;
  final VoidCallback onTap;

  const _MemoryTile({
    required this.faceUp,
    required this.matched,
    required this.locked,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bg = matched
        ? const Color(0xFF1B4332).withOpacity(0.95)
        : Colors.white.withOpacity(faceUp ? 0.12 : 0.06);

    final border = matched
        ? const Color(0xFF52B788).withOpacity(0.6)
        : Colors.white.withOpacity(faceUp ? 0.18 : 0.10);

    return InkWell(
      onTap: locked ? null : onTap,
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          color: bg,
          border: Border.all(color: border),
        ),
        child: Center(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: faceUp
                ? Icon(
              icon,
              key: const ValueKey('face'),
              color: matched ? Colors.white : Colors.white,
              size: 26,
            )
                : Icon(
              Icons.question_mark_rounded,
              key: const ValueKey('back'),
              color: Colors.white.withOpacity(0.55),
              size: 22,
            ),
          ),
        ),
      ),
    );
  }
}
