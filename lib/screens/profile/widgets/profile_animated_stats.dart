import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/settings/multi_profile_service.dart';
import '../../../game/providers/multi_profile_providers.dart';
import '../../../game/services/educational_stats_service.dart';
import './animated_state_box.dart';

/// Three animated stat boxes (Quizzes / Correct / Streak).
class ProfileAnimatedStats extends ConsumerWidget {
  const ProfileAnimatedStats({super.key, required this.profile});

  final ProfileData profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final educationalStatsAsync = ref.watch(educationalStatsProvider);
    final profileStats = ref.watch(activeProfileStatsProvider);

    return educationalStatsAsync.when(
      data: (stats) => _buildRow(
        quizzes: profileStats['totalQuizzes'] ?? stats.totalQuizzes,
        correct: profileStats['correctAnswers'] ?? stats.correctAnswers,
        streak: profileStats['currentStreak'] ?? stats.currentStreak,
      ),
      loading: () => _buildRow(
        quizzes: profileStats['totalQuizzes'] ?? 0,
        correct: profileStats['correctAnswers'] ?? 0,
        streak: profileStats['currentStreak'] ?? 0,
      ),
      error: (_, __) => _buildRow(
        quizzes: profileStats['totalQuizzes'] ?? 0,
        correct: profileStats['correctAnswers'] ?? 0,
        streak: profileStats['currentStreak'] ?? 0,
      ),
    );
  }

  Widget _buildRow({
    required int quizzes,
    required int correct,
    required int streak,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: AnimatedStatBox(
            label: 'Quizzes',
            value: quizzes,
            gradientColors: const [Color(0xFF40E0D0), Color(0xFF00CED1)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedStatBox(
            label: 'Correct',
            value: correct,
            gradientColors: const [Color(0xFF26de81), Color(0xFF20bf6b)],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: AnimatedStatBox(
            label: 'Streak',
            value: streak,
            gradientColors: const [Color(0xFFFF6B6B), Color(0xFFEE5A24)],
          ),
        ),
      ],
    );
  }
}