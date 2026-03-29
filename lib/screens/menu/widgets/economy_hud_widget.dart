import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/economy_providers.dart';
import '../../../game/providers/profile_providers.dart';

/// Compact HUD bar showing live energy, daily ticket availability, and a
/// subtle pity-active dot.  Intended for the main menu header area.
///
/// Refresh triggers are handled by the caller (app-resume, post-match, etc.)
/// via [EconomyNotifier.fetchState].
class EconomyHudWidget extends ConsumerStatefulWidget {
  const EconomyHudWidget({super.key});

  @override
  ConsumerState<EconomyHudWidget> createState() => _EconomyHudWidgetState();
}

class _EconomyHudWidgetState extends ConsumerState<EconomyHudWidget> {
  Timer? _regenTimer;

  @override
  void initState() {
    super.initState();
    // Tick every minute so the regen countdown stays live.
    _regenTimer = Timer.periodic(
      const Duration(minutes: 1),
      (_) => setState(() {}),
    );
  }

  @override
  void dispose() {
    _regenTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final energy = ref.watch(energyProvider);
    final economy = ref.watch(economyProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Energy pill ──────────────────────────────────────────────────
        _EnergyPill(
          current: energy.current,
          max: energy.max,
          regenInterval: energy.refillInterval,
          lastRefill: energy.lastRefillTime,
          colorScheme: colorScheme,
        ),
        // ── Daily ticket badge ───────────────────────────────────────────
        if (economy.dailyTicketAvailable) ...[
          const SizedBox(width: 8),
          _TicketBadge(count: economy.dailyTicketsRemaining),
        ],
        // ── Pity hint dot ────────────────────────────────────────────────
        if (economy.pityActive) ...[
          const SizedBox(width: 6),
          const _PityHintDot(),
        ],
        // ── Offline indicator ────────────────────────────────────────────
        if (economy.isOffline) ...[
          const SizedBox(width: 6),
          const _OfflineDot(),
        ],
      ],
    );
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────

class _EnergyPill extends StatelessWidget {
  final int current;
  final int max;
  final Duration regenInterval;
  final DateTime? lastRefill;
  final ColorScheme colorScheme;

  const _EnergyPill({
    required this.current,
    required this.max,
    required this.regenInterval,
    required this.lastRefill,
    required this.colorScheme,
  });

  String _regenText() {
    if (current >= max) return 'Full';
    final mins = regenInterval.inMinutes;
    if (mins < 60) return '+1 every ${mins}m';
    final hrs = regenInterval.inHours;
    final rem = mins - hrs * 60;
    return rem == 0 ? '+1 every ${hrs}h' : '+1 every ${hrs}h ${rem}m';
  }

  @override
  Widget build(BuildContext context) {
    final fraction = max > 0 ? current / max : 0.0;
    final energyColor = fraction > 0.5
        ? const Color(0xFF4CAF50)
        : fraction > 0.25
            ? const Color(0xFFFFC107)
            : const Color(0xFFF44336);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: energyColor.withOpacity(0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 16, color: energyColor),
          const SizedBox(width: 4),
          Text(
            '$current/$max',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: energyColor,
            ),
          ),
          if (current < max) ...[
            const SizedBox(width: 6),
            Text(
              _regenText(),
              style: TextStyle(
                fontSize: 11,
                color: colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TicketBadge extends StatelessWidget {
  final int count;

  const _TicketBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD700).withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFD700).withOpacity(0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.confirmation_number_outlined,
              size: 14, color: Color(0xFFFFD700)),
          const SizedBox(width: 4),
          Text(
            count == 1 ? '1 ticket' : '$count tickets',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFFFFD700),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small cloud-off icon shown when economy data is stale (fetch failed but
/// cached data is available).  Tapping shows a tooltip with the reason.
class _OfflineDot extends StatelessWidget {
  const _OfflineDot();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Economy data may be outdated',
      child: Icon(
        Icons.cloud_off_outlined,
        size: 14,
        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.45),
      ),
    );
  }
}

/// Tiny amber dot hinting that pity protection is active without overexposing
/// the mechanic.
class _PityHintDot extends StatelessWidget {
  const _PityHintDot();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Luck boost active',
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: Color(0xFFFF9800),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}
