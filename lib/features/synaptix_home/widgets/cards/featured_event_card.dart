import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../layout/synaptix_panel.dart';

class FeaturedEventCard extends StatelessWidget {
  final SynaptixFeaturedEvent event;

  const FeaturedEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      minHeight: 210,
      onTap: () => context.go(event.route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF32105F), Color(0xFF06264D)],
              ),
            ),
            child: Center(
              child: Icon(event.icon, color: Colors.white, size: 42),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            event.title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.subtitle,
            style: const TextStyle(color: SynaptixHomeTheme.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.timer_rounded,
                color: SynaptixHomeTheme.blue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                event.timeRemaining,
                style: const TextStyle(color: SynaptixHomeTheme.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
