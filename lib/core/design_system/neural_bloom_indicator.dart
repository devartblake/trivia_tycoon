import 'dart:math';
import 'package:flutter/material.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';

/// A biological-inspired pulsing loading indicator for Synaptix.
///
/// Replaces the standard [CircularProgressIndicator] with a "Neural Bloom"
/// aesthetic consisting of interconnected pulsing nodes.
class NeuralBloomIndicator extends StatefulWidget {
  final double size;
  final Color? color;

  const NeuralBloomIndicator({
    super.key,
    this.size = 60.0,
    this.color,
  });

  @override
  State<NeuralBloomIndicator> createState() => _NeuralBloomIndicatorState();
}

class _NeuralBloomIndicatorState extends State<NeuralBloomIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final accent = widget.color ?? synaptix?.accentGlow ?? Colors.cyanAccent;

    // Adjust speed based on demographic motion preference
    if (synaptix?.useHighEnergyMotion == false) {
      _controller.duration = const Duration(milliseconds: 3000);
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _NeuralBloomIndicatorPainter(
            animationValue: _controller.value,
            color: accent,
          ),
        );
      },
    );
  }
}

class _NeuralBloomIndicatorPainter extends CustomPainter {
  final double animationValue;
  final Color color;

  _NeuralBloomIndicatorPainter({
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2.5;
    const nodeCount = 3;

    final filamentPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final nodePaint = Paint()..style = PaintingStyle.fill;

    // Calculate node positions with rotation
    final nodes = <Offset>[];
    for (var i = 0; i < nodeCount; i++) {
      final angle = (i * 2 * pi / nodeCount) + (animationValue * 2 * pi);
      // Slight "breathing" distance from center
      final dist = radius * (0.8 + 0.2 * sin(animationValue * 2 * pi + i));
      nodes.add(Offset(
        center.dx + dist * cos(angle),
        center.dy + dist * sin(angle),
      ));
    }

    // 1. Draw connecting filaments
    for (var i = 0; i < nodes.length; i++) {
      final start = nodes[i];
      final end = nodes[(i + 1) % nodes.length];
      canvas.drawLine(start, end, filamentPaint);
      canvas.drawLine(center, start, filamentPaint);
    }

    // 2. Draw pulsing nodes
    for (var i = 0; i < nodes.length; i++) {
      final nodePos = nodes[i];
      final pulse = (sin(animationValue * 2 * pi + i) + 1) / 2; // 0.0 to 1.0

      // Outer glow
      canvas.drawCircle(
        nodePos,
        6.0 + (4.0 * pulse),
        Paint()..color = color.withValues(alpha: 0.3 * pulse),
      );

      // Core
      canvas.drawCircle(nodePos, 4.0, nodePaint..color = color);
    }

    // 3. Central nucleus
    final nucleusPulse = (cos(animationValue * 2 * pi) + 1) / 2;
    canvas.drawCircle(
      center,
      8.0 * nucleusPulse,
      Paint()..color = color.withValues(alpha: 0.1 * nucleusPulse),
    );
  }

  @override
  bool shouldRepaint(covariant _NeuralBloomIndicatorPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}
