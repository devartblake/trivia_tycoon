import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import '../theme/synaptix_theme_extension.dart';

/// Compact XP/level progress snapshot for the Synaptix Hub.
class SynaptixProgressSnapshot extends ConsumerWidget {
  const SynaptixProgressSnapshot({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileService = ref.watch(playerProfileServiceProvider);
    final userProfile = profileService.getProfile();
    final level = userProfile['level'] ?? 0;
    final currentXP = userProfile['currentXP'] ?? 0;
    final maxXP = userProfile['maxXP'] ?? 500;
    final rank = userProfile['rank'] ?? 'Novice';
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final radius = synaptix?.cardRadius ?? 14.0;
    final accent = synaptix?.accentGlow ?? const Color(0xFF6366F1);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: accent.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Level $level',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  rank.toString(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: maxXP > 0 ? (currentXP / maxXP).clamp(0.0, 1.0) : 0,
              minHeight: 8,
              backgroundColor: accent.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '$currentXP / $maxXP XP',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}
