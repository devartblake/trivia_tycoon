import 'package:flutter/widgets.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class PerformanceUtils {
  /// Dispose a controller safely, if the plugin/controller supports it.
  /// Keep this for backward compatibility with older DepthCard versions.
  static void disposeController(Flutter3DController controller) {
    // Intentionally defensive: some 3D controllers don't expose dispose.
    // If you later add an extension, this remains safe.
    try {
      // ignore: invalid_use_of_protected_member
      final dynamic dyn = controller;
      dyn.dispose?.call();
    } catch (_) {}
  }

  /// Basic frame throttling placeholder.
  /// Keep this API stable even if implementation evolves.
  static void throttleFrameRate({int fps = 30}) {
    // No-op for now; can be implemented via TickerMode, SchedulerBinding, etc.
  }

  /// Wrap [child] with a [RepaintBoundary] to prevent unrelated widgets from
  /// repainting when this subtree animates (parallax, overlay glows, 3D viewer).
  ///
  /// This name is used by your current DepthCard3D implementation.
  static Widget rebuildBoundary({
    required Widget child,
    bool enabled = true,
  }) {
    if (!enabled) return child;
    return RepaintBoundary(child: child);
  }
}
