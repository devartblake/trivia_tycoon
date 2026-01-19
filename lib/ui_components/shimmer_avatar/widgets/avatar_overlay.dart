import 'package:flutter/material.dart';

/// Avatar overlay widget for additional content
class AvatarOverlay extends StatelessWidget {
  final Widget? overlayWidget;
  final double opacity;

  const AvatarOverlay({
    super.key,
    this.overlayWidget,
    this.opacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    if (overlayWidget == null) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withOpacity(opacity),
        ),
        child: Center(child: overlayWidget),
      ),
    );
  }
}
