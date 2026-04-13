import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../game/models/leaderboard_entry.dart';

class UserStatsTab extends StatelessWidget {
  final LeaderboardEntry entry;

  const UserStatsTab({super.key, required this.entry});

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  Widget _buildStatRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatRow("Score", entry.score),
        _buildStatRow("Wins", entry.wins),
        _buildStatRow("Rank", entry.rank),
        _buildStatRow("Streak", entry.streak),
        _buildStatRow("Accuracy", "${(entry.accuracy * 100).toStringAsFixed(1)}%"),
        _buildStatRow("Favorite Category", entry.favoriteCategory),
        _buildStatRow("Joined", _formatDate(entry.joinedDate)),
        const SizedBox(height: 32),
        Text("More stat tracking coming soon...", style: Theme.of(context).textTheme.labelMedium),
      ],
    );
  }
}
