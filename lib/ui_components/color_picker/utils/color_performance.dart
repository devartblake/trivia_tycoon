import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';

class ColorPerformance {
  static final ColorPerformance _instance = ColorPerformance._internal();
  factory ColorPerformance() => _instance;
  ColorPerformance._internal();

  // Performance tracking
  final Queue<int> _frameTimes = Queue<int>();
  double _fps = 60.0;
  double _averageFps = 60.0;
  Timer? _timer;
  VoidCallback? _onPerformanceUpdated;
  bool _isTracking = false;

  // Memory and performance metrics
  int _droppedFrames = 0;
  int _totalFrames = 0;
  DateTime? _trackingStartTime;

  static const int _maxSamples = 60; // Keep last 60 frame times
  static const Duration _updateInterval = Duration(seconds: 1);
  static const int _targetFrameTime = 16; // 60fps = ~16ms per frame

  /// Start performance tracking with optional callback
  void startTracking({VoidCallback? onUpdated}) {
    if (_isTracking) {
      stopTracking(); // Stop previous tracking
    }

    _onPerformanceUpdated = onUpdated;
    _isTracking = true;
    _trackingStartTime = DateTime.now();
    _frameTimes.clear();
    _droppedFrames = 0;
    _totalFrames = 0;
    _fps = 60.0;
    _averageFps = 60.0;

    _timer = Timer.periodic(_updateInterval, _calculatePerformanceMetrics);

    // Use SchedulerBinding for more accurate frame timing
    SchedulerBinding.instance.addTimingsCallback(_onFrameTiming);
  }

  /// Handle frame timing data from Flutter's scheduler
  void _onFrameTiming(List<FrameTiming> timings) {
    if (!_isTracking) return;

    for (final timing in timings) {
      final frameTime = timing.totalSpan.inMilliseconds;
      _totalFrames++;

      // Track frame times for FPS calculation
      _frameTimes.add(frameTime);
      if (_frameTimes.length > _maxSamples) {
        _frameTimes.removeFirst();
      }

      // Count dropped frames (frames that took longer than target)
      if (frameTime > _targetFrameTime * 1.5) {
        _droppedFrames++;
      }
    }
  }

  /// Calculate performance metrics periodically
  void _calculatePerformanceMetrics(Timer timer) {
    if (!_isTracking || _frameTimes.isEmpty) return;

    // Calculate current FPS from recent frame times
    final recentFrames = _frameTimes.length;
    final totalTime = _frameTimes.reduce((a, b) => a + b);
    final avgFrameTime = totalTime / recentFrames;

    _fps = avgFrameTime > 0 ? 1000 / avgFrameTime : 60.0;
    _fps = _fps.clamp(0.0, 120.0); // Reasonable bounds

    // Calculate overall average FPS
    final trackingDuration = DateTime.now().difference(_trackingStartTime!);
    final totalSeconds = trackingDuration.inMilliseconds / 1000.0;
    _averageFps = totalSeconds > 0 ? _totalFrames / totalSeconds : 60.0;

    _onPerformanceUpdated?.call();
  }

  /// Stop performance tracking and cleanup
  void stopTracking() {
    if (!_isTracking) return;

    _isTracking = false;
    _timer?.cancel();
    _timer = null;
    _onPerformanceUpdated = null;

    SchedulerBinding.instance.removeTimingsCallback(_onFrameTiming);

    // Keep some data for final metrics
    if (kDebugMode) {
      _logFinalMetrics();
    }
  }

  /// Log final performance metrics for debugging
  void _logFinalMetrics() {
    if (_trackingStartTime == null) return;

    final duration = DateTime.now().difference(_trackingStartTime!);
    final dropRate = _totalFrames > 0 ? (_droppedFrames / _totalFrames) * 100 : 0.0;

    debugPrint('Color Picker Performance Summary:');
    debugPrint('  Duration: ${duration.inSeconds}s');
    debugPrint('  Total Frames: $_totalFrames');
    debugPrint('  Dropped Frames: $_droppedFrames (${dropRate.toStringAsFixed(1)}%)');
    debugPrint('  Average FPS: ${_averageFps.toStringAsFixed(1)}');
    debugPrint('  Final FPS: ${_fps.toStringAsFixed(1)}');
  }

