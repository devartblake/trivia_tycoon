import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Define a breakpoint for switching between mobile and web layouts
const double kWebBreakpoint = 800.0;

class AdminDashboardShell extends StatelessWidget {
  final Widget child;

  const AdminDashboardShell({
    super.key,
    required this.child,
  });

  // Helper method to determine the current navigation index from the route path
  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/admin/analytics')) {
      return 1;
    }
    if (location.startsWith('/admin/settings')) {
      return 2;
    }
    // Default to the dashboard
    return 0;
  }

  // Helper method to handle navigation taps
  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('admin-dashboard');
        break;
      case 1:
        context.goNamed('admin-analytics');
        break;
      case 2:
        context.goNamed('admin-settings');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // LayoutBuilder provides the screen constraints to decide which UI to build
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < kWebBreakpoint) {
          return _buildMobileLayout(context);
        } else {
          return _buildWebLayout(context);
        }
      },
    );
  }

  // The Web Layout uses a persistent NavigationRail
  Widget _buildWebLayout(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: selectedIndex,
            onDestinationSelected: (index) => _onItemTapped(index, context),
            labelType: NavigationRailLabelType.all,
            leading: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Icon(
                Icons.admin_panel_settings_rounded,
                color: Theme.of(context).colorScheme.primary,
                size: 32,
              ),
            ),
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.dashboard_outlined),
                selectedIcon: Icon(Icons.dashboard_rounded),
                label: Text('Dashboard'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics_rounded),
                label: Text('Analytics'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: Text('Settings'),
              ),
            ],
          ),
          const VerticalDivider(thickness: 1, width: 1),
          // The main content area is the `child` widget passed from ShellRoute
          Expanded(
            child: child,
          ),
        ],
      ),
    );
  }

  // The Mobile Layout uses a standard AppBar and Drawer
  Widget _buildMobileLayout(BuildContext context) {
    final int selectedIndex = _calculateSelectedIndex(context);

    return Scaffold(
      // The AppBar title can change based on the selected page
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Colors.deepOrange[400],
      ),
      // The body is the `child` widget passed from ShellRoute
      body: child,
      drawer: Drawer(
        child: ListView(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.deepOrange[400]),
              child: const Text('Admin Menu', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard_rounded),
              title: const Text('Dashboard'),
              selected: selectedIndex == 0,
              onTap: () {
                _onItemTapped(0, context);
                Navigator.pop(context); // Close the drawer
              },
            ),
            ListTile(
              leading: const Icon(Icons.analytics_rounded),
              title: const Text('Analytics'),
              selected: selectedIndex == 1,
              onTap: () {
                _onItemTapped(1, context);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_rounded),
              title: const Text('Settings'),
              selected: selectedIndex == 2,
              onTap: () {
                _onItemTapped(2, context);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
