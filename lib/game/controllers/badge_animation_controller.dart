import 'package:flutter/material.dart';

class BadgeAnimationController {
  static void playUnlockAnimation(BuildContext context) {
    // Placeholder for animation logic when a badge is unlocked
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("🎉 Badge Unlocked!"),
        content: const Text("You've unlocked a new badge!"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Awesome!"),
          ),
        ],
      ),
    );
  }
}