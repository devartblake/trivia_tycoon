import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../models/spin_system_models.dart';
import '../physics/spin_physics_handler.dart';
import '../physics/spin_velocity.dart';
import '../services/rewards/reward_probability.dart';
import '../ui/widgets/result_dialog.dart';
import '../services/spin_tracker.dart';
import '../services/prize_log_provider.dart';

/// Enhanced spinning controller with modern architecture and performance optimizations
final spinningControllerProvider = ChangeNotifierProvider<EnhancedSpinningController>((ref) {
  return EnhancedSpinningController(ref);
});

/// State model for spinning controller
@immutable
class SpinningState {
  final bool isSpinning;
  final bool isPaused;
  final WheelSegment? lastResult;
  final int totalSpins;
  final DateTime? lastSpinTime;
  final Map<String, int> rewardStats;
  final SpinResult? currentSpinResult;
  final double currentAngle;

  const SpinningState({
    this.isSpinning = false,
    this.isPaused = false,
    this.lastResult,
    this.totalSpins = 0,
    this.lastSpinTime,
    this.rewardStats = const {},
    this.currentSpinResult,
    this.currentAngle = 0.0,
  });

  SpinningState copyWith({
    bool? isSpinning,
    bool? isPaused,
    WheelSegment? lastResult,
    int? totalSpins,
    DateTime? lastSpinTime,
    Map<String, int>? rewardStats,
    SpinResult? currentSpinResult,
    double? currentAngle,
  }) {
    return SpinningState(
      isSpinning: isSpinning ?? this.isSpinning,
      isPaused: isPaused ?? this.isPaused,
      lastResult: lastResult ?? this.lastResult,
      totalSpins: totalSpins ?? this.totalSpins,
      lastSpinTime: lastSpinTime ?? this.lastSpinTime,
      rewardStats: rewardStats ?? this.rewardStats,
      currentSpinResult: currentSpinResult ?? this.currentSpinResult,
      currentAngle: currentAngle ?? this.currentAngle,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isSpinning': isSpinning,
      'isPaused': isPaused,
      'lastResult': lastResult?.toJson(),
      'totalSpins': totalSpins,
      'lastSpinTime': lastSpinTime?.toIso8601String(),
      'rewardStats': rewardStats,
      'currentSpinResult': currentSpinResult?.toJson(),
      'currentAngle': currentAngle,
    };
  }

  factory SpinningState.fromJson(Map<String, dynamic> json) {
    return SpinningState(
      isSpinning: json['isSpinning'] ?? false,
      isPaused: json['isPaused'] ?? false,
      lastResult: json['lastResult'] != null
          ? WheelSegment.fromJson(json['lastResult'])
          : null,
      totalSpins: json['totalSpins'] ?? 0,
      lastSpinTime: json['lastSpinTime'] != null
          ? DateTime.parse(json['lastSpinTime'])
          : null,
      rewardStats: Map<String, int>.from(json['rewardStats'] ?? {}),
      currentSpinResult: json['currentSpinResult'] != null
          ? SpinResult.fromJson(json['currentSpinResult'])
          : null,
      currentAngle: (json['currentAngle'] ?? 0.0).toDouble(),
    );
  }
}

class EnhancedSpinningController extends ChangeNotifier {
  final Ref ref;

  // Enhanced physics system
  late final EnhancedSpinPhysics _physics;
  late final EnhancedSpinVelocity _velocityCalculator;
  late final EnhancedSpinHandler _spinHandler;

  // State management
  SpinningState _state = const SpinningState();

  // Performance optimizations
  Timer? _autoSaveTimer;
  Timer? _validationTimer;
  final StreamController<SpinResult> _spinResultController = StreamController.broadcast();

  // Cached values
  static const String _stateKey = 'enhanced_spinning_state';
  static const Duration _autoSaveInterval = Duration(seconds: 30);
  static const Duration _validationInterval = Duration(minutes: 5);

  EnhancedSpinningController(this.ref) {
    _initializePhysics();
    _loadState();
    _startPeriodicTasks();
  }

  // Getters for state
  SpinningState get state => _state;
  bool get isSpinning => _state.isSpinning;
  bool get isPaused => _state.isPaused;
  WheelSegment? get lastResult => _state.lastResult;
  int get totalSpins => _state.totalSpins;
  DateTime? get lastSpinTime => _state.lastSpinTime;
  Map<String, int> get rewardStats => Map.unmodifiable(_state.rewardStats);
  double get currentAngle => _state.currentAngle;

