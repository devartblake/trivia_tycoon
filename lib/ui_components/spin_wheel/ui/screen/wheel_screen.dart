import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/ui/widgets/floating_spin_cta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../../../game/analytics/providers/analytics_providers.dart';
import '../../../../game/providers/riverpod_providers.dart';
import '../../../../core/services/settings/app_settings.dart';
import '../../models/spin_system_models.dart';
import '../../physics/non_uniform_motion.dart';
import '../../physics/updated_spin_handler.dart';
import '../../utils/spin_transition_utils.dart';
import '../dialogs/result_dialog.dart';
import '../toasts/spin_ready_toast.dart';
import '../widgets/stat_card_widget.dart';
import '../widgets/wheel_segment_stack.dart';
import '../widgets/spin_button.dart';
import '../widgets/spin_cooldown_widget.dart';
import '../../../confetti/ui/confetti_debug_overlay.dart';
import '../../../confetti/ui/confetti_settings.dart';
import '../../services/spin_tracker.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class WheelScreen extends ConsumerStatefulWidget {
  const WheelScreen({super.key});

  @override
  ConsumerState<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends ConsumerState<WheelScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late AnimationController _scaleController;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  double _currentAngle = 0;
  int? _activeIndex;
  bool _isSpinning = false;
  bool _canSpin = true;

  List<WheelSegment> _segments = [];

  // Analytics tracking
  DateTime? _screenEnteredTime;
  int _spinCount = 0;
  Timer? _cooldownCheckTimer;

  @override
  void initState() {
    super.initState();
    _screenEnteredTime = DateTime.now();
    _initializeAnimations();
    _loadSegments();
    _checkSpinAvailability();
    _trackScreenView();
    _startCooldownMonitor();
  }

  // Monitor cooldown and show toast when ready
  void _startCooldownMonitor() {
    _cooldownCheckTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      final wasCanSpin = _canSpin;
      await _checkSpinAvailability();

      // If spin just became available
      if (_canSpin && !wasCanSpin && mounted) {
        await _showSpinReadyToast();
      }
    });
  }

  Future<void> _showSpinReadyToast() async {
    await _trackUserAction('spin_ready_toast_shown');

    await SpinReadyToast.show(
      context: context,
      onSpinNow: () {
        _handleSpin();
      },
      customMessage: 'Your cooldown has expired! Spin now to win rewards!',
    );
  }

  @override
  void dispose() {
    _cooldownCheckTimer?.cancel();
    _trackScreenExit();
    _animationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  // ============ ANALYTICS METHODS ============

  /// Track screen view
  Future<void> _trackScreenView() async {
    try {
      final analytics = ref.read(analyticsServiceProvider);
      await analytics.trackEvent('wheel_screen_view', {
        'screen_name': 'WheelScreen',
        'can_spin': _canSpin,
        'segments_count': _segments.length,
      });
    } catch (e) {
      LogManager.debug('Analytics tracking failed: $e');
    }
  }

  /// Track screen exit with duration
  Future<void> _trackScreenExit() async {
    if (_screenEnteredTime == null) return;

    try {
      final analytics = ref.read(analyticsServiceProvider);
      final duration = DateTime.now().difference(_screenEnteredTime!);

      await analytics.trackEvent('wheel_screen_exit', {
        'screen_name': 'WheelScreen',
        'duration_seconds': duration.inSeconds,
        'spins_completed': _spinCount,
        'final_can_spin': _canSpin,
      });
    } catch (e) {
      LogManager.debug('Analytics tracking failed: $e');
    }
  }

  /// Track user action
  Future<void> _trackUserAction(String action, {Map<String, dynamic>? additionalData}) async {
    try {
      final analytics = ref.read(analyticsServiceProvider);
      await analytics.trackEngagement(
        action: action,
        screen: 'WheelScreen',
        properties: {
          'can_spin': _canSpin,
          'is_spinning': _isSpinning,
          'spin_count': _spinCount,
          ...?additionalData,
        },
      );
    } catch (e) {
      LogManager.debug('Analytics tracking failed: $e');
    }
  }

  /// Track spin started
  Future<void> _trackSpinStarted({required String triggerMethod}) async {
    await _trackUserAction('spin_started', additionalData: {
      'trigger_method': triggerMethod, // 'button' or 'gesture'
      'current_angle': _currentAngle,
      'segments_count': _segments.length,
    });
  }

  /// Track spin completed with result
  Future<void> _trackSpinCompleted(WheelSegment result) async {
    try {
      final analytics = ref.read(analyticsServiceProvider);

      // Track the spin completion event
      await analytics.trackEvent('spin_completed', {
        'reward_type': result.label,
        'reward_value': result.reward,
        'segment_index': _activeIndex,
        'spin_number': _spinCount,
      });

      // Update spin statistics in AppSettings
      await AppSettings.updateSpinStatistics(
        rewardType: result.label,
        rewardValue: result.reward,
      );

      // Add to spin history
      await AppSettings.addSpinToHistory({
        'rewardType': result.label,
        'rewardValue': result.reward,
        'timestamp': DateTime.now().toIso8601String(),
        'segmentIndex': _activeIndex,
      });

      // Increment spin counters
      await AppSettings.incrementTodaySpinCount();
      await AppSettings.incrementWeeklySpinCount();
      await AppSettings.incrementTotalLifetimeSpins();

      // Update reward points
      final currentPoints = await AppSettings.getSpinRewardPoints();
      await AppSettings.addSpinRewardPoints(result.reward.toDouble());

    } catch (e) {
      LogManager.debug('Failed to track spin completion: $e');
    }
  }

  /// Track error
  Future<void> _trackError(String errorType, String errorMessage) async {
    await _trackUserAction('wheel_screen_error', additionalData: {
      'error_type': errorType,
      'error_message': errorMessage,
    });
  }

  // ============ END ANALYTICS METHODS ============

  void _initializeAnimations() {
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    )..addListener(() {
      if (mounted) {
        setState(() {
          _currentAngle = _animation.value;
        });
      }
    });

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.7).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _segments.isNotEmpty) {
        _handleSpinComplete();
      }
    });

    // Start entrance animation
    _scaleController.forward();
  }

  Future<void> _loadSegments() async {
    try {
      final loader = ref.read(segmentLoaderProvider);
      final segments = await loader.loadSegments();
      if (mounted) {
        setState(() {
          _segments = segments;
        });

        await _trackUserAction('segments_loaded', additionalData: {
          'segments_count': segments.length,
        });
      }
    } catch (e) {
      await _trackError('segment_load_failed', e.toString());
      _showErrorSnackBar('Failed to load wheel segments');
    }
  }

  Future<void> _checkSpinAvailability() async {
    final canSpin = await SpinTracker.canSpin();
    if (mounted) {
      setState(() {
        _canSpin = canSpin;
      });

      await _trackUserAction('spin_availability_checked', additionalData: {
        'can_spin': canSpin,
      });
    }
  }

  void _handleSpinComplete() {
    final index = SpinTransitionUtils.getSegmentIndexFromAngle(
      _currentAngle,
      _segments.length,
    );
    final result = _segments[index];

    setState(() {
      _activeIndex = index;
      _isSpinning = false;
      _spinCount++;
    });

    // Track spin completion
    _trackSpinCompleted(result);

    // Trigger confetti and haptic feedback
    ref.read(confettiControllerProvider).play();
    HapticFeedback.heavyImpact();

    // Delay result dialog for better UX
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        _showResultDialog(result);
      }
    });
  }

  Future<void> _handleSpin() async {
    if (_isSpinning || !_canSpin) {
      if (!_canSpin) {
        await _trackUserAction('spin_blocked_cooldown');
      }
      return;
    }

    setState(() {
      _isSpinning = true;
      _activeIndex = null;
    });

    HapticFeedback.mediumImpact();

    // Track spin started
    await _trackSpinStarted(triggerMethod: 'button');

    try {
      await UpdatedSpinHandlers.handleSpinWithPhysics(
        vsync: this,
        ref: ref,
        currentAngle: _currentAngle,
        segments: _segments,
        setAnimation: (controller, anim) {
          _animationController = controller;
          _animation = anim;
          _animation.addListener(() {
            if (mounted) {
              setState(() {
                _currentAngle = _animation.value;
              });
            }
          });
        },
        onStart: () {
          // Audio handled in physics handler
        },
        onComplete: (segment) {
          // Handled in animation status listener
        },
      );
      _scheduleCooldownNotification();
      await _checkSpinAvailability();
    } catch (e) {
      setState(() {
        _isSpinning = false;
      });
      await _trackError('spin_failed', e.toString());
      _showErrorSnackBar('Spin failed. Please try again.');
    }
  }

  void _handleGestureSpin(double velocity) {
    if (velocity.abs() < 100 || _isSpinning || !_canSpin) return;

    setState(() {
      _isSpinning = true;
      _activeIndex = null;
    });

    // Track gesture spin
    _trackSpinStarted(triggerMethod: 'gesture').then((_) {
      _trackUserAction('gesture_spin', additionalData: {
        'velocity': velocity,
      });
    });

    final physics = EnhancedNonUniformMotion(resistance: 0.015);
    final physicsVelocity = _convertGestureVelocity(velocity);
    final duration = physics.calculateDuration(physicsVelocity);
    final distance = physics.calculateDistance(physicsVelocity, duration);

    _animation = Tween<double>(
      begin: _currentAngle,
      end: _currentAngle + distance,
    ).animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.decelerate
    ));

    _animationController.forward(from: 0);
    HapticFeedback.lightImpact();
  }

  double _convertGestureVelocity(double gestureVelocity) {
    final normalizedVelocity = gestureVelocity.abs() / 1000.0;
    return (normalizedVelocity * 10.0).clamp(2.0, 15.0);
  }

  void _showResultDialog(WheelSegment segment) {
    _trackUserAction('result_dialog_shown', additionalData: {
      'reward': segment.label,
      'reward_value': segment.reward,
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ResultDialog(
        result: SpinResult(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          label: segment.label,
          imagePath: segment.imagePath,
          reward: segment.reward,
          timestamp: DateTime.now(),
        ),
      ),
    ).then((_) {
      _trackUserAction('result_dialog_closed');
    });
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _scheduleCooldownNotification() {
    final readyTime = DateTime.now().add(SpinTracker.cooldown);
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 101,
        channelKey: 'spin_channel',
        title: 'Your spin is ready!',
        body: 'Come back and spin again for more rewards!',
        notificationLayout: NotificationLayout.Default,
      ),
      schedule: NotificationCalendar(
        year: readyTime.year,
        month: readyTime.month,
        day: readyTime.day,
        hour: readyTime.hour,
        minute: readyTime.minute,
        second: 0,
        millisecond: 0,
        allowWhileIdle: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0A0A0F)
          : const Color(0xFFF8F9FA),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.casino,
                color: Colors.purple,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              "Spin the Wheel",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 20,
              ),
            ),
            const Spacer(),
            FutureBuilder<bool>(
              future: SpinTracker.canSpin(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox.shrink();

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: snapshot.data!
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: snapshot.data! ? Colors.green : Colors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        snapshot.data! ? 'Ready' : 'Cooldown',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: snapshot.data! ? Colors.green : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () async {
              await _trackUserAction('history_button_pressed');
              // Navigate to prize log
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: AnimatedBuilder(
              animation: _fadeAnimation,
              builder: (context, child) {
                return Opacity(
                  opacity: _isSpinning ? _fadeAnimation.value : 1.0,
                  child: Stack(
                    children: [
                      // Main content
                      SafeArea(
                        child: SingleChildScrollView(
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              minHeight: MediaQuery.of(context).size.height -
                                  MediaQuery.of(context).padding.top -
                                  kToolbarHeight,
                            ),
                            child: IntrinsicHeight(
                              child: Column(
                                children: [
                                  // Wheel section
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      margin: const EdgeInsets.all(20),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? const Color(0xFF1E1E2E)
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(24),
                                        boxShadow: [
                                          BoxShadow(
                                            color: isDark
                                                ? Colors.black.withValues(alpha: 0.3)
                                                : Colors.grey.withValues(alpha: 0.1),
                                            blurRadius: 20,
                                            offset: const Offset(0, 10),
                                          ),
                                        ],
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(24),
                                        child: Stack(
                                          children: [
                                            // Wheel
                                            Center(
                                              child: AspectRatio(
                                                aspectRatio: 1.0,
                                                child: Padding(
                                                  padding: const EdgeInsets.all(16.0),
                                                  child: WheelSegmentStack(
                                                    segments: _segments,
                                                    rotationAngle: _currentAngle,
                                                    activeIndex: _activeIndex,
                                                    onSegmentTap: (index) => LogManager.debug('Tapped segment $index'),
                                                    onGestureSpin: _handleGestureSpin,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Loading overlay
                                            if (_isSpinning)
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withValues(alpha: 0.2),
                                                  borderRadius: BorderRadius.circular(24),
                                                ),
                                                child: const Center(
                                                  child: Column(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      CircularProgressIndicator(
                                                        color: Colors.purple,
                                                        strokeWidth: 3,
                                                      ),
                                                      SizedBox(height: 16),
                                                      Text(
                                                        'Spinning...',
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 16,
                                                          fontWeight: FontWeight.w600,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),

                                  // Controls section
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const SpinCooldownWidget(),
                                        const SizedBox(height: 16),

                                        // Spin button
                                        if (_canSpin && !_isSpinning)
                                          AnimatedScale(
                                            scale: 1.0,
                                            duration: const Duration(milliseconds: 200),
                                            child: SpinButton(
                                              onSpin: () => _handleSpin(),
                                            ),
                                          )
                                        else
                                          AnimatedScale(
                                            scale: 0.95,
                                            duration: const Duration(milliseconds: 200),
                                            child: SpinButton(
                                              onSpin: () {},
                                            ),
                                          ),

                                        const SizedBox(height: 16),

                                        // Stats row
                                        if (!_isSpinning)
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Flexible(
                                                child: StatCard(
                                                  icon: Icons.casino,
                                                  label: 'Spins Today',
                                                  value: '${SpinTracker.maxSpinsPerDay}',
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: StatCard(
                                                  icon: Icons.timer,
                                                  label: 'Cooldown',
                                                  value: '${SpinTracker.cooldown.inHours}h',
                                                  color: Colors.orange,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: StatCard(
                                                  icon: Icons.emoji_events,
                                                  label: 'Rewards',
                                                  value: '${_segments.length}',
                                                  color: Colors.green,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Confetti overlay
                      if (ref.watch(showDebugOverlayProvider))
                        const ConfettiDebugOverlay(),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}