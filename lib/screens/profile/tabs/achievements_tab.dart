import 'package:flutter/material.dart';
import '../../../ui_components/badges/badge_grid_widget.dart';

class AchievementsTab extends StatelessWidget {
  const AchievementsTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text("🏆 Your Badges", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 12),
          Expanded(child: BadgeGridWidget(badges: [],)),
        ],
      ),
    );
  }
}
