import 'package:flutter_3d_controller/flutter_3d_controller.dart';

/// Adds a `dispose()` method to Flutter3DController so widgets can
/// clean up consistently.
///
/// flutter_3d_controller (v2.3.0) does not provide a dispose method.
/// We at least:
/// - stop rotation (and reset state)
/// - stop animation
/// - dispose the internal onModelLoaded ValueNotifier
extension Flutter3DControllerDisposeX on Flutter3DController {
  void dispose() {
    // These calls are safe even if nothing is running.
    try {
      stopRotation();
    } catch (_) {}

    try {
      stopAnimation();
    } catch (_) {}

    // onModelLoaded is a ValueNotifier<bool>. Disposing it prevents leaks.
    try {
      onModelLoaded.dispose();
    } catch (_) {}
  }
}
