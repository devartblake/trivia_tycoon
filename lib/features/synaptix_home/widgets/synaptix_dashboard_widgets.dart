import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/navigation/canonical_routes.dart';
import '../models/synaptix_home_state.dart';
import '../theme/synaptix_home_theme.dart';

class SynaptixPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double? height;
  final double? minHeight;
  final VoidCallback? onTap;

  const SynaptixPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.height,
    this.minHeight,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      width: double.infinity,
      height: height,
      constraints: BoxConstraints(minHeight: minHeight ?? 0),
      padding: padding,
      decoration: BoxDecoration(
        color: SynaptixHomeTheme.panel.withOpacity(0.78),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: SynaptixHomeTheme.stroke.withOpacity(0.90)),
        boxShadow: [
          BoxShadow(
            color: SynaptixHomeTheme.purple.withOpacity(0.14),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );

    if (onTap == null) return panel;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: panel,
      ),
    );
  }
}

class SynaptixProgressBar extends StatelessWidget {
  final double value;

  const SynaptixProgressBar({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: LinearProgressIndicator(
        minHeight: 8,
        value: value,
        backgroundColor: SynaptixHomeTheme.stroke.withOpacity(0.72),
        valueColor: const AlwaysStoppedAnimation(SynaptixHomeTheme.cyan),
      ),
    );
  }
}

class SynaptixTopNavigationBar extends StatelessWidget {
  final SynaptixHomeState home;
  final bool isCompact;
  final bool showMenuButton;
  final VoidCallback? onMenuPressed;

