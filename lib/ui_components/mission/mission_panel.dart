import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../ui_components/mission/mission_card_widget.dart';
import '../../game/providers/xp_provider.dart';

class MissionPanel extends ConsumerStatefulWidget {
  final int playerXP;
  final Function(int xpGained) onXPAdded;

  const MissionPanel({
    super.key,
    required this.playerXP,
    required this.onXPAdded,
  });

  @override
  ConsumerState<MissionPanel> createState() => _MissionPanelState();
}

class _MissionPanelState extends ConsumerState<MissionPanel> {
  final List<Map<String, dynamic>> _missions = [
    {
      'title': "Answer 10 Science question correctly in Survival",
      'progress': 4,
      'total': 10,
      'reward': 500,
      'icon': Icons.science,
      'badge': "Science"
    },
    {
      'title': "Achieve 10 Streaks",
      'progress': 6,
      'total': 10,
      'reward': 1200,
      'icon': Icons.flash_on,
      'badge': "Streak Master"
    },
    {
      'title': "Answer 5 Topics",
      'progress': 5,
      'total': 5,
      'reward': 800,
      'icon': Icons.quiz,
      'badge': "Explorer"
    },
    {
      'title': "Answer 3 Geography questions correctly in Classic",
      'progress': 0,
      'total': 3,
      'reward': 500,
      'icon': Icons.science,
      'badge': "Daily",
    },
    {
      'title': "Achieve 5 Sports question in Classic",
      'progress': 1,
      'total': 5,
      'reward': 400,
      'icon': Icons.whatshot,
      'badge': "Streak",
    },
  ];

  void _handleSwap(int index) {
    setState(() {
      _missions[index] = {
        'title': "New Random Mission",
        'progress': 0,
        'total': 10,
        'reward': 700,
        'icon': Icons.shuffle,
        'badge': "Wildcard"
      };
    });
  }

  void _handleCompleteMission(int reward) {
    incrementXP(ref, reward);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("+$reward XP gained!"),
        backgroundColor: Colors.green.shade600,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentXP = ref.watch(playerXPProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("🎯 Missions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              Text("XP: $currentXP", style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
        SizedBox(
          height: 240,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            itemCount: _missions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final mission = _missions[index];
              return Stack (
                clipBehavior: Clip.none,
                children: [
                  GestureDetector(
                    onDoubleTap: mission['progress'] >= mission['total']
                        ? () => _handleCompleteMission(mission['reward'])
                        : null,
                    child: MissionCard(
                      title: mission['title'],
                      progress: mission['progress'],
                      total: mission['total'],
                      reward: mission['reward'],
                      icon: mission['icon'],
                      badge: mission['badge'],
                      onSwap: () => _handleSwap(index),
                    ),
                  ),
                ]
              );
            },
          ),
        ),
      ],
    );
  }
}
