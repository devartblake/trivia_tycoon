import 'package:flutter/material.dart';
import '../../game/models/badge.dart';
import 'badge_item_tile.dart';

class BadgeGridWidget extends StatelessWidget {
  final List<GameBadge> badges;

  const BadgeGridWidget({super.key, required this.badges});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: badges.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        return BadgeItemTile(badge: badges[index]);
      },
    );
  }
}