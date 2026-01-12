import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/riverpod_providers.dart';
import '../../../../game/providers/wallet_providers.dart';
import '../arcade_mission_models.dart';

class MissionDetailsModal {
  static Future<void> show(
      BuildContext context, {
        required WidgetRef ref,
        required ArcadeMission mission,
      }) async {
    final service = ref.read(arcadeMissionServiceProvider);
    final progress = service.progressFor(mission.id);
    final ratio = (progress.current / mission.target).clamp(0.0, 1.0);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0E0E12),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              14,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(mission: mission),
                const SizedBox(height: 12),

                Text(
                  mission.subtitle,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),

                _RewardRow(reward: mission.reward),
                const SizedBox(height: 14),

                Text(
                  'Progress',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),

                LinearProgressIndicator(
                  value: ratio,
                  backgroundColor: Colors.white.withOpacity(0.10),
                  color: Colors.amberAccent,
                  minHeight: 7,
                ),
                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      '${progress.current}/${mission.target}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    _StatusChip(
                      claimed: progress.claimed,
                      completed: progress.current >= mission.target,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.white.withOpacity(0.20)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        child: const Text(
                          'Close',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref2, __) {
                          // Re-read latest state to avoid stale UI if user opens modal after claiming elsewhere.
                          final svc = ref2.read(arcadeMissionServiceProvider);
                          final p = svc.progressFor(mission.id);

                          final canClaim = svc.canClaim(mission.id);

                          return ElevatedButton(
                            onPressed: canClaim
                                ? () {
                              final accepted = svc.tryClaim(mission.id);
                              if (!accepted) return;

                              // Award only if accepted (anti-double-claim protection)
                              incrementCoins(ref2, mission.reward.coins);
                              incrementGems(ref2, mission.reward.gems);
                              // If you have XP in your wallet providers:
                              // incrementXp(ref2, mission.reward.xp);

                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Mission claimed: +${mission.reward.coins} coins, +${mission.reward.gems} gems',
                                  ),
                                ),
                              );

                              Navigator.of(context).pop();
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: canClaim
                                  ? Colors.amberAccent
                                  : Colors.white.withOpacity(0.12),
                              foregroundColor: Colors.black,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: Text(
                              p.claimed
                                  ? 'Claimed'
                                  : (p.current >= mission.target ? 'Claim' : 'Not Ready'),
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  final ArcadeMission mission;

  const _Header({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            mission.title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 10),
        _TierBadge(tier: mission.tier),
      ],
    );
  }
}

class _TierBadge extends StatelessWidget {
  final ArcadeMissionTier tier;

  const _TierBadge({required this.tier});

  @override
  Widget build(BuildContext context) {
    final (label, bg) = switch (tier) {
      ArcadeMissionTier.daily => ('DAILY', const Color(0xFF10B981)),
      ArcadeMissionTier.weekly => ('WEEKLY', const Color(0xFFF59E0B)),
      ArcadeMissionTier.season => ('SEASON', const Color(0xFF6366F1)),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg.withOpacity(0.20),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: bg.withOpacity(0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: bg,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _RewardRow extends StatelessWidget {
  final ArcadeMissionReward reward;

  const _RewardRow({required this.reward});

  @override
  Widget build(BuildContext context) {
    Widget pill(String text, IconData icon) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.06),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: Colors.white.withOpacity(0.85)),
            const SizedBox(width: 6),
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        pill('+${reward.coins} Coins', Icons.monetization_on_rounded),
        pill('+${reward.gems} Gems', Icons.diamond_rounded),
        if (reward.xp > 0) pill('+${reward.xp} XP', Icons.bolt_rounded),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool claimed;
  final bool completed;

  const _StatusChip({
    required this.claimed,
    required this.completed,
  });

  @override
  Widget build(BuildContext context) {
    final (text, color) = claimed
        ? ('CLAIMED', const Color(0xFF10B981))
        : completed
        ? ('READY', const Color(0xFFFBBF24))
        : ('IN PROGRESS', Colors.white54);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.40)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w900,
          fontSize: 11,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
