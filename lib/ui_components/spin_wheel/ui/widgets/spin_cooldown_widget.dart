import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/spin_tracker.dart';

class SpinCooldownWidget extends ConsumerStatefulWidget {
  const SpinCooldownWidget({super.key});

  @override
  ConsumerState<SpinCooldownWidget> createState() => _SpinCooldownWidgetState();
}

class _SpinCooldownWidgetState extends ConsumerState<SpinCooldownWidget> {
  Duration _timeLeft = Duration.zero;
  int _remainingSpins = SpinTracker.getMaxSpins();

  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _refreshCooldown();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _refreshCooldown());
  }

  Future<void> _refreshCooldown() async {
    final timeLeft = await SpinTracker.timeLeft();
    final count = await SpinTracker.getDailyCount();
    if (!mounted) return;
    setState(() {
      _timeLeft = timeLeft;
      _remainingSpins = SpinTracker.getMaxSpins() - count;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percentage = (_timeLeft.inSeconds / SpinTracker.cooldown.inSeconds).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("⏱ Cooldown Time Left: ${_format(_timeLeft)}"),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: 1.0 - percentage),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 500),
          transitionBuilder: (child, animation) =>
              ScaleTransition(scale: animation, child: child),
          child: Text(
            "🎯 Remaining Daily Spins: $_remainingSpins / ${SpinTracker.getMaxSpins()}",
            key: ValueKey(_remainingSpins),
            style: Theme.of(context).textTheme.bodyLarge,
          ),
        ),
      ],
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "${d.inHours.toString().padLeft(2, '0')}:$minutes:$seconds";
  }
}