  // Stream for listening to spin results
  Stream<SpinResult> get spinResults => _spinResultController.stream;

  void _initializePhysics() {
    _physics = const EnhancedSpinPhysics(
      resistance: 0.015,
      minVelocity: 3.0,
      maxVelocity: 15.0,
      enableRealism: true,
    );

    _velocityCalculator = const EnhancedSpinVelocity(
      width: 400,
      height: 400,
      sensitivityMultiplier: 1.0,
      enableGestureOptimization: true,
    );

    _spinHandler = EnhancedSpinHandler(
      physics: _physics,
      velocityCalculator: _velocityCalculator,
      enableHaptics: true,
      enableSoundEffects: true,
    );
  }

  void _startPeriodicTasks() {
    // Auto-save state periodically
    _autoSaveTimer = Timer.periodic(_autoSaveInterval, (_) => _saveState());

    // Validate state periodically
    _validationTimer = Timer.periodic(_validationInterval, (_) => _validateState());
  }

  /// Enhanced state update with performance optimization
  void _updateState(SpinningState newState) {
    if (_state == newState) return; // Avoid unnecessary updates

    _state = newState;
    notifyListeners();
  }

  /// Load state with error handling and validation
  Future<void> _loadState() async {
    try {
      final stateJson = await AppSettings.getString(_stateKey);
      if (stateJson != null && stateJson.isNotEmpty) {
        final decodedState = jsonDecode(stateJson);
        final loadedState = SpinningState.fromJson(decodedState);

        // Validate loaded state
        final validatedState = _validateLoadedState(loadedState);
        _updateState(validatedState);
      }
    } catch (e) {
      debugPrint('Failed to load spinning state: $e');
      await _resetState();
    }
  }

  /// Validate loaded state for integrity
  SpinningState _validateLoadedState(SpinningState state) {
    // Reset spinning flag if loaded as true (app was closed during spin)
    final isSpinning = false;

    // Validate total spins
    final totalSpins = math.max(0, state.totalSpins);

    // Validate angle
    final currentAngle = state.currentAngle.isFinite ? state.currentAngle : 0.0;

    // Clean reward stats
    final cleanStats = Map<String, int>.from(state.rewardStats);
    cleanStats.removeWhere((key, value) => value < 0 || key.isEmpty);

    return state.copyWith(
      isSpinning: isSpinning,
      totalSpins: totalSpins,
      currentAngle: currentAngle,
      rewardStats: cleanStats,
    );
  }

  /// Save state with error handling
  Future<void> _saveState() async {
    try {
      final stateJson = jsonEncode(_state.toJson());
      await AppSettings.setString(_stateKey, stateJson);
    } catch (e) {
      debugPrint('Failed to save spinning state: $e');
    }
  }

  /// Periodic state validation
  Future<void> _validateState() async {
    try {
      bool needsUpdate = false;
      var currentState = _state;

      // Reset spinning if stuck
      if (currentState.isSpinning && currentState.lastSpinTime != null) {
        final timeSinceLastSpin = DateTime.now().difference(currentState.lastSpinTime!);
        if (timeSinceLastSpin.inMinutes > 5) {
          currentState = currentState.copyWith(isSpinning: false);
          needsUpdate = true;
        }
      }

      // Clean old stats (older than 30 days)
      if (currentState.lastSpinTime != null) {
        final daysSinceLastSpin = DateTime.now().difference(currentState.lastSpinTime!).inDays;
        if (daysSinceLastSpin > 30) {
          currentState = currentState.copyWith(rewardStats: {});
          needsUpdate = true;
        }
      }

      if (needsUpdate) {
        _updateState(currentState);
        await _saveState();
      }
    } catch (e) {
      debugPrint('State validation failed: $e');
    }
  }

