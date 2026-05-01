import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/dto/personalization_dto.dart';
import '../../game/providers/personalization_providers.dart';
import '../../game/providers/personalization_settings_provider.dart';
import 'recommendation_card.dart';

/// Shows backend-driven recommendations for a specific surface.
///
/// [filterType] — if set, only shows recommendations matching that type
/// (e.g. 'store_offer', 'learning_module'). Null shows all types.
///
/// Collapses to [SizedBox.shrink] when:
///   - personalization is disabled
///   - the provider returns no data
///   - there are no recommendations for the filtered type
class RecommendedForYouSection extends ConsumerWidget {
  final String playerId;
  final String? filterType;
  final String? sectionTitle;

  const RecommendedForYouSection({
    super.key,
    required this.playerId,
    this.filterType,
    this.sectionTitle,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabled =
        ref.watch(personalizationEnabledProvider(playerId));
    final settings = ref.watch(personalizationSettingsProvider);

    if (!enabled) return const SizedBox.shrink();

    final asyncHome = ref.watch(homePersonalizationProvider(playerId));

    return asyncHome.when(
      loading: () => const _LoadingShimmer(),
      error: (_, __) => const SizedBox.shrink(),
      data: (home) {
        var recs = home.topRecommendations;

        if (filterType != null) {
          recs = recs.where((r) => r.type == filterType).toList();
        }
        if (settings.reduceSuggestions) {
          recs = recs.take(2).toList();
        }
        if (recs.isEmpty) return const SizedBox.shrink();

        final title = sectionTitle ??
            (filterType == null ? 'Recommended for You' : _titleForType(filterType!));

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome,
                    size: 15,
                    color: Color(0xFF6366F1),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                      letterSpacing: 0.1,
                    ),
                  ),
                ],
              ),
            ),
            for (final rec in recs)
              RecommendationCard(
                playerId: playerId,
                recommendation: rec,
                showReason: settings.showReasons,
              ),
          ],
        );
      },
    );
  }

  String _titleForType(String type) => switch (type) {
        'learning_module' => 'Recommended Lessons',
        'study_set' => 'Recommended Study Sets',
        'mission' => 'Recommended Missions',
        'store_offer' => 'Suggested for You',
        'coach_tip' => 'Coach Tips',
        _ => 'Recommended for You',
      };
}

class _LoadingShimmer extends StatelessWidget {
  const _LoadingShimmer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LinearProgressIndicator(
        minHeight: 2,
        backgroundColor: Colors.transparent,
        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
      ),
    );
  }
}
