import 'package:flutter/material.dart';
import 'package:synaptix/synaptix/theme/synaptix_theme_extension.dart';

/// A touch-responsive surface that renders "liquid neon" trails.
class InteractiveGlowSurface extends StatefulWidget {
  final Widget child;
  final Color? glowColor;

  const InteractiveGlowSurface({
    super.key,
    required this.child,
    this.glowColor,
  });

  @override
  State<InteractiveGlowSurface> createState() => _InteractiveGlowSurfaceState();
}

class _InteractiveGlowSurfaceState extends State<InteractiveGlowSurface>
    with SingleTickerProviderStateMixin {
  final List<_GlowPoint> _points = [];
  late final AnimationController _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..addListener(() {
        _prunePoints();
      });
  }

  @override
  void dispose() {
    _ticker.dispose();
    super.dispose();
  }

  void _prunePoints() {
    if (_points.isEmpty) return;

    final now = DateTime.now();
    setState(() {
      _points.removeWhere((p) =>
          now.difference(p.timestamp) > const Duration(milliseconds: 600));
    });

    if (_points.isEmpty) {
      _ticker.stop();
    }
  }

  void _handlePointerMove(PointerMoveEvent event) {
    if (!_ticker.isAnimating) _ticker.repeat();

    setState(() {
      _points.add(_GlowPoint(
        position: event.localPosition,
        timestamp: DateTime.now(),
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final accent =
        widget.glowColor ?? synaptix?.accentGlow ?? Colors.cyanAccent;
    final enabled = synaptix?.useHighEnergyMotion ?? true;

    if (!enabled) return widget.child;

    return Listener(
      onPointerMove: _handlePointerMove,
      child: CustomPaint(
        foregroundPainter: _GlowTrailPainter(
          points: _points,
          color: accent,
        ),
        child: widget.child,
      ),
    );
  }
}

class _GlowPoint {
  final Offset position;
  final DateTime timestamp;

  _GlowPoint({required this.position, required this.timestamp});
}

class _GlowTrailPainter extends CustomPainter {
  final List<_GlowPoint> points;
  final Color color;

  _GlowTrailPainter({required this.points, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final now = DateTime.now();
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    for (var i = 0; i < points.length - 1; i++) {
      final p1 = points[i];
      final p2 = points[i + 1];

      // Skip if points are too far apart (likely separate touches)
      if (p2.position.dx - p1.position.dx > 100 ||
          p2.position.dy - p1.position.dy > 100) {
        continue;
      }

      final age = now.difference(p1.timestamp).inMilliseconds;
      final life = (1.0 - (age / 600)).clamp(0.0, 1.0);

      if (life <= 0) continue;

      paint.color = color.withValues(alpha: 0.4 * life);
      paint.strokeWidth = 12.0 * life;

      // Blur effect simulated via layering
      canvas.drawLine(p1.position, p2.position, paint);

      paint.strokeWidth = 4.0 * life;
      paint.color = Colors.white.withValues(alpha: 0.6 * life);
      canvas.drawLine(p1.position, p2.position, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _GlowTrailPainter oldDelegate) => true;
}
