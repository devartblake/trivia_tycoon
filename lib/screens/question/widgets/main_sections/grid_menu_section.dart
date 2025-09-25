import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GridMenuSection extends StatelessWidget {
  const GridMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> menuItems = [
      {
        "icon": Icons.history_outlined,
        "label": "History",
        "color": Colors.blue,
        "route": "/history",
        "description": "View past quizzes"
      },
      {
        "icon": Icons.trending_up_outlined,
        "label": "Leaderboard",
        "color": Colors.green,
        "route": "/leaderboard",
        "description": "Top performers"
      },
      {
        "icon": Icons.star_outline,
        "label": "Favorites",
        "color": Colors.amber,
        "route": "/favorites",
        "description": "Saved questions"
      },
      {
        "icon": Icons.group_outlined,
        "label": "Multiplayer",
        "color": Colors.purple,
        "route": "/multiplayer",
        "description": "Play with friends"
      },
      {
        "icon": Icons.settings_outlined,
        "label": "Settings",
        "color": Colors.grey,
        "route": "/settings",
        "description": "App preferences"
      },
      {
        "icon": Icons.help_outline,
        "label": "Help",
        "color": Colors.teal,
        "route": "/help",
        "description": "Support center"
      },
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Quick Actions",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              GestureDetector(
                onTap: () {
                  context.push('/all-actions');
                },
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.grey.shade600,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 3.2, // Increased from 2.8 to give more height
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: menuItems.length,
            itemBuilder: (context, index) {
              final item = menuItems[index];
              return _buildRectangularMenuItem(
                context,
                item["icon"],
                item["label"],
                item["color"],
                item["route"],
                item["description"],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRectangularMenuItem(
      BuildContext context,
      IconData icon,
      String label,
      Color color,
      String route,
      String description,
      ) {
    return GestureDetector(
      onTap: () {
        context.push(route);
      },
      child: Container(
        padding: const EdgeInsets.all(10), // Reduced from 12 to 10
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6), // Reduced from 8 to 6
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 18, // Reduced from 20 to 18
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 10), // Reduced from 12 to 10
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min, // Added to prevent overflow
                children: [
                  Flexible( // Wrapped with Flexible
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13, // Reduced from 14 to 13
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(height: 1), // Reduced from 2 to 1
                  Flexible( // Wrapped with Flexible
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 10, // Reduced from 11 to 10
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
