import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/ui/widgets/floating_spin_cta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../../../game/providers/riverpod_providers.dart';
import '../../models/spin_system_models.dart';
import '../../physics/non_uniform_motion.dart';
import '../../physics/updated_spin_handler.dart';
import '../../utils/spin_transition_utils.dart';
import '../widgets/result_dialog.dart';
import '../widgets/wheel_segment_stack.dart';
import '../widgets/spin_button.dart';
import '../widgets/spin_cooldown_widget.dart';
import '../../../confetti/ui/confetti_debug_overlay.dart';
import '../../../confetti/ui/confetti_settings.dart';
import '../../services/spin_tracker.dart';

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

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadSegments();
    _checkSpinAvailability();
  }

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
      }
    } catch (e) {
      _showErrorSnackBar('Failed to load wheel segments');
    }
  }

  Future<void> _checkSpinAvailability() async {
    final canSpin = await SpinTracker.canSpin();
    if (mounted) {
      setState(() {
        _canSpin = canSpin;
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
    });

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
    if (_isSpinning || !_canSpin) return;

    setState(() {
      _isSpinning = true;
      _activeIndex = null;
    });

    HapticFeedback.mediumImpact();

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
      _showErrorSnackBar('Spin failed. Please try again.');
    }
  }

  void _handleGestureSpin(double velocity) {
    if (velocity.abs() < 100 || _isSpinning || !_canSpin) return;

    setState(() {
      _isSpinning = true;
      _activeIndex = null;
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

  // Helper method for gesture velocity conversion
  double _convertGestureVelocity(double gestureVelocity) {
    final normalizedVelocity = gestureVelocity.abs() / 1000.0;
    return (normalizedVelocity * 10.0).clamp(2.0, 15.0);
  }

  void _showResultDialog(WheelSegment segment) {
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
    );
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
  void dispose() {
    _animationController.dispose();
    _scaleController.dispose();
    super.dispose();
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
                color: Colors.purple.withOpacity(0.1),
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
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
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
            onPressed: () {
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
                      // Main content - Use SafeArea and SingleChildScrollView to prevent overflow
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
                                                ? Colors.black.withOpacity(0.3)
                                                : Colors.grey.withOpacity(0.1),
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
                                                    onSegmentTap: (index) => debugPrint('Tapped segment $index'),
                                                    onGestureSpin: _handleGestureSpin,
                                                  ),
                                                ),
                                              ),
                                            ),

                                            // Loading overlay
                                            if (_isSpinning)
                                              Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.black.withOpacity(0.2),
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

                                  // Controls section - Make this more compact
                                  Container(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Cooldown widget - make it more compact
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
                                              onSpin: () {}, // Empty callback when disabled
                                            ),
                                          ),

                                        const SizedBox(height: 16),

                                        // Stats row - make more compact
                                        if (!_isSpinning)
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            children: [
                                              Flexible(
                                                child: _StatCard(
                                                  icon: Icons.casino,
                                                  label: 'Spins Today',
                                                  value: '${SpinTracker.maxSpinsPerDay}',
                                                  color: Colors.blue,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: _StatCard(
                                                  icon: Icons.timer,
                                                  label: 'Cooldown',
                                                  value: '${SpinTracker.cooldown.inHours}h',
                                                  color: Colors.orange,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              Flexible(
                                                child: _StatCard(
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

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF2A2A3E)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}