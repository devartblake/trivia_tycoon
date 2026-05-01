import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/dto/personalization_dto.dart';
import '../../game/providers/personalization_providers.dart';

// ── Reason sheet ──────────────────────────────────────────────────────────────

void showRecommendationReasonSheet(
  BuildContext context,
  PlayerRecommendationDto rec,
) {
  final reason = rec.payload['reason']?.toString() ?? '';
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Why am I seeing this?',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            reason.isEmpty
                ? 'This was recommended based on your recent activity.'
                : reason,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Text(
            'Recommendations are kept fair and non-intrusive. '
            'You can turn them off in Settings → Personalization.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
        ],
      ),
    ),
  );
}

// ── Card ──────────────────────────────────────────────────────────────────────

class RecommendationCard extends ConsumerWidget {
  final String playerId;
  final PlayerRecommendationDto recommendation;
  final bool showReason;

  const RecommendationCard({
    super.key,
    required this.playerId,
    required this.recommendation,
    this.showReason = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = recommendation.payload['title']?.toString() ??
        _fallbackTitle(recommendation.type);
    final route = recommendation.payload['route']?.toString();
    final reason = recommendation.payload['reason']?.toString() ?? '';
    final accent = _accentColor(recommendation.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _onAccept(context, ref, route),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
            child: Row(
              children: [
                // Type icon
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _iconForType(recommendation.type),
                    color: accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Text content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      if (showReason && reason.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (showReason) ...[
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () => showRecommendationReasonSheet(
                              context, recommendation),
                          child: Text(
                            'Why am I seeing this?',
                            style: TextStyle(
                              fontSize: 11,
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                // Dismiss button
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: Colors.black38),
                  splashRadius: 16,
                  onPressed: () => _onDismiss(ref),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onAccept(BuildContext context, WidgetRef ref, String? route) {
    ref.read(personalizationServiceProvider).fireEvent(
          playerId,
          BehaviourEventDto(
            eventType: 'recommendation_accepted',
            eventSource: 'recommendation_card',
            metadata: {'recommendationId': recommendation.id, 'type': recommendation.type},
          ),
        );
    ref.invalidate(homePersonalizationProvider(playerId));
    if (route != null && route.isNotEmpty && context.mounted) {
      context.go(route);
    }
  }

  void _onDismiss(WidgetRef ref) {
    ref.read(personalizationServiceProvider).fireEvent(
          playerId,
          BehaviourEventDto(
            eventType: 'recommendation_dismissed',
            eventSource: 'recommendation_card',
            metadata: {'recommendationId': recommendation.id, 'type': recommendation.type},
          ),
        );
    ref.invalidate(homePersonalizationProvider(playerId));
  }

  Color _accentColor(String type) => switch (type) {
        'learning_module' => const Color(0xFF6366F1),
        'study_set' => const Color(0xFF10B981),
        'mission' => const Color(0xFFF59E0B),
        'store_offer' => const Color(0xFFEC4899),
        'coach_tip' => const Color(0xFF64B5F6),
        _ => const Color(0xFF8B5CF6),
      };

  IconData _iconForType(String type) => switch (type) {
        'learning_module' => Icons.school_rounded,
        'study_set' => Icons.style_rounded,
        'mission' => Icons.flag_rounded,
        'store_offer' => Icons.storefront_rounded,
        'coach_tip' => Icons.psychology_rounded,
        _ => Icons.recommend_rounded,
      };

  String _fallbackTitle(String type) => switch (type) {
        'learning_module' => 'Recommended Lesson',
        'study_set' => 'Recommended Study Set',
        'mission' => 'Recommended Mission',
        'store_offer' => 'Suggested Offer',
        'coach_tip' => 'Coach Tip',
        _ => 'Recommended for You',
      };
}