  /// Enhanced spin method with physics integration
  Future<SpinResult?> spin({
    required List<WheelSegment> segments,
    required BuildContext context,
    required TickerProvider vsync,
    double? customVelocity,
    Offset? gestureStart,
    Offset? gestureVelocity,
    Duration? gestureDuration,
  }) async {
    if (_state.isSpinning || _state.isPaused || segments.isEmpty) return null;

    // Check if can spin
    if (!await SpinTracker.canSpin()) {
      _showCooldownMessage(context);
      return null;
    }

    // Start spinning
    _updateState(_state.copyWith(isSpinning: true));

    try {
      // Use enhanced physics directly instead of the handler
      final velocity = customVelocity ?? _velocityCalculator.generateRandomVelocity();

      // Calculate physics
      final duration = _physics.calculateDuration(velocity);
      final distance = _physics.calculateDistance(velocity, duration);

      // Create spin result
      final spinResult = _physics.calculateSpinResult(
        initialVelocity: velocity,
        initialAngle: _state.currentAngle,
        segments: segments,
        spinId: DateTime.now().millisecondsSinceEpoch.toString(),
      );

      // Simulate spin duration
      await Future.delayed(Duration(milliseconds: (duration * 1000).round()));

      // Handle completion
      await _handleSpinComplete(spinResult, context);

      return spinResult;
    } catch (e) {
      debugPrint('Spin failed: $e');
      _updateState(_state.copyWith(isSpinning: false));
      _showErrorMessage(context, 'Spin failed. Please try again.');
      return null;
    }
  }

  /// Handle spin completion with enhanced logic
  Future<void> _handleSpinComplete(SpinResult result, BuildContext context) async {
    try {
      // Calculate enhanced reward
      final enhancedResult = await _calculateEnhancedReward(result);

      // Update state
      final updatedStats = Map<String, int>.from(_state.rewardStats);
      updatedStats[result.rewardType ?? 'unknown'] =
          (updatedStats[result.rewardType ?? 'unknown'] ?? 0) + 1;

      _updateState(_state.copyWith(
        isSpinning: false,
        lastResult: _getSegmentFromResult(enhancedResult),
        totalSpins: _state.totalSpins + 1,
        lastSpinTime: DateTime.now(),
        rewardStats: updatedStats,
        currentSpinResult: enhancedResult,
      ));

      // Process rewards
      await _processReward(enhancedResult);

      // Save state
      await _saveState();

      // Add to spin results stream
      _spinResultController.add(enhancedResult);

      // Show result dialog
      if (context.mounted) {
        _showResultDialog(context, enhancedResult);
      }

    } catch (e) {
      debugPrint('Failed to handle spin completion: $e');
      _updateState(_state.copyWith(isSpinning: false));
    }
  }

  /// Calculate enhanced reward with quality bonuses
  Future<SpinResult> _calculateEnhancedReward(SpinResult baseResult) async {
    try {
      // Use the enhanced reward service
      final rewardService = EnhancedRewardService(
        config: RewardConfig.balanced(),
      );

      final rewardResult = await rewardService.generateReward();

      // Apply quality multiplier if available from base result
      final qualityMultiplier = baseResult.metadata?['qualityMultiplier'] ?? 1.0;
      final enhancedReward = (rewardResult.segment.reward * qualityMultiplier).round();

      // Create enhanced spin result combining both results
      return baseResult.copyWith(
        label: rewardResult.segment.label,
        imagePath: rewardResult.segment.imagePath,
        reward: enhancedReward,
        rewardType: rewardResult.segment.rewardType,
        metadata: {
          ...?baseResult.metadata,
          'originalReward': baseResult.reward,
          'qualityMultiplier': qualityMultiplier,
          'rewardType': rewardResult.rewardType.name,
          'probabilities': rewardResult.probabilities.toMap(),
        },
        isJackpot: rewardResult.rewardType == RewardType.jackpot,
        isRare: [RewardType.rare, RewardType.jackpot].contains(rewardResult.rewardType),
      );
    } catch (e) {
      debugPrint('Failed to calculate enhanced reward: $e');
      return baseResult;
    }
  }

  /// Process reward distribution
  Future<void> _processReward(SpinResult result) async {
    try {
      // Add to prize log
      final prizeEntry = result.toPrizeEntry();
      ref.read(prizeLogProvider.notifier).addEntry(prizeEntry);

      // Update coin balance
      if (['coins', 'currency'].contains(result.rewardType?.toLowerCase())) {
        ref.read(coinNotifierProvider).addValue(result.reward);
      }

      // Handle other reward types
      switch (result.rewardType?.toLowerCase()) {
        case 'gems':
        case 'premium':
        // Handle premium currency
          final currentGems = await AppSettings.getInt('gems') ?? 0;
          await AppSettings.setInt('gems', currentGems + result.reward);
          break;
        case 'lives':
        case 'health':
        // Handle lives/health
          final currentLives = await AppSettings.getInt('lives') ?? 3;
          await AppSettings.setInt('lives', math.min(currentLives + result.reward, 10));
          break;
      }

      // Trigger celebration effects
      if (result.isPremium) {
        ref.read(confettiControllerProvider).play();
        HapticFeedback.heavyImpact();
      } else {
        HapticFeedback.lightImpact();
      }

    } catch (e) {
      debugPrint('Failed to process reward: $e');
    }
  }

