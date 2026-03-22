import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/economy_providers.dart';
import '../../../game/providers/profile_providers.dart';

/// Wraps any mode button/card with economy-aware CTA logic.
///
/// - Shows a cost badge (energy units or ticket icon).
/// - Overlays a discount chip when a session-start discount is active.
/// - Greys out and blocks tap when policy disallows entry.
/// - Shows a user-friendly snackbar on 409 denial.
///
/// Usage:
/// ```dart
/// ModeEntryCard(
///   mode: 'ranked',
///   onEnter: () => context.push('/ranked'),
///   child: ExistingModeCardWidget(),
/// )
/// ```
class ModeEntryCard extends ConsumerWidget {
  final String mode;
  final Widget child;

  /// Called after the economy session is confirmed and the match-start
  /// policy check passes. Navigate or launch the game inside this callback.
  final VoidCallback? onEnter;

  const ModeEntryCard({
    super.key,
    required this.mode,
    required this.child,
    this.onEnter,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cost = ref.watch(modeCostProvider(mode));
    final denyReason = ref.watch(modeDenyReasonProvider(mode));
    final available = cost?.available ?? true;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        // ── Underlying card (dimmed when unavailable) ────────────────────
        IgnorePointer(
          ignoring: !available,
          child: AnimatedOpacity(
            opacity: available ? 1.0 : 0.45,
            duration: const Duration(milliseconds: 200),
            child: child,
          ),
        ),
        // ── Cost badge (top-right corner) ────────────────────────────────
        if (cost != null)
          Positioned(
            top: -6,
            right: -6,
            child: _CostBadge(cost: cost),
          ),
        // ── Discount chip (below cost badge) ────────────────────────────
        if (cost?.hasDiscount == true)
          Positioned(
            top: 18,
            right: -6,
            child: _DiscountChip(
                base: cost!.baseCost, adjusted: cost.adjustedCost!),
          ),
        // ── Tap handler ──────────────────────────────────────────────────
        Positioned.fill(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _onTap(context, ref, available, denyReason),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onTap(
    BuildContext context,
    WidgetRef ref,
    bool available,
    String? denyReason,
  ) async {
    if (!available) {
      _showDenySnackbar(context, denyReason ?? 'Mode unavailable right now');
      return;
    }
    await _confirmAndEnter(context, ref);
  }

  Future<void> _confirmAndEnter(BuildContext context, WidgetRef ref) async {
    final playerId = await ref.read(currentUserIdProvider.future);

    // 1. Start economy session → receives any active discount costs.
    await ref.read(economyProvider.notifier).startSession(playerId, mode);

    // 2. Policy-enforced match start (handles 409 internally).
    final result =
        await ref.read(economyProvider.notifier).enterMode(playerId, mode);

    if (!context.mounted) return;

    if (result.started) {
      onEnter?.call();
    } else {
      _showDenySnackbar(context, _mapDenyReason(result.denyReason));
    }
  }

  static void _showDenySnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static String _mapDenyReason(String? raw) {
    final lower = raw?.toLowerCase() ?? '';
    if (lower.contains('energy')) return 'Not enough energy';
    if (lower.contains('ticket')) return 'No ticket available';
    return 'Mode unavailable right now';
  }
}

// ── Private sub-widgets ──────────────────────────────────────────────────────

class _CostBadge extends StatelessWidget {
  final ModeCostDto cost;

  const _CostBadge({required this.cost});

  @override
  Widget build(BuildContext context) {
    final isTicket = cost.costType == 'ticket';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isTicket
            ? const Color(0xFFFFD700)
            : Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTicket ? Icons.confirmation_number : Icons.bolt,
            size: 12,
            color: isTicket
                ? Colors.black87
                : Theme.of(context).colorScheme.onPrimaryContainer,
          ),
          const SizedBox(width: 2),
          Text(
            '${cost.effectiveCost}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isTicket
                  ? Colors.black87
                  : Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ],
      ),
    );
  }
}

class _DiscountChip extends StatelessWidget {
  final int base;
  final int adjusted;

  const _DiscountChip({required this.base, required this.adjusted});

  @override
  Widget build(BuildContext context) {
    final pct = ((1 - adjusted / base) * 100).round();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFF4CAF50),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '-$pct%',
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }
}

// Re-export for callers that import this file.
export '../../../core/dto/economy_dto.dart' show ModeCostDto;
