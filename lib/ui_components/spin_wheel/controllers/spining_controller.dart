import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../models/prize_entry.dart';
import '../models/wheel_segment.dart';
import '../models/spin_result.dart';
import '../ui/widgets/result_dialog.dart';
import '../services/spin_tracker.dart';
import '../services/prize_log_provider.dart';
import '../services/rewards/reward_probability.dart';

final spinningControllerProvider = ChangeNotifierProvider<SpinningController>((ref) {
  return SpinningController(ref);
});

class SpinningController extends ChangeNotifier {
  final Ref ref;
  final Random _random = Random();
  bool isSpinning = false;
  WheelSegment? lastResult;

  // Enhanced state tracking
  DateTime? _lastSpinTime;
  int _totalSpins = 0;
  bool _isPaused = false;
  Map<String, int> _rewardStats = {};

  SpinningController(this.ref) {
    _loadSpinningState();
  }

  /// Load saved spinning state
  Future<void> _loadSpinningState() async {
    try {
      _totalSpins = await AppSettings.getInt('total_spins') ?? 0;
      final lastSpinStr = await AppSettings.getString('last_spin_time');
      if (lastSpinStr!.isNotEmpty) {
        _lastSpinTime = DateTime.parse(lastSpinStr!);
      }

      // Load reward statistics
      final statsStr = await AppSettings.getString('reward_stats');
      if (statsStr!.isNotEmpty) {
        _rewardStats = Map<String, int>.from(statsStr as Map);
      }
    } catch (e) {
      debugPrint('Failed to load spinning state: $e');
    }
  }

  /// Util to define fixed reward types (loosely coupled logic)
  WheelSegment getRewardByType(String rewardType) {
    switch (rewardType) {
      case 'jackpot':
        return WheelSegment(label: "Ultimate Diamond", rewardType: "jackpot", reward: 500, imagePath: "assets/images/diamond.png", color: Colors.purple);
      case 'large':
        return WheelSegment(label: "Gold Chest", rewardType: "large", reward: 250, imagePath: "assets/images/gold.png", color: Colors.orange);
      case 'medium':
        return WheelSegment(label: "Silver Crate", rewardType: "medium", reward: 100, imagePath: "assets/images/silver.png", color: Colors.grey);
      default:
        return WheelSegment(label: "Small Prize", rewardType: "small", reward: 50, imagePath: "assets/images/small.png", color: Colors.green);
    }
  }

  /// Main spin function with loosely coupled reward logic.
  Future<void> spin(List<WheelSegment> segments, BuildContext context) async {
    if (isSpinning || _isPaused) return;

    isSpinning = true;
    notifyListeners();

    final prefs = ref.read(appCacheServiceProvider);
    final spinTracker = SpinTracker();

    // Check cooldown and limit
    if (await SpinTracker.canSpin()) {
      // Optionally show cooldown message
      isSpinning = false;
      notifyListeners();
      return;
    }

    // Visual spin result only
    final visualResult = segments[_random.nextInt(segments.length)];
    lastResult = visualResult;
    notifyListeners();

    // Simulate spin duration
    await Future.delayed(const Duration(seconds: 2));
    SpinTracker.registerSpin();

    // --- Reward Calculation (Loosely Coupled) ---
    final userLevel = await AppSettings.getInt("userLevel") ?? 1;
    final exclusiveCurrency = await AppSettings.getInt("exclusiveCurrency") ?? 0;
    final winStreak = await AppSettings.getWinStreak();
    final lastJackpot = await AppSettings.getJackpotTime();

    final rewardEngine = RewardProbability()
      ..userLevel = userLevel
      ..exclusiveCurrency = exclusiveCurrency
      ..winStreak = winStreak
      ..recentlyWonJackpot = false
      ..lastJackpotWin = lastJackpot;

    final rewardType = rewardEngine.spinWheel();
    final prize = getRewardByType(rewardType);

    // Handle win streak updates
    if (rewardType == "jackpot") {
      await AppSettings.setJackpotTime(DateTime.now());
    }

    await AppSettings.setWinStreak(rewardType == "nothing" ? 0 : winStreak + 1);

    // Update statistics
    await _updateSpinStats(rewardType, prize.reward);

    // Save to prize log
    PrizeLogNotifier().addEntry(PrizeEntry(prize: prize.label, timestamp: DateTime.now()));

    // Update coins with animation
    ref.read(coinNotifierProvider).addCoins(prize.reward);

    // Trigger confetti
    ref.read(confettiControllerProvider).play();

    isSpinning = false;
    notifyListeners();

    // Guarded dialog display after async gap
    if (context.mounted) {
      showDialog(
        context: context,
        builder: (_) => ResultDialog(
          result: SpinResult(
            label: prize.label,
            imagePath: prize.imagePath,
            reward: prize.reward,
            timestamp: DateTime.now(),
          ),
        ),
      );
    }
  }

