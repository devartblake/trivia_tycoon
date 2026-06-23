import 'package:flutter/material.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../components/synaptix_panel_header.dart';
import '../layout/synaptix_panel.dart';

class RecentActivityCard extends StatelessWidget {
  final List<SynaptixRecentActivity> items;

  const RecentActivityCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      minHeight: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SynaptixPanelHeader(title: 'RECENT PLAY', action: 'HISTORY'),
          const SizedBox(height: 12),
          for (final item in items)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: SynaptixHomeTheme.panelAlt,
                child: Icon(
                  Icons.history_rounded,
                  color: SynaptixHomeTheme.cyan,
                ),
              ),
              title: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                item.date,
                style: const TextStyle(color: SynaptixHomeTheme.muted),
              ),
              trailing: Text(
                item.score,
                style: const TextStyle(
                  color: SynaptixHomeTheme.green,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
