import 'package:flutter/material.dart';
import '../../game/models/badge.dart';

class BadgeItemTile extends StatelessWidget {
  final GameBadge badge;

  const BadgeItemTile({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: badge.description,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: badge.isUnlocked ? Colors.green[100] : Colors.grey[200],
          border: Border.all(
            color: badge.isUnlocked ? Colors.green : Colors.grey,
            width: 2,
          ),
        ),
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(badge.iconPath, height: 40),
            const SizedBox(height: 8),
            Text(
              badge.name,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}