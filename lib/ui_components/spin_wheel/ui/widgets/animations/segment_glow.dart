import 'package:flutter/material.dart';

class SegmentGlow extends StatelessWidget {
  final bool active;
  final double size;

  const SegmentGlow({super.key, required this.active, this.size = 120});

  @override
  Widget build(BuildContext context) {
    if (!active) return const SizedBox.shrink();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.yellow.withOpacity(0.6),
            blurRadius: 30,
            spreadRadius: 10,
          ),
        ],
      ),
    );
  }
}