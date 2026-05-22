import 'dart:math';

import 'package:flutter/material.dart';

class ReactorParticleLayer extends StatefulWidget {
  final bool active;

  const ReactorParticleLayer({super.key, required this.active});

  @override
  State<ReactorParticleLayer> createState() => _ReactorParticleLayerState();
}

class _ReactorParticleLayerState extends State<ReactorParticleLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  static final _rng = Random();
  static final List<_Particle> _particles = List.generate(
    20,
    (_) => _Particle(
      x: _rng.nextDouble(),
      y: _rng.nextDouble(),
      radius: 3 + _rng.nextDouble() * 4,
      color: [
        const Color(0xFFFFD700),
        const Color(0xFF7C3AED),
        const Color(0xFF00E5FF),
      ][_rng.nextInt(3)],
      phase: _rng.nextDouble() * 2 * pi,
    ),
  );

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ReactorParticleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return const SizedBox.shrink();

    return RepaintBoundary(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return CustomPaint(
              painter: _ParticlePainter(_particles, _controller.value),
              child: const SizedBox.expand(),
            );
          },
        ),
      ),
    );
  }
}

class _Particle {
  final double x;
  final double y;
  final double radius;
  final Color color;
  final double phase;

  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.color,
    required this.phase,
  });
}

class _ParticlePainter extends CustomPainter {
  final List<_Particle> particles;
  final double progress;

  const _ParticlePainter(this.particles, this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in particles) {
      final opacity = (sin(p.phase + progress * pi * 2) + 1) / 2;
      final paint = Paint()
        ..color = p.color.withValues(alpha: opacity * 0.8)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(
        Offset(p.x * size.width, p.y * size.height),
        p.radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter old) => old.progress != progress;
}
