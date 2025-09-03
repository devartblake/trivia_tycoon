import 'dart:async';
import 'dart:developer';
import 'package:flutter/widgets.dart';

import '../../../core/manager/log_manager.dart';

class ConfettiPerformance extends ChangeNotifier {
  static final ConfettiPerformance _instance = ConfettiPerformance._internal();
  factory ConfettiPerformance() => _instance;
  ConfettiPerformance._internal();

  int _frameCount = 0;
  double _fps = 60.0;
  double _memoryUsage = 0.0;
  Timer? _timer;

  void startTracking() {
    _frameCount = 0;
    _fps = 60.0;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer){
      _fps = _frameCount.toDouble();
      _memoryUsage = _getMemoryUsage();
      _frameCount = 0;
      notifyListeners();
    });
    _trackFrames();

    LogManager.log(
      "Confetti started animation at ${_fps}fps",
      level: LogLevel.performance,
      source: "Confetti",
    );
  }

  void _trackFrames() {
    WidgetsBinding.instance.addPostFrameCallback((_){
      _frameCount++;
      _trackFrames();
    });
  }

  double _getMemoryUsage() {
    // Simulate memory tracking (replace with real memory tracking logic.)
    log('Memory usage: ${DateTime.now().microsecond}');
    return DateTime.now().microsecond.toDouble();
  }

  void stopTracking() {
    _timer?.cancel();
  }

  double get fps => _fps;
  double get memoryUsage => _memoryUsage;

  String getPerformanceCategory() {
    if (_fps >= 50) return 'High';
    if (_fps >= 30) return 'Medium';
    return 'Low';
  }

  @override
  void dispose() {
    stopTracking();
    super.dispose();
  }
}