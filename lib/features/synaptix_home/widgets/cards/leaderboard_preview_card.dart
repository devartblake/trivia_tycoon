import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/canonical_routes.dart';
import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../components/synaptix_panel_header.dart';
import '../layout/synaptix_panel.dart';

class LeaderboardPreviewCard extends StatelessWidget {
  final List<SynaptixHomeLeaderboardEntry> entries;

  const LeaderboardPreviewCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SynaptixPanelHeader(title: 'LEADERBOARD', action: 'GLOBAL'),
          const SizedBox(height: 12),
          for (final entry in entries) _LeaderboardRow(entry: entry),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go(canonicalArenaRoute),
              child: const Text('View leaderboard'),
            ),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final SynaptixHomeLeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? SynaptixHomeTheme.purple.withValues(alpha: 0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: entry.isCurrentUser
                    ? SynaptixHomeTheme.purple
                    : SynaptixHomeTheme.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const CircleAvatar(
            radius: 13,
            backgroundColor: SynaptixHomeTheme.blue,
            child: Icon(Icons.person, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: entry.isCurrentUser
                    ? Colors.white
                    : SynaptixHomeTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${entry.score}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
