import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../layout/synaptix_panel.dart';

class DailyRewardCard extends StatelessWidget {
  final SynaptixRewardPrompt prompt;

  const DailyRewardCard({super.key, required this.prompt});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      minHeight: 86,
      onTap: () => context.go(prompt.route),
      child: Row(
        children: [
          Icon(prompt.icon, color: SynaptixHomeTheme.purple, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  prompt.title.toUpperCase(),
                  style: const TextStyle(
                    color: SynaptixHomeTheme.purple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  prompt.body,
                  style: const TextStyle(color: SynaptixHomeTheme.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
