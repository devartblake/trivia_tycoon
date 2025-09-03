import 'package:flutter/material.dart';

class RewardMissionCard extends StatelessWidget {
  final String missionText;
  final int currentProgress;
  final int goal;
  final int rewardAmount;

  const RewardMissionCard({
    super.key,
    required this.missionText,
    required this.currentProgress,
    required this.goal,
    required this.rewardAmount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentProgress / goal).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.pink.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      width: 180,
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 6),
              Text(
                missionText,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              Stack(
                alignment: Alignment.center,
                children: [
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 14,
                    backgroundColor: Colors.grey.shade300,
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  Text(
                    '$currentProgress/$goal',
                    style: const TextStyle(fontSize: 12, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  const Icon(Icons.emoji_events, color: Colors.orange, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$rewardAmount',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Icon(Icons.refresh, size: 18),
        ],
      ),
    );
  }
}
