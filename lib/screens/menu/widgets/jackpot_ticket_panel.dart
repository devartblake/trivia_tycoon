import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/economy_providers.dart';
import '../../../game/providers/profile_providers.dart';

/// Panel shown near the jackpot mode card.
///
/// Shows a "Claim Daily Ticket" button when a ticket is available, and
/// switches to a disabled "Ticket Claimed" state after the limit is reached.
class JackpotTicketPanel extends ConsumerWidget {
  const JackpotTicketPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final economy = ref.watch(economyProvider);
    final available = economy.dailyTicketAvailable;
    final remaining = economy.dailyTicketsRemaining;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: available
          ? _ClaimButton(key: const ValueKey('claim'), remaining: remaining)
          : const _ClaimedButton(key: ValueKey('claimed')),
    );
  }
}

class _ClaimButton extends ConsumerWidget {
  final int remaining;

  const _ClaimButton({super.key, required this.remaining});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black87,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      icon: const Icon(Icons.confirmation_number_outlined, size: 18),
      label: Text(
        remaining == 1
            ? 'Claim Daily Ticket'
            : 'Claim Ticket ($remaining left)',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      onPressed: () async {
        final playerId = await ref.read(currentUserIdProvider.future);
        final result =
            await ref.read(economyProvider.notifier).claimTicket(playerId);
        if (!context.mounted) return;
        if (!result.success && result.denyReason != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result.denyReason!),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
    );
  }
}

class _ClaimedButton extends StatelessWidget {
  const _ClaimedButton({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Come back tomorrow for another free ticket',
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.grey,
          side: const BorderSide(color: Colors.grey),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
        icon: const Icon(Icons.check_circle_outline, size: 18),
        label: const Text(
          'Ticket Claimed',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        onPressed: null,
      ),
    );
  }
}
