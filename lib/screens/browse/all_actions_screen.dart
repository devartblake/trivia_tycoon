import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AllActionsScreen extends StatelessWidget {
  const AllActionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {'title': 'History', 'icon': Icons.history, 'route': '/history'},
      {'title': 'Leaderboard', 'icon': Icons.trending_up, 'route': '/leaderboard'},
      {'title': 'Favorites', 'icon': Icons.star, 'route': '/favorites'},
      {'title': 'Multiplayer', 'icon': Icons.group, 'route': '/multiplayer'},
      {'title': 'Settings', 'icon': Icons.settings, 'route': '/settings'},
      {'title': 'Help', 'icon': Icons.help_outline, 'route': '/help'},
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('All Actions'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Quick Actions',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: actions.length,
                itemBuilder: (context, index) {
                  final action = actions[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(action['icon'] as IconData, color: Colors.purple),
                      title: Text(action['title'] as String),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () => context.push(action['route'] as String),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      tileColor: Colors.purple.withOpacity(0.1),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}