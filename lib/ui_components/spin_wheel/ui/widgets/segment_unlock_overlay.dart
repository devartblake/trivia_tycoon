import 'package:flutter/material.dart';

class SegmentUnlockOverlay extends StatelessWidget {
  final bool isUnlocked;

  const SegmentUnlockOverlay({super.key, required this.isUnlocked});

  @override
  Widget build(BuildContext context) {
    if (isUnlocked) return const SizedBox();
    return Container(
      color: Colors.black.withOpacity(0.4),
      child: const Center(
        child: Icon(Icons.lock, color: Colors.white, size: 28),
      ),
    );
  }
}