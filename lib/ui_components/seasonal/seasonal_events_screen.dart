import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SeasonalEventsScreen extends StatefulWidget {
  const SeasonalEventsScreen({super.key});

  @override
  State<SeasonalEventsScreen> createState() => _SeasonalEventsScreenState();
}

class _SeasonalEventsScreenState extends State<SeasonalEventsScreen>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  Animation<Offset>? _slideAnimation;

  // Mock seasonal events data
  final List<Map<String, dynamic>> _seasonalEvents = [
    {
      'id': 'easter_2025',
      'name': 'EASTER CELEBRATION',
      'description': 'Hop into spring with egg-citing rewards!',
      'icon': Icons.egg,
      'theme': 'easter',
      'startDate': '2025-03-30',
      'endDate': '2025-04-13',
      'isActive': true,
      'progress': 65,
      'totalChallenges': 12,
      'completedChallenges': 8,
      'rewards': [
        {'id': 'r1', 'type': 'xp', 'amount': 1000, 'claimed': true, 'requirement': 'Complete 3 challenges'},
        {'id': 'r2', 'type': 'coins', 'amount': 5000, 'claimed': true, 'requirement': 'Complete 6 challenges'},
        {'id': 'r3', 'type': 'gems', 'amount': 50, 'claimed': false, 'requirement': 'Complete 9 challenges'},
        {'id': 'r4', 'type': 'exclusive_avatar', 'amount': 1, 'claimed': false, 'requirement': 'Complete all challenges'},
      ],
      'challenges': [
        {'title': 'Spring Trivia Master', 'description': 'Answer 25 spring-themed questions', 'progress': 25, 'total': 25, 'completed': true},
        {'title': 'Easter Egg Hunt', 'description': 'Find 10 hidden easter eggs in quizzes', 'progress': 10, 'total': 10, 'completed': true},
        {'title': 'Bunny Hop Streak', 'description': 'Achieve a 15-question streak', 'progress': 15, 'total': 15, 'completed': true},
        {'title': 'Garden Knowledge', 'description': 'Complete 5 nature category quizzes', 'progress': 5, 'total': 5, 'completed': true},
        {'title': 'Spring Festival', 'description': 'Participate in 3 daily events', 'progress': 3, 'total': 3, 'completed': true},
        {'title': 'Flower Power', 'description': 'Score 90% or higher in 5 quizzes', 'progress': 5, 'total': 5, 'completed': true},
        {'title': 'Seasonal Scholar', 'description': 'Learn 20 new facts about spring', 'progress': 20, 'total': 20, 'completed': true},
        {'title': 'Community Helper', 'description': 'Help 5 friends with quiz questions', 'progress': 5, 'total': 5, 'completed': true},
        {'title': 'Master Collector', 'description': 'Collect all seasonal badges', 'progress': 8, 'total': 12, 'completed': false},
        {'title': 'Speed Demon', 'description': 'Complete 10 quizzes in under 2 minutes each', 'progress': 6, 'total': 10, 'completed': false},
        {'title': 'Perfect Score', 'description': 'Get 100% on 3 challenging quizzes', 'progress': 1, 'total': 3, 'completed': false},
        {'title': 'Event Champion', 'description': 'Finish in top 10 of seasonal leaderboard', 'progress': 0, 'total': 1, 'completed': false},
      ],
    },
    {
      'id': 'summer_2025',
      'name': 'SUMMER SOLSTICE',
      'description': 'Beat the heat with sizzling challenges!',
      'icon': Icons.wb_sunny,
      'theme': 'summer',
      'startDate': '2025-06-20',
      'endDate': '2025-07-05',
      'isActive': false,
      'progress': 0,
      'totalChallenges': 15,
      'completedChallenges': 0,
      'rewards': [],
      'challenges': [],
    },
    {
      'id': 'halloween_2024',
      'name': 'SPOOKY OCTOBER',
      'description': 'Trick or treat your way to victory!',
      'icon': Icons.face,
      'theme': 'halloween',
      'startDate': '2024-10-25',
      'endDate': '2024-11-01',
      'isActive': false,
      'progress': 100,
      'totalChallenges': 10,
      'completedChallenges': 10,
      'rewards': [],
      'challenges': [],
    },
  ];

  int _selectedEventIndex = 0;

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
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeOutBack,
    ));
    _animationController!.forward();
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F23),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(),
          if (_fadeAnimation != null && _slideAnimation != null)
            SliverToBoxAdapter(
              child: FadeTransition(
                opacity: _fadeAnimation!,
                child: SlideTransition(
                  position: _slideAnimation!,
                  child: _buildContent(),
                ),
              ),
            )
          else
            SliverToBoxAdapter(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: const Color(0xFF0F0F23),
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          splashRadius: 24,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        title: const Text(
          'Seasonal Events',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
                Color(0xFF0F0F23),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      children: [
        _buildEventSelector(),
        const SizedBox(height: 24),
        _buildEventDetails(),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildEventSelector() {
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _seasonalEvents.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final event = _seasonalEvents[index];
          final isSelected = index == _selectedEventIndex;
          final isActive = event['isActive'] as bool;

          return GestureDetector(
            onTap: () => setState(() => _selectedEventIndex = index),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 160,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? _getSeasonalGradient(event['theme'])
                    : LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.1),
                    Colors.white.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected
                      ? Colors.white.withOpacity(0.3)
                      : Colors.white.withOpacity(0.1),
                  width: isSelected ? 2 : 1,
                ),
                boxShadow: isSelected
                    ? [
                  BoxShadow(
                    color: _getSeasonalColor(event['theme']).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
                    : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    children: [
                      Icon(
                        event['icon'],
                        size: 32,
                        color: isSelected ? Colors.white : Colors.white70,
                      ),
                      if (isActive)
                        Positioned(
                          top: -2,
                          right: -2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    event['name'],
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${event['progress']}%',
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white54,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEventDetails() {
    final event = _seasonalEvents[_selectedEventIndex];
    final isActive = event['isActive'] as bool;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: _getSeasonalGradient(event['theme']),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _getSeasonalColor(event['theme']).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildEventHeader(event, isActive),
          if (isActive) ...[
            _buildProgressSection(event),
            _buildRewardsSection(event),
            _buildChallengesSection(event),
          ] else
            _buildInactiveEventContent(event),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEventHeader(Map<String, dynamic> event, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              event['icon'],
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      event['name'],
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (isActive) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event['description'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                if (isActive) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.access_time, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      const Text(
                        'Ends in 01d 04h',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(Map<String, dynamic> event) {
    final progress = (event['progress'] as int) / 100.0;
    final completed = event['completedChallenges'] as int;
    final total = event['totalChallenges'] as int;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Overall Progress',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$completed/$total challenges',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 12,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: progress,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.white.withOpacity(0.5),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(progress * 100).toInt()}% Complete',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardsSection(Map<String, dynamic> event) {
    final rewards = event['rewards'] as List<Map<String, dynamic>>;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Rewards',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...rewards.map((reward) => _buildRewardItem(reward)).toList(),
        ],
      ),
    );
  }

  Widget _buildRewardItem(Map<String, dynamic> reward) {
    final isClaimed = reward['claimed'] as bool;
    final type = reward['type'] as String;
    final amount = reward['amount'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isClaimed ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isClaimed
              ? Colors.green.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isClaimed ? Colors.green : _getRewardColor(type),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isClaimed ? Icons.check : _getRewardIcon(type),
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getRewardTitle(type, amount),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: isClaimed ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reward['requirement'],
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isClaimed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'CLAIMED',
                style: TextStyle(
                  color: Colors.green,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildChallengesSection(Map<String, dynamic> event) {
    final challenges = event['challenges'] as List<Map<String, dynamic>>;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Event Challenges',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ...challenges.map((challenge) => _buildChallengeItem(challenge)).toList(),
        ],
      ),
    );
  }

  Widget _buildChallengeItem(Map<String, dynamic> challenge) {
    final isCompleted = challenge['completed'] as bool;
    final progress = challenge['progress'] as int;
    final total = challenge['total'] as int;
    final progressPercent = progress / total;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(isCompleted ? 0.15 : 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted
              ? Colors.green.withOpacity(0.5)
              : Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  challenge['title'],
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    decoration: isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
              ),
              if (isCompleted)
                const Icon(Icons.check_circle, color: Colors.green, size: 20)
              else
                Text(
                  '$progress/$total',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            challenge['description'],
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 12,
            ),
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 12),
            Container(
              height: 6,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: progressPercent,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInactiveEventContent(Map<String, dynamic> event) {
    final progress = event['progress'] as int;
    final isCompleted = progress == 100;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.schedule,
            color: Colors.white.withOpacity(0.7),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            isCompleted ? 'Event Completed!' : 'Coming Soon!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isCompleted
                ? 'You completed this seasonal event with $progress% progress!'
                : 'This seasonal event will be available soon. Stay tuned!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 16,
            ),
          ),
          if (!isCompleted) ...[
            const SizedBox(height: 24),
            Text(
              'Expected: ${event['startDate']} - ${event['endDate']}',
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ],
      ),
    );
  }

  LinearGradient _getSeasonalGradient(String theme) {
    switch (theme) {
      case 'easter':
        return LinearGradient(
          colors: [
            Colors.pink.shade300,
            Colors.purple.shade400,
            Colors.pink.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'summer':
        return LinearGradient(
          colors: [
            Colors.orange.shade300,
            Colors.yellow.shade400,
            Colors.orange.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'halloween':
        return LinearGradient(
          colors: [
            Colors.orange.shade400,
            Colors.deepOrange.shade500,
            Colors.red.shade400,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'christmas':
        return LinearGradient(
          colors: [
            Colors.red.shade400,
            Colors.green.shade500,
            Colors.red.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return LinearGradient(
          colors: [
            Colors.blue.shade400,
            Colors.purple.shade500,
            Colors.blue.shade500,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  Color _getSeasonalColor(String theme) {
    switch (theme) {
      case 'easter':
        return Colors.pink;
      case 'summer':
        return Colors.orange;
      case 'halloween':
        return Colors.orange;
      case 'christmas':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

  IconData _getRewardIcon(String type) {
    switch (type) {
      case 'xp':
        return Icons.star;
      case 'coins':
        return Icons.monetization_on;
      case 'gems':
        return Icons.diamond;
      case 'exclusive_avatar':
        return Icons.person;
      default:
        return Icons.card_giftcard;
    }
  }

  Color _getRewardColor(String type) {
    switch (type) {
      case 'xp':
        return Colors.purple;
      case 'coins':
        return Colors.amber;
      case 'gems':
        return Colors.blue;
      case 'exclusive_avatar':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }

  String _getRewardTitle(String type, dynamic amount) {
    switch (type) {
      case 'xp':
        return '$amount XP';
      case 'coins':
        return '$amount Coins';
      case 'gems':
        return '$amount Gems';
      case 'exclusive_avatar':
        return 'Exclusive Avatar';
      default:
        return 'Reward';
    }
  }
}
