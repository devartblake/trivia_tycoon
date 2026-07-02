import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../platform/platform_config.dart';

/// Web-specific sidebar navigation component
class WebSidebarNavigator extends ConsumerWidget {
  final GoRouter router;
  final String? selectedRoute;

  const WebSidebarNavigator({
    super.key,
    required this.router,
    this.selectedRoute,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWeb = ref.watch(isWebProvider);

    if (!isWeb) return const SizedBox.shrink();

    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          right: BorderSide(color: Colors.grey[800]!),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      'ST',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Synaptix',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Trivia Platform',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
          // Navigation Items (same as mobile)
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _NavSection(
                    title: 'Main',
                    items: [
                      _NavItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        route: '/home',
                        isSelected: selectedRoute == '/home',
                        onTap: () => context.go('/home'),
                      ),
                      _NavItem(
                        icon: Icons.quiz_rounded,
                        label: 'Play',
                        route: '/quiz',
                        isSelected: selectedRoute == '/quiz',
                        onTap: () => context.go('/quiz'),
                      ),
                      _NavItem(
                        icon: Icons.leaderboard_rounded,
                        label: 'Arena',
                        route: '/leaderboard',
                        isSelected: selectedRoute == '/leaderboard',
                        onTap: () => context.go('/leaderboard'),
                      ),
                      _NavItem(
                        icon: Icons.science_rounded,
                        label: 'Labs',
                        route: '/arcade',
                        isSelected: selectedRoute == '/arcade',
                        onTap: () => context.go('/arcade'),
                      ),
                      _NavItem(
                        icon: Icons.person_rounded,
                        label: 'Journey',
                        route: '/profile',
                        isSelected: selectedRoute == '/profile',
                        onTap: () => context.go('/profile'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _NavSection(
                    title: 'Web Exclusive',
                    items: [
                      _NavItem(
                        icon: Icons.emoji_events,
                        label: 'Tier Progression',
                        route: '/tier-progression',
                        isSelected: selectedRoute == '/tier-progression',
                        onTap: () => context.go('/tier-progression'),
                      ),
                      _NavItem(
                        icon: Icons.tune,
                        label: 'Advanced Leaderboard',
                        route: '/leaderboard-advanced',
                        isSelected: selectedRoute == '/leaderboard-advanced',
                        onTap: () => context.go('/leaderboard-advanced'),
                      ),
                      _NavItem(
                        icon: Icons.bar_chart,
                        label: 'Analytics',
                        route: '/analytics',
                        isSelected: selectedRoute == '/analytics',
                        onTap: () => context.go('/analytics'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _NavSection(
                    title: 'Admin',
                    items: [
                      _NavItem(
                        icon: Icons.admin_panel_settings,
                        label: 'Admin Panel',
                        route: '/admin',
                        isSelected: selectedRoute == '/admin',
                        onTap: () => context.go('/admin'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Footer
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey[800]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'v1.0.0',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NavSection extends StatelessWidget {
  final String title;
  final List<_NavItem> items;

  const _NavSection({
    required this.title,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...items,
      ],
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String route;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        hoverColor: Colors.grey[800]?.withValues(alpha: 0.3),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey[800] : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isSelected
                ? Border.all(
                    color: Theme.of(context).primaryColor,
                    width: 1,
                  )
                : null,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey[400],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: isSelected ? Colors.white : Colors.grey[300],
                    fontWeight:
                        isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
