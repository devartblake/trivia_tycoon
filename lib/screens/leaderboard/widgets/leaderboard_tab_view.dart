import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/controllers/leaderboard_controller.dart';
import '../../../game/providers/riverpod_providers.dart';
import 'animated_leaderboard_list.dart';

class LeaderboardTabView extends ConsumerWidget {
  const LeaderboardTabView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(leaderboardControllerProvider);

    return DefaultTabController(
      length: LeaderboardCategory.values.length,
      child: Column(
        children: [
          TabBar(
            isScrollable: true,
            onTap: (index) {
              ref.read(leaderboardControllerProvider).setCategory(
                LeaderboardCategory.values[index],
              );
            },
            tabs: LeaderboardCategory.values.map((e) => Tab(text: _getLabel(e))).toList(),
          ),
          Expanded(
            child: controller.isLoading
                ? const Center(child: CircularProgressIndicator())
                : AnimatedLeaderboardList(entries: controller.filteredEntries),
          ),
        ],
      ),
    );
  }

  String _getLabel(LeaderboardCategory category) {
    switch (category) {
      case LeaderboardCategory.topXP:
        return "Top XP";
      case LeaderboardCategory.mostWins:
        return "Most Wins";
      case LeaderboardCategory.daily:
        return "Daily";
      case LeaderboardCategory.weekly:
        return "Weekly";
      case LeaderboardCategory.global:
        return "Global";
    }
  }
}
