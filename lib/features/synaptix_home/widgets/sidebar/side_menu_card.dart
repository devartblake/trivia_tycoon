import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/canonical_routes.dart';
import '../../theme/synaptix_home_theme.dart';
import '../layout/synaptix_panel.dart';

class SideMenuCard extends StatelessWidget {
  const SideMenuCard({super.key});

  @override
  Widget build(BuildContext context) {
    final destinations = <CanonicalNavDestination>[
      CanonicalNavDestination(
        label: 'Dashboard',
        icon: Icons.dashboard_rounded,
        route: canonicalHomeRoute,
      ),
      CanonicalNavDestination(
        label: 'Profile',
        icon: Icons.person_rounded,
        route: canonicalJourneyRoute,
      ),
      CanonicalNavDestination(
        label: 'Store',
        icon: Icons.inventory_2_rounded,
        route: canonicalStoreRoute,
      ),
      CanonicalNavDestination(
        label: 'Rewards',
        icon: Icons.card_giftcard_rounded,
        route: canonicalRewardsRoute,
      ),
      CanonicalNavDestination(
        label: 'Skill Tree',
        icon: Icons.account_tree_rounded,
        route: '/skills',
      ),
      CanonicalNavDestination(
        label: 'Arcade',
        icon: Icons.sports_esports_rounded,
        route: canonicalLabsRoute,
      ),
      CanonicalNavDestination(
        label: 'Settings',
        icon: Icons.settings_rounded,
        route: canonicalSettingsRoute,
      ),
    ];

    return SynaptixPanel(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (final destination in destinations)
            _SideNavItem(destination: destination),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final CanonicalNavDestination destination;

  const _SideNavItem({required this.destination});

  @override
  Widget build(BuildContext context) {
    final selected = GoRouterState.of(context).uri.path == destination.route;
    final router = GoRouter.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
        }
        router.go(destination.route);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF6426C7), Color(0xFF240D69)],
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              destination.icon,
              color: selected ? Colors.white : SynaptixHomeTheme.muted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                destination.label.toUpperCase(),
                style: TextStyle(
                  color: selected ? Colors.white : SynaptixHomeTheme.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}
