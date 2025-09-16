import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class TopMenuSection extends StatelessWidget {
  const TopMenuSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.purple.shade50, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
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
        children: [
          // User Profile Section
          Row(
            children: [
              GestureDetector(
                onTap: () => context.push('/profile'),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.purple.shade200,
                      width: 3,
                    ),
                  ),
                  child: const CircleAvatar(
                    radius: 28,
                    backgroundImage: AssetImage('assets/images/avatars/default-avatar.png'),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: GestureDetector(
                  onTap: () => context.push('/profile'),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        "Username", // TODO: Connect to user provider in Phase 2
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Diamond/Points Display - Tappable to show details
              GestureDetector(
                onTap: () => _showPointsDialog(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.purple.shade100,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.purple.shade200,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.diamond,
                        color: Colors.purple.shade700,
                        size: 18,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        "12,000", // TODO: Connect to user points provider in Phase 2
                        style: TextStyle(
                          color: Colors.purple.shade700,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Action Buttons with enhanced navigation
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildActionButton(
                context: context,
                icon: Icons.play_arrow_rounded,
                label: "Play Quiz",
                color: Colors.green,
                onTap: () => _handlePlayQuizTap(context),
              ),
              _buildActionButton(
                context: context,
                icon: Icons.add_circle_outline,
                label: "Create Quiz",
                color: Colors.purple,
                onTap: () => _handleCreateQuizTap(context),
              ),
              _buildActionButton(
                context: context,
                icon: Icons.emoji_events_outlined,
                label: "Achievements",
                color: Colors.orange,
                onTap: () => _handleAchievementsTap(context),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.3),
                  spreadRadius: 0,
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    size: 24,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Enhanced navigation handlers with custom logic
  void _handlePlayQuizTap(BuildContext context) {
    // TODO: Add analytics tracking in Phase 2
    // TODO: Check if user has completed onboarding in Phase 2
    context.push('/play-quiz');
  }

  void _handleCreateQuizTap(BuildContext context) {
    // TODO: Check if user has premium access in Phase 2
    // TODO: Add analytics tracking in Phase 2
    context.push('/create-quiz');
  }

  void _handleAchievementsTap(BuildContext context) {
    // TODO: Add analytics tracking in Phase 2
    context.push('/achievements');
  }

  // Dynamic greeting based on time of day
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return "Good Morning!";
    } else if (hour < 17) {
      return "Good Afternoon!";
    } else {
      return "Good Evening!";
    }
  }

  // Points dialog for showing point breakdown
  void _showPointsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.diamond, color: Colors.purple.shade700),
            const SizedBox(width: 8),
            const Text('Your Points'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPointRow('Quiz Points', '8,500'),
            _buildPointRow('Daily Bonus', '2,000'),
            _buildPointRow('Achievements', '1,500'),
            const Divider(),
            _buildPointRow('Total', '12,000', isTotal: true),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/store');
            },
            child: const Text('Spend Points'),
          ),
        ],
      ),
    );
  }

  Widget _buildPointRow(String label, String points, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            points,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? Colors.purple.shade700 : null,
            ),
          ),
        ],
      ),
    );
  }
}