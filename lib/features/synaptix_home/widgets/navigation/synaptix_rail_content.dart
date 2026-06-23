import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import '../cards/friends_online_card.dart';
import '../layout/synaptix_panel.dart';
import '../sidebar/side_menu_card.dart';
import '../sidebar/side_rank_card.dart';
import '../sidebar/side_refer_card.dart';
import '../sidebar/side_streak_card.dart';

class SynaptixRailContent extends StatelessWidget {
  final SynaptixHomeState home;

  const SynaptixRailContent({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SideMenuCard(),
        const SizedBox(height: 20),
        SideRankCard(player: home.player),
        const SizedBox(height: 20),
        SideStreakCard(player: home.player),
        const SizedBox(height: 20),
        const SideReferCard(),
      ],
    );
  }
}

class SynaptixRightPanel extends StatelessWidget {
  final SynaptixHomeState home;

  const SynaptixRightPanel({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SynaptixPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'QUICK STATS',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${home.player.wins}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Wins',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text(
                          '${home.player.streak}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Streak',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FriendsOnlineCard(friends: home.friends),
      ],
    );
  }
}
