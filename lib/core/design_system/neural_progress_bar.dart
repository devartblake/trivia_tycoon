import 'dart:math';
import 'package:flutter/material.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';

/// A biological-inspired non-linear progress indicator.
///
/// Replaces standard linear bars with glowing "neural nodes" connected by
/// energy filaments.
class NeuralProgressBar extends StatefulWidget {
  final int total;
  final int current; // 0-based
  final Color? color;

  const NeuralProgressBar({
    super.key,
    required this.total,
    required this.current,
    this.color,
  });

  @override
  State<NeuralProgressBar> createState() => _NeuralProgressBarState();
}

class _NeuralProgressBarState extends State<NeuralProgressBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final accent = widget.color ?? synaptix?.accentGlow ?? Colors.cyanAccent;

    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(double.infinity, 30),
          painter: _NeuralProgressBarPainter(
            total: widget.total,
            current: widget.current,
            color: accent,
            pulse: _pulseController.value,
          ),
        );
      },
    );
  }
}

class _NeuralProgressBarPainter extends CustomPainter {
  final int total;
  final int current;
  final Color color;
  final double pulse;

  _NeuralProgressBarPainter({
    required this.total,
    required this.current,
    required this.color,
    required this.pulse,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;

    final nodeRadius = size.height / 4;
    final spacing =
        (size.width - (nodeRadius * 2)) / (total > 1 ? total - 1 : 1);
    final centerY = size.height / 2;

    final filamentPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final nodePaint = Paint()..style = PaintingStyle.fill;

    // 1. Draw connecting filaments (Organic Curves)
    for (var i = 0; i < total - 1; i++) {
      final startX = nodeRadius + (i * spacing);
      final endX = nodeRadius + ((i + 1) * spacing);

      final isCompleted = i < current;

      filamentPaint.color = isCompleted
          ? color.withValues(alpha: 0.4)
          : Colors.white.withValues(alpha: 0.1);

      final path = Path();
      path.moveTo(startX, centerY);

      // Add organic "sag" or "tension" to the filament based on pulse
      final controlY = centerY + (2.0 * sin(pulse * pi + i));
      path.quadraticBezierTo(
        (startX + endX) / 2,
        controlY,
        endX,
        centerY,
      );

      canvas.drawPath(path, filamentPaint);
    }

    // 2. Draw nodes
    for (var i = 0; i < total; i++) {
      final x = nodeRadius + (i * spacing);
      final isActive = i == current;
      final isCompleted = i < current;

      if (isActive) {
        // Active node: high intensity glow
        final glowAlpha = 0.2 + (0.3 * pulse);
        canvas.drawCircle(
          Offset(x, centerY),
          nodeRadius + (4.0 * pulse),
          Paint()..color = color.withValues(alpha: glowAlpha),
        );

        canvas.drawCircle(
          Offset(x, centerY),
          nodeRadius,
          nodePaint..color = color,
        );
      } else if (isCompleted) {
        // Completed node: solid fill
        canvas.drawCircle(
          Offset(x, centerY),
          nodeRadius,
          nodePaint..color = color.withValues(alpha: 0.6),
        );
      } else {
        // Future node: outline
        canvas.drawCircle(
          Offset(x, centerY),
          nodeRadius,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.2)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.0,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _NeuralProgressBarPainter oldDelegate) {
    return oldDelegate.current != current ||
        oldDelegate.pulse != pulse ||
        oldDelegate.total != total;
  }
}