  const SynaptixTopNavigationBar({
    super.key,
    required this.home,
    required this.isCompact,
    this.showMenuButton = false,
    this.onMenuPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 24),
      decoration: BoxDecoration(
        color: SynaptixHomeTheme.panel.withOpacity(0.72),
        border: Border(
          bottom: BorderSide(
            color: SynaptixHomeTheme.stroke.withOpacity(0.65),
          ),
        ),
      ),
      child: Row(
        children: [
          if (showMenuButton) ...[
            Tooltip(
              message: 'Open navigation menu',
              child: IconButton.filledTonal(
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu_rounded),
                color: Colors.white,
                style: IconButton.styleFrom(
                  backgroundColor: SynaptixHomeTheme.panelAlt.withOpacity(0.92),
                  fixedSize: const Size.square(40),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          const _LogoMark(),
          if (!isCompact) ...[
            const SizedBox(width: 12),
            const Text(
              'SYNAPTIX',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
          ],
          if (!isCompact) ...[
            const SizedBox(width: 32),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final destination in canonicalPrimaryNavRoutes)
                      _TopNavItem(destination: destination),
                    const _TopNavItem(
                      destination: CanonicalNavDestination(
                        label: 'Rewards',
                        icon: Icons.card_giftcard_rounded,
                        route: canonicalRewardsRoute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ] else
            const Spacer(),
          _CurrencyPill(
            icon: Icons.monetization_on_rounded,
            value: home.player.coins.toString(),
          ),
          if (!isCompact) ...[
            const SizedBox(width: 10),
            _CurrencyPill(
              icon: Icons.diamond_rounded,
              value: home.player.gems.toString(),
            ),
          ],
          const SizedBox(width: 12),
          _CircleIconButton(
            icon: Icons.message_rounded,
            route: canonicalMessagesRoute,
            tooltip: 'Messages',
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            icon: Icons.settings_rounded,
            route: canonicalSettingsRoute,
            tooltip: 'Settings',
          ),
        ],
      ),
    );
  }
}

class SynaptixCompactNav extends StatelessWidget {
  const SynaptixCompactNav({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 46,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemBuilder: (context, index) {
          final destination = canonicalPrimaryNavRoutes[index];
          return ActionChip(
            avatar: Icon(
              destination.icon,
              size: 18,
              color: SynaptixHomeTheme.text,
            ),
            label: Text(destination.label),
            labelStyle: const TextStyle(color: SynaptixHomeTheme.text),
            backgroundColor: SynaptixHomeTheme.panel.withOpacity(0.84),
            side: const BorderSide(color: SynaptixHomeTheme.stroke),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onPressed: () => context.go(destination.route),
          );
        },
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemCount: canonicalPrimaryNavRoutes.length,
      ),
    );
  }
}

class SynaptixLeftRail extends StatelessWidget {
  final SynaptixHomeState home;

  const SynaptixLeftRail({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: _SynaptixRailContent(home: home),
    );
  }
}

class SynaptixHomeDrawer extends StatelessWidget {
  final SynaptixHomeState home;

  const SynaptixHomeDrawer({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final drawerWidth = screenWidth < 360 ? screenWidth * 0.90 : 320.0;

    return Drawer(
      width: drawerWidth,
      backgroundColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: SynaptixHomeTheme.pageGradient,
          border: Border(
            right: BorderSide(
              color: SynaptixHomeTheme.stroke.withOpacity(0.86),
            ),
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    const _LogoMark(),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'SYNAPTIX',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    Tooltip(
                      message: 'Close navigation menu',
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        color: SynaptixHomeTheme.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _SynaptixRailContent(home: home),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SynaptixRailContent extends StatelessWidget {
  final SynaptixHomeState home;

  const _SynaptixRailContent({required this.home});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const _SideMenuCard(),
        const SizedBox(height: 20),
        _RankCard(player: home.player),
        const SizedBox(height: 20),
        _StreakCard(player: home.player),
        const SizedBox(height: 20),
        const _ReferCard(),
      ],
    );
  }
}

class SynaptixDashboardFooter extends StatelessWidget {
  final SynaptixHomeState home;
  final bool isWide;
  final bool isMedium;

  const SynaptixDashboardFooter({
    super.key,
    required this.home,
    required this.isWide,
    required this.isMedium,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 8, 20, isWide ? 20 : 16),
      decoration: BoxDecoration(
        color: SynaptixHomeTheme.page.withOpacity(0.78),
        border: Border(
          top: BorderSide(color: SynaptixHomeTheme.stroke.withOpacity(0.72)),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 240,
                  child: FriendsOnlineCard(friends: home.friends),
                ),
                const SizedBox(width: 20),
                Expanded(flex: 7, child: NewsCard(item: home.newsItem)),
                const SizedBox(width: 20),
                SizedBox(
                  width: 340,
                  child: DailyRewardCard(prompt: home.dailyReward),
                ),
              ],
            );
          }

          if (isMedium && constraints.maxWidth >= 760) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: FriendsOnlineCard(friends: home.friends)),
                const SizedBox(width: 16),
                Expanded(child: NewsCard(item: home.newsItem)),
                const SizedBox(width: 16),
                Expanded(child: DailyRewardCard(prompt: home.dailyReward)),
              ],
            );
          }

          return Column(
            children: [
              FriendsOnlineCard(friends: home.friends),
              const SizedBox(height: 12),
              NewsCard(item: home.newsItem),
              const SizedBox(height: 12),
              DailyRewardCard(prompt: home.dailyReward),
            ],
          );
        },
      ),
    );
  }
}

class HeroTournamentCard extends StatelessWidget {
  final SynaptixHomeState home;

