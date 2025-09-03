import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../models/wheel_segment.dart';
import '../services/spin_tracker.dart';
import 'spin_velocity.dart';
import 'non_uniform_motion.dart';

Future<void> handleSpinWithPhysics({
  required TickerProvider vsync,
  required WidgetRef ref,
  required double currentAngle,
  required List<WheelSegment> segments,
  required void Function(AnimationController controller, Animation<double> animation) setAnimation,
  required VoidCallback onStart,
  required void Function(WheelSegment) onComplete,
}) async {
  final size = MediaQueryData.fromView(WidgetsBinding.instance.window).size;
  final spinVelocity = SpinVelocity(height: size.height, width: size.width);
  final physics = NonUniformCircularMotion(resistance: 0.015);

  final velocity = spinVelocity.generateRandomSpinVelocity();
  final durationSec = physics.duration(velocity);
  final targetAngle = physics.distance(velocity, durationSec);

  final controller = AnimationController(
    vsync: vsync,
    duration: Duration(milliseconds: (durationSec * 1000).toInt()),
  );

  final animation = Tween<double>(
    begin: currentAngle,
    end: currentAngle + targetAngle,
  ).animate(CurvedAnimation(
    parent: controller,
    curve: Curves.easeOutQuart,
  ));

  // Give both to the WheelScreen
  setAnimation(controller, animation);

  onStart();
  controller.forward();

  controller.addStatusListener((status) async {
    if (status == AnimationStatus.completed) {
      final finalAngle = animation.value % (2 * pi);
      final index = ((segments.length - (finalAngle / (2 * pi / segments.length))) % segments.length).floor();
      final selectedSegment = segments[index];

      ref.read(confettiControllerProvider).play();
      await SpinTracker.registerSpin();

      // Optionally update coin balance, trigger animations, etc.
      onComplete(selectedSegment);
    }
  });
}
