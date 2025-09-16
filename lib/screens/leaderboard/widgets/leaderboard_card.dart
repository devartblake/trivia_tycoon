import 'package:flutter/material.dart';
import '../../../game/models/leaderboard_entry.dart';
import '../../leaderboard/widgets/shimmer_avatar.dart';
import '../../profile/user_profile_screen.dart';

class LeaderboardCard extends StatefulWidget {
  final LeaderboardEntry entry;
  final int rank;

  const LeaderboardCard({
    super.key,
    required this.entry,
    required this.rank,
  });

  @override
  State<LeaderboardCard> createState() => _LeaderboardCardState();
}

class _LeaderboardCardState extends State<LeaderboardCard> with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Widget _buildMedalIcon(int rank) {
    switch (rank) {
      case 1:
        return const Icon(Icons.emoji_events, color: Colors.amber, size: 28);
      case 2:
        return const Icon(Icons.emoji_events, color: Colors.grey, size: 24);
      case 3:
        return const Icon(Icons.emoji_events, color: Colors.brown, size: 24);
      default:
        return Text(
          '#$rank',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final xp = entry.xpProgress.clamp(0.0, 1.0);
    final accuracy = ((entry.accuracy ?? 0.0) * 100).clamp(0, 100).toInt();
    final ageLabel = entry.ageGroup ?? "Unknown";

    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          PageRouteBuilder(
            pageBuilder: (_, __, ___) => UserProfileScreen(entry: entry),
            transitionsBuilder: (_, animation, __, child) {
              return SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(1, 0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeInOut,
                )),
                child: child,
              );
            },
          ),
        );
      },

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Row(
          children: [
            // Rank / Medal with animation
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: widget.rank.toDouble()),
              duration: const Duration(milliseconds: 500),
              builder: (context, value, _) => _buildMedalIcon(value.round()),
            ),

            const SizedBox(width: 16),

            // Avatar with shimmer + status badge
            ShimmerAvatar(
              avatarPath: entry.avatar,
              initials: (entry.playerName.isNotEmpty)
                  ? entry.playerName[0].toUpperCase()
                  : '?',
              ageGroup: entry.ageGroup,
              gender: entry.gender,
              radius: 24,
              xpProgress: entry.xpProgress,
              status: entry.status,
            ),

            const SizedBox(width: 12),

            // Username + XP Bar + Accuracy
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.playerName, style: Theme.of(context).textTheme.titleMedium),
                  Text("Age: $ageLabel", style: const TextStyle(fontSize: 12)),

                  const SizedBox(height: 4),

                  // Animated XP Bar with pulse
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: xp),
                    duration: const Duration(milliseconds: 700),
                    builder: (context, value, _) {
                      return ScaleTransition(
                        scale: Tween<double>(begin: 0.97, end: 1.03).animate(
                          CurvedAnimation(
                            parent: _pulseController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: LinearProgressIndicator(
                          value: value,
                          minHeight: 6,
                          backgroundColor: Colors.grey[200],
                          color: Colors.blueAccent,
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 4),

                  // Accuracy Percentage
                  LinearProgressIndicator(
                    value: (entry.accuracy ?? 0.0).clamp(0.0, 1.0),
                    minHeight: 5,
                    color: Colors.green,
                    backgroundColor: Colors.grey[300],
                  ),
                  Text("Accuracy: $accuracy%", style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // Score with animation
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: entry.score.toDouble()),
              duration: const Duration(milliseconds: 700),
              builder: (context, value, _) => Text(
                value.toInt().toString(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