  const HeroTournamentCard({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    final showTrophy = MediaQuery.sizeOf(context).width >= 680;
    return SynaptixPanel(
      minHeight: 260,
      padding: EdgeInsets.zero,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: SynaptixHomeTheme.heroGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              if (showTrophy) ...[
                Container(
                  width: 250,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: RadialGradient(
                      colors: [
                        SynaptixHomeTheme.purple.withOpacity(0.8),
                        SynaptixHomeTheme.blue.withOpacity(0.18),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: SynaptixHomeTheme.gold,
                      size: 128,
                    ),
                  ),
                ),
                const SizedBox(width: 24),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _LiveBadge(),
                    const SizedBox(height: 18),
                    const Text(
                      'SYNAPTIX\nARENA CUP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 42,
                        height: 0.95,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Welcome back, ${home.player.displayName}. Compete, train, and collect rewards from one command center.',
                      style: const TextStyle(
                        color: SynaptixHomeTheme.muted,
                        fontSize: 15,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const _RewardMini(
                          icon: Icons.monetization_on_rounded,
                          title: '10,000',
                          subtitle: 'Synap Coins',
                        ),
                        _RewardMini(
                          icon: Icons.workspace_premium_rounded,
                          title: home.player.rankTier,
                          subtitle: 'Current Tier',
                        ),
                        _PrimaryGlowButton(
                          label: 'Join Tournament',
                          route: canonicalArenaRoute,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class GameModeGrid extends StatelessWidget {
  final List<SynaptixHomeAction> modes;

  const GameModeGrid({super.key, required this.modes});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'CHOOSE YOUR MODE',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 18),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth > 900
                  ? 4
                  : constraints.maxWidth > 560
                      ? 2
                      : 1;
              final aspectRatio = columns == 1
                  ? 1.25
                  : columns == 2
                      ? 0.92
                      : 0.72;
              return GridView.count(
                crossAxisCount: columns,
                shrinkWrap: true,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: aspectRatio,
                children: [
                  for (final mode in modes) _ModeCard(mode: mode),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class ProgressionCard extends StatelessWidget {
  final SynaptixHomePlayer player;
  final List<SynaptixAchievement> achievements;

  const ProgressionCard({
    super.key,
    required this.player,
    required this.achievements,
  });

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      minHeight: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'YOUR PROGRESSION',
            style: TextStyle(
              color: SynaptixHomeTheme.purple,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _LevelBadge(level: player.level),
              const SizedBox(width: 14),
              Expanded(child: SynaptixProgressBar(value: player.xpProgress)),
              const SizedBox(width: 14),
              Text(
                '${player.currentXp} / ${player.targetXp} XP',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'RECENT ACHIEVEMENTS',
            style: TextStyle(
              color: SynaptixHomeTheme.muted,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 14),
          LayoutBuilder(
            builder: (context, constraints) {
              final stack = constraints.maxWidth < 420;
              final tiles = [
                for (final achievement in achievements)
                  AchievementTile(achievement: achievement),
              ];
              if (stack) {
                return Column(
                  children: [
                    for (final tile in tiles) ...[
                      tile,
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              }
              return Row(
                children: [
                  for (final tile in tiles) Expanded(child: tile),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class FeaturedEventCard extends StatelessWidget {
  final SynaptixFeaturedEvent event;

  const FeaturedEventCard({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      minHeight: 210,
      onTap: () => context.go(event.route),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 84,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                colors: [Color(0xFF32105F), Color(0xFF06264D)],
              ),
            ),
            child: Center(
              child: Icon(event.icon, color: Colors.white, size: 42),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            event.title.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            event.subtitle,
            style: const TextStyle(color: SynaptixHomeTheme.muted),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(
                Icons.timer_rounded,
                color: SynaptixHomeTheme.blue,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                event.timeRemaining,
                style: const TextStyle(color: SynaptixHomeTheme.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class SynaptixRightPanel extends StatelessWidget {
  final SynaptixHomeState home;

  const SynaptixRightPanel({super.key, required this.home});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ProfileSummaryCard(player: home.player),
        const SizedBox(height: 18),
        DailyMissionsCard(missions: home.missions),
        const SizedBox(height: 18),
        LeaderboardPreviewCard(entries: home.leaderboard),
      ],
    );
  }
}

class NewsRewardRow extends StatelessWidget {
  final SynaptixNewsItem newsItem;
  final SynaptixRewardPrompt dailyReward;

  const NewsRewardRow({
    super.key,
    required this.newsItem,
    required this.dailyReward,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stack = constraints.maxWidth < 720;
        final news = NewsCard(item: newsItem);
        final reward = DailyRewardCard(prompt: dailyReward);
        if (stack) {
          return Column(
            children: [
              news,
              const SizedBox(height: 16),
              reward,
            ],
          );
        }
        return Row(
          children: [
            Expanded(flex: 2, child: news),
            const SizedBox(width: 16),
            Expanded(child: reward),
          ],
        );
      },
    );
  }
}

class CompleteProfileCard extends StatelessWidget {
  const CompleteProfileCard({super.key});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      onTap: () => context.go('/onboarding'),
      child: Row(
        children: [
          const Icon(
            Icons.assignment_ind_rounded,
            color: SynaptixHomeTheme.gold,
            size: 34,
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPLETE YOUR PROFILE',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Finish setup to personalize missions, rewards, and recommendations.',
                  style: TextStyle(color: SynaptixHomeTheme.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: SynaptixHomeTheme.muted),
        ],
      ),
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  final List<SynaptixRecentActivity> items;

  const RecentActivityCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      minHeight: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: 'RECENT PLAY', action: 'HISTORY'),
          const SizedBox(height: 12),
          for (final item in items)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: SynaptixHomeTheme.panelAlt,
                child: Icon(
                  Icons.history_rounded,
                  color: SynaptixHomeTheme.cyan,
                ),
              ),
              title: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                item.date,
                style: const TextStyle(color: SynaptixHomeTheme.muted),
              ),
              trailing: Text(
                item.score,
                style: const TextStyle(
                  color: SynaptixHomeTheme.green,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class RecommendationsCard extends StatelessWidget {
  final List<SynaptixRecommendation> recommendations;
  final int rewards;

  const RecommendationsCard({
    super.key,
    required this.recommendations,
    required this.rewards,
  });

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      minHeight: 210,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _PanelHeader(title: 'RECOMMENDED', action: '$rewards REWARDS'),
          const SizedBox(height: 12),
          for (final item in recommendations)
            ListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              leading: Icon(item.icon, color: SynaptixHomeTheme.gold),
              title: Text(
                item.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              subtitle: Text(
                item.subtitle,
                style: const TextStyle(color: SynaptixHomeTheme.muted),
              ),
              trailing: const Icon(
                Icons.chevron_right_rounded,
                color: SynaptixHomeTheme.muted,
              ),
              onTap: () => context.go(item.route),
            ),
        ],
      ),
    );
  }
}

class ProfileSummaryCard extends StatelessWidget {
  final SynaptixHomePlayer player;

  const ProfileSummaryCard({super.key, required this.player});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 42,
                backgroundColor: SynaptixHomeTheme.purple,
                child: Icon(
                  Icons.person_rounded,
                  color: Colors.white,
                  size: 42,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.handle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player.title,
                      style: const TextStyle(color: SynaptixHomeTheme.muted),
                    ),
                    const SizedBox(height: 10),
                    SynaptixProgressBar(value: player.xpProgress),
                    const SizedBox(height: 6),
                    Text(
                      '${player.currentXp} / ${player.targetXp} XP',
                      style: const TextStyle(
                        color: SynaptixHomeTheme.muted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _StatBlock(label: 'Wins', value: '${player.wins}')),
              Expanded(
                child: _StatBlock(label: 'Matches', value: '${player.matches}'),
              ),
              Expanded(
                child: _StatBlock(
                  label: 'Win Rate',
                  value: '${(player.winRate * 100).toStringAsFixed(0)}%',
                ),
              ),
              Expanded(
                  child: _StatBlock(label: 'Rank', value: '#${player.rank}')),
            ],
          ),
        ],
      ),
    );
  }
}

class DailyMissionsCard extends StatelessWidget {
  final List<SynaptixHomeMission> missions;

  const DailyMissionsCard({super.key, required this.missions});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: 'DAILY MISSIONS', action: 'LOCAL'),
          const SizedBox(height: 16),
          for (final mission in missions) _MissionTile(mission: mission),
        ],
      ),
    );
  }
}

class LeaderboardPreviewCard extends StatelessWidget {
  final List<SynaptixHomeLeaderboardEntry> entries;

  const LeaderboardPreviewCard({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _PanelHeader(title: 'LEADERBOARD', action: 'GLOBAL'),
          const SizedBox(height: 12),
          for (final entry in entries) _LeaderboardRow(entry: entry),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go(canonicalArenaRoute),
              child: const Text('View leaderboard'),
            ),
          ),
        ],
      ),
    );
  }
}

class FriendsOnlineCard extends StatelessWidget {
  final List<SynaptixFriendPreview> friends;

  const FriendsOnlineCard({super.key, required this.friends});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Row(
        children: [
          Expanded(
            child: Text(
              'FRIENDS ONLINE (${friends.length})',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          for (final friend in friends.take(5))
            Padding(
              padding: const EdgeInsets.only(left: 6),
              child: CircleAvatar(
                radius: 14,
                backgroundColor: friend.color.withOpacity(0.8),
                child: Text(
                  friend.initials,
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class AchievementTile extends StatelessWidget {
  final SynaptixAchievement achievement;

  const AchievementTile({super.key, required this.achievement});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(achievement.icon, color: SynaptixHomeTheme.gold, size: 34),
        const SizedBox(height: 8),
        Text(
          achievement.title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          achievement.subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(color: SynaptixHomeTheme.muted, fontSize: 11),
        ),
      ],
    );
  }
}

class NewsCard extends StatelessWidget {
  final SynaptixNewsItem item;

  const NewsCard({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      minHeight: 86,
      onTap: () => context.go(item.route),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  item.title.toUpperCase(),
                  style: const TextStyle(
                    color: SynaptixHomeTheme.purple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.body,
                  style: const TextStyle(color: SynaptixHomeTheme.muted),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded,
              color: SynaptixHomeTheme.muted),
        ],
      ),
    );
  }
}

class DailyRewardCard extends StatelessWidget {
  final SynaptixRewardPrompt prompt;

  const DailyRewardCard({super.key, required this.prompt});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      minHeight: 86,
      onTap: () => context.go(prompt.route),
      child: Row(
        children: [
          Icon(prompt.icon, color: SynaptixHomeTheme.purple, size: 42),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  prompt.title.toUpperCase(),
                  style: const TextStyle(
                    color: SynaptixHomeTheme.purple,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  prompt.body,
                  style: const TextStyle(color: SynaptixHomeTheme.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  const _LogoMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          colors: [SynaptixHomeTheme.purple, SynaptixHomeTheme.blue],
        ),
      ),
      child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 28),
    );
  }
}

class _TopNavItem extends StatelessWidget {
  final CanonicalNavDestination destination;

  const _TopNavItem({required this.destination});

  @override
  Widget build(BuildContext context) {
    final selected = GoRouterState.of(context).uri.path == destination.route;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go(destination.route),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? SynaptixHomeTheme.purple.withOpacity(0.22)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: selected
                ? Border.all(color: SynaptixHomeTheme.purple.withOpacity(0.55))
                : null,
          ),
          child: Row(
            children: [
              Icon(
                destination.icon,
                color: selected ? Colors.white : SynaptixHomeTheme.muted,
                size: 18,
              ),
              const SizedBox(width: 7),
              Text(
                destination.label.toUpperCase(),
                style: TextStyle(
                  color: selected ? Colors.white : SynaptixHomeTheme.muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CurrencyPill extends StatelessWidget {
  final IconData icon;
  final String value;

  const _CurrencyPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    final iconColor = icon == Icons.diamond_rounded
        ? SynaptixHomeTheme.blue
        : SynaptixHomeTheme.gold;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SynaptixHomeTheme.panelAlt.withOpacity(0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: SynaptixHomeTheme.stroke),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  final IconData icon;
  final String route;
  final String tooltip;

  const _CircleIconButton({
    required this.icon,
    required this.route,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton.filledTonal(
        onPressed: () => context.go(route),
        icon: Icon(icon),
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: SynaptixHomeTheme.panelAlt.withOpacity(0.92),
          fixedSize: const Size.square(40),
        ),
      ),
    );
  }
}

class _SideMenuCard extends StatelessWidget {
  const _SideMenuCard();

  @override
  Widget build(BuildContext context) {
    const destinations = [
      CanonicalNavDestination(
        label: 'Dashboard',
        icon: Icons.dashboard_rounded,
        route: canonicalHomeRoute,
      ),
      CanonicalNavDestination(
        label: 'Profile',
        icon: Icons.person_rounded,
        route: canonicalJourneyRoute,
      ),
      CanonicalNavDestination(
        label: 'Store',
        icon: Icons.inventory_2_rounded,
        route: canonicalStoreRoute,
      ),
      CanonicalNavDestination(
        label: 'Rewards',
        icon: Icons.card_giftcard_rounded,
        route: canonicalRewardsRoute,
      ),
      CanonicalNavDestination(
        label: 'Skill Tree',
        icon: Icons.account_tree_rounded,
        route: '/skills',
      ),
      CanonicalNavDestination(
        label: 'Arcade',
        icon: Icons.sports_esports_rounded,
        route: canonicalLabsRoute,
      ),
      CanonicalNavDestination(
        label: 'Settings',
        icon: Icons.settings_rounded,
        route: canonicalSettingsRoute,
      ),
    ];

    return SynaptixPanel(
      padding: const EdgeInsets.all(8),
      child: Column(
        children: [
          for (final destination in destinations)
            _SideNavItem(destination: destination),
        ],
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final CanonicalNavDestination destination;

  const _SideNavItem({required this.destination});

  @override
  Widget build(BuildContext context) {
    final selected = GoRouterState.of(context).uri.path == destination.route;
    final router = GoRouter.of(context);
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        final scaffold = Scaffold.maybeOf(context);
        if (scaffold?.isDrawerOpen ?? false) {
          Navigator.of(context).pop();
        }
        router.go(destination.route);
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF6426C7), Color(0xFF240D69)],
                )
              : null,
        ),
        child: Row(
          children: [
            Icon(
              destination.icon,
              color: selected ? Colors.white : SynaptixHomeTheme.muted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                destination.label.toUpperCase(),
                style: TextStyle(
                  color: selected ? Colors.white : SynaptixHomeTheme.muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.chevron_right_rounded,
                color: Colors.white,
                size: 18,
              ),
          ],
        ),
      ),
    );
  }
}

class _RankCard extends StatelessWidget {
  final SynaptixHomePlayer player;

  const _RankCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Column(
        children: [
          const Text(
            'CURRENT RANK',
            style: TextStyle(color: SynaptixHomeTheme.muted, fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            player.rankTier.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          const Icon(
            Icons.workspace_premium_rounded,
            color: SynaptixHomeTheme.purple,
            size: 86,
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'RATING',
                  style: TextStyle(
                    color: SynaptixHomeTheme.muted,
                    fontSize: 12,
                  ),
                ),
              ),
              Text(
                '${player.rating}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SynaptixProgressBar(value: player.xpProgress),
        ],
      ),
    );
  }
}

class _StreakCard extends StatelessWidget {
  final SynaptixHomePlayer player;

  const _StreakCard({required this.player});

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      child: Row(
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: SynaptixHomeTheme.orange,
            size: 42,
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'WIN STREAK',
                style: TextStyle(color: SynaptixHomeTheme.muted, fontSize: 12),
              ),
              Text(
                '${player.streak}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'Best: ${player.bestStreak}',
                style: const TextStyle(
                  color: SynaptixHomeTheme.muted,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReferCard extends StatelessWidget {
  const _ReferCard();

  @override
  Widget build(BuildContext context) {
    return SynaptixPanel(
      onTap: () => context.go('/invite'),
      child: const Row(
        children: [
          Icon(Icons.redeem_rounded, color: SynaptixHomeTheme.purple, size: 38),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'REFER & EARN',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Invite friends, earn rewards.',
                  style:
                      TextStyle(color: SynaptixHomeTheme.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: SynaptixHomeTheme.blue.withOpacity(0.16),
        border: Border.all(color: SynaptixHomeTheme.blue),
      ),
      child: const Text(
        'LIVE NOW',
        style: TextStyle(
          color: SynaptixHomeTheme.cyan,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _RewardMini extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _RewardMini({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: SynaptixHomeTheme.gold, size: 24),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 12,
              ),
            ),
            Text(
              subtitle,
              style: const TextStyle(
                color: SynaptixHomeTheme.muted,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PrimaryGlowButton extends StatelessWidget {
  final String label;
  final String route;

  const _PrimaryGlowButton({required this.label, required this.route});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: SynaptixHomeTheme.buttonGradient,
        boxShadow: [
          BoxShadow(
            color: SynaptixHomeTheme.blue.withOpacity(0.45),
            blurRadius: 20,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.go(route),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
            child: Text(
              label.toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  final SynaptixHomeAction mode;

  const _ModeCard({required this.mode});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.go(mode.route),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: SynaptixHomeTheme.modeGradient(mode.color),
          border: Border.all(color: mode.color.withOpacity(0.55)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(mode.icon, color: mode.color, size: 42),
            const SizedBox(height: 12),
            Text(
              mode.title.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              mode.subtitle,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SynaptixHomeTheme.muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: mode.color.withOpacity(0.84),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () => context.go(mode.route),
                child: const Text(
                  'PLAY NOW',
                  style: TextStyle(fontWeight: FontWeight.w900),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LevelBadge extends StatelessWidget {
  final int level;

  const _LevelBadge({required this.level});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 54,
      height: 54,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: SynaptixHomeTheme.panelAlt,
        border: Border.all(color: SynaptixHomeTheme.purple),
      ),
      child: Center(
        child: Text(
          '$level',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  final String title;
  final String action;

  const _PanelHeader({required this.title, required this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          action,
          style: const TextStyle(
            color: SynaptixHomeTheme.purple,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _MissionTile extends StatelessWidget {
  final SynaptixHomeMission mission;

  const _MissionTile({required this.mission});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SynaptixHomeTheme.panelAlt.withOpacity(0.84),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SynaptixHomeTheme.stroke.withOpacity(0.75)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: SynaptixHomeTheme.purple.withOpacity(0.82),
            child: Icon(mission.icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mission.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 8),
                SynaptixProgressBar(value: mission.progress),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            mission.progressLabel,
            style:
                const TextStyle(color: SynaptixHomeTheme.muted, fontSize: 12),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.monetization_on_rounded,
            color: SynaptixHomeTheme.gold,
            size: 16,
          ),
          Text(
            '${mission.rewardCoins}',
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  final SynaptixHomeLeaderboardEntry entry;

  const _LeaderboardRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 8),
      decoration: BoxDecoration(
        color: entry.isCurrentUser
            ? SynaptixHomeTheme.purple.withOpacity(0.18)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 42,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                color: entry.isCurrentUser
                    ? SynaptixHomeTheme.purple
                    : SynaptixHomeTheme.muted,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const CircleAvatar(
            radius: 13,
            backgroundColor: SynaptixHomeTheme.blue,
            child: Icon(Icons.person, color: Colors.white, size: 14),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              entry.username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: entry.isCurrentUser
                    ? Colors.white
                    : SynaptixHomeTheme.muted,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            '${entry.score}',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String label;
  final String value;

  const _StatBlock({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          textAlign: TextAlign.center,
          style: const TextStyle(color: SynaptixHomeTheme.muted, fontSize: 11),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}
