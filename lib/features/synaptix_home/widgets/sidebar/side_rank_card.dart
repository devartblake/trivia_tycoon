import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../components/synaptix_progress_bar.dart';
import '../layout/synaptix_panel.dart';

class SideRankCard extends StatelessWidget {
  final SynaptixHomePlayer player;

  const SideRankCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Column(
        children: [
          const Text(
            'CURRENT RANK',
            style: TextStyle(color: SynaptixHomeTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            player.rankTier.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          const Icon(
            Icons.workspace_premium_rounded,
            color: SynaptixHomeTheme.purple,
            size: 86,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'RATING',
                  style: TextStyle(
                    color: SynaptixHomeTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${player.rating}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SynaptixProgressBar(value: player.xpProgress),
        ],
      ),
    );
  }
}
