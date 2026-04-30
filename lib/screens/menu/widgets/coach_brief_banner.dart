import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/dto/personalization_dto.dart';
import '../../../game/providers/personalization_providers.dart';

/// Displays the backend-driven coach brief as a dismissable banner.
/// Tap on the CTA routes the player to [CoachBriefDto.targetRoute].
/// Interactions (engage/dismiss) are reported back to the backend.
class CoachBriefBanner extends ConsumerStatefulWidget {
  final String playerId;
  final CoachBriefDto brief;

  const CoachBriefBanner({
    super.key,
    required this.playerId,
    required this.brief,
  });

  @override
  ConsumerState<CoachBriefBanner> createState() => _CoachBriefBannerState();
}

class _CoachBriefBannerState extends ConsumerState<CoachBriefBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fade;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
      value: 1.0,
    );
    _fade = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  void _dismiss() async {
    if (_dismissed) return;
    setState(() => _dismissed = true);
    _sendFeedback('dismiss');
    await _fadeCtrl.reverse();
  }

  void _engage() {
    _sendFeedback('engage');
    final route = widget.brief.targetRoute;
    if (route.isNotEmpty && mounted) {
      context.go(route);
    }
  }

  void _sendFeedback(String feedback) {
    final briefId = widget.brief.id;
    if (briefId == null || briefId.isEmpty) return;
    ref.read(personalizationServiceProvider).sendCoachFeedback(
          playerId: widget.playerId,
          briefId: briefId,
          feedback: feedback,
        );
  }

  Color _toneColor(String tone) => switch (tone) {
        'urgent' => const Color(0xFFFF5252),
        'warning' => const Color(0xFFFFB74D),
        'celebratory' => const Color(0xFF69F0AE),
        _ => const Color(0xFF64B5F6), // encouraging / default
      };

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    final accent = _toneColor(widget.brief.tone);

    return FadeTransition(
      opacity: _fade,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0D1035).withOpacity(0.92),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: accent.withOpacity(0.35), width: 1),
          boxShadow: [
            BoxShadow(color: accent.withOpacity(0.12), blurRadius: 12, spreadRadius: 1),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: widget.brief.targetRoute.isNotEmpty ? _engage : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 3,
                    height: 44,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.brief.title,
                          style: TextStyle(
                            color: accent,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.brief.message,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.brief.recommendedAction.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _engage,
                            child: Text(
                              widget.brief.recommendedAction,
                              style: TextStyle(
                                color: accent,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                decoration: TextDecoration.underline,
                                decorationColor: accent,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16, color: Colors.white38),
                    splashRadius: 18,
                    onPressed: _dismiss,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Wraps the async loading of coach brief data so callers don't need to handle AsyncValue.
class CoachBriefBannerLoader extends ConsumerWidget {
  final String playerId;

  const CoachBriefBannerLoader({super.key, required this.playerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncHome = ref.watch(homePersonalizationProvider(playerId));
    return asyncHome.when(
      data: (home) {
        final brief = home.coachBrief;
        if (brief == null) return const SizedBox.shrink();
        return CoachBriefBanner(playerId: playerId, brief: brief);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
