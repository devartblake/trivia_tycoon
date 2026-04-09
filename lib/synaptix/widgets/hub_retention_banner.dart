import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../arcade/providers/arcade_providers.dart';
import '../../screens/question/widgets/challenges/daily_quiz_widget.dart';
import '../mode/synaptix_mode.dart';
import '../mode/synaptix_mode_provider.dart';
import '../theme/synaptix_theme_extension.dart';

/// A retention banner shown on the Hub to encourage daily return.
///
/// Displays:
/// - Daily bonus claim CTA (if unclaimed)
/// - Current streak with visual emphasis
/// - Bonus challenge prompt (links to daily quiz if available)
///
/// Hides itself when the daily bonus is already claimed AND the daily quiz
/// is already completed — the user has done everything for today.
class HubRetentionBanner extends ConsumerWidget {
  const HubRetentionBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bonus = ref.watch(arcadeDailyBonusServiceProvider);
    final quizStatus = ref.watch(dailyQuizStatusProvider);
    final mode = ref.watch(synaptixModeProvider);
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final radius = synaptix?.cardRadius ?? 16.0;

    final bonusClaimed = bonus.isClaimedToday;
    final quizDone = !quizStatus.canPlay;

    // Nothing to prompt — user completed everything today
    if (bonusClaimed && quizDone) return const SizedBox.shrink();

    final streak = bonus.currentStreak;
    final todayCoins = bonus.todayCoins;
    final todayGems = bonus.todayGems;

    final isKids = mode == SynaptixMode.kids;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A3E), Color(0xFF2D1B69)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x44B388FF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF7C3AED).withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row with streak badge
          Row(
            children: [
              Icon(
                isKids ? Icons.star_rounded : Icons.local_fire_department,
                color: const Color(0xFFFF6B00),
                size: 24,
              ),
              const SizedBox(width: 8),
              Text(
                isKids ? 'Welcome Back, Champion!' : 'Daily Rewards',
                style: const TextStyle(
                  fontFamily: 'OpenSans',
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (streak > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B00), Color(0xFFFF8C00)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$streak day${streak == 1 ? '' : 's'}',
                    style: const TextStyle(
                      fontFamily: 'OpenSans',
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Action buttons row
          Row(
            children: [
              // Daily bonus claim
              if (!bonusClaimed)
                Expanded(
                  child: _ActionChip(
                    icon: Icons.card_giftcard_rounded,
                    label: 'Claim $todayCoins coins + $todayGems gems',
                    color: const Color(0xFF50C878),
                    onTap: () {
                      bonus.tryClaimToday();
                      // Navigate to daily bonus screen for animation
                      context.push('/arcade/daily-bonus');
                    },
                  ),
                ),
              if (!bonusClaimed && quizStatus.canPlay)
                const SizedBox(width: 10),
              // Bonus challenge
              if (quizStatus.canPlay)
                Expanded(
                  child: _ActionChip(
                    icon: Icons.bolt_rounded,
                    label: isKids ? 'Bonus Challenge!' : 'Bonus Quiz',
                    color: const Color(0xFF6366F1),
                    onTap: () => context.push('/daily-quiz'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
