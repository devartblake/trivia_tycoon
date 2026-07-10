import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/multiplayer_providers.dart';

/// Displays match history and active matches.
///
/// Loads match data from the REST API via MatchesService and displays:
/// - Match opponent name
/// - Final scores
/// - Match result (won/lost/tied)
/// - Creation timestamp
///
/// Error handling:
/// - Shows empty state when no matches found
/// - Gracefully handles API failures with retry button
/// - Loading state support via state management
class MatchHistoryWidget extends ConsumerWidget {
  final String? filterStatus; // 'completed', 'ongoing', or null for all
  final int? maxItems; // Limit number of items displayed, or null for all

  const MatchHistoryWidget({
    super.key,
    this.filterStatus,
    this.maxItems,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matches = ref.watch(activeMatchesProvider);
    final theme = Theme.of(context);

    // Empty state
    if (matches.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.games_outlined,
                size: 64,
                color: theme.colorScheme.secondary.withAlpha(128),
              ),
              const SizedBox(height: 16),
              Text(
                'No matches yet',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Complete challenges to see your match history here',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.secondary.withAlpha(200),
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () {
                  // Trigger manual refresh
                  ref.invalidate(activeMatchesProvider);
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Refresh'),
              ),
            ],
          ),
        ),
      );
    }

    // Apply filter if specified
    final filteredMatches = filterStatus != null
        ? matches
            .where(
              (m) =>
                  (m['status']?.toString().toLowerCase() ?? '') ==
                  filterStatus!.toLowerCase(),
            )
            .toList()
        : matches;

    // Apply max items limit if specified
    final displayMatches = maxItems != null
        ? filteredMatches.take(maxItems!).toList()
        : filteredMatches;

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(activeMatchesProvider);
      },
      child: ListView.builder(
        itemCount: displayMatches.length,
        itemBuilder: (context, index) {
          final match = displayMatches[index];
          return _MatchHistoryCard(match: match);
        },
      ),
    );
  }
}

class _MatchHistoryCard extends StatelessWidget {
  final Map<String, dynamic> match;

  const _MatchHistoryCard({
    required this.match,
  });

  String _getResultLabel() {
    final result = match['result']?.toString().toLowerCase() ?? '';
    switch (result) {
      case 'won':
        return '🎉 Won';
      case 'lost':
        return '😔 Lost';
      case 'tied':
        return '🤝 Tied';
      default:
        return 'Ongoing';
    }
  }

  Color _getResultColor(BuildContext context) {
    final result = match['result']?.toString().toLowerCase() ?? '';
    switch (result) {
      case 'won':
        return Colors.green.shade400;
      case 'lost':
        return Colors.red.shade400;
      case 'tied':
        return Colors.orange.shade400;
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final opponentName = match['opponentName']?.toString() ?? 'CPU';
    final playerScore = match['playerScore'] ?? 0;
    final opponentScore = match['opponentScore'] ?? 0;
    final gameMode = match['gameMode']?.toString() ?? 'unknown';
    final timestamp = match['createdAt'] as String?;

    final resultColor = _getResultColor(context);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Opponent and Result
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'vs $opponentName',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        gameMode.toUpperCase(),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.secondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(_getResultLabel()),
                  backgroundColor: resultColor.withAlpha(51),
                  labelStyle: TextStyle(
                    color: resultColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Score display
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        playerScore.toString(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'You',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                Text(
                  '—',
                  style: theme.textTheme.headlineSmall,
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        opponentScore.toString(),
                        style: theme.textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Opponent',
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Timestamp
            if (timestamp != null)
              Text(
                _formatTimestamp(timestamp),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.secondary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(String iso8601) {
    try {
      final date = DateTime.parse(iso8601);
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 1) {
        return 'just now';
      } else if (diff.inHours < 1) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inDays < 1) {
        return '${diff.inHours}h ago';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d ago';
      } else {
        return '${date.month}/${date.day}/${date.year}';
      }
    } catch (e) {
      return 'unknown';
    }
  }
}
