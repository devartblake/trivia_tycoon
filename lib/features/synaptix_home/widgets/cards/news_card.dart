import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../layout/synaptix_panel.dart';

class NewsCard extends StatelessWidget {
  final SynaptixNewsItem item;

  const NewsCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      minHeight: 86,
      onTap: () => context.go(item.route),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title.toUpperCase(),
                  style: const TextStyle(
                    color: SynaptixHomeTheme.purple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.body,
                  style: const TextStyle(color: SynaptixHomeTheme.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: SynaptixHomeTheme.muted),
        ],
      ),
    );
  }
}
