import 'dart:async';
import 'package:flutter/widgets.dart';

class ColorPerformance {
  static final ColorPerformance _instance = ColorPerformance._internal();
  factory ColorPerformance() => _instance;
  ColorPerformance._internal();

  int _frameCount = 0;
  double _fps = 60.0;
  Timer? _timer;
  VoidCallback? onPerformanceUpdated;

  void startTracking({VoidCallback? onUpdated}) {
    onPerformanceUpdated = onUpdated;
    _frameCount = 0;
    _fps = 60.0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _fps = _frameCount.toDouble();
      _frameCount = 0;
      onPerformanceUpdated?.call(); // Notify UI when FPS changes.
    });
    _trackFrames();
  }

  void _trackFrames() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _frameCount++;
      _trackFrames();
    });
  }

  void stopTracking() {
    _timer?.cancel();
  }

  double getFPS() => _fps;

  String getPerformanceCategory() {
    if (_fps >= 50) return 'High';
    if (_fps >= 30) return 'Medium';
    return 'Low';
  }
}
