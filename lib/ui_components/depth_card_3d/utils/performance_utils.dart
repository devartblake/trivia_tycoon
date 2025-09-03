import 'package:flutter_3d_controller/flutter_3d_controller.dart';

class PerformanceUtils {
  /// Dispose the 3D controller safely
  static void disposeController(Flutter3DController controller) {
    // No dispose method currently available.
    // You can manually null the controller elsewhere if needed.
  }

  /// Optional: throttle redraws or animations
  static void throttleFrameRate({int fps = 30}) {
    final frameInterval = Duration(milliseconds: (1000 / fps).round());
    Future.doWhile(() async {
      await Future.delayed(frameInterval);
      return false; // Replace with true for repeating frame logic
    });
  }
}
