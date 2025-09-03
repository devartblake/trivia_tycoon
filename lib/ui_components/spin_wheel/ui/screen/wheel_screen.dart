import 'dart:math';
import 'package:flutter/material.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/ui/widgets/floating_spin_cta.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import '../../../../game/providers/riverpod_providers.dart';
import '../../physics/non_uniform_motion.dart';
import '../../physics/spin_physics_handler.dart';
import '../../utils/spin_transition_utils.dart';
import '../widgets/result_dialog.dart';
import '../widgets/wheel_segment_stack.dart';
import '../widgets/spin_button.dart';
import '../widgets/spin_cooldown_widget.dart';
import '../../../confetti/ui/confetti_debug_overlay.dart';
import '../../../confetti/ui/confetti_settings.dart';
import '../../models/spin_result.dart';
import '../../models/wheel_segment.dart';
import '../../services/spin_tracker.dart';

class WheelScreen extends ConsumerStatefulWidget {
  const WheelScreen({super.key});

  @override
  ConsumerState<WheelScreen> createState() => _WheelScreenState();
}

class _WheelScreenState extends ConsumerState<WheelScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;
  double _currentAngle = 0;
  final _random = Random();
  int? _activeIndex;

  late List<WheelSegment> _segments = [];

  @override
  void initState() {
    super.initState();
    _loadSegments();
    _animationController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    );

    _animation = Tween<double>(begin: 0, end: 0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutQuart),
    )..addListener(() {
      setState(() {
        _currentAngle = _animation.value;
      });
    });

    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed && _segments.isNotEmpty) {
        final index = SpinTransitionUtils.getSegmentIndexFromAngle(
          _currentAngle,
          _segments.length,
        );
        final result = _segments[index];
        _activeIndex = index;

        // Trigger confetti 🎉
        ref.read(confettiControllerProvider).play(); // Assuming you have this

        _showResultDialog(result);
      }
    });
  }

  Future<void> _loadSegments() async {
    final loader = ref.read(segmentLoaderProvider); // Handles remote or l0cal
    final segments = await loader.loadSegments();
    setState(() {
      _segments = segments;
    });
  }

  Future<void> _handleSpin() async {
    await handleSpinWithPhysics(
      vsync: this,
      ref: ref,
      currentAngle: _currentAngle,
      segments: _segments,
      setAnimation: (controller, anim) {
        _animationController = controller;
        _animation = _animation;
        _animation.addListener(() {
          setState(() {
            _currentAngle = _animation.value;
          });
        });
      },
      onStart: () {
        //ref.read(audioPlayerProvider).play();
      },
      onComplete: (segment) {
        _showResultDialog(segment);
      },
    );
    _scheduleCooldownNotification();
  }

  void _handleGestureSpin(double velocity) {
    if (velocity.abs() < 100) return; // Ignore weak gestures

    final physics = NonUniformCircularMotion(resistance: 0.015);
    final spinVelocity = pixelsPerSecondToRadians(velocity);
    final duration = physics.duration(spinVelocity);
    final angle = physics.distance(spinVelocity, duration);
    final controller = _animationController;

    _animation = Tween<double>(
      begin: _currentAngle,
      end: _currentAngle + angle,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.decelerate));

    controller.forward(from: 0);
    //ref.read(audioPlayerProvider).play(); // Trigger audio if needed
  }

  void _showResultDialog(WheelSegment segment) {
    showDialog(
      context: context,
      builder:
          (_) => ResultDialog(
            result: SpinResult(
              label: segment.label,
              imagePath: segment.imagePath,
              reward: segment.reward,
              timestamp: DateTime.now(),
            ),
          ),
    );
  }

  void _scheduleCooldownNotification() {
    final readyTime = DateTime.now().add(SpinTracker.cooldown);
    AwesomeNotifications().createNotification(
      content: NotificationContent(
        id: 101,
        channelKey: 'spin_channel',
        title: '🎉 Your spin is ready!',
        body: 'Come back and spin again!',
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
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text("🎡 Spin the Wheel"),
            const SizedBox(width: 8),
            FutureBuilder<bool>(
              future: SpinTracker.canSpin(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data == false)
                  return const SizedBox();
                return Icon(
                  Icons.fiber_manual_record,
                  color: Colors.blueGrey,
                  size: 20,
                );
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Center(
                  child: WheelSegmentStack(
                    segments: _segments,
                    rotationAngle: _currentAngle,
                    activeIndex: _activeIndex,
                    onSegmentTap:
                        (index) => debugPrint('Tapped segment $index'),
                    onGestureSpin: _handleGestureSpin,
                  ),
                ),
              ),
              const SpinCooldownWidget(),
              const SizedBox(height: 10),
              SpinButton(onSpin: _handleSpin),
              const SizedBox(height: 50),
            ],
          ),
          // Positioned.fill(
          //   child: ConfettiWidget(
          //     controller: ref.read(confettiControllerProvider),
          //     theme: ref.watch(confettiControllerProvider).theme,
          //   ),
          // ),
          if (ref.watch(showDebugOverlayProvider)) const ConfettiDebugOverlay(),
        ],
      ),
      floatingActionButton: FloatingSpinCTA(onPressed: _handleSpin),
    );
  }
}
