import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../game/analytics/providers/analytics_providers.dart';
import '../../game/providers/riverpod_providers.dart';
import '../mode/synaptix_mode_provider.dart';
import '../theme/synaptix_theme_extension.dart';
import '../utils/hub_feedback.dart';

/// A recommended match definition for the Hub.
class _FeaturedMatchData {
  final String title;
  final String difficulty;
  final IconData icon;
  final Color iconColor;

  const _FeaturedMatchData({
    required this.title,
    required this.difficulty,
    required this.icon,
    required this.iconColor,
  });
}

/// Provider that selects a featured match based on the player's category
/// preferences and recent activity. Falls back to a curated rotation.
final featuredMatchProvider = Provider<_FeaturedMatchData>((ref) {
  final profileService = ref.watch(playerProfileServiceProvider);
  final profile = profileService.getProfile();
  final categories =
      (profile['categories'] as List<dynamic>?)?.cast<String>() ?? [];

  // Match catalog keyed by category slug
  const catalog = <String, _FeaturedMatchData>{
    'science': _FeaturedMatchData(
      title: 'Global Science Showdown',
      difficulty: 'Medium',
      icon: Icons.science_rounded,
      iconColor: Colors.purpleAccent,
    ),
    'history': _FeaturedMatchData(
      title: 'Ancient History Clash',
      difficulty: 'Hard',
      icon: Icons.history_edu_rounded,
      iconColor: Colors.amber,
    ),
    'technology': _FeaturedMatchData(
      title: 'Tech Innovator Challenge',
      difficulty: 'Medium',
      icon: Icons.computer_rounded,
      iconColor: Colors.cyanAccent,
    ),
    'geography': _FeaturedMatchData(
      title: 'World Explorer Quest',
      difficulty: 'Easy',
      icon: Icons.public_rounded,
      iconColor: Colors.greenAccent,
    ),
    'entertainment': _FeaturedMatchData(
      title: 'Pop Culture Blitz',
      difficulty: 'Easy',
      icon: Icons.movie_filter_rounded,
      iconColor: Colors.pinkAccent,
    ),
    'sports': _FeaturedMatchData(
      title: 'Sports Legends Arena',
      difficulty: 'Medium',
      icon: Icons.sports_soccer_rounded,
      iconColor: Colors.orangeAccent,
    ),
    'art': _FeaturedMatchData(
      title: 'Creative Arts Duel',
      difficulty: 'Hard',
      icon: Icons.palette_rounded,
      iconColor: Colors.deepPurpleAccent,
    ),
  };

  // Pick from player's preferred categories when available
  if (categories.isNotEmpty) {
    final preferred = categories
        .where((c) => catalog.containsKey(c.toLowerCase()))
        .toList();
    if (preferred.isNotEmpty) {
      final pick = preferred[Random().nextInt(preferred.length)];
      return catalog[pick.toLowerCase()]!;
    }
  }

  // Fallback: rotate through catalog by day-of-year
  final dayIndex = DateTime.now().difference(DateTime(2026)).inDays;
  final values = catalog.values.toList();
  return values[dayIndex % values.length];
});

/// Glassmorphic "Recommended Match" centerpiece card for the Synaptix Hub.
///
/// Uses the GlassCard visual pattern (Impeller-safe, no BackdropFilter).
/// The play button pulses via a [ScaleTransition] driven by an
/// [Animation] passed from the parent screen.
class HubFeaturedMatch extends ConsumerWidget {
  final Animation<double> pulseAnimation;

  const HubFeaturedMatch({super.key, required this.pulseAnimation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final radius = synaptix?.cardRadius ?? 20.0;
    final match = ref.watch(featuredMatchProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0x1AFFFFFF),
        borderRadius: BorderRadius.circular(radius + 8),
        border: Border.all(color: const Color(0x33FFFFFF), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'RECOMMENDED MATCH',
            style: TextStyle(
              fontFamily: 'OpenSans',
              color: Colors.white60,
              letterSpacing: 2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),

          // Topic icon
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0x1AFFFFFF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              match.icon,
              size: 52,
              color: match.iconColor,
            ),
          ),
          const SizedBox(height: 16),

          // Topic name
          Text(
            match.title,
            style: const TextStyle(
              fontFamily: 'OpenSans',
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 6),

          // Difficulty badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: match.iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              match.difficulty,
              style: TextStyle(
                color: match.iconColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Pulsing play button
          ScaleTransition(
            scale: pulseAnimation,
            child: GestureDetector(
              onTap: () {
                HapticFeedback.mediumImpact();
                playHubTapSound(ref);
                final mode = ref.read(synaptixModeProvider);
                ref.read(analyticsServiceProvider).trackEvent(
                  'synaptix_hub_featured_match_tapped',
                  {
                    'surface': 'featured_match',
                    'synaptix_mode': mode.name,
                    'entry_point': 'featured_card',
                    'audience_segment': mode.name,
                    'match_title': match.title,
                  },
                );
                context.push('/quiz/start/classic');
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF50C878), Color(0xFF3DA55C)],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF50C878).withValues(alpha: 0.4),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.play_arrow_rounded,
                        color: Colors.white, size: 22),
                    SizedBox(width: 8),
                    Text(
                      'PLAY NOW',
                      style: TextStyle(
                        fontFamily: 'OpenSans',
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
