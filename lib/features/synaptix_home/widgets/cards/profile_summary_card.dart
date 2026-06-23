import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../components/synaptix_progress_bar.dart';
import '../layout/synaptix_panel.dart';

class ProfileSummaryCard extends StatelessWidget {
  final SynaptixHomePlayer player;

  const ProfileSummaryCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: SynaptixHomeTheme.purple,
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player.title,
                      style: const TextStyle(color: SynaptixHomeTheme.muted),
                    ),
                    const SizedBox(height: 10),
                    SynaptixProgressBar(value: player.xpProgress),
                    const SizedBox(height: 6),
                    Text(
                      '${player.currentXp} / ${player.targetXp} XP',
                      style: const TextStyle(
                        color: SynaptixHomeTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _StatBlock(label: 'Wins', value: '${player.wins}')),
              Expanded(
                child: _StatBlock(label: 'Matches', value: '${player.matches}'),
              ),
              Expanded(
                child: _StatBlock(
                  label: 'Win Rate',
                  value: '${(player.winRate * 100).toStringAsFixed(0)}%',
                ),
              ),
              Expanded(
                  child: _StatBlock(label: 'Rank', value: '#${player.rank}')),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: SynaptixHomeTheme.muted, fontSize: 11),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
