import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../game/models/champion_event.dart';
import '../../../game/providers/arcade_providers.dart';
import '../../../game/providers/core_providers.dart' show apiServiceProvider;
import '../../../game/providers/learning_providers.dart' show currentPlayerIdProvider;

/// Weekly "Champion vs Tier" headline card: the tier's #1 defends the crown
/// against 99 challengers, and every elimination grows the jackpot. Hides
/// itself when there's no active event.
class ChampionVsTierCard extends ConsumerWidget {
  const ChampionVsTierCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(championEventProvider).valueOrNull;
    if (event == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: _Card(event: event),
    );
  }
}

class _Card extends ConsumerStatefulWidget {
  const _Card({required this.event});
  final ChampionEvent event;

  @override
  ConsumerState<_Card> createState() => _CardState();
}

class _CardState extends ConsumerState<_Card> {
  bool _entering = false;

  Future<void> _enter() async {
    final event = widget.event;
    final playerId = await ref.read(currentPlayerIdProvider.future);
    if (playerId == null || playerId.isEmpty) return;
    setState(() => _entering = true);
    try {
      final status = await ref.read(apiServiceProvider).enterGameEvent(
            eventId: const Uuid().v4(),
            gameEventId: event.id,
            playerId: playerId,
          );
      if (!mounted) return;
      final ok = status == 'Entered' || status == 'Duplicate';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(ok
            ? "You're in the arena — good luck!"
            : 'Could not enter: $status'),
        backgroundColor: ok ? const Color(0xFF10B981) : const Color(0xFFEF4444),
      ));
      if (ok) ref.invalidate(championEventProvider);
    } finally {
      if (mounted) setState(() => _entering = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final event = widget.event;
    final playerId = ref.watch(currentPlayerIdProvider).valueOrNull;
    final isChampion =
        event.championPlayerId != null && event.championPlayerId == playerId;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B0764), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFA855F7), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded,
                  color: Color(0xFFFCD34D), size: 28),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Champion vs Tier',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              _StatusPill(status: event.status),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'The tier #1 defends the crown against 99 challengers. '
            'Every elimination grows the jackpot.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 12.5,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _Stat(
                label: 'Jackpot',
                value: NumberFormat.decimalPattern().format(event.displayJackpot),
                icon: Icons.savings_rounded,
                accent: const Color(0xFFFCD34D),
              ),
              const SizedBox(width: 20),
              if (event.jackpotMultiplier > 1.0)
                _Stat(
                  label: 'Sponsor',
                  value: '${event.jackpotMultiplier.toStringAsFixed(1)}×',
                  icon: Icons.bolt_rounded,
                  accent: const Color(0xFF34D399),
                ),
              if (event.aliveCount > 0) ...[
                const SizedBox(width: 20),
                _Stat(
                  label: 'Alive',
                  value: '${event.aliveCount}',
                  icon: Icons.groups_rounded,
                  accent: Colors.white,
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          if (isChampion)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFFCD34D).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFCD34D)),
              ),
              child: const Text(
                '👑 You are the Champion — defend your crown!',
                style: TextStyle(
                  color: Color(0xFFFCD34D),
                  fontWeight: FontWeight.w800,
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (event.isOpenForEntry && !_entering) ? _enter : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFCD34D),
                  foregroundColor: const Color(0xFF3B0764),
                  disabledBackgroundColor: Colors.white24,
                  disabledForegroundColor: Colors.white60,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _entering
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(
                        event.isOpenForEntry
                            ? (event.entryFeeCoins > 0
                                ? 'Challenge the Champion — ${event.entryFeeCoins} coins'
                                : 'Challenge the Champion')
                            : event.isLive
                                ? 'Battle in progress'
                                : 'Opens ${DateFormat('MMM d, h:mm a').format(event.scheduledAtUtc.toLocal())}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      'Live' => ('LIVE', const Color(0xFFEF4444)),
      'Open' => ('OPEN', const Color(0xFF10B981)),
      'Closed' => ('ENDED', Colors.white38),
      _ => ('SOON', const Color(0xFFA855F7)),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontSize: 11, fontWeight: FontWeight.w900),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 15, color: accent),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                color: accent,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.7),
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}
