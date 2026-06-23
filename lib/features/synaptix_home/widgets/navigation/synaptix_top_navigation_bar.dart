import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/navigation/canonical_routes.dart';
import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import 'synaptix_logo_mark.dart';

class SynaptixTopNavigationBar extends StatelessWidget {
  final SynaptixHomeState home;
  final bool isCompact;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  const SynaptixTopNavigationBar({
    super.key,
    required this.home,
    required this.isCompact,
    this.showMenuButton = false,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 24),
      decoration: BoxDecoration(
        color: SynaptixHomeTheme.panel.withValues(alpha: 0.72),
        border: Border(
          bottom: BorderSide(
            color: SynaptixHomeTheme.stroke.withValues(alpha: 0.65),
          ),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            Tooltip(
              message: 'Open navigation menu',
              child: IconButton.filledTonal(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: SynaptixHomeTheme.panelAlt.withValues(alpha: 0.92),
                  fixedSize: const Size.square(40),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const SynaptixLogoMark(),
          if (!isCompact) ...[
            const SizedBox(width: 12),
            const Text(
              'SYNAPTIX',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
          if (!isCompact) ...[
            const SizedBox(width: 32),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final destination in canonicalPrimaryNavRoutes)
                      _TopNavItem(destination: destination),
                    _TopNavItem(
                      destination: CanonicalNavDestination(
                        label: 'Rewards',
                        icon: Icons.card_giftcard_rounded,
                        route: canonicalRewardsRoute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            const Spacer(),
          _CurrencyPill(
            icon: Icons.monetization_on_rounded,
            value: home.player.coins.toString(),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 10),
            _CurrencyPill(
              icon: Icons.diamond_rounded,
              value: home.player.gems.toString(),
            ),
          ],
          const SizedBox(width: 12),
          _CircleIconButton(
            icon: Icons.message_rounded,
            route: canonicalMessagesRoute,
            tooltip: 'Messages',
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            icon: Icons.settings_rounded,
            route: canonicalSettingsRoute,
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
}

class _TopNavItem extends StatelessWidget {
  final CanonicalNavDestination destination;

  const _TopNavItem({required this.destination});

  @override
  Widget build(BuildContext context) {
    final selected = GoRouterState.of(context).uri.path == destination.route;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(destination.route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? SynaptixHomeTheme.purple.withValues(alpha: 0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: SynaptixHomeTheme.purple.withValues(alpha: 0.55))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                destination.icon,
                color: selected ? Colors.white : SynaptixHomeTheme.muted,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                destination.label.toUpperCase(),
                style: TextStyle(
                  color: selected ? Colors.white : SynaptixHomeTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final IconData icon;
  final String value;

  const _CurrencyPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final iconColor = icon == Icons.diamond_rounded
        ? SynaptixHomeTheme.blue
        : SynaptixHomeTheme.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SynaptixHomeTheme.panelAlt.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: const Border.all(color: SynaptixHomeTheme.stroke),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String route;
  final String tooltip;

  const _CircleIconButton({
    required this.icon,
    required this.route,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: () => context.go(route),
        icon: Icon(icon),
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: SynaptixHomeTheme.panelAlt.withValues(alpha: 0.92),
          fixedSize: const Size.square(40),
        ),
      ),
    );
  }
}
