import 'dart:math';
import 'package:flutter/material.dart';
// import 'package:audioplayers/audioplayers.dart';

const Map<int, Offset> quadrants = {
  1: Offset(0.5, 0.5),
  2: Offset(-0.5, 0.5),
  3: Offset(-0.5, -0.5),
  4: Offset(0.5, -0.5),
};

const double pi_0_5 = pi * 0.5;
const double pi_2_5 = pi * 2.5;
const double pi_2 = pi * 2;

class SpinVelocity {
  final double height;
  final double width;
  // final AudioPlayer _audioPlayer = AudioPlayer();

  SpinVelocity({required this.height, required this.width});

  double get width_0_5 => width / 2;
  double get height_0_5 => height / 2;

  /// Generates a random velocity when clicking the center button
  double generateRandomSpinVelocity() {
    return Random().nextDouble() * 10 + 5; // Random velocity between 5 and 15
  }

  /// Calculates velocity based on user touch
  double getVelocity(Offset position, Offset pps) {
    int quadrantIndex = _getQuadrantFromOffset(position);
    Offset quadrant = quadrants[quadrantIndex]!;
    return (quadrant.dx * pps.dx) + (quadrant.dy * pps.dy);
  }

  /// Converts offset to radians
  double offsetToRadians(Offset position) {
    var a = position.dx - width_0_5;
    var b = height_0_5 - position.dy;
    var angle = atan2(b, a);
    return _normalizeAngle(angle);
  }

  int _getQuadrantFromOffset(Offset p) =>
      p.dx > width_0_5 ? (p.dy > height_0_5 ? 2 : 1) : (p.dy > height_0_5 ? 3 : 4);

  double _normalizeAngle(double angle) => angle > 0
      ? (angle > pi_0_5 ? (pi_2_5 - angle) : (pi_0_5 - angle))
      : pi_0_5 - angle;

  /// Plays spin sound when the wheel starts
  /*Future<void> _playSpinSound() async {
    await _audioPlayer.play(AssetSource('sounds/spin.mp3'));
  }*/

  /// Plays landing sound when the wheel stops
  /*Future<void> _playLandingSound() async {
    await _audioPlayer.play(AssetSource('sounds/landing.mp3'));
  }*/

  /// Shows a notification dialog when the spin ends
  void showLandingNotification(BuildContext context, String result) {
    //_playLandingSound();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text("You won!"),
        content: Text("You landed on: $result"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text("OK"),
          ),
        ],
      ),
    );
  }

  bool contains(Offset p) => Size(width, height).contains(p);
}