  /// Convert SpinResult back to WheelSegment for compatibility
  WheelSegment _getSegmentFromResult(SpinResult result) {
    return WheelSegment(
      id: result.id,
      label: result.label,
      color: result.categoryColor,
      imagePath: result.imagePath,
      reward: result.reward,
      rewardType: result.rewardType ?? 'unknown',
    );
  }

  /// Show result dialog with enhanced UI
  void _showResultDialog(BuildContext context, SpinResult result) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResultDialog(
        result: result,
        onClaim: () async {
          // Additional claim logic if needed
        },
        onShare: () {
          // Share functionality
          _shareResult(result);
        },
      ),
    );
  }

  /// Share spin result
  void _shareResult(SpinResult result) {
    // Implement sharing logic
    final shareText = 'I just won ${result.label} with ${result.reward} coins!';
    // Use share_plus package or similar
  }

  /// Show cooldown message
  void _showCooldownMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.access_time, color: Colors.white),
            SizedBox(width: 8),
            Text('Please wait before spinning again'),
          ],
        ),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Show error message
  void _showErrorMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Pause spinning operations
  void pause() {
    _updateState(_state.copyWith(isPaused: true));
  }

  /// Resume spinning operations
  void resume() {
    _updateState(_state.copyWith(isPaused: false));
  }

  /// Check if can spin
  Future<bool> canSpin() async {
    if (_state.isPaused || _state.isSpinning) return false;
    return await SpinTracker.canSpin();
  }

  /// Get time until next spin
  Future<Duration?> getTimeUntilNextSpin() async {
    return await SpinTracker.timeLeft();
  }

  /// Get spinning statistics
  Map<String, dynamic> getSpinningStats() {
    return {
      'totalSpins': _state.totalSpins,
      'lastSpinTime': _state.lastSpinTime?.toIso8601String(),
      'rewardStats': _state.rewardStats,
      'isSpinning': _state.isSpinning,
      'isPaused': _state.isPaused,
      'lastResult': _state.lastResult?.label,
      'rewardDistribution': getRewardDistribution(),
    };
  }

  /// Get reward distribution percentages
  Map<String, double> getRewardDistribution() {
    if (_state.totalSpins == 0) return {};

    return _state.rewardStats.map((rewardType, count) =>
        MapEntry(rewardType, (count / _state.totalSpins) * 100));
  }

  /// Export data for backup
  Map<String, dynamic> exportData() {
    return {
      ..._state.toJson(),
      'exported': DateTime.now().toIso8601String(),
      'version': '2.0',
    };
  }

  /// Import data from backup
  Future<void> importData(Map<String, dynamic> data) async {
    try {
      final importedState = SpinningState.fromJson(data);
      final validatedState = _validateLoadedState(importedState);

      _updateState(validatedState);
      await _saveState();

      debugPrint('Data imported successfully');
    } catch (e) {
      debugPrint('Failed to import data: $e');
      throw Exception('Invalid data format');
    }
  }

  /// Reset all data
  Future<void> resetAllData() async {
    await _resetState();
  }

  /// Reset state to defaults
  Future<void> _resetState() async {
    _updateState(const SpinningState());
    await AppSettings.setString(_stateKey, '');
  }

  /// Update current angle (for animation tracking)
  void updateCurrentAngle(double angle) {
    _updateState(_state.copyWith(currentAngle: angle));
  }

  @override
  void dispose() {
    _autoSaveTimer?.cancel();
    _validationTimer?.cancel();
    _spinResultController.close();
    super.dispose();
  }
}

/// Provider for accessing spinning statistics
final spinningStatsProvider = Provider<Map<String, dynamic>>((ref) {
  final controller = ref.watch(spinningControllerProvider);
  return controller.getSpinningStats();
});

/// Provider for reward distribution
final rewardDistributionProvider = Provider<Map<String, double>>((ref) {
  final controller = ref.watch(spinningControllerProvider);
  return controller.getRewardDistribution();
});

/// Provider for checking if can spin
final canSpinProvider = FutureProvider<bool>((ref) async {
  final controller = ref.watch(spinningControllerProvider);
  return await controller.canSpin();
});