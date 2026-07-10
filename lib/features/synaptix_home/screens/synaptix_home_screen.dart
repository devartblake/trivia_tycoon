import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/helpers/responsive_layout.dart';
import '../models/synaptix_home_state.dart';
import '../providers/synaptix_home_provider.dart';
import '../theme/synaptix_home_theme.dart';
import '../widgets/synaptix_dashboard_widgets.dart';
import '../widgets/cards/phase2_daily_bonus_card.dart';
import '../widgets/cards/phase2_weekly_rewards_card.dart';
import '../widgets/cards/phase2_tier_progress_card.dart';

class SynaptixHomeScreen extends ConsumerWidget {
  const SynaptixHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(synaptixHomeProvider);

    return state.when(
      data: (home) => _SynaptixHomeAdaptiveShell(home: home),
      loading: () => const Scaffold(
        backgroundColor: SynaptixHomeTheme.page,
        body: _HomeShell(child: _LoadingDashboard()),
      ),
      error: (error, _) => Scaffold(
        backgroundColor: SynaptixHomeTheme.page,
        body: _HomeShell(child: _HomeError(message: error.toString())),
      ),
    );
  }
}

class _HomeShell extends StatelessWidget {
  final Widget child;

  const _HomeShell({required this.child});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: SynaptixHomeTheme.pageGradient,
        ),
        child: child,
      ),
    );
  }
}

class _SynaptixHomeAdaptiveShell extends StatelessWidget {
  final SynaptixHomeState home;

  const _SynaptixHomeAdaptiveShell({required this.home});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= AppBreakpoints.dashboardRail;
        final isMedium = width >= 760;

        return AppAdaptiveScaffold(
          backgroundColor: SynaptixHomeTheme.page,
          decoration: const BoxDecoration(
            gradient: SynaptixHomeTheme.pageGradient,
          ),
          drawer: SynaptixHomeDrawer(home: home),
          rail: SynaptixLeftRail(home: home),
          rightPanel: SingleChildScrollView(
            child: SynaptixRightPanel(home: home),
          ),
          bodyPadding: isWide
              ? const EdgeInsets.fromLTRB(20, 16, 20, 12)
              : EdgeInsets.zero,
          topBar: Builder(
            builder: (context) => SynaptixTopNavigationBar(
              home: home,
              isCompact: width < 760,
              showMenuButton: !isWide,
              onMenuPressed: () => Scaffold.of(context).openDrawer(),
            ),
          ),
          body: isWide
              ? SingleChildScrollView(
                  key: const Key('synaptix-main-scroll'),
                  child: _MainDashboard(
                      home: home, isWide: isWide, isMedium: isMedium),
                )
              : _StackedDashboard(home: home, isMedium: isMedium),
        );
      },
    );
  }
}

class _StackedDashboard extends StatelessWidget {
  final SynaptixHomeState home;
  final bool isMedium;

  const _StackedDashboard({required this.home, required this.isMedium});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const Key('synaptix-main-scroll'),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!isMedium) ...[
            const SynaptixCompactNav(),
            const SizedBox(height: 16),
          ],
          _MainDashboard(home: home, isWide: false, isMedium: isMedium),
          const SizedBox(height: 12),
          if (isMedium)
            Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: ProfileSummaryCard(player: home.player)),
                    const SizedBox(width: 16),
                    Expanded(child: DailyMissionsCard(missions: home.missions)),
                  ],
                ),
                const SizedBox(height: 16),
                LeaderboardPreviewCard(entries: home.leaderboard),
              ],
            )
          else
            SynaptixRightPanel(home: home),
          const SizedBox(height: 16),
          SynaptixDashboardFooter(
            home: home,
            isWide: false,
            isMedium: isMedium,
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

class _MainDashboard extends StatelessWidget {
  final SynaptixHomeState home;
  final bool isWide;
  final bool isMedium;

  const _MainDashboard({
    required this.home,
    this.isWide = false,
    this.isMedium = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (home.profileIncomplete) ...[
          const CompleteProfileCard(),
          const SizedBox(height: 20),
        ],
        HeroTournamentCard(home: home),
        const SizedBox(height: 20),
        GameModeGrid(modes: home.primaryActions),
        const SizedBox(height: 20),

        // Phase 2: Daily Bonus, Weekly Rewards, Tier Progress
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  Phase2DailyBonusCard(),
                  const SizedBox(height: 16),
                  Phase2WeeklyRewardsCard(),
                  const SizedBox(height: 16),
                  Phase2TierProgressCard(),
                  const SizedBox(height: 20),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Phase2DailyBonusCard()),
                const SizedBox(width: 16),
                Expanded(child: Phase2WeeklyRewardsCard()),
                const SizedBox(width: 16),
                Expanded(child: Phase2TierProgressCard()),
              ],
            );
          },
        ),
        const SizedBox(height: 20),

        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  FeaturedEventCard(event: home.featuredEvent),
                  const SizedBox(height: 20),
                  ProgressionCard(
                    player: home.player,
                    achievements: home.achievements,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: FeaturedEventCard(event: home.featuredEvent)),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: ProgressionCard(
                    player: home.player,
                    achievements: home.achievements,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth < 720) {
              return Column(
                children: [
                  RecentActivityCard(items: home.recentActivity),
                  const SizedBox(height: 20),
                  RecommendationsCard(
                    recommendations: home.recommendations,
                    rewards: home.remainingAccountRewards,
                  ),
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: RecentActivityCard(items: home.recentActivity)),
                const SizedBox(width: 20),
                Expanded(
                  child: RecommendationsCard(
                    recommendations: home.recommendations,
                    rewards: home.remainingAccountRewards,
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 32),
        SynaptixDashboardFooter(
          home: home,
          isWide: isWide,
          isMedium: isMedium,
        ),
      ],
    );
  }
}

class _LoadingDashboard extends StatelessWidget {
  const _LoadingDashboard();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: SynaptixHomeTheme.cyan),
    );
  }
}

class _HomeError extends StatelessWidget {
  final String message;

  const _HomeError({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SynaptixPanel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.error_outline_rounded,
              color: SynaptixHomeTheme.red,
              size: 42,
            ),
            const SizedBox(height: 12),
            const Text(
              'Home dashboard could not load',
              style: TextStyle(
                color: SynaptixHomeTheme.text,
                fontWeight: FontWeight.w900,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: SynaptixHomeTheme.muted),
            ),
          ],
        ),
      ),
    );
  }
}
