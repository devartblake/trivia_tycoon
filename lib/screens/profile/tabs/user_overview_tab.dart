import 'package:flutter/material.dart';
import '../../../game/models/leaderboard_entry.dart';
import '../widgets/user_profile_header.dart';

class UserOverviewTab extends StatelessWidget {
  final LeaderboardEntry entry;

  const UserOverviewTab({super.key, required this.entry});

  Color _getXPColor(double xp) {
    if (xp >= 0.8) return Colors.green;
    if (xp >= 0.5) return Colors.orange;
    return Colors.redAccent;
  }

  @override
  Widget build(BuildContext context) {
    final xp = entry.xpProgress.clamp(0.0, 1.0);
    final xpColor = _getXPColor(xp);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          UserProfileHeader(entry: entry),
          const SizedBox(height: 24),
          Text('XP Progress'),
          AnimatedContainer(
            duration: const Duration(milliseconds: 700),
            height: 10,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(8),
            ),
            child: FractionallySizedBox(
              widthFactor: xp,
              child: Container(
                decoration: BoxDecoration(
                  color: xpColor,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          if (entry.status != null)
            Chip(
              label: Text(entry.status!.toUpperCase()),
              backgroundColor: Colors.blue.shade100,
            ),
        ],
      ),
    );
  }
}