import 'package:flutter/material.dart';

class AnimatedRankBadge extends StatefulWidget {
  final int rank;
  final int? previousRank;

  const AnimatedRankBadge({
    super.key,
    required this.rank,
    this.previousRank,
  });

  @override
  State<AnimatedRankBadge> createState() => _AnimatedRankBadgeState();
}

class _AnimatedRankBadgeState extends State<AnimatedRankBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    if (widget.previousRank != null && widget.previousRank != widget.rank) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(AnimatedRankBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.rank != widget.rank) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    final improved =
        widget.previousRank != null && widget.rank < widget.previousRank!;
    final declined =
        widget.previousRank != null && widget.rank > widget.previousRank!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: improved
                ? Colors.green.withOpacity(0.2 * (1 - _controller.value))
                : declined
                    ? Colors.red.withOpacity(0.2 * (1 - _controller.value))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('#${widget.rank}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              if (improved) ...[
                const SizedBox(width: 4),
                const Icon(Icons.arrow_upward, color: Colors.green, size: 16),
              ],
              if (declined) ...[
                const SizedBox(width: 4),
                const Icon(Icons.arrow_downward, color: Colors.red, size: 16),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
