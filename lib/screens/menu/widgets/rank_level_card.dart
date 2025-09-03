import 'package:flutter/material.dart';

class RankLevelCard extends StatelessWidget {
  final String rank;
  final int level;
  final int currentXP;
  final int maxXP;
  final String ageGroup;

  const RankLevelCard({
    super.key,
    required this.rank,
    required this.level,
    required this.currentXP,
    required this.maxXP,
    required this.ageGroup,
  });

  @override
  Widget build(BuildContext context) {
    final titleStyle = _getTitleStyle();
    final accentColor = _getAccentColor();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Rank: $rank', style: titleStyle),
            const SizedBox(height: 5),
            Text('Level: $level', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: currentXP / maxXP,
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation(accentColor),
            ),
            const SizedBox(height: 5),
            Text('$currentXP / $maxXP XP', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  TextStyle _getTitleStyle() {
    switch (ageGroup) {
      case 'kids':
        return const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.orange);
      case 'teens':
        return const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.blueAccent);
      case 'adults':
        return const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: Colors.black87);
      default:
        return const TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: Colors.blueAccent);
    }
  }

  Color _getAccentColor() {
    switch (ageGroup) {
      case 'kids':
        return Colors.pinkAccent;
      case 'teens':
        return Colors.blueAccent;
      case 'adults':
        return Colors.green;
      default:
        return Colors.blueAccent;
    }
  }
}
