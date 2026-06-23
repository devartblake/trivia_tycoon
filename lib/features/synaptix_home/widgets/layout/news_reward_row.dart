import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import '../cards/daily_reward_card.dart';
import '../cards/news_card.dart';

class NewsRewardRow extends StatelessWidget {
  final SynaptixNewsItem newsItem;
  final SynaptixRewardPrompt dailyReward;

  const NewsRewardRow({
    super.key,
    required this.newsItem,
    required this.dailyReward,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 720;
        final news = NewsCard(item: newsItem);
        final reward = DailyRewardCard(prompt: dailyReward);
        if (stack) {
          return Column(
            children: [
              news,
              const SizedBox(height: 16),
              reward,
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 2, child: news),
            const SizedBox(width: 16),
            Expanded(child: reward),
          ],
        );
      },
    );
  }
}
