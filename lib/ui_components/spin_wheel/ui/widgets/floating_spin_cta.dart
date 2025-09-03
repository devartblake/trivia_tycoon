import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/spin_tracker.dart';

/// ✅ A Floating CTA button that only appears when spin is available
class FloatingSpinCTA extends ConsumerStatefulWidget {
  final VoidCallback onPressed;

  const FloatingSpinCTA({super.key, required this.onPressed});

  @override
  ConsumerState<FloatingSpinCTA> createState() => _FloatingSpinCTAState();
}

class _FloatingSpinCTAState extends ConsumerState<FloatingSpinCTA>
    with SingleTickerProviderStateMixin {
  bool _canSpin = false;
  late final AnimationController _controller;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _checkSpin();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  Future<void> _checkSpin() async {
    final allowed = await SpinTracker.canSpin();
    if (!mounted) return;
    setState(() => _canSpin = allowed);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_canSpin) return const SizedBox.shrink();

    return ScaleTransition(
      scale: _pulseAnimation,
      child: FloatingActionButton.extended(
        backgroundColor: Colors.amber,
        icon: const Icon(Icons.casino),
        label: const Text("Spin Ready!"),
        onPressed: widget.onPressed,
      ),
    );
  }
}
