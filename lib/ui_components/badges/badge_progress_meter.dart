import 'package:flutter/material.dart';

class BadgeProgressMeter extends StatelessWidget {
  final int current;
  final int goal;

  const BadgeProgressMeter({super.key, required this.current, required this.goal});

  @override
  Widget build(BuildContext context) {
    final double progress = current / goal;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Progress: $current / $goal"),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          minHeight: 8,
          color: Colors.green,
          backgroundColor: Colors.grey[300],
        ),
      ],
    );
  }
}