import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../game/models/season_tiebreaker.dart';
import '../../../game/providers/arcade_providers.dart';

/// Banner shown when the player has a pending end-of-season tie-breaker.
/// Renders nothing while loading, on error, or when there is none — the
/// backend schedules and notifies; this is just the in-app surface.
class TiebreakerBanner extends ConsumerWidget {
  const TiebreakerBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiebreakers = ref.watch(myTiebreakersProvider).valueOrNull;
    if (tiebreakers == null || tiebreakers.isEmpty) {
      return const SizedBox.shrink();
    }
    final tiebreaker = tiebreakers.first;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: _TiebreakerCard(tiebreaker: tiebreaker),
    );
  }
}

class _TiebreakerCard extends StatelessWidget {
  const _TiebreakerCard({required this.tiebreaker});

  final SeasonTiebreaker tiebreaker;

  @override
  Widget build(BuildContext context) {
    final scheduled = tiebreaker.scheduledAtUtc.toLocal();
    final expires = tiebreaker.expiresAtUtc.toLocal();
    final now = DateTime.now();
    final playable = !now.isBefore(scheduled);
    final title = tiebreaker.isChampionship
        ? 'Championship tie-breaker!'
        : 'Promotion tie-breaker!';
    final subtitle = playable
        ? 'Your match is live — win it to lock in the contested rank. '
            'No-show by ${DateFormat('MMM d, h:mm a').format(expires)} forfeits.'
        : 'You are tied for a contested rank. Match opens '
            '${DateFormat('MMM d, h:mm a').format(scheduled)}.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF7C2D12), Color(0xFFB45309)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF59E0B), width: 1.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.emoji_events_rounded,
              color: Color(0xFFFCD34D), size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFFFDE68A),
                    fontSize: 12.5,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton(
            onPressed: playable ? () => context.push('/multiplayer') : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFCD34D),
              foregroundColor: const Color(0xFF7C2D12),
              disabledBackgroundColor: Colors.white24,
              disabledForegroundColor: Colors.white54,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              playable ? 'Play now' : 'Scheduled',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}
