
import 'package:flutter/material.dart';

class MissionAnalyticsWidget extends StatelessWidget {
  final int totalCompleted;
  final int totalSwapped;
  final int xpEarned;

  const MissionAnalyticsWidget({
    super.key,
    required this.totalCompleted,
    required this.totalSwapped,
    required this.xpEarned,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Mission Analytics", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20, width: 150),
            Text("Total Completed: $totalCompleted"),
            Text("Missions Swapped: $totalSwapped"),
            Text("XP Earned from Missions: $xpEarned"),
          ],
        ),
      ),
    );
  }
}
