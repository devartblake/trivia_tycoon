import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/analytics/providers/analytics_providers.dart';
import '../mode/synaptix_mode.dart';
import '../mode/synaptix_mode_provider.dart';
import '../theme/synaptix_theme_extension.dart';
import '../utils/hub_feedback.dart';

/// Reusable quick-launch card for the Synaptix Hub grid.
class SynaptixHubCard extends ConsumerWidget {
  final String label;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final String route;
  final String surface;

  const SynaptixHubCard({
    super.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.gradient,
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
        ref.read(analyticsServiceProvider).trackEvent('synaptix_hub_card_tapped', {
          'surface': surface,
          'synaptix_mode': mode.name,
          'entry_point': 'hub_card',
          'audience_segment': mode.name,
        });
        context.push(route);
      },
      child: Container(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(radius),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const Spacer(),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
