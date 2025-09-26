import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../game/models/game_mode.dart';

class HowToPlayScreen extends StatefulWidget {
  final GameMode gameMode;
  final bool isMultiplayer;

  const HowToPlayScreen({
    super.key,
    required this.gameMode,
    this.isMultiplayer = false,
  });

  @override
  State<HowToPlayScreen> createState() => _HowToPlayScreenState();
}

class _HowToPlayScreenState extends State<HowToPlayScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  static final Map<GameMode, GameModeInfo> _gameModeInfo = {
    GameMode.classic: GameModeInfo(
      title: 'Classic Quiz',
      description: 'Traditional quiz experience with multiple choice questions across various topics.',
      icon: Icons.quiz,
      gradient: LinearGradient(
        colors: [Colors.blue, Colors.blueAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      rules: [
        'Answer multiple choice questions from various categories',
        'Choose from 10, 25, or 50 question rounds',
        'Select difficulty: Easy, Medium, or Hard',
        'No time pressure - take your time to think',
        'Score points for correct answers',
        'Review results at the end',
      ],
      tips: [
        'Read questions carefully before selecting an answer',
        'Start with easier difficulties to build confidence',
        'Track your progress across different topics',
        'Review incorrect answers to learn from mistakes',
      ],
      features: {
        'Questions': '10-50 per round',
        'Categories': '20+ topics',
        'Difficulty': 'Easy to Hard',
        'Time Limit': 'None',
      },
      difficulty: 'Beginner Friendly',
      duration: '5-15 minutes',
      navigationRoute: '/category-quiz/general',
    ),

    GameMode.topicExplorer: GameModeInfo(
      title: 'Topic Explorer',
      description: 'Deep dive into specific subjects and master different categories with progressive learning.',
      icon: Icons.explore,
      gradient: LinearGradient(
        colors: [Colors.green, Colors.teal],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      rules: [
        'Choose from 25+ specialized categories',
        'Start with basic level and progress through difficulty tiers',
        'Unlock advanced topics by mastering basics',
        'Complete achievement challenges for bonus rewards',
        'Track mastery percentage for each topic',
        'Access expert mode after reaching 80% mastery',
      ],
      tips: [
        'Focus on one topic at a time for better retention',
        'Complete all difficulty levels before moving on',
        'Use the study mode to review weak areas',
        'Check progress charts to identify improvement areas',
      ],
      features: {
        'Categories': '25+ specialized',
        'Progression': 'Tiered difficulty',
        'Tracking': 'Detailed analytics',
        'Expert Mode': 'Unlock at 80%',
      },
      difficulty: 'Progressive',
      duration: '10-30 minutes',
      navigationRoute: '/all-categories',
    ),

    GameMode.survival: GameModeInfo(
      title: 'Survival Mode',
      description: 'Test your limits! Answer questions correctly to survive. One wrong answer ends the game.',
      icon: Icons.local_fire_department,
      gradient: LinearGradient(
        colors: [Colors.orange, Colors.deepOrange],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      rules: [
        'Answer questions from random categories',
        'ONE wrong answer ends the game immediately',
        'Questions get progressively harder',
        'Earn bonus points for streaks',
        'No hints or lifelines available',
        'Compete for high scores on leaderboards',
      ],
      tips: [
        'Stay calm under pressure',
        'If unsure, trust your first instinct',
        'Practice with Classic mode first',
        'Learn from failed attempts',
        'Take breaks between attempts to stay sharp',
      ],
      features: {
        'Questions': 'Unlimited',
        'Lives': 'Only 1',
        'Difficulty': 'Progressive',
        'Leaderboards': 'Global rankings',
      },
      difficulty: 'High Challenge',
      duration: '2-20 minutes',
    ),

    GameMode.arena: GameModeInfo(
      title: 'Survival Arena',
      description: 'Battle other players in real-time survival challenges. Last player standing wins!',
      icon: Icons.sports_martial_arts,
      gradient: LinearGradient(
        colors: [Colors.red, Colors.redAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      rules: [
        'Join live battles with up to 10 players',
        'Same questions for all players simultaneously',
        'Wrong answers eliminate you from the round',
        'Fastest correct answers get bonus points',
        'Win tournaments to climb rankings',
        'Seasonal rewards for top performers',
      ],
      tips: [
        'Speed matters - answer quickly but accurately',
        'Watch the player count to gauge competition',
        'Practice in Survival mode first',
        'Stay focused when others get eliminated',
        'Learn common question patterns',
      ],
      features: {
        'Players': 'Up to 10',
        'Format': 'Real-time battles',
        'Elimination': 'Wrong answer = out',
        'Rewards': 'Seasonal rankings',
      },
      difficulty: 'Expert Level',
      duration: '3-8 minutes',
    ),

    GameMode.teams: GameModeInfo(
      title: 'Team Mode',
      description: 'Collaborate with friends to tackle challenging quizzes together and achieve higher scores.',
      icon: Icons.groups,
      gradient: LinearGradient(
        colors: [Colors.indigo, Colors.indigoAccent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      rules: [
        'Form teams of 2-4 players',
        'Each player answers different questions',
        'Team score is combined from all members',
        'Use team chat for strategy discussion',
        'Harder questions give more points',
        'Complete team challenges for bonuses',
      ],
      tips: [
        'Coordinate with teammates on strengths',
        'Communicate about difficult questions',
        'Support struggling team members',
        'Plan your strategy before starting',
        'Practice together to improve team synergy',
      ],
      features: {
        'Team Size': '2-4 players',
        'Scoring': 'Combined team total',
        'Communication': 'In-game chat',
        'Challenges': 'Team objectives',
      },
      difficulty: 'Collaborative',
      duration: '10-20 minutes',
    ),

    GameMode.daily: GameModeInfo(
      title: 'Daily Challenge',
      description: 'Fresh challenges every day with special themes, limited attempts, and exclusive rewards.',
      icon: Icons.today,
      gradient: LinearGradient(
        colors: [Colors.amber, Colors.orange],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      rules: [
        'New challenge available every 24 hours',
        'Limited to 3 attempts per day',
        'Special themed questions (History Monday, Science Tuesday, etc.)',
        'Earn bonus XP and exclusive rewards',
        'Perfect scores unlock achievement badges',
        'Streak bonuses for consecutive daily completions',
      ],
      tips: [
        'Check daily themes to prepare mentally',
        'Use all 3 attempts if needed',
        'Focus on consistency over perfection',
        'Save your best attempt for last',
        'Build streaks for maximum rewards',
      ],
      features: {
        'Frequency': 'Every 24 hours',
        'Attempts': '3 per day',
        'Themes': 'Daily topics',
        'Streaks': 'Consecutive bonuses',
      },
      difficulty: 'Variable',
      duration: '5-10 minutes',
      navigationRoute: '/daily-quiz',
    ),
  };

  void _startPlaying() {
    if (widget.isMultiplayer) {
      // Navigate to multiplayer matchmaking
      context.go('/multiplayer/matchmaking/${widget.gameMode}');
    } else {
      // Navigate directly to single-player quiz
      context.go('/quiz/start/${widget.gameMode}');
    }
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.2, 1.0, curve: Curves.easeOutCubic),
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  GameModeInfo get _info => _gameModeInfo[widget.gameMode]!;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0F) : const Color(0xFFF8F9FA),
      body: CustomScrollView(
        slivers: [
          // Custom App Bar with Gradient
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () {
                HapticFeedback.lightImpact();
                context.pop();
              },
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: _info.gradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: SlideTransition(
                            position: _slideAnimation,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    _info.icon,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                                const SizedBox(width: 20),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'How to Play',
                                        style: TextStyle(
                                          color: Colors.white.withOpacity(0.9),
                                          fontSize: 16,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        _info.title,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Text(
                            _info.description,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.95),
                              fontSize: 16,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats
                      Row(
                        children: [
                          Expanded(
                            child: _InfoCard(
                              title: 'Difficulty',
                              value: _info.difficulty,
                              icon: Icons.trending_up,
                              color: Colors.orange,
                              isDark: isDark,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _InfoCard(
                              title: 'Duration',
                              value: _info.duration,
                              icon: Icons.access_time,
                              color: Colors.blue,
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),

                      // Features
                      _SectionHeader(
                        title: 'Game Features',
                        icon: Icons.stars,
                        color: _info.gradient.colors.first,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      _FeatureGrid(
                        features: _info.features,
                        color: _info.gradient.colors.first,
                        isDark: isDark,
                      ),

                      const SizedBox(height: 32),

                      // Rules
                      _SectionHeader(
                        title: 'How It Works',
                        icon: Icons.rule,
                        color: _info.gradient.colors.first,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      ..._info.rules.asMap().entries.map((entry) =>
                          _RuleItem(
                            number: entry.key + 1,
                            text: entry.value,
                            color: _info.gradient.colors.first,
                            isDark: isDark,
                          ),
                      ),

                      const SizedBox(height: 32),

                      // Tips
                      _SectionHeader(
                        title: 'Pro Tips',
                        icon: Icons.lightbulb,
                        color: Colors.amber.shade600,
                        isDark: isDark,
                      ),
                      const SizedBox(height: 16),
                      ..._info.tips.map((tip) =>
                          _TipItem(
                            text: tip,
                            color: Colors.amber.shade600,
                            isDark: isDark,
                          ),
                      ),

                      const SizedBox(height: 40),

                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                HapticFeedback.lightImpact();
                                context.pop();
                              },
                              icon: const Icon(Icons.arrow_back),
                              label: const Text('Back to Games'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: BorderSide(color: _info.gradient.colors.first),
                                foregroundColor: _info.gradient.colors.first,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                HapticFeedback.mediumImpact();
                                context.pop();
                                if (_info.navigationRoute != null) {
                                  context.push(_info.navigationRoute!);
                                } else {
                                  _showComingSoonSnackBar(context);
                                }
                              },
                              icon: Icon(widget.isMultiplayer ? Icons.people : Icons.play_arrow),
                              label: Text(widget.isMultiplayer ? 'Find Match' : 'Start Playing'),
                              style: FilledButton.styleFrom(
                                backgroundColor: widget.isMultiplayer
                                    ? const Color(0xFF8B5CF6)
                                    : _info.gradient.colors.first,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed:  () {
          HapticFeedback.mediumImpact();
          _startPlaying();
        },
        icon: Icon(widget.isMultiplayer ? Icons.people : Icons.play_arrow),
        label: Text(widget.isMultiplayer ? 'Find Match' : 'Start Playing'),
        backgroundColor: widget.isMultiplayer
            ? Colors.purple
            : Theme.of(context).primaryColor,
        foregroundColor: Colors.white24,
      ),
    );
  }

  void _showComingSoonSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_info.title} is coming soon! Stay tuned for updates.'),
        backgroundColor: _info.gradient.colors.first,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  const _InfoCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _FeatureGrid extends StatelessWidget {
  final Map<String, String> features;
  final Color color;
  final bool isDark;

  const _FeatureGrid({
    required this.features,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: features.entries.map((entry) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${entry.key}: ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      entry.value,
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey.shade300 : Colors.grey.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ).toList(),
      ),
    );
  }
}

class _RuleItem extends StatelessWidget {
  final int number;
  final String text;
  final Color color;
  final bool isDark;

  const _RuleItem({
    required this.number,
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E2E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                number.toString(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 16,
                color: isDark ? Colors.white : Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TipItem extends StatelessWidget {
  final String text;
  final Color color;
  final bool isDark;

  const _TipItem({
    required this.text,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.tips_and_updates,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 15,
                color: isDark ? Colors.white : Colors.grey.shade700,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}