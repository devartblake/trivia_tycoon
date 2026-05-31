import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/synaptix_home_state.dart';
import '../providers/synaptix_home_provider.dart';
import '../theme/synaptix_home_theme.dart';
import '../widgets/synaptix_dashboard_widgets.dart';

class SynaptixHomeScreen extends ConsumerWidget {
  const SynaptixHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(synaptixHomeProvider);

    return Scaffold(
      backgroundColor: SynaptixHomeTheme.page,
      body: SafeArea(
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: SynaptixHomeTheme.pageGradient,
          ),
          child: state.when(
            data: (home) => _HomeLayout(home: home),
            loading: () => const _LoadingDashboard(),
            error: (error, _) => _HomeError(message: error.toString()),
          ),
        ),
      ),
    );
  }
}

class _HomeLayout extends StatelessWidget {
  final SynaptixHomeState home;

  const _HomeLayout({required this.home});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isWide = width >= 1120;
        final isMedium = width >= 760;

        return Column(
          children: [
            SynaptixTopNavigationBar(home: home, isCompact: width < 760),
            Expanded(
              child: isWide
                  ? _WideDashboard(home: home)
                  : _StackedDashboard(home: home, isMedium: isMedium),
            ),
          ],
        );
      },
    );
  }
}

class _WideDashboard extends StatelessWidget {
  final SynaptixHomeState home;

  const _WideDashboard({required this.home});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 240, child: SynaptixLeftRail(home: home)),
          const SizedBox(width: 20),
          Expanded(
            flex: 7,
            child: SingleChildScrollView(child: _MainDashboard(home: home)),
          ),
          const SizedBox(width: 20),
          SizedBox(
            width: 340,
            child: SingleChildScrollView(
              child: SynaptixRightPanel(home: home),
            ),
          ),
        ],
      ),
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          if (!isMedium) ...[
            const SynaptixCompactNav(),
            const SizedBox(height: 16),
          ],
          if (isMedium) ...[
            FriendsOnlineCard(friends: home.friends),
            const SizedBox(height: 16),
          ],
          _MainDashboard(home: home),
          const SizedBox(height: 16),
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
        ],
      ),
    );
  }
}

class _MainDashboard extends StatelessWidget {
  final SynaptixHomeState home;

  const _MainDashboard({required this.home});

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
        const SizedBox(height: 20),
        NewsRewardRow(
          newsItem: home.newsItem,
          dailyReward: home.dailyReward,
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
