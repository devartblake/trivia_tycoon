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
          top: BorderSide(
              color: SynaptixHomeTheme.stroke.withValues(alpha: 0.72)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // The Synaptix right panel already owns the FriendsOnlineCard, and
          // it is shown alongside the dashboard in the wide (side panel) and
          // narrow (inline) layouts. Only the medium layout hides that panel,
          // so the footer surfaces Friends solely there to avoid rendering the
          // same card twice on one screen.
          final showFriends = isMedium && !isWide;

          // A three/two-card row needs real width; below this the cards are
          // uncomfortably narrow, so stack them. This also keeps the footer
          // clear of the horizontal RenderFlex overflow the old fixed-width
          // wide layout produced inside the constrained main column.
          if (constraints.maxWidth >= 520) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showFriends) ...[
                  Expanded(
                    flex: 4,
                    child: FriendsOnlineCard(friends: home.friends),
                  ),
                  const SizedBox(width: 16),
                ],
                Expanded(flex: 7, child: NewsCard(item: home.newsItem)),
                const SizedBox(width: 16),
                Expanded(
                  flex: 5,
                  child: DailyRewardCard(prompt: home.dailyReward),
                ),
              ],
            );
          }

          return Column(
            children: [
              if (showFriends) ...[
                FriendsOnlineCard(friends: home.friends),
                const SizedBox(height: 12),
              ],
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
