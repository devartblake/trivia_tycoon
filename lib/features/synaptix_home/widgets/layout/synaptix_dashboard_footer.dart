import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../cards/daily_reward_card.dart';
import '../cards/friends_online_card.dart';
import '../cards/news_card.dart';

class SynaptixDashboardFooter extends StatelessWidget {
  final SynaptixHomeState home;
  final bool isWide;
  final bool isMedium;

  const SynaptixDashboardFooter({
    super.key,
    required this.home,
    required this.isWide,
    required this.isMedium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, isWide ? 20 : 16),
      decoration: BoxDecoration(
        color: SynaptixHomeTheme.page.withValues(alpha: 0.78),
        border: Border(
          top: BorderSide(color: SynaptixHomeTheme.stroke.withValues(alpha: 0.72)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 240,
                  child: FriendsOnlineCard(friends: home.friends),
                ),
                const SizedBox(width: 20),
                Expanded(flex: 7, child: NewsCard(item: home.newsItem)),
                const SizedBox(width: 20),
                SizedBox(
                  width: 340,
                  child: DailyRewardCard(prompt: home.dailyReward),
                ),
              ],
            );
          }

          if (isMedium && constraints.maxWidth >= 760) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: FriendsOnlineCard(friends: home.friends)),
                const SizedBox(width: 16),
                Expanded(child: NewsCard(item: home.newsItem)),
                const SizedBox(width: 16),
                Expanded(child: DailyRewardCard(prompt: home.dailyReward)),
              ],
            );
          }

          return Column(
            children: [
              FriendsOnlineCard(friends: home.friends),
              const SizedBox(height: 12),
              NewsCard(item: home.newsItem),
              const SizedBox(height: 12),
              DailyRewardCard(prompt: home.dailyReward),
            ],
          );
        },
      ),
    );
  }
}
