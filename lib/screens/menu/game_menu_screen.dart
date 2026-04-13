import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/game/providers/riverpod_providers.dart';
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode.dart';
import 'package:trivia_tycoon/synaptix/mode/synaptix_mode_provider.dart';
import 'package:trivia_tycoon/synaptix/theme/synaptix_theme_extension.dart';
import 'package:trivia_tycoon/synaptix/widgets/hub_daily_quest.dart';
import 'package:trivia_tycoon/synaptix/widgets/hub_retention_banner.dart';
import 'package:trivia_tycoon/synaptix/widgets/hub_featured_match.dart';
import 'package:trivia_tycoon/synaptix/widgets/hub_live_ticker.dart';
import 'package:trivia_tycoon/synaptix/widgets/hub_metallic_buttons.dart';
import 'package:trivia_tycoon/synaptix/widgets/synaptix_hub_card.dart';
import 'package:trivia_tycoon/synaptix/widgets/synaptix_hub_header.dart';
import 'package:trivia_tycoon/synaptix/widgets/synaptix_mode_banner.dart';
import 'package:trivia_tycoon/synaptix/widgets/synaptix_progress_snapshot.dart';

/// Synaptix Hub — the central launch surface for all product areas.
///
/// Premium dark-themed design with glassmorphic elements, live ticker,
/// featured match centerpiece, metallic action buttons, and daily quest.
///
/// Mode-aware card emphasis:
/// - Kids: Play + Labs + Journey + Rewards
/// - Teen: Arena + Pathways + Labs + Circles
/// - Adult: Arena + Journey + Pathways + Labs
class GameMenuScreen extends ConsumerStatefulWidget {
  const GameMenuScreen({super.key});

  @override
  ConsumerState<GameMenuScreen> createState() => _GameMenuScreenState();
}

class _GameMenuScreenState extends ConsumerState<GameMenuScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _pulseController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    final mode = ref.watch(synaptixModeProvider);
    final profileService = ref.watch(playerProfileServiceProvider);
    final userProfile = profileService.getProfile();
    final playerName = userProfile['name'] ?? 'Player';

    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: canPop,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded),
                onPressed: () => Navigator.of(context).maybePop(),
              )
            : null,
        backgroundColor: Colors.transparent,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Synaptix Hub',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 12),
            child: SynaptixModeBanner(),
          ),
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Layer 0: Background image
          Positioned.fill(
            child: Opacity(
              opacity: 0.15,
              child: Image.asset(
                'assets/images/backgrounds/geometry_background.jpg',
                fit: BoxFit.cover,
              ),
            ),
          ),

          // Layer 1: Scrollable content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),

                  // Welcome header
                  SynaptixHubHeader(
                    playerName: playerName,
                    isDarkBackground: true,
                  ),

                  // Progress snapshot
                  const SynaptixProgressSnapshot(isDarkBackground: true),
                  const SizedBox(height: 16),

                  // Retention banner (daily bonus + bonus challenge)
                  const HubRetentionBanner(),

                  // Live win ticker
                  const HubLiveTicker(),
                  const SizedBox(height: 20),

                  // Featured match centerpiece
                  HubFeaturedMatch(pulseAnimation: _pulseAnimation),
                  const SizedBox(height: 16),

                  // Metallic action buttons
                  const HubMetallicButtons(),
                  const SizedBox(height: 16),

                  // Daily quest
                  const HubDailyQuest(),
                  const SizedBox(height: 24),

                  // Quick-launch grid section
                  const Text(
                    'Explore',
                    style: TextStyle(
                      fontFamily: 'OpenSans',
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildQuickLaunchGrid(context, mode),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickLaunchGrid(BuildContext context, SynaptixMode mode) {
    final cards = _cardsForMode(mode);
    Theme.of(context).extension<SynaptixTheme>();

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
          surface: card['surface'] as String,
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
      'surface': 'arena',
    };

    final labs = {
      'label': 'Labs',
      'subtitle': 'Games & challenges',
      'icon': Icons.science_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFF06B6D4), Color(0xFF0891B2)],
      ),
      'route': '/arcade',
      'surface': 'labs',
    };

    final pathways = {
      'label': mode == SynaptixMode.teen ? 'Neural Pathways' : 'Pathways',
      'subtitle': 'Skills & progression',
      'icon': Icons.account_tree_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
      ),
      'route': '/skills',
      'surface': 'pathways',
    };

    final journey = {
      'label': mode == SynaptixMode.kids ? 'My Journey' : 'Journey',
      'subtitle': 'Profile & milestones',
      'icon': Icons.explore_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFF10B981), Color(0xFF059669)],
      ),
      'route': '/profile',
      'surface': 'journey',
    };

    final circles = {
      'label': 'Circles',
      'subtitle': 'Friends & groups',
      'icon': Icons.people_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFFEC4899), Color(0xFFDB2777)],
      ),
      'route': '/messages',
      'surface': 'circles',
    };

    final rewards = {
      'label': 'Rewards',
      'subtitle': 'Store & unlocks',
      'icon': Icons.card_giftcard_rounded,
      'gradient': const LinearGradient(
        colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
      ),
      'route': '/rewards',
      'surface': 'rewards',
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
