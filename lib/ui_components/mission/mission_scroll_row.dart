import 'package:flutter/material.dart';
import 'widgets/mission_card_widget.dart';
// import 'mission_swap_button.dart';

class MissionScrollRow extends StatelessWidget {
  final List<MissionData> missions;
  final void Function(int index) onSwap;

  const MissionScrollRow({
    super.key,
    required this.missions,
    required this.onSwap,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
      child: Row(
        children: List.generate(missions.length, (index) {
          final mission = missions[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                MissionCard(
                  title: mission.title,
                  progress: mission.progress,
                  total: mission.total,
                  reward: mission.reward,
                  icon: mission.icon,
                  badge: mission.badge,
                  onSwap: () => onSwap(index),
                ),
                Positioned(
                  top: -10,
                  right: -10,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(scale: animation, child: child);
                    },
                    // child: MissionSwapButton(
                    //   key: ValueKey(mission.title),
                    //   onPressed: () => onSwap(index),
                    // ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }
}

class MissionData {
  final String title;
  final int progress;
  final int total;
  final int reward;
  final IconData icon;
  final String badge;

  MissionData({
    required this.title,
    required this.progress,
    required this.total,
    required this.reward,
    required this.icon,
    required this.badge,
  });
}

// Simulated dynamic mission fetcher
Future<MissionData> fetchNewMission() async {
  await Future.delayed(const Duration(seconds: 1));
  return MissionData(
    title: "New Mission!",
    progress: 0,
    total: 10,
    reward: 1000,
    icon: Icons.local_fire_department,
    badge: "🔥 Bonus",
  );
}
