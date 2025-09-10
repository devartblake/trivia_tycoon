import 'package:flutter/material.dart';

class HexInteractive extends StatelessWidget {
  final Widget child;
  final double minScale;
  final double maxScale;
  final EdgeInsets boundaryMargin;
  const HexInteractive({
    super.key,
    required this.child,
    this.minScale = 0.5,
    this.maxScale = 2.5,
    this.boundaryMargin = const EdgeInsets.all(512),
  });
  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: minScale,
      maxScale: maxScale,
      boundaryMargin: boundaryMargin,
      child: child,
    );
  }
}