  /// Update spin statistics
  Future<void> _updateSpinStats(String rewardType, int reward) async {
    try {
      _totalSpins++;
      _lastSpinTime = DateTime.now();

      // Update reward type statistics
      _rewardStats[rewardType] = (_rewardStats[rewardType] ?? 0) + 1;

      // Save to AppSettings
      await AppSettings.setInt('total_spins', _totalSpins);
      await AppSettings.setString('last_spin_time', _lastSpinTime!.toIso8601String());
      await AppSettings.setString('reward_stats', _rewardStats.toString());

    } catch (e) {
      debugPrint('Failed to update spin stats: $e');
    }
  }

  /// LIFECYCLE METHOD: Save spinning state when app backgrounded
  /// Called by AppLifecycleObserver when app goes to background
  Future<void> saveSpinningState() async {
    try {
      // Stop any active spinning animation
      if (isSpinning) {
        isSpinning = false;
        notifyListeners();
      }

      // Save current state
      await AppSettings.setInt('total_spins', _totalSpins);
      if (_lastSpinTime != null) {
        await AppSettings.setString('last_spin_time', _lastSpinTime!.toIso8601String());
      }
      await AppSettings.setString('reward_stats', _rewardStats.toString());

      // Create state snapshot
      final stateSnapshot = {
        'totalSpins': _totalSpins,
        'lastSpinTime': _lastSpinTime?.toIso8601String(),
        'rewardStats': _rewardStats,
        'lastResult': lastResult?.toJson(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      await AppSettings.setString('spinning_state_snapshot', stateSnapshot.toString());

      debugPrint('Spinning state saved successfully');
    } catch (e) {
      debugPrint('Failed to save spinning state: $e');
    }
  }

  /// LIFECYCLE METHOD: Validate spinning state when app resumes
  /// Called by AppLifecycleObserver when app resumes from background
  Future<void> validateSpinningState() async {
    try {
      // Reset spinning flag in case app was backgrounded during spin
      if (isSpinning) {
        isSpinning = false;
        notifyListeners();
      }

      // Validate state integrity
      await _validateStateIntegrity();

      // Resume normal operations
      _isPaused = false;

      debugPrint('Spinning state validation completed');
    } catch (e) {
      debugPrint('Spinning state validation failed: $e');
      await _resetSpinningState();
    }
  }

  /// Validate state integrity
  Future<void> _validateStateIntegrity() async {
    try {
      bool needsRepair = false;

      // Validate total spins
      if (_totalSpins < 0) {
        _totalSpins = 0;
        needsRepair = true;
      }

      // Validate last spin time
      if (_lastSpinTime != null) {
        final now = DateTime.now();
        final timeDiff = now.difference(_lastSpinTime!);

        // If last spin was more than 30 days ago, reset stats
        if (timeDiff.inDays > 30) {
          _rewardStats.clear();
          needsRepair = true;
        }
      }

      // Validate reward stats
      _rewardStats.removeWhere((key, value) => value < 0);

      if (needsRepair) {
        await _saveValidatedState();
        debugPrint('Spinning state integrity restored');
      }
    } catch (e) {
      debugPrint('Failed to validate spinning state: $e');
    }
  }

  /// Save validated state
  Future<void> _saveValidatedState() async {
    await AppSettings.setInt('total_spins', _totalSpins);
    if (_lastSpinTime != null) {
      await AppSettings.setString('last_spin_time', _lastSpinTime!.toIso8601String());
    }
    await AppSettings.setString('reward_stats', _rewardStats.toString());
  }

  /// Reset spinning state
  Future<void> _resetSpinningState() async {
    try {
      _totalSpins = 0;
      _lastSpinTime = null;
      _rewardStats.clear();
      lastResult = null;
      isSpinning = false;

      await AppSettings.setInt('total_spins', 0);
      await AppSettings.setString('last_spin_time', '');
      await AppSettings.setString('reward_stats', '');

      debugPrint('Spinning state reset to defaults');
      notifyListeners();
    } catch (e) {
      debugPrint('Failed to reset spinning state: $e');
    }
  }

  /// Pause spinning operations
  void pauseSpinning() {
    _isPaused = true;
    if (isSpinning) {
      isSpinning = false;
      notifyListeners();
    }
  }

  /// Resume spinning operations
  void resumeSpinning() {
    _isPaused = false;
  }

  /// Resume function (alias for resumeSpinning for consistency)
  void resume() {
    resumeSpinning();
  }

  // Pause function (alias for pauseSpinning for consistency)
  void pause() {
    pauseSpinning();
  }

  /// Get spinning statistics
  Map<String, dynamic> getSpinningStats() {
    return {
      'totalSpins': _totalSpins,
      'lastSpinTime': _lastSpinTime?.toIso8601String(),
      'rewardStats': _rewardStats,
      'isSpinning': isSpinning,
      'isPaused': _isPaused,
      'lastResult': lastResult?.label,
    };
  }

  /// Get reward distribution
  Map<String, double> getRewardDistribution() {
    if (_totalSpins == 0) return {};

    return _rewardStats.map((rewardType, count) =>
        MapEntry(rewardType, (count / _totalSpins) * 100));
  }

  /// Export spinning data for backup
  Map<String, dynamic> exportSpinningData() {
    return {
      'totalSpins': _totalSpins,
      'lastSpinTime': _lastSpinTime?.toIso8601String(),
      'rewardStats': _rewardStats,
      'lastResult': lastResult?.toJson(),
      'exported': DateTime.now().toIso8601String(),
    };
  }

  /// Import spinning data from backup
  Future<void> importSpinningData(Map<String, dynamic> data) async {
    try {
      if (data.containsKey('totalSpins')) {
        _totalSpins = data['totalSpins'];
      }

      if (data.containsKey('lastSpinTime') && data['lastSpinTime'] != null) {
        _lastSpinTime = DateTime.parse(data['lastSpinTime']);
      }

      if (data.containsKey('rewardStats')) {
        _rewardStats = Map<String, int>.from(data['rewardStats']);
      }

      await _saveValidatedState();
      notifyListeners();

      debugPrint('Spinning data imported successfully');
    } catch (e) {
      debugPrint('Failed to import spinning data: $e');
      rethrow;
    }
  }

  /// Clear all spinning data
  Future<void> clearAllSpinningData() async {
    await _resetSpinningState();
  }

  /// Check if can spin (considering cooldowns)
  Future<bool> canSpin() async {
    if (_isPaused || isSpinning) return false;
    return await SpinTracker.canSpin();
  }

  /// Get time until next spin is available
  Future<Duration?> getTimeUntilNextSpin() async {
    return await SpinTracker.timeLeft();
  }
}
