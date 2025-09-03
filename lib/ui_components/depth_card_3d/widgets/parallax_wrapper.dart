import 'package:flutter/material.dart';
import '../utils/parallax_utils.dart';

class ParallaxWrapper extends StatelessWidget {
  final Widget child;
  final double depth;

  const ParallaxWrapper({
    super.key,
    required this.child,
    this.depth = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerMove: (event) {
        ParallaxUtils.updatePointer(event.position);
      },
      onPointerUp: (_) => ParallaxUtils.reset(),
      child: AnimatedBuilder(
        animation: ParallaxUtils.notifier,
        builder: (context, _) {
          final offset = ParallaxUtils.notifier.value * depth;
          return TweenAnimationBuilder(
            tween: Tween<Offset>(begin: Offset.zero, end: offset),
            duration: const Duration(milliseconds: 300),
            builder: (context, animatedOffset, child) {
              return Transform(
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(animatedOffset.dy)
                  ..rotateY(-animatedOffset.dx),
                alignment: Alignment.center,
                child: child,
              );
            },
            child: child,
          );
        },
      ),
    );
  }
}
