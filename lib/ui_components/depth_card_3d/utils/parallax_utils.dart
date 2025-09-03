import 'package:flutter/material.dart';

class ParallaxUtils {
  static final ValueNotifier<Offset> notifier = ValueNotifier(Offset.zero);

  /// Update pointer position and normalize it relative to screen size
  static void updatePointer(Offset globalPosition) {
    final size = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize;
    final normalized = Offset(
      (globalPosition.dx / size.width - 0.5) * 2,
      (globalPosition.dy / size.height - 0.5) * 2,
    );

    notifier.value = normalized;
  }

  /// Optional reset method
  static void reset() {
    notifier.value = Offset.zero;
  }
}
