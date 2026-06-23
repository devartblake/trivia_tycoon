import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../components/synaptix_panel_header.dart';
import '../layout/synaptix_panel.dart';

class RecommendationsCard extends StatelessWidget {
  final List<SynaptixRecommendation> recommendations;
  final int rewards;

  const RecommendationsCard({
    super.key,
    required this.recommendations,
    required this.rewards,
  });

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      minHeight: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SynaptixPanelHeader(title: 'RECOMMENDED', action: '$rewards REWARDS'),
          const SizedBox(height: 12),
          for (final item in recommendations)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.icon, color: SynaptixHomeTheme.gold),
              title: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                item.subtitle,
                style: const TextStyle(color: SynaptixHomeTheme.muted),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: SynaptixHomeTheme.muted,
              ),
              onTap: () => context.go(item.route),
            ),
        ],
      ),
    );
  }
}
