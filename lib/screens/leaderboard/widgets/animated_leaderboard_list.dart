import 'package:flutter/material.dart';
import '../../../game/models/leaderboard_entry.dart';
import 'leaderboard_card.dart';

class AnimatedLeaderboardList extends StatelessWidget {
  final List<LeaderboardEntry> entries;

  const AnimatedLeaderboardList({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: Duration(milliseconds: 300 + index * 100),
          curve: Curves.easeOut,
          builder: (context, opacity, child) {
            return Opacity(
              opacity: opacity,
              child: Transform.translate(
                offset: Offset(0, (1 - opacity) * 20),
                child: child,
              ),
            );
          },
          child: LeaderboardCard(
            entry: entry,
            rank: index + 1,
          ),
        );
      },
    );
  }
}
