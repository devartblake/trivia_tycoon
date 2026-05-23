import 'dart:math';

import 'package:flutter/material.dart';

class ReactorParticleLayer extends StatefulWidget {
  final bool active;
  final String rarity;
  final String? seasonKey;

  const ReactorParticleLayer({
    super.key,
    required this.active,
    this.rarity = 'common',
    this.seasonKey,
  });

  @override
  State<ReactorParticleLayer> createState() => _ReactorParticleLayerState();
}

class _ReactorParticleLayerState extends State<ReactorParticleLayer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<_Particle> _particles;

  static final _rng = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _particles = _buildParticles(widget.rarity, widget.seasonKey);
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(ReactorParticleLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.rarity != oldWidget.rarity ||
        widget.seasonKey != oldWidget.seasonKey) {
      _particles = _buildParticles(widget.rarity, widget.seasonKey);
    }
    if (widget.active && !oldWidget.active) {
      _controller.repeat(reverse: true);
    } else if (!widget.active && oldWidget.active) {
      _controller.stop();
      _controller.value = 0;
    }
  }

  static List<_Particle> _buildParticles(String rarity, String? seasonKey) {
    final colors = _paletteFor(seasonKey, rarity);
    final count = switch (rarity) {
      'legendary' => 42,
      'rare' => 32,
      'uncommon' => 26,
      _ => 20,
    };

    return List.generate(
      count,
      (_) => _Particle(
        x: _rng.nextDouble(),
        y: _rng.nextDouble(),
        radius: 3 + _rng.nextDouble() * 5,
        color: colors[_rng.nextInt(colors.length)],
        phase: _rng.nextDouble() * 2 * pi,
      ),
    );
  }

  static List<Color> _paletteFor(String? seasonKey, String rarity) {
    if (seasonKey?.startsWith('halloween') == true) {
      return const [Color(0xFFFF8A00), Color(0xFF8B5CF6), Color(0xFF39FF14)];
    }
    if (seasonKey?.startsWith('winter') == true) {
      return const [Color(0xFFBDEBFF), Color(0xFFFFFFFF), Color(0xFF7DD3FC)];
    }
    if (seasonKey?.startsWith('spring') == true) {
      return const [Color(0xFFFF7AB6), Color(0xFF64D96B), Color(0xFFFFE066)];
    }
    return rarity == 'legendary'
        ? const [Color(0xFFFFD700), Color(0xFFFF7A00), Color(0xFFFFFFFF)]
        : const [Color(0xFFFFD700), Color(0xFF7C3AED), Color(0xFF00E5FF)];
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
