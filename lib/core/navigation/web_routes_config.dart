import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../screens/leaderboard/tier_progression_showcase_screen.dart';
import '../../screens/leaderboard/comprehensive_leaderboard_screen.dart';

/// Web-specific routes configuration
final List<RouteBase> webRoutes = [
  GoRoute(
    path: '/tier-progression',
    name: 'tier-progression',
    builder: (context, state) => const TierProgressionShowcaseScreen(),
  ),
  GoRoute(
    path: '/leaderboard-advanced',
    name: 'leaderboard-advanced',
    builder: (context, state) {
      final api = state.extra as dynamic; // Pass API client if needed
      return ComprehensiveLeaderboardScreen(
        api: api,
        seasonId: state.uri.queryParameters['season'],
      );
    },
  ),
  GoRoute(
    path: '/analytics',
    name: 'analytics',
    builder: (context, state) => const WebAnalyticsDashboard(),
  ),
  GoRoute(
    path: '/admin',
    name: 'admin',
    builder: (context, state) => const WebAdminPanel(),
  ),
];

/// Web Analytics Dashboard Screen
class WebAnalyticsDashboard extends StatefulWidget {
  const WebAnalyticsDashboard({super.key});

  @override
  State<WebAnalyticsDashboard> createState() => _WebAnalyticsDashboardState();
}

class _WebAnalyticsDashboardState extends State<WebAnalyticsDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics Dashboard',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            // Analytics cards grid
            GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 24,
              crossAxisSpacing: 24,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _AnalyticsCard(
                  title: 'Total Users',
                  value: '12,450',
                  icon: Icons.people,
                  color: Colors.blue,
                  trend: '+12% this month',
                ),
                _AnalyticsCard(
                  title: 'Active Sessions',
                  value: '2,340',
                  icon: Icons.login,
                  color: Colors.green,
                  trend: '+5% this week',
                ),
                _AnalyticsCard(
                  title: 'Total Matches',
                  value: '45,678',
                  icon: Icons.sports_basketball,
                  color: Colors.orange,
                  trend: '+8% this week',
                ),
                _AnalyticsCard(
                  title: 'Avg Tier Rank',
                  value: '5.2',
                  icon: Icons.emoji_events,
                  color: Colors.purple,
                  trend: 'Stable',
                ),
              ],
            ),
            const SizedBox(height: 32),
            Text(
              'Coming Soon',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Text(
              'More detailed analytics and charts will be available soon.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final String trend;

  const _AnalyticsCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              color.withValues(alpha: 0.05),
            ],
          ),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Icon(icon, color: color, size: 24),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              trend,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Web Admin Panel Screen
class WebAdminPanel extends StatefulWidget {
  const WebAdminPanel({super.key});

  @override
  State<WebAdminPanel> createState() => _WebAdminPanelState();
}

class _WebAdminPanelState extends State<WebAdminPanel> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        elevation: 0,
      ),
      body: Row(
        children: [
          // Tab navigation
          Container(
            width: 250,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(
                right: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Admin Sections',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ...[
                  ('Users', Icons.people),
                  ('Questions', Icons.help),
                  ('Tiers', Icons.emoji_events),
                  ('Reports', Icons.assessment),
                  ('Settings', Icons.settings),
                ].asMap().entries.map(
                  (entry) {
                    final index = entry.key;
                    final (label, icon) = entry.value;
                    return ListTile(
                      leading: Icon(icon),
                      title: Text(label),
                      selected: _selectedTab == index,
                      onTap: () => setState(() => _selectedTab = index),
                    );
                  },
                ),
              ],
            ),
          ),
          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Admin Panel',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coming Soon',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Administrative tools and management features will be available soon.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
