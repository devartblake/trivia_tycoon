import 'package:flutter/material.dart';
import '../../../game/models/leaderboard_entry.dart';
import '../../leaderboard/widgets/shimmer_avatar.dart';

class TopThreeLeaderboard extends StatelessWidget {
  final List<LeaderboardEntry> topThree;

  const TopThreeLeaderboard({super.key, required this.topThree});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: List.generate(topThree.length, (index) {
        final entry = topThree[index];
        final isFirst = index == 0;
        final size = isFirst ? 80.0 : 60.0;

        return Column(
          children: [
            ShimmerAvatar(
              radius: size / 2,
              avatarPath: entry.avatar,
              initials: entry.playerName.isNotEmpty ? entry.playerName[0].toUpperCase() : '',
              ageGroup: entry.ageGroup,
              gender: entry.gender,
              xpProgress: entry.xpProgress,
              isLoading: false,
              status: entry.status, // Add this line once `status` is in the widget
            ),
            const SizedBox(height: 6),
            Text(entry.playerName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text('${entry.score} XP'),
          ],
        );
      }),
    );
  }
}
