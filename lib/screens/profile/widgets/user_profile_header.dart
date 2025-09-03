import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../game/models/leaderboard_entry.dart';

class UserProfileHeader extends StatelessWidget {
  final LeaderboardEntry entry;

  const UserProfileHeader({super.key, required this.entry});

  String _formatDate(DateTime date) {
    return DateFormat.yMMMd().add_jm().format(date);
  }

  Widget _buildFlag(String? countryCode) {
    if (countryCode == null || countryCode.isEmpty) return const SizedBox.shrink();

    // Ensure only letters A-Z are processed and cast to int
    final codeUnits = countryCode
        .toUpperCase()
        .codeUnits
        .map((c) => 0x1F1E6 + (c - 65))
        .where((c) => c >= 0x1F1E6 && c <= 0x1F1FF)
        .toList();

    return Text(
      String.fromCharCodes(codeUnits),
      style: const TextStyle(fontSize: 24),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundImage: entry.avatar.isNotEmpty
              ? NetworkImage(entry.avatar)
              : null,
          child: (entry.avatar.isEmpty)
              ? Text(entry.username[0].toUpperCase(), style: const TextStyle(fontSize: 24))
              : null,
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(entry.username, style: theme.textTheme.headlineSmall),
              Text("${entry.ageGroup.toUpperCase()} • Level ${entry.level}"),
              const SizedBox(height: 4),
              _buildFlag(entry.country),
              const SizedBox(height: 4),
              Tooltip(
                message: "Last active: ${_formatDate(entry.lastActive)}",
                child: Row(
                  children: [
                    const Icon(Icons.access_time, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      'Online ${DateFormat('jm').format(entry.lastActive)}',
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
      ],
    );
  }
}
