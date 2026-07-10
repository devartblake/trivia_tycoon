import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../components/synaptix_panel_header.dart';
import '../components/synaptix_progress_bar.dart';
import '../layout/synaptix_panel.dart';

class DailyMissionsCard extends StatelessWidget {
  final List<SynaptixHomeMission> missions;

  const DailyMissionsCard({super.key, required this.missions});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SynaptixPanelHeader(title: 'DAILY MISSIONS', action: 'LOCAL'),
          const SizedBox(height: 16),
          for (final mission in missions) _MissionTile(mission: mission),
        ],
      ),
    );
  }
}

class _MissionTile extends StatelessWidget {
  final SynaptixHomeMission mission;

  const _MissionTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SynaptixHomeTheme.panelAlt.withValues(alpha: 0.84),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: SynaptixHomeTheme.stroke.withValues(alpha: 0.75)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: SynaptixHomeTheme.purple.withValues(alpha: 0.82),
            child: Icon(mission.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                SynaptixProgressBar(value: mission.progress),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            mission.progressLabel,
            style:
                const TextStyle(color: SynaptixHomeTheme.muted, fontSize: 12),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.monetization_on_rounded,
            color: SynaptixHomeTheme.gold,
            size: 16,
          ),
          Text(
            '${mission.rewardCoins}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
