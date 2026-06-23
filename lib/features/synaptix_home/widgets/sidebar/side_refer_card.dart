import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../theme/synaptix_home_theme.dart';
import '../layout/synaptix_panel.dart';

class SideReferCard extends StatelessWidget {
  const SideReferCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      onTap: () => context.go('/invite'),
      child: const Row(
        children: [
          Icon(Icons.redeem_rounded, color: SynaptixHomeTheme.purple, size: 38),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REFER & EARN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Invite friends, earn rewards.',
                  style:
                      TextStyle(color: SynaptixHomeTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
