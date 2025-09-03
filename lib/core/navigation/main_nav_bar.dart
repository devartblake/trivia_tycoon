import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/ui_components/navigation/fluid_nav_bar.dart';
import 'package:trivia_tycoon/ui_components/navigation/fluid_nav_bar_icon.dart';
import 'package:trivia_tycoon/ui_components/navigation/fluid_nav_bar_style.dart';

class MainNavBar extends StatelessWidget {
  final Widget child;

  const MainNavBar({super.key, required this.child});

  static const List<_NavItem> _navItems = [
    _NavItem(label: 'Home', icon: Icons.home, route: '/store'),
    _NavItem(label: 'Quiz', icon: Icons.quiz, route: '/quiz'),
    _NavItem(label: 'Leaderboard', icon: Icons.leaderboard, route: '/leaderboard'),
    _NavItem(label: 'Profile', icon: Icons.person, route: '/profile'),
    _NavItem(label: 'Settings', icon: Icons.settings, route: '/settings'),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final index = _navItems.indexWhere((item) => location.startsWith(item.route));
    return index == -1 ? 0 : index;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: FluidNavBar(
        body: const SizedBox.shrink(),
        icons: _navItems.map((item) => FluidNavBarIcon(icon: item.icon, extras: {'label': item.label})).toList(),
        defaultIndex: currentIndex,
        onChange: (index) {
          final route = _navItems[index].route;
          final location = GoRouterState.of(context).uri.toString();
          if (location != route) {
            context.go(route);
          }
        },
        style: FluidNavBarStyle(
          barBackgroundColor: Theme.of(context).primaryColor,
          iconSelectedForegroundColor: Colors.white,
          iconUnselectedForegroundColor: Colors.black54,
        ),
        scaleFactor: 1.5,
        itemBuilder: (icon, item) => Semantics(
          label: icon.extras?['label'] ?? 'Tab',
          child: item as Widget?, // ✅ FIX: cast to Widget?
        ),
      ),
    );
  }
}

class _NavItem {
  final String label;
  final IconData icon;
  final String route;

  const _NavItem({required this.label, required this.icon, required this.route});
}
