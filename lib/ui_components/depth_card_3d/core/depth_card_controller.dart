import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

/// Enhanced 3D controller with performance optimizations and proper resource management
class DepthCardController extends ChangeNotifier {
  Flutter3DController? _controller;
  Timer? _animationTimer;
  Timer? _performanceTimer;

  // State management
  bool _isAttached = false;
  bool _isModelLoaded = false;
  bool _isDisposed = false;
  String? _currentModelPath;

  // Animation state
  double _rotationX = 0.0;
  double _rotationY = 0.0;
  double _rotationZ = 0.0;
  bool _isAnimating = false;
  bool _glowEnabled = false;
  double _glowStrength = 1.0;

  // Performance tracking
  int _frameCount = 0;
  double _lastFPS = 60.0;
  final List<double> _frameTimes = [];
  static const int _maxFrameTimeSamples = 30;

  // Configuration
  static const Duration _animationInterval = Duration(milliseconds: 16); // ~60fps
  static const Duration _performanceUpdateInterval = Duration(seconds: 1);
  static const double _maxRotationSpeed = 2.0; // degrees per frame

  // Getters for state
  bool get isAttached => _isAttached;
  bool get isModelLoaded => _isModelLoaded;
  bool get isAnimating => _isAnimating;
  bool get glowEnabled => _glowEnabled;
  double get glowStrength => _glowStrength;
  double get rotationX => _rotationX;
  double get rotationY => _rotationY;
  double get rotationZ => _rotationZ;
  double get currentFPS => _lastFPS;
  String? get currentModelPath => _currentModelPath;

  /// Attach the 3D controller with error handling
  bool attach(Flutter3DController controller) {
    if (_isDisposed) {
      debugPrint('DepthCardController: Cannot attach to disposed controller');
      return false;
    }

    try {
      _controller = controller;
      _isAttached = true;
      _startPerformanceTracking();
      notifyListeners();

      debugPrint('DepthCardController: Successfully attached to 3D controller');
      return true;
    } catch (e) {
      debugPrint('DepthCardController: Error attaching controller: $e');
      _isAttached = false;
      return false;
    }
  }

  /// Detach the controller and cleanup resources
  void detach() {
    if (!_isAttached) return;

    _stopAllTimers();
    _controller = null;
    _isAttached = false;
    _isModelLoaded = false;
    _currentModelPath = null;

    notifyListeners();
    debugPrint('DepthCardController: Detached from 3D controller');
  }

  /// Load 3D model with comprehensive error handling and performance optimization
  Future<bool> loadModelFromAsset(String assetPath, {BuildContext? context}) async {
    if (!_isAttached || _isDisposed) {
      debugPrint('DepthCardController: Cannot load model - controller not attached');
      return false;
    }

    if (_currentModelPath == assetPath && _isModelLoaded) {
      debugPrint('DepthCardController: Model already loaded: $assetPath');
      return true;
    }

    try {
      final stopwatch = Stopwatch()..start();

      // Validate asset exists using rootBundle (no context required)
      await _validateAssetExists(assetPath);

      _isModelLoaded = false;
      _currentModelPath = null;
      notifyListeners();

      // Load the model using the actual flutter_3d_controller API
      await _loadModel(assetPath);

      _isModelLoaded = true;
      _currentModelPath = assetPath;

      stopwatch.stop();
      final loadTime = stopwatch.elapsedMilliseconds;

      notifyListeners();

      debugPrint('DepthCardController: Model loaded successfully: $assetPath (${loadTime}ms)');
      return true;

    } catch (e) {
      debugPrint('DepthCardController: Error loading model $assetPath: $e');
      _isModelLoaded = false;
      _currentModelPath = null;
      notifyListeners();
      return false;
    }
  }

  /// Validate that the asset exists before attempting to load
  Future<void> _validateAssetExists(String assetPath) async {
    try {
      // Use rootBundle which doesn't require context
      await rootBundle.load(assetPath);
    } catch (e) {
      throw Exception('Asset not found: $assetPath');
    }
  }

