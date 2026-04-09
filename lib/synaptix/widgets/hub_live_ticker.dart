import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:trivia_tycoon/ui_components/shimmer_avatar/shimmer_avatar.dart';
import '../mode/synaptix_mode.dart';
import '../mode/synaptix_mode_provider.dart';
import '../../game/providers/hub_providers.dart';

/// Provider that builds ticker items from live notification events,
/// falling back to a seeded rotation when no live data is available.
final tickerItemsProvider = Provider<List<String>>((ref) {
  final mode = ref.watch(synaptixModeProvider);
  final prefix = mode == SynaptixMode.kids;

  // Try to pull from game event stream (non-blocking)
  final eventsAsync = ref.watch(upcomingGameEventsProvider);

  final liveItems = eventsAsync.maybeWhen(
    data: (events) {
      if (events.isEmpty) return <String>[];
      return events.take(5).map((e) {
        final label = e.name;
        return '${prefix ? "🎯 " : ""}$label starting soon';
      }).toList();
    },
    orElse: () => <String>[],
  );

  if (liveItems.isNotEmpty) return liveItems;

  // Fallback: seeded items (rotate daily for freshness)
  final allItems = [
    '${prefix ? "🏆 " : ""}User_882 won 500 Coins in Science',
    '${prefix ? "🔥 " : ""}PlayerX secured a 10-streak in Tech',
    '${prefix ? "⭐ " : ""}LizK reached Arena Rank 5',
    '${prefix ? "🎯 " : ""}NovaMind completed Daily Signal',
    '${prefix ? "💎 " : ""}QuizPro unlocked Diamond tier',
    '${prefix ? "🏆 " : ""}MindWarp won the History Championship',
    '${prefix ? "🔥 " : ""}SynapseX hit a 25-streak in Geography',
    '${prefix ? "⭐ " : ""}BrainWave earned Neural Master badge',
  ];

  // Rotate starting position by day
  final dayOffset = DateTime.now().day % allItems.length;
  return [
    ...allItems.sublist(dayOffset),
    ...allItems.sublist(0, dayOffset),
  ];
});

/// Horizontal auto-scrolling ticker showing live player events.
///
/// Displays the user's avatar alongside a scrolling text banner.
/// Reads from [tickerItemsProvider] which prefers live event data
/// and falls back to seeded rotation items.
class HubLiveTicker extends ConsumerWidget {
  const HubLiveTicker({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(tickerItemsProvider);
    final text = items.join('   •   ');

    // Get user avatar from profile
    final profileService = ref.watch(playerProfileServiceProvider);
    final profile = profileService.getProfile();
    final avatarPath = profile['avatar'] as String? ??
        'assets/images/avatars/default-avatar.png';

    return Container(
      height: 36,
      width: double.infinity,
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: Color(0x22FFFFFF), width: 0.5),
          bottom: BorderSide(color: Color(0x22FFFFFF), width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // User avatar
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: ShimmerAvatar(
              avatarPath: avatarPath,
              radius: 12,
              showStatusIndicator: false,
            ),
          ),
          const SizedBox(width: 8),

          // Scrolling ticker text
          Expanded(
            child: ClipRect(
              child: SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: 100,
                  itemBuilder: (context, index) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        text,
                        style: const TextStyle(
                          fontFamily: 'OpenSans',
                          color: Color(0xFF50C878),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ).animate(onPlay: (controller) => controller.repeat()).slideX(
                      begin: -1,
                      end: 0,
                      duration: 8.seconds,
                      curve: Curves.linear,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
