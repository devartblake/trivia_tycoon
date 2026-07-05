import 'package:flutter/material.dart';

/// Trivia-deck style question card: an elevated white card with two offset
/// "deck" cards peeking out behind it, entering with a slide + fade.
///
/// Give it a key derived from the question (e.g. `ValueKey(question.id)`) so
/// the entrance animation replays on every new question.
class QuestionCardStack extends StatelessWidget {
  final Widget child;

  const QuestionCardStack({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, t, card) => Opacity(
        opacity: t,
        child: Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: card,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _GhostCard(angle: -0.020, opacity: 0.45)),
          Positioned.fill(child: _GhostCard(angle: 0.014, opacity: 0.70)),
          Container(
            width: double.infinity,
            constraints: const BoxConstraints(minHeight: 190),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _GhostCard extends StatelessWidget {
  final double angle;
  final double opacity;

  const _GhostCard({required this.angle, required this.opacity});

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: angle,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: opacity),
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}
