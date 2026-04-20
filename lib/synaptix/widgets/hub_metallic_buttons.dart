import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/analytics/providers/analytics_providers.dart';
import '../mode/synaptix_mode_provider.dart';
import '../theme/synaptix_theme_extension.dart';
import '../utils/hub_feedback.dart';

/// Row of two metallic-style action buttons for the Synaptix Hub.
///
/// Each button has a 3D gradient effect with a subtle white sheen overlay
/// at the top and a deeper shadow at the bottom.
class HubMetallicButtons extends ConsumerWidget {
  const HubMetallicButtons({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const Row(
      children: [
        Expanded(
          child: _MetallicButton(
            label: 'TOURNAMENTS',
            icon: Icons.emoji_events_rounded,
            gradientColors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
            route: '/leaderboard',
            surface: 'tournaments',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _MetallicButton(
            label: 'PRIVATE DUEL',
            icon: Icons.flash_on_rounded,
            gradientColors: [Color(0xFFF59E0B), Color(0xFFD97706)],
            route: '/multiplayer',
            surface: 'private_duel',
          ),
        ),
      ],
    );
  }
}

class _MetallicButton extends ConsumerWidget {
  final String label;
  final IconData icon;
  final List<Color> gradientColors;
  final String route;
  final String surface;

  const _MetallicButton({
    required this.label,
    required this.icon,
    required this.gradientColors,
    required this.route,
    required this.surface,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final radius = synaptix?.cardRadius ?? 16.0;

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        playHubTapSound(ref);
        final mode = ref.read(synaptixModeProvider);
        ref
            .read(analyticsServiceProvider)
            .trackEvent('synaptix_hub_action_tapped', {
          'surface': surface,
          'synaptix_mode': mode.name,
          'entry_point': 'metallic_button',
          'audience_segment': mode.name,
        });
        context.push(route);
      },
      child: Container(
        height: 56,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradientColors,
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: gradientColors.first.withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: -5,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Metallic sheen overlay
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 24,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(radius)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            // Content
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'OpenSans',
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
