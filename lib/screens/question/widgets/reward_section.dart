import 'package:flutter/material.dart';

class EnhancedRewardSection extends StatefulWidget {
  final int coins;
  final int diamonds;
  final int stars;
  final String classLevel;
  final List<String> achievements;
  final bool showAnimation;

  const EnhancedRewardSection({
    super.key,
    required this.coins,
    required this.diamonds,
    this.stars = 0,
    this.classLevel = '1',
    this.achievements = const [],
    this.showAnimation = true,
  });

  @override
  State<EnhancedRewardSection> createState() => _EnhancedRewardSectionState();
}

class _EnhancedRewardSectionState extends State<EnhancedRewardSection>
    with TickerProviderStateMixin {
  late AnimationController _rewardAnimationController;
  late AnimationController _achievementAnimationController;
  late List<Animation<int>> _rewardAnimations;

  @override
  void initState() {
    super.initState();

    _rewardAnimationController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _achievementAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _rewardAnimations = [
      IntTween(begin: 0, end: widget.coins).animate(
        CurvedAnimation(
          parent: _rewardAnimationController,
          curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
        ),
      ),
      IntTween(begin: 0, end: widget.diamonds).animate(
        CurvedAnimation(
          parent: _rewardAnimationController,
          curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
        ),
      ),
      IntTween(begin: 0, end: widget.stars).animate(
        CurvedAnimation(
          parent: _rewardAnimationController,
          curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
        ),
      ),
    ];

    if (widget.showAnimation) {
      _rewardAnimationController.forward();
      Future.delayed(const Duration(milliseconds: 1000), () {
        _achievementAnimationController.forward();
      });
    }
  }

  @override
  void dispose() {
    _rewardAnimationController.dispose();
    _achievementAnimationController.dispose();
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

  @override
  Widget build(BuildContext context) {
    final classColor = _getClassColor();

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            classColor.withOpacity(0.1),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: classColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.card_giftcard,
                  color: Colors.white,
                  size: 20,
                ),
              ),
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

          // Reward Items
          Row(
            children: [
              Expanded(
                child: _buildRewardItem(
                  icon: Icons.monetization_on,
                  label: "Coins",
                  animation: _rewardAnimations[0],
                  color: Colors.amber,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _buildRewardItem(
                  icon: Icons.diamond,
                  label: "Diamonds",
                  animation: _rewardAnimations[1],
                  color: Colors.lightBlue,
                ),
              ),

              if (widget.stars > 0) ...[
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRewardItem(
                    icon: Icons.star,
                    label: "Stars",
                    animation: _rewardAnimations[2],
                    color: Colors.orange,
                  ),
                ),
              ],
            ],
          ),

          // Achievements Section
          if (widget.achievements.isNotEmpty) ...[
            const SizedBox(height: 24),
            _buildAchievementsSection(),
          ],

          // Motivational Message
          const SizedBox(height: 20),
          _buildMotivationalMessage(),
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
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),

              const SizedBox(height: 8),

              Text(
                animation.value.toString(),
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.green.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.green,
                size: 20,
              ),
              const SizedBox(width: 8),
              const Text(
                "New Achievements",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...widget.achievements.map((achievement) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      achievement,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMotivationalMessage() {
    final messages = [
      "Keep up the amazing work!",
      "You're becoming a learning superstar!",
      "Every question makes you smarter!",
      "Great job exploring new topics!",
      "Your curiosity is your superpower!",
    ];

    final message = messages[widget.coins.hashCode % messages.length];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _getClassColor().withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(
            Icons.lightbulb,
            color: _getClassColor(),
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _getClassColor(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
