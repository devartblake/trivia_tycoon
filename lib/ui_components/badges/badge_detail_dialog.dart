import 'package:flutter/material.dart';
import '../../game/models/badge.dart';

class BadgeDetailDialog extends StatelessWidget {
  final GameBadge badge;

  const BadgeDetailDialog({super.key, required this.badge});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(badge.name),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(badge.iconPath, height: 60),
          const SizedBox(height: 12),
          Text(badge.description),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Close"),
        ),
      ],
    );
  }
}