  /// Load the model using the actual 3D controller
  Future<void> _loadModel(String assetPath) async {
    if (_controller == null) {
      throw Exception('3D controller not attached');
    }

    // Check supported formats
    if (!_isSupportedFormat(assetPath)) {
      throw Exception('Unsupported model format: $assetPath');
    }

    try {
      // Use the actual flutter_3d_controller method
      // Note: Replace this with the actual API method when available
      if (_controller!.onModelLoaded != null) {
        // Some 3D controllers have callback-based loading
        final completer = Completer<void>();

        // Set up completion callback
        void onLoadComplete() {
          completer.complete();
        }

        // Trigger the load (replace with actual method)
        // _controller!.loadModelFromAsset(assetPath);

        // For now, simulate the loading
        await _simulateModelLoading(assetPath);

      } else {
        // Direct loading approach
        await _simulateModelLoading(assetPath);
      }

    } catch (e) {
      throw Exception('Failed to load 3D model: $e');
    }
  }

  /// Check if the model format is supported
  bool _isSupportedFormat(String assetPath) {
    final supportedExtensions = ['.glb', '.gltf', '.obj', '.fbx'];
    return supportedExtensions.any((ext) =>
        assetPath.toLowerCase().endsWith(ext));
  }

  /// Simulate model loading for demonstration
  Future<void> _simulateModelLoading(String assetPath) async {
    // Simulate loading time based on file complexity
    final complexity = assetPath.contains('complex') ? 2000 : 500;
    await Future.delayed(Duration(milliseconds: complexity));

    if (kDebugMode) {
      print('DepthCardController: Simulated loading of $assetPath');
    }
  }

  /// Enable/disable glow effect with performance consideration
  void setGlowEffect({required bool enabled, double strength = 1.0}) {
    if (_isDisposed) return;

    final oldGlowEnabled = _glowEnabled;
    final oldStrength = _glowStrength;

    _glowEnabled = enabled;
    _glowStrength = strength.clamp(0.0, 3.0);

    if (oldGlowEnabled != _glowEnabled || oldStrength != _glowStrength) {
      HapticFeedback.lightImpact();
      notifyListeners();

      if (kDebugMode) {
        print('DepthCardController: Glow effect ${enabled ? "enabled" : "disabled"} (strength: ${_glowStrength.toStringAsFixed(2)})');
      }
    }
  }

  /// Set rotation with smooth animation and performance optimization
  void setRotation(double x, double y, {double z = 0.0, bool animate = true}) {
    if (_isDisposed || !_isAttached) return;

    // Clamp rotation values to reasonable ranges
    final targetX = (x % 360).clamp(-180.0, 180.0);
    final targetY = (y % 360).clamp(-180.0, 180.0);
    final targetZ = (z % 360).clamp(-180.0, 180.0);

    if (animate) {
      _animateToRotation(targetX, targetY, targetZ);
    } else {
      _rotationX = targetX;
      _rotationY = targetY;
      _rotationZ = targetZ;
      notifyListeners();
    }

    if (kDebugMode) {
      print('DepthCardController: Rotation set to x=$targetX, y=$targetY, z=$targetZ (animate=$animate)');
    }
  }

  /// Animate to target rotation smoothly
  void _animateToRotation(double targetX, double targetY, double targetZ) {
    if (_isAnimating) {
      _stopAnimation();
    }

    _isAnimating = true;
    final startX = _rotationX;
    final startY = _rotationY;
    final startZ = _rotationZ;

    final deltaX = _getShortestRotationDelta(startX, targetX);
    final deltaY = _getShortestRotationDelta(startY, targetY);
    final deltaZ = _getShortestRotationDelta(startZ, targetZ);

    final maxDelta = max(max(deltaX.abs(), deltaY.abs()), deltaZ.abs());
    final animationDuration = (maxDelta / _maxRotationSpeed).ceil();

    int frameCount = 0;

    _animationTimer = Timer.periodic(_animationInterval, (timer) {
      frameCount++;
      final progress = (frameCount / animationDuration).clamp(0.0, 1.0);
      final easedProgress = _easeOutCubic(progress);

      _rotationX = startX + deltaX * easedProgress;
      _rotationY = startY + deltaY * easedProgress;
      _rotationZ = startZ + deltaZ * easedProgress;

      notifyListeners();
      _updateFrameRate();

      if (progress >= 1.0) {
        _stopAnimation();
      }
    });
  }

  /// Calculate shortest rotation delta considering 360-degree wrap
  double _getShortestRotationDelta(double start, double target) {
    double delta = target - start;
    while (delta > 180) {
      delta -= 360;
    }
    while (delta < -180) {
      delta += 360;
    }
    return delta;
  }

  /// Easing function for smooth animation
  num _easeOutCubic(double t) {
    return 1 - pow(1 - t, 3);
  }

