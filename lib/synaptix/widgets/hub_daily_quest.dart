import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../screens/question/widgets/challenges/daily_quiz_widget.dart';
import '../theme/synaptix_theme_extension.dart';

/// Neo-skeuomorphic daily quest progress card for the Synaptix Hub.
///
/// Reads from [dailyQuizStatusProvider] and [dailyQuizProvider] for real
/// quest progress, streak, and availability data.
class HubDailyQuest extends ConsumerWidget {
  const HubDailyQuest({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final radius = synaptix?.cardRadius ?? 16.0;

    final status = ref.watch(dailyQuizStatusProvider);
    final quizAsync = ref.watch(dailyQuizProvider);

    // Derive display values from providers
    final completed = status.canPlay ? 0 : quizAsync.maybeWhen(
      data: (d) => d.totalQuestions,
      orElse: () => 0,
    );
    final total = quizAsync.maybeWhen(
      data: (d) => d.totalQuestions,
      orElse: () => 5,
    );
    final xpReward = quizAsync.maybeWhen(
      data: (d) => d.totalXPReward,
      orElse: () => 75,
    );
    final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;

    final description = status.canPlay
        ? 'Answer $total questions to claim $xpReward XP.'
        : 'Completed! Resets in ${status.timeUntilReset}.';

    return GestureDetector(
      onTap: status.canPlay ? () => context.push('/daily-quiz') : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0x15FFFFFF),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: const Color(0x22FFFFFF), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF50C878), Color(0xFF3DA55C)],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'DAILY QUEST',
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.2,
                      ),
                    ),
                    if (status.completionStreak > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0x33FF6B00),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${status.completionStreak} streak',
                          style: const TextStyle(
                            fontFamily: 'OpenSans',
                            color: Color(0xFFFF6B00),
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  '$completed/$total',
                  style: const TextStyle(
                    fontFamily: 'OpenSans',
                    color: Color(0xFF50C878),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: const Color(0x1AFFFFFF),
                color: status.canPlay
                    ? const Color(0xFF50C878)
                    : const Color(0xFF6366F1),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              description,
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