  /// Get current FPS
  double getFPS() => _fps;

  /// Get average FPS since tracking started
  double getAverageFPS() => _averageFps;

  /// Get performance category based on FPS
  String getPerformanceCategory() {
    if (_fps >= 55) return 'Excellent';
    if (_fps >= 45) return 'Good';
    if (_fps >= 30) return 'Fair';
    if (_fps >= 15) return 'Poor';
    return 'Critical';
  }

  /// Get performance color for UI indication
  ColorPerformanceLevel getPerformanceLevel() {
    if (_fps >= 55) return ColorPerformanceLevel.excellent;
    if (_fps >= 45) return ColorPerformanceLevel.good;
    if (_fps >= 30) return ColorPerformanceLevel.fair;
    if (_fps >= 15) return ColorPerformanceLevel.poor;
    return ColorPerformanceLevel.critical;
  }

  /// Get dropped frame percentage
  double getDroppedFrameRate() {
    return _totalFrames > 0 ? (_droppedFrames / _totalFrames) * 100 : 0.0;
  }

  /// Check if performance is acceptable
  bool isPerformanceAcceptable() => _fps >= 30;

  /// Get detailed performance metrics
  ColorPerformanceMetrics getDetailedMetrics() {
    return ColorPerformanceMetrics(
      currentFps: _fps,
      averageFps: _averageFps,
      droppedFrames: _droppedFrames,
      totalFrames: _totalFrames,
      droppedFrameRate: getDroppedFrameRate(),
      performanceLevel: getPerformanceLevel(),
      isTracking: _isTracking,
    );
  }

  /// Reset all metrics
  void reset() {
    _frameTimes.clear();
    _droppedFrames = 0;
    _totalFrames = 0;
    _fps = 60.0;
    _averageFps = 60.0;
    _trackingStartTime = null;
  }
}

/// Performance level enumeration
enum ColorPerformanceLevel {
  excellent,
  good,
  fair,
  poor,
  critical;

  /// Get color representation for UI
  Color get color {
    switch (this) {
      case ColorPerformanceLevel.excellent:
        return const Color(0xFF4CAF50); // Green
      case ColorPerformanceLevel.good:
        return const Color(0xFF8BC34A); // Light Green
      case ColorPerformanceLevel.fair:
        return const Color(0xFFFF9800); // Orange
      case ColorPerformanceLevel.poor:
        return const Color(0xFFFF5722); // Deep Orange
      case ColorPerformanceLevel.critical:
        return const Color(0xFFF44336); // Red
    }
  }

  /// Get icon representation for UI
  IconData get icon {
    switch (this) {
      case ColorPerformanceLevel.excellent:
        return Icons.speed_rounded;
      case ColorPerformanceLevel.good:
        return Icons.trending_up_rounded;
      case ColorPerformanceLevel.fair:
        return Icons.timeline_rounded;
      case ColorPerformanceLevel.poor:
        return Icons.warning_rounded;
      case ColorPerformanceLevel.critical:
        return Icons.error_rounded;
    }
  }
}

/// Detailed performance metrics data class
@immutable
class ColorPerformanceMetrics {
  final double currentFps;
  final double averageFps;
  final int droppedFrames;
  final int totalFrames;
  final double droppedFrameRate;
  final ColorPerformanceLevel performanceLevel;
  final bool isTracking;

  const ColorPerformanceMetrics({
    required this.currentFps,
    required this.averageFps,
    required this.droppedFrames,
    required this.totalFrames,
    required this.droppedFrameRate,
    required this.performanceLevel,
    required this.isTracking,
  });

  @override
  String toString() {
    return 'ColorPerformanceMetrics('
        'currentFps: ${currentFps.toStringAsFixed(1)}, '
        'averageFps: ${averageFps.toStringAsFixed(1)}, '
        'droppedFrames: $droppedFrames/$totalFrames '
        '(${droppedFrameRate.toStringAsFixed(1)}%), '
        'level: ${performanceLevel.name})';
  }
}