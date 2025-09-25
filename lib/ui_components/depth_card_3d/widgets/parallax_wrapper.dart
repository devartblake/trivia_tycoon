import 'package:flutter/material.dart';
import '../utils/parallax_utils.dart';

class ParallaxWrapperBuilder extends StatelessWidget {
  final double depth;
  final Widget Function(BuildContext context, Offset tilt) builder;

  const ParallaxWrapperBuilder({
    super.key,
    required this.builder,
    this.depth = 5.0,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerHover: (e) => ParallaxUtils.updatePointer(e.position),
      onPointerMove: (e) => ParallaxUtils.updatePointer(e.position),
      onPointerDown: (e) => ParallaxUtils.updatePointer(e.position),
      onPointerUp: (_) => ParallaxUtils.reset(),
      child: ValueListenableBuilder<Offset>(
        valueListenable: ParallaxUtils.notifier,
        builder: (context, offset, _) {
          return TweenAnimationBuilder<Offset>(
            tween: Tween<Offset>(
              begin: Offset.zero,
              end: offset * depth,
            ),
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            builder: (context, animatedOffset, __) {
              // Provide tilt to the builder AND apply the transform here
              final m = Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateX(animatedOffset.dy)
                ..rotateY(-animatedOffset.dx);

              return Transform(
                alignment: Alignment.center,
                transform: m,
                child: builder(context, animatedOffset),
              );
            },
          );
        },
      ),
    );
  }
}
