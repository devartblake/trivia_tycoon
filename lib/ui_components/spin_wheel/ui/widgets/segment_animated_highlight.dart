import 'package:flutter/material.dart';

class SegmentAnimatedHighlight extends StatefulWidget {
  final bool isActive;
  final double size;

  const SegmentAnimatedHighlight({super.key, required this.isActive, this.size = 60});

  @override
  State<SegmentAnimatedHighlight> createState() => _SegmentAnimatedHighlightState();
}

class _SegmentAnimatedHighlightState extends State<SegmentAnimatedHighlight>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) return const SizedBox();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.amber.withOpacity(_controller.value),
              width: 3,
            ),
          ),
        );
      },
    );
  }
}