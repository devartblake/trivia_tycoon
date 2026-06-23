import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/synaptix_home_state.dart';
import '../../theme/synaptix_home_theme.dart';
import '../layout/synaptix_panel.dart';

class HeroTournamentCard extends StatelessWidget {
  final SynaptixHomeState home;

  const HeroTournamentCard({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    final showTrophy = MediaQuery.sizeOf(context).width >= 680;
    final event = home.featuredEvent;
    final titleWords = event.title.split(' ');
    final titleLine1 = titleWords.take((titleWords.length / 2).ceil()).join(' ');
    final titleLine2 = titleWords.skip((titleWords.length / 2).ceil()).join(' ');

    return SynaptixPanel(
      minHeight: 260,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: SynaptixHomeTheme.heroGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              if (showTrophy) ...[
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: RadialGradient(
                      colors: [
                        SynaptixHomeTheme.purple.withValues(alpha: 0.8),
                        SynaptixHomeTheme.blue.withValues(alpha: 0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      event.icon,
                      color: SynaptixHomeTheme.gold,
                      size: 128,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LiveBadge(label: event.timeRemaining),
                    const SizedBox(height: 18),
                    Text(
                      titleLine2.isEmpty ? titleLine1 : '$titleLine1\n$titleLine2',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome back, ${home.player.displayName}. ${event.subtitle}',
                      style: const TextStyle(
                        color: SynaptixHomeTheme.muted,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        _RewardMini(
                          icon: Icons.monetization_on_rounded,
                          title: event.rewardLabel,
                          subtitle: 'Prize Pool',
                        ),
                        _RewardMini(
                          icon: Icons.workspace_premium_rounded,
                          title: home.player.rankTier,
                          subtitle: 'Current Tier',
                        ),
                        _PrimaryGlowButton(
                          label: 'Join Tournament',
                          route: event.route,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  final String label;

  const _LiveBadge({this.label = 'LIVE NOW'});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: SynaptixHomeTheme.blue.withValues(alpha: 0.16),
        border: Border.all(color: SynaptixHomeTheme.blue),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: SynaptixHomeTheme.cyan,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RewardMini extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RewardMini({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: SynaptixHomeTheme.gold, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: SynaptixHomeTheme.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryGlowButton extends StatelessWidget {
  final String label;
  final String route;

  const _PrimaryGlowButton({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: SynaptixHomeTheme.buttonGradient,
        boxShadow: [
          BoxShadow(
            color: SynaptixHomeTheme.blue.withValues(alpha: 0.45),
            blurRadius: 20,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
