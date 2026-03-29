import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode.dart';
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode_provider.dart';
import 'package:trivia_tycoon/synaptix/theme/synaptix_theme_extension.dart';
import 'package:trivia_tycoon/synaptix/widgets/synaptix_hub_card.dart';
import 'package:trivia_tycoon/synaptix/widgets/synaptix_hub_header.dart';
import 'package:trivia_tycoon/synaptix/widgets/synaptix_mode_banner.dart';
import 'package:trivia_tycoon/synaptix/widgets/synaptix_progress_snapshot.dart';

/// Synaptix Hub — the central launch surface for all product areas.
///
/// Mode-aware card emphasis:
/// - Kids: Play + Labs + Journey + Rewards
/// - Teen: Arena + Pathways + Labs + Circles
/// - Adult: Arena + Journey + Pathways + Labs
class GameMenuScreen extends ConsumerWidget {
  const GameMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(synaptixModeProvider);
    final profileService = ref.watch(playerProfileServiceProvider);
    final userProfile = profileService.getProfile();
    final playerName = userProfile['name'] ?? 'Player';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Synaptix Hub'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SynaptixModeBanner(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome header
            SynaptixHubHeader(playerName: playerName),

            // Progress snapshot
            const SynaptixProgressSnapshot(),
            const SizedBox(height: 24),

            // Quick-launch grid
            Text(
              'Explore',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildQuickLaunchGrid(context, mode),

            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickLaunchGrid(BuildContext context, SynaptixMode mode) {
    final cards = _cardsForMode(mode);
    final synaptix = Theme.of(context).extension<SynaptixTheme>();
    final highEnergy = synaptix?.useHighEnergyMotion ?? true;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.05,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
      ),
      itemCount: cards.length,
      itemBuilder: (context, index) {
        final card = cards[index];
        return SynaptixHubCard(
          label: card['label'] as String,
          subtitle: card['subtitle'] as String,
          icon: card['icon'] as IconData,
          gradient: card['gradient'] as LinearGradient,
          route: card['route'] as String,
        );
      },
    );
  }

  /// Returns mode-ordered hub cards with emphasis differences per audience.
  List<Map<String, dynamic>> _cardsForMode(SynaptixMode mode) {
    // All available hub cards
    final arena = {
      'label': mode == SynaptixMode.kids ? 'Top Players' : 'Arena',
      'subtitle': 'Leaderboards & rankings',
      'icon': Icons.emoji_events_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
      ),
      'route': '/leaderboard',
    };

    final labs = {
      'label': 'Labs',
      'subtitle': 'Games & challenges',
      'icon': Icons.science_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      ),
      'route': '/arcade',
    };

    final pathways = {
      'label': mode == SynaptixMode.teen ? 'Neural Pathways' : 'Pathways',
      'subtitle': 'Skills & progression',
      'icon': Icons.account_tree_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      ),
      'route': '/skills',
    };

    final journey = {
      'label': mode == SynaptixMode.kids ? 'My Journey' : 'Journey',
      'subtitle': 'Profile & milestones',
      'icon': Icons.explore_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
      ),
      'route': '/profile',
    };

    final circles = {
      'label': 'Circles',
      'subtitle': 'Friends & groups',
      'icon': Icons.people_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
      ),
      'route': '/messages',
    };

    final rewards = {
      'label': 'Rewards',
      'subtitle': 'Store & unlocks',
      'icon': Icons.card_giftcard_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
      ),
      'route': '/rewards',
    };

    // Mode-aware emphasis ordering
    switch (mode) {
      case SynaptixMode.kids:
        return [labs, journey, rewards, arena, pathways, circles];
      case SynaptixMode.teen:
        return [arena, pathways, labs, circles, journey, rewards];
      case SynaptixMode.adult:
        return [arena, journey, pathways, labs, circles, rewards];
    }
  }
}
