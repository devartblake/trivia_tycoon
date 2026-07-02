import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Tier history timeline event
class TierHistoryEvent {
  final int tier;
  final String tierName;
  final DateTime timestamp;
  final String achievement; // "Tier Up", "Reward Claimed", etc.
  final Color tierColor;

  TierHistoryEvent({
    required this.tier,
    required this.tierName,
    required this.timestamp,
    required this.achievement,
    required this.tierColor,
  });
}

/// Timeline displaying tier progression history
class TierHistoryTimeline extends StatelessWidget {
  final List<TierHistoryEvent> events;
  final bool showDates;

  const TierHistoryTimeline({
    super.key,
    required this.events,
    this.showDates = true,
  });

  @override
  Widget build(BuildContext context) {
    if (events.isEmpty) {
      return _buildEmptyState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tier History',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final event = events[index];
            final isLast = index == events.length - 1;

            return _buildTimelineItem(
              context,
              event,
              isLast,
            );
          },
        ),
      ],
    );
  }

  /// Build individual timeline item
  Widget _buildTimelineItem(
    BuildContext context,
    TierHistoryEvent event,
    bool isLast,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Timeline dot and line
        SizedBox(
          width: 60,
          child: Column(
            children: [
              // Dot
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: event.tierColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: event.tierColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Line to next item
              if (!isLast)
                Container(
                  width: 2,
                  height: 80,
                  color: Colors.grey[300],
                  margin: const EdgeInsets.only(top: 4),
                ),
            ],
          ),
        ),

        // Content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2, left: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title and achievement
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        event.tierName,
                        style:
                            Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: event.tierColor,
                                ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: event.tierColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        event.achievement,
                        style:
                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                  color: event.tierColor,
                                  fontWeight: FontWeight.w600,
                                ),
                      ),
                    ),
                  ],
                ),

                if (showDates) ...[
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(event.timestamp),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],

                const SizedBox(height: 12),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Build empty state
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Icon(
              Icons.history,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No tier history yet',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Complete challenges to progress through tiers',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Colors.grey[500],
                  ),
            ),
          ],
        ),
      ),
    );
  }

  /// Format date for display
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final eventDate = DateTime(date.year, date.month, date.day);

    if (eventDate == today) {
      return 'Today at ${DateFormat('h:mm a').format(date)}';
    } else if (eventDate == yesterday) {
      return 'Yesterday at ${DateFormat('h:mm a').format(date)}';
    } else if (now.difference(date).inDays < 7) {
      final daysAgo = now.difference(date).inDays;
      return '$daysAgo day${daysAgo > 1 ? 's' : ''} ago';
    } else {
      return DateFormat('MMM d, yyyy').format(date);
    }
  }
}

/// Mock data generator for testing
List<TierHistoryEvent> generateMockTierHistory() {
  final now = DateTime.now();

  return [
    TierHistoryEvent(
      tier: 5,
      tierName: 'Tier 5: Master',
      timestamp: now.subtract(const Duration(hours: 2)),
      achievement: 'Tier Up',
      tierColor: Colors.amber,
    ),
    TierHistoryEvent(
      tier: 4,
      tierName: 'Tier 4: Expert',
      timestamp: now.subtract(const Duration(days: 1, hours: 5)),
      achievement: 'Tier Up',
      tierColor: Colors.orange,
    ),
    TierHistoryEvent(
      tier: 3,
      tierName: 'Tier 3: Advanced',
      timestamp: now.subtract(const Duration(days: 3, hours: 12)),
      achievement: 'Tier Up',
      tierColor: Colors.purple,
    ),
    TierHistoryEvent(
      tier: 2,
      tierName: 'Tier 2: Intermediate',
      timestamp: now.subtract(const Duration(days: 7)),
      achievement: 'Tier Up',
      tierColor: Colors.blue,
    ),
    TierHistoryEvent(
      tier: 1,
      tierName: 'Tier 1: Foundation',
      timestamp: now.subtract(const Duration(days: 14)),
      achievement: 'Started',
      tierColor: Colors.green,
    ),
  ];
}
