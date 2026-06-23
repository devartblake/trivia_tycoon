import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/synaptix_home_theme.dart';
import '../layout/synaptix_panel.dart';

class CompleteProfileCard extends StatelessWidget {
  const CompleteProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      onTap: () => context.go('/onboarding'),
      child: Row(
        children: [
          const Icon(
            Icons.assignment_ind_rounded,
            color: SynaptixHomeTheme.gold,
            size: 34,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPLETE YOUR PROFILE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Finish setup to personalize missions, rewards, and recommendations.',
                  style: TextStyle(color: SynaptixHomeTheme.muted),
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
