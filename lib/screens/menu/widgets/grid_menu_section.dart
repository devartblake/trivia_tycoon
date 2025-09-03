import 'package:flutter/material.dart';

class GridMenuSection extends StatelessWidget {
  const GridMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {"icon": Icons.history, "label": "History"},
      {"icon": Icons.trending_up, "label": "Leaderboard"},
      {"icon": Icons.star, "label": "Favorites"},
      {"icon": Icons.group, "label": "Multiplayer"},
      {"icon": Icons.settings, "label": "Settings"},
      {"icon": Icons.help_outline, "label": "Help"},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        return _buildRectangularMenuItem(menuItems[index]["icon"], menuItems[index]["label"]);
      },
    );
  }

  Widget _buildRectangularMenuItem(IconData icon, String label) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: Colors.blueAccent,
      ),
      onPressed: () {},
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }
}
