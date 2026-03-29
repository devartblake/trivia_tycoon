import 'package:flutter/material.dart';

/// Styled tab bar for the profile screen collection/stats/awards/created tabs.
class ProfileTabBar extends StatelessWidget {
  const ProfileTabBar({super.key, required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: TabBar(
          controller: controller,
          indicatorColor: const Color(0xFF6A5ACD),
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.tab,
          labelColor: const Color(0xFF6A5ACD),
          unselectedLabelColor: Colors.grey[600],
          labelStyle: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
          dividerColor: Colors.transparent,
          tabs: const [
            Tab(
              icon: Icon(Icons.grid_view_rounded, size: 22),
              text: 'Collection',
            ),
            Tab(
              icon: Icon(Icons.bar_chart_rounded, size: 22),
              text: 'Stats',
            ),
            Tab(
              icon: Icon(Icons.emoji_events_rounded, size: 22),
              text: 'Awards',
            ),
            Tab(
              icon: Icon(Icons.create_rounded, size: 22),
              text: 'Created',
            ),
          ],
        ),
      ),
    );
  }
}
