import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';

enum GameMode {
  classic,
  topicExplorer,
  survival,
  arena,
  teams,
  daily,
}

class PlayQuizScreen extends StatefulWidget {
  const PlayQuizScreen({super.key});

  @override
  State<PlayQuizScreen> createState() => _PlayQuizScreenState();
}

class _PlayQuizScreenState extends State<PlayQuizScreen> {
  Timer? _timer;
  Duration _timeRemaining = const Duration(hours: 23, minutes: 45, seconds: 30);

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining.inSeconds > 0) {
        setState(() {
          _timeRemaining = Duration(seconds: _timeRemaining.inSeconds - 1);
        });
      } else {
        timer.cancel();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    return "${hours}d ${minutes}h";
  }

  void _navigateToHowToPlay(BuildContext context, GameMode gameMode) {
    context.push('/how-to-play/${gameMode.name}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text(
          'Choose a game mode',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Classic Mode - Large Card
            _SimpleGameCard(
              title: 'CLASSIC',
              gradient: const LinearGradient(
                colors: [Color(0xFF4FC3F7), Color(0xFF29B6F6)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              height: 180,
              titleSize: 32,
              onTap: () => _navigateToHowToPlay(context, GameMode.classic),
            ),

            const SizedBox(height: 16),

            // Topics Mode - Full Width
            _SimpleGameCard(
              title: 'TOPICS',
              gradient: const LinearGradient(
                colors: [Color(0xFF66BB6A), Color(0xFF4CAF50)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              height: 120,
              titleSize: 24,
              onTap: () => _navigateToHowToPlay(context, GameMode.topicExplorer),
            ),

            const SizedBox(height: 16),

            // Survival and Arena Row
            Row(
              children: [
                Expanded(
                  child: _SimpleGameCard(
                    title: 'SURVIVAL',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFB74D), Color(0xFFFF9800)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    height: 140,
                    titleSize: 18,
                    onTap: () => _navigateToHowToPlay(context, GameMode.survival),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SimpleGameCard(
                    title: 'TREASURE MINE',
                    gradient: const LinearGradient(
                      colors: [Color(0xFFEF5350), Color(0xFFF44336)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    height: 140,
                    titleSize: 16,
                    onTap: () => _navigateToHowToPlay(context, GameMode.arena),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Survival Arena - Single Card
            _SimpleGameCard(
              title: 'SURVIVAL ARENA',
              gradient: const LinearGradient(
                colors: [Color(0xFFAB47BC), Color(0xFF9C27B0)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              height: 120,
              titleSize: 20,
              width: MediaQuery.of(context).size.width * 0.6,
              onTap: () => _navigateToHowToPlay(context, GameMode.teams),
            ),

            const SizedBox(height: 32),

            // Events Section
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Events',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Grand Prix Event - Using the original _EventWidget
            _EventWidget(
              title: "Grand Prix Championship",
              description: "Compete for ultimate glory and exclusive rewards",
              endsIn: _timeRemaining,
              gradient: const LinearGradient(
                colors: [Color(0xFF42A5F5), Color(0xFF1E88E5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              onTap: () => _showComingSoon(context, 'Grand Prix Event'),
            ),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature coming soon!'),
        backgroundColor: Colors.blue.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _SimpleGameCard extends StatelessWidget {
  final String title;
  final Gradient gradient;
  final double height;
  final double titleSize;
  final double? width;
  final VoidCallback onTap;

  const _SimpleGameCard({
    required this.title,
    required this.gradient,
    required this.height,
    required this.titleSize,
    this.width,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Decorative elements (you can add custom illustrations here)
            Positioned(
              top: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForTitle(title),
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),

            // Title
            Positioned(
              left: 20,
              bottom: 20,
              child: Text(
                title,
                style: TextStyle(
                  fontSize: titleSize,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      offset: const Offset(2, 2),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),

            // Sparkle effects
            Positioned(
              top: height * 0.2,
              right: width != null ? width! * 0.3 : 60,
              child: Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              top: height * 0.6,
              right: width != null ? width! * 0.2 : 40,
              child: Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'classic':
        return Icons.quiz;
      case 'topics':
        return Icons.explore;
      case 'survival':
        return Icons.local_fire_department;
      case 'treasure mine':
        return Icons.diamond;
      case 'survival arena':
        return Icons.sports_martial_arts;
      default:
        return Icons.games;
    }
  }
}

class _EventWidget extends StatelessWidget {
  final String title;
  final String description;
  final Duration endsIn;
  final Gradient gradient;
  final VoidCallback onTap;

  const _EventWidget({
    required this.title,
    required this.description,
    required this.endsIn,
    required this.gradient,
    required this.onTap,
  });

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return "${hours}h ${minutes}m ${seconds}s";
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.3),
              spreadRadius: 2,
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.event,
                        color: Colors.white,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          'LIVE EVENT',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Ends in: ${_formatDuration(endsIn)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}