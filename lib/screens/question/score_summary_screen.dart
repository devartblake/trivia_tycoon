import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../game/state/tier_update_result.dart';

class EnhancedScoreSummaryScreen extends StatefulWidget {
  final int score;
  final int totalQuestions;
  final int totalXP;
  final int coins;
  final int diamonds;
  final int stars;
  final String classLevel;
  final String category;
  final Map<String, int> categoryScores;
  final List<String> achievements;
  final Duration quizDuration;
  final TierUpdateResult? tierResult;

  const EnhancedScoreSummaryScreen({
    super.key,
    required this.score,
    required this.totalQuestions,
    this.totalXP = 0,
    this.coins = 0,
    this.diamonds = 0,
    this.stars = 0,
    this.classLevel = '1',
    this.category = 'Mixed',
    this.categoryScores = const {},
    this.achievements = const [],
    this.quizDuration = const Duration(minutes: 5),
    this.tierResult,
  });

  @override
  State<EnhancedScoreSummaryScreen> createState() => _EnhancedScoreSummaryScreenState();
}

class _EnhancedScoreSummaryScreenState extends State<EnhancedScoreSummaryScreen>
    with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _celebrationController;
  late AnimationController _rewardAnimationController;

  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late List<Animation<int>> _rewardAnimations;

  bool _showDetailedStats = false;

  @override
  void initState() {
    super.initState();

    _mainAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _celebrationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _rewardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.elasticOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _mainAnimationController, curve: Curves.easeOut),
    );

    _rewardAnimations = [
      IntTween(begin: 0, end: widget.coins).animate(
        CurvedAnimation(
          parent: _rewardAnimationController,
          curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
        ),
      ),
      IntTween(begin: 0, end: widget.diamonds).animate(
        CurvedAnimation(
          parent: _rewardAnimationController,
          curve: const Interval(0.2, 0.6, curve: Curves.easeOut),
        ),
      ),
      IntTween(begin: 0, end: widget.stars).animate(
        CurvedAnimation(
          parent: _rewardAnimationController,
          curve: const Interval(0.4, 0.8, curve: Curves.easeOut),
        ),
      ),
      IntTween(begin: 0, end: widget.totalXP).animate(
        CurvedAnimation(
          parent: _rewardAnimationController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
        ),
      ),
    ];

    // Start animations sequentially
    _mainAnimationController.forward().then((_) {
      _celebrationController.forward();
      Future.delayed(const Duration(milliseconds: 500), () {
        _rewardAnimationController.forward();
      });
    });
  }

  @override
  void dispose() {
    _mainAnimationController.dispose();
    _celebrationController.dispose();
    _rewardAnimationController.dispose();
    super.dispose();
  }

  Color _getClassColor() {
    switch (widget.classLevel.toLowerCase()) {
      case 'kindergarten':
      case 'k':
        return Colors.pink;
      case '1':
        return Colors.orange;
      case '2':
        return Colors.blue;
      case '3':
        return Colors.green;
      default:
        return Colors.purple;
    }
  }

  String _getPerformanceLevel() {
    final percentage = (widget.score / widget.totalQuestions) * 100;
    if (percentage >= 90) return "Outstanding";
    if (percentage >= 80) return "Excellent";
    if (percentage >= 70) return "Good";
    if (percentage >= 60) return "Fair";
    return "Keep Practicing";
  }

  String _getEncouragingMessage() {
    final percentage = (widget.score / widget.totalQuestions) * 100;
    final messages = {
      90: [
        "You're a learning superstar!",
        "Amazing work! You've mastered this topic!",
        "Incredible! You really know your stuff!",
      ],
      80: [
        "Great job! You're really getting it!",
        "Excellent work! Keep it up!",
        "You're doing fantastic!",
      ],
      70: [
        "Good effort! You're on the right track!",
        "Nice work! You're improving!",
        "Well done! Keep learning!",
      ],
      60: [
        "Good try! Practice makes perfect!",
        "You're getting there! Keep going!",
        "Every question makes you smarter!",
      ],
      0: [
        "Learning is a journey! Keep exploring!",
        "Every attempt helps you grow!",
        "Don't give up! You've got this!",
      ],
    };

    final threshold = percentage >= 90 ? 90 :
    percentage >= 80 ? 80 :
    percentage >= 70 ? 70 :
    percentage >= 60 ? 60 : 0;

    final messageList = messages[threshold]!;
    return messageList[widget.score.hashCode % messageList.length];
  }

  IconData _getPerformanceIcon() {
    final percentage = (widget.score / widget.totalQuestions) * 100;
    if (percentage >= 90) return Icons.star;
    if (percentage >= 80) return Icons.thumb_up;
    if (percentage >= 70) return Icons.sentiment_satisfied;
    if (percentage >= 60) return Icons.sentiment_neutral;
    return Icons.school;
  }

  @override
  Widget build(BuildContext context) {
    final classColor = _getClassColor();
    final percentage = (widget.score / widget.totalQuestions) * 100;

    return Scaffold(
      backgroundColor: Colors.grey.shade300,
      appBar: AppBar(
        title: const Text("Quiz Complete!"),
        backgroundColor: Colors.grey.shade100,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: true,
      ),
      body: AnimatedBuilder(
        animation: _fadeAnimation,
        builder: (context, child) {
          return Opacity(
            opacity: _fadeAnimation.value,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Main Score Display
                  SlideTransition(
                    position: _slideAnimation,
                    child: ScaleTransition(
                      scale: _scaleAnimation,
                      child: _buildMainScoreCard(classColor, percentage),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Performance Level
                  _buildPerformanceLevelCard(classColor),

                  const SizedBox(height: 24),

                  // Rewards Section
                  _buildRewardsSection(classColor),

                  const SizedBox(height: 24),

                  // Achievements (if any)
                  if (widget.achievements.isNotEmpty)
                    _buildAchievementsSection(classColor),

                  const SizedBox(height: 24),

                  // Detailed Stats Toggle
                  _buildStatsToggle(classColor),

                  // Detailed Stats (if expanded)
                  if (_showDetailedStats) ...[
                    const SizedBox(height: 16),
                    _buildDetailedStats(classColor),
                  ],

                  const SizedBox(height: 32),

                  // Action Buttons
                  _buildActionButtons(classColor),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMainScoreCard(Color classColor, double percentage) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white,
            classColor.withOpacity(0.1),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: classColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // Performance Icon with Animation
          AnimatedBuilder(
            animation: _celebrationController,
            builder: (context, child) {
              return Transform.scale(
                scale: 1.0 + (_celebrationController.value * 0.1),
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: classColor,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: classColor.withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Icon(
                    _getPerformanceIcon(),
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Score Display
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                widget.score.toString(),
                style: TextStyle(
                  fontSize: 64,
                  fontWeight: FontWeight.bold,
                  color: classColor,
                ),
              ),
              Text(
                " / ${widget.totalQuestions}",
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Percentage
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: classColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${percentage.round()}%",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: classColor,
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Encouraging Message
          Text(
            _getEncouragingMessage(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: classColor,
            ),
          ),

          const SizedBox(height: 16),

          // Duration display
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: classColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer, size: 16, color: classColor),
                const SizedBox(width: 8),
                Text(
                  "Completed in ${widget.quizDuration.inMinutes}m ${widget.quizDuration.inSeconds % 60}s",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: classColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceLevelCard(Color classColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: classColor, size: 24),
              const SizedBox(width: 12),
              Text(
                "Performance Level",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: classColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _getPerformanceLevel(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: classColor,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: classColor,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    "Class ${widget.classLevel}",
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection(Color classColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.card_giftcard, color: classColor, size: 24),
              const SizedBox(width: 12),
              const Text(
                "Rewards Earned",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              if (widget.coins > 0)
                Expanded(
                  child: _buildRewardItem(
                    icon: Icons.monetization_on,
                    label: "Coins",
                    animation: _rewardAnimations[0],
                    color: Colors.amber,
                  ),
                ),

              if (widget.diamonds > 0) ...[
                if (widget.coins > 0) const SizedBox(width: 12),
                Expanded(
                  child: _buildRewardItem(
                    icon: Icons.diamond,
                    label: "Diamonds",
                    animation: _rewardAnimations[1],
                    color: Colors.lightBlue,
                  ),
                ),
              ],

              if (widget.stars > 0) ...[
                if (widget.coins > 0 || widget.diamonds > 0) const SizedBox(width: 12),
                Expanded(
                  child: _buildRewardItem(
                    icon: Icons.star,
                    label: "Stars",
                    animation: _rewardAnimations[2],
                    color: Colors.orange,
                  ),
                ),
              ],

              if (widget.totalXP > 0) ...[
                if (widget.coins > 0 || widget.diamonds > 0 || widget.stars > 0)
                  const SizedBox(width: 12),
                Expanded(
                  child: _buildRewardItem(
                    icon: Icons.psychology,
                    label: "XP",
                    animation: _rewardAnimations[3],
                    color: Colors.purple,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRewardItem({
    required IconData icon,
    required String label,
    required Animation<int> animation,
    required Color color,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                animation.value.toString(),
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsSection(Color classColor) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 24),
              const SizedBox(width: 12),
              const Text(
                "New Achievements",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          ...widget.achievements.map((achievement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        achievement,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildStatsToggle(Color classColor) {
    return GestureDetector(
      onTap: () => setState(() => _showDetailedStats = !_showDetailedStats),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: classColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.analytics, color: classColor, size: 20),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Detailed Statistics",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Icon(
              _showDetailedStats ? Icons.expand_less : Icons.expand_more,
              color: classColor,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStats(Color classColor) {
    final minutes = widget.quizDuration.inMinutes;
    final seconds = widget.quizDuration.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStatRow("Quiz Duration", "${minutes}m ${seconds}s", Icons.timer),
          _buildStatRow("Category", widget.category, Icons.category),
          _buildStatRow("Correct Answers", "${widget.score}", Icons.check_circle),
          _buildStatRow("Incorrect Answers", "${widget.totalQuestions - widget.score}", Icons.cancel),

          // NEW: Tier progression info
          if (widget.tierResult?.tierChanged == true) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.amber.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.trending_up, color: Colors.amber, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Tier ${widget.tierResult!.oldTierId + 1} → Tier ${widget.tierResult!.newTierId + 1}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (widget.categoryScores.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              "Subject Breakdown",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...widget.categoryScores.entries.map((entry) {
              return _buildStatRow(
                entry.key.replaceAll('_', ' ').toUpperCase(),
                "${entry.value} correct",
                Icons.book,
              );
            }).toList(),
          ],
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(Color classColor) {
    return Column(
      children: [
        // Primary Actions
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // Start a new quiz with same parameters
                  context.go('/quiz/play', extra: {
                    'classLevel': widget.classLevel,
                    'category': widget.category,
                    'questionCount': widget.totalQuestions,
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text("Try Again"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: classColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(width: 16),

            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.go('/'),
                icon: const Icon(Icons.home),
                label: const Text("Home"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: classColor,
                  side: BorderSide(color: classColor),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Secondary Actions
        Row(
          children: [
            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  // Navigate to category selection
                  context.push('/all-categories');
                },
                icon: Icon(Icons.explore, color: classColor),
                label: Text(
                  "Explore More",
                  style: TextStyle(color: classColor),
                ),
              ),
            ),

            Expanded(
              child: TextButton.icon(
                onPressed: () {
                  // Share results functionality
                  _shareResults();
                },
                icon: Icon(Icons.share, color: classColor),
                label: Text(
                  "Share",
                  style: TextStyle(color: classColor),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _shareResults() {
    // Implement share functionality
    final message = "I just scored ${widget.score}/${widget.totalQuestions} "
        "(${((widget.score / widget.totalQuestions) * 100).round()}%) "
        "on a Class ${widget.classLevel} ${widget.category} quiz! 🎉";

    // This would typically use a share plugin
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Share: $message"),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
