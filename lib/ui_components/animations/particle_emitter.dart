import 'dart:math';
import 'package:flutter/material.dart';

class ParticleEmitter extends StatefulWidget {
  final Widget child;
  final bool trigger;
  final Color color;
  final int particleCount;

  const ParticleEmitter({
    super.key,
    required this.child,
    required this.trigger,
    this.color = Colors.amber,
    this.particleCount = 12,
  });

  @override
  State<ParticleEmitter> createState() => _ParticleEmitterState();
}

class _ParticleEmitterState extends State<ParticleEmitter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  final List<_Particle> _particles = [];
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void didUpdateWidget(ParticleEmitter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.trigger && !oldWidget.trigger) {
      _emitParticles();
    }
  }

  void _emitParticles() {
    _particles.clear();
    for (var i = 0; i < widget.particleCount; i++) {
      _particles.add(_Particle(
        angle: _random.nextDouble() * 2 * pi,
        distance: 40.0 + _random.nextDouble() * 60.0,
        size: 2.0 + _random.nextDouble() * 4.0,
        speed: 0.5 + _random.nextDouble() * 1.5,
      ));
    }
    _controller.forward(from: 0.0);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      clipBehavior: Clip.none,
      children: [
        widget.child,
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            if (!_controller.isAnimating) return const SizedBox.shrink();

            return SizedBox(
              width: 1,
              height: 1,
              child: Stack(
                clipBehavior: Clip.none,
                children: _particles.map((p) {
                  final progress = _controller.value;
                  final opacity = (1.0 - progress).clamp(0.0, 1.0);
                  final offset = Offset(
                    cos(p.angle) * p.distance * progress * p.speed,
                    sin(p.angle) * p.distance * progress * p.speed,
                  );

                  return Positioned(
                    left: offset.dx,
                    top: offset.dy,
                    child: Opacity(
                      opacity: opacity,
                      child: Container(
                        width: p.size,
                        height: p.size,
                        decoration: BoxDecoration(
                          color: widget.color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: widget.color.withValues(alpha: 0.5),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _Particle {
  final double angle;
  final double distance;
  final double size;
  final double speed;

  _Particle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.speed,
  });
}
