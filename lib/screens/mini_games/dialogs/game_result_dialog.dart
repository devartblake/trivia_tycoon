import 'package:flutter/material.dart';

/// Configuration for the game result screen
class GameResultConfig {
  final String gameTitle;
  final String completionTime;
  final String achievementTitle;
  final String achievementSubtitle;
  final int totalPlays;
  final int winPercentage;
  final String bestScore;
  final int currentStreak;
  final Color primaryColor;
  final IconData gameIcon;

  const GameResultConfig({
    required this.gameTitle,
    required this.completionTime,
    required this.achievementTitle,
    required this.achievementSubtitle,
    required this.totalPlays,
    required this.winPercentage,
    required this.bestScore,
    required this.currentStreak,
    this.primaryColor = const Color(0xFFFF6B35),
    this.gameIcon = Icons.emoji_events,
  });
}

class GameResultScreen extends StatelessWidget {
  final GameResultConfig config;
  final VoidCallback? onShare;
  final VoidCallback? onClose;
  final VoidCallback? onPlayAgain;

  const GameResultScreen({
    super.key,
    required this.config,
    this.onShare,
    this.onClose,
    this.onPlayAgain,
  });

  /// Presents the result screen as a full-screen page.
  static Future<void> show({
    required BuildContext context,
    required GameResultConfig config,
    VoidCallback? onShare,
    VoidCallback? onClose,
    VoidCallback? onPlayAgain,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GameResultScreen(
          config: config,
          onShare: onShare,
          onClose: onClose,
          onPlayAgain: onPlayAgain,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: config.primaryColor,
            foregroundColor: Colors.white,
            pinned: true,
            expandedHeight: 450, // Adjust this height as needed
            flexibleSpace: FlexibleSpaceBar(
              background: _HeaderSection(
                config: config,
                onShare: onShare,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: _StatsSection(
              config: config,
              onClose: onClose,
              onPlayAgain: onPlayAgain,
            ),
          )
        ],
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final GameResultConfig config;
  final VoidCallback? onShare;

  const _HeaderSection({required this.config, this.onShare});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            config.primaryColor,
            config.primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      padding: const EdgeInsets.only(top: kToolbarHeight + 24, left: 24, right: 24, bottom: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              config.gameIcon,
              size: 36,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            config.gameTitle,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'See you tomorrow!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4E6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer, size: 16, color: Color(0xFFF59E0B)),
                      const SizedBox(width: 6),
                      Text(
                        'solved in ${config.completionTime}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  config.achievementTitle,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  config.achievementSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade600, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsSection extends StatelessWidget {
  final GameResultConfig config;
  final VoidCallback? onClose;
  final VoidCallback? onPlayAgain;

  const _StatsSection({required this.config, this.onClose, this.onPlayAgain});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _StatItem(value: '${config.totalPlays}', label: 'Plays')),
              _VerticalDivider(),
              Expanded(child: _StatItem(value: '${config.winPercentage}%', label: 'Win %')),
              _VerticalDivider(),
              Expanded(child: _StatItem(value: config.bestScore, label: 'Best score')),
              _VerticalDivider(),
              Expanded(child: _StatItem(value: '${config.currentStreak}', label: 'Max streak')),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E6),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1-day win streak',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF92400E)),
                      ),
                      const SizedBox(height: 4),
                      Text('You\'re heating up!', style: TextStyle(fontSize: 13, color: Colors.grey.shade700)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.local_fire_department, color: Color(0xFFF59E0B), size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _DayIndicator(label: 'S', isCompleted: false),
              _DayIndicator(label: 'M', isCompleted: false),
              _DayIndicator(label: 'T', isCompleted: true),
              _DayIndicator(label: 'W', isCompleted: false),
              _DayIndicator(label: 'T', isCompleted: false),
              _DayIndicator(label: 'F', isCompleted: false),
              _DayIndicator(label: 'S', isCompleted: false),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _AchievementBadge(icon: Icons.star, label: '3 days', sublabel: 'Star', isEarned: true),
              _AchievementBadge(icon: Icons.star, label: '5 days', sublabel: 'Superstar', isEarned: false),
              _AchievementBadge(icon: Icons.emoji_events, label: '7 days', sublabel: 'Champion', isEarned: false),
              _AchievementBadge(icon: Icons.workspace_premium, label: '31 days', sublabel: 'Icon', isEarned: false),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onClose?.call();
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    side: BorderSide(color: Colors.grey.shade300, width: 1.5),
                  ),
                  child: const Text('Close', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPlayAgain?.call();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: config.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Play Again', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VerticalDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 40, color: Colors.grey.shade200);
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;
  const _StatItem({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
      ],
    );
  }
}

class _DayIndicator extends StatelessWidget {
  final String label;
  final bool isCompleted;
  const _DayIndicator({required this.label, required this.isCompleted});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: isCompleted ? const Color(0xFFF59E0B) : Colors.grey.shade200,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: isCompleted
            ? const Icon(Icons.check, color: Colors.white, size: 20)
            : Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade400)),
      ),
    );
  }
}

class _AchievementBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final bool isEarned;
  const _AchievementBadge({required this.icon, required this.label, required this.sublabel, required this.isEarned});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: isEarned ? const Color(0xFFF59E0B).withOpacity(0.1) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 28, color: isEarned ? const Color(0xFFF59E0B) : Colors.grey.shade300),
        ),
        const SizedBox(height: 8),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isEarned ? const Color(0xFF1E293B) : Colors.grey.shade400)),
        Text(sublabel, style: TextStyle(fontSize: 11, color: isEarned ? Colors.grey.shade600 : Colors.grey.shade400)),
      ],
    );
  }
}

// Helper function to format time from seconds
String formatGameTime(int seconds) {
  final minutes = seconds ~/ 60;
  final secs = seconds % 60;
  return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
}