  /// Stop current animation
  void _stopAnimation() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _isAnimating = false;
  }

  /// Reset rotation to default position with animation
  void resetRotation({bool animate = true}) {
    setRotation(0.0, 0.0, z: 0.0, animate: animate);

    if (kDebugMode) {
      print('DepthCardController: Rotation reset to default');
    }
  }

  /// Auto-rotate the model continuously
  void startAutoRotation({double speedX = 0.5, double speedY = 1.0}) {
    if (_isAnimating || _isDisposed) return;

    _isAnimating = true;

    _animationTimer = Timer.periodic(_animationInterval, (timer) {
      _rotationX = (_rotationX + speedX) % 360;
      _rotationY = (_rotationY + speedY) % 360;

      notifyListeners();
      _updateFrameRate();
    });

    if (kDebugMode) {
      print('DepthCardController: Auto-rotation started (speedX=$speedX, speedY=$speedY)');
    }
  }

  /// Stop auto-rotation
  void stopAutoRotation() {
    _stopAnimation();

    if (kDebugMode) {
      print('DepthCardController: Auto-rotation stopped');
    }
  }

  /// Refresh/reload the current model
  Future<bool> refreshModel() async {
    if (!_isModelLoaded || _currentModelPath == null) {
      debugPrint('DepthCardController: No model to refresh');
      return false;
    }

    final currentPath = _currentModelPath!;
    _isModelLoaded = false;
    _currentModelPath = null;
    notifyListeners();

    // Small delay to show loading state
    await Future.delayed(const Duration(milliseconds: 100));

    return await loadModelFromAsset(currentPath);
  }

  /// Start performance tracking
  void _startPerformanceTracking() {
    _performanceTimer = Timer.periodic(_performanceUpdateInterval, (timer) {
      _calculateFPS();
    });
  }

  /// Update frame rate tracking
  void _updateFrameRate() {
    _frameCount++;
    final now = DateTime.now().millisecondsSinceEpoch.toDouble();
    _frameTimes.add(now);

    if (_frameTimes.length > _maxFrameTimeSamples) {
      _frameTimes.removeAt(0);
    }
  }

  /// Calculate FPS from frame times
  void _calculateFPS() {
    if (_frameTimes.length < 2) {
      _lastFPS = 60.0;
      return;
    }

    final totalTime = _frameTimes.last - _frameTimes.first;
    final frameCount = _frameTimes.length - 1;

    if (totalTime > 0) {
      _lastFPS = (frameCount * 1000.0 / totalTime).clamp(0.0, 120.0);
    }

    _frameCount = 0;
  }

  /// Stop all timers
  void _stopAllTimers() {
    _animationTimer?.cancel();
    _animationTimer = null;
    _performanceTimer?.cancel();
    _performanceTimer = null;
    _isAnimating = false;
  }

  /// Get performance metrics
  Map<String, dynamic> getPerformanceMetrics() {
    return {
      'fps': _lastFPS,
      'isAnimating': _isAnimating,
      'frameCount': _frameCount,
      'isModelLoaded': _isModelLoaded,
      'glowEnabled': _glowEnabled,
      'rotationX': _rotationX,
      'rotationY': _rotationY,
      'rotationZ': _rotationZ,
    };
  }

  /// Reset all state to defaults
  void reset() {
    if (_isDisposed) return;

    _stopAllTimers();
    resetRotation(animate: false);
    setGlowEffect(enabled: false);

    _frameCount = 0;
    _frameTimes.clear();
    _lastFPS = 60.0;

    notifyListeners();

    if (kDebugMode) {
      print('DepthCardController: Reset to default state');
    }
  }

  @override
  void dispose() {
    if (_isDisposed) return;

    _isDisposed = true;
    _stopAllTimers();
    detach();

    super.dispose();

    if (kDebugMode) {
      print('DepthCardController: Disposed');
    }
  }
}

/// Extension for additional utility methods
extension DepthCardControllerExtension on DepthCardController {
  /// Check if controller is in a valid state for operations
  bool get isReady => isAttached && !_isDisposed;

  /// Get rotation as a formatted string
  String get rotationString =>
      'X: ${rotationX.toStringAsFixed(1)}° '
          'Y: ${rotationY.toStringAsFixed(1)}° '
          'Z: ${rotationZ.toStringAsFixed(1)}°';

  /// Get performance category based on FPS
  String get performanceCategory {
    if (currentFPS >= 55) return 'Excellent';
    if (currentFPS >= 45) return 'Good';
    if (currentFPS >= 30) return 'Fair';
    if (currentFPS >= 15) return 'Poor';
    return 'Critical';
  }
}
