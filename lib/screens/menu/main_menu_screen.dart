import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/menu/widgets/app_drawer.dart';
import '../../screens/menu/widgets/rank_level_card.dart';
import '../../screens/menu/widgets/recently_played_section.dart';
import '../../screens/menu/widgets/user_greeting_appbar.dart';
import '../profile/widgets/shimmer_avatar.dart';
import '../../game/providers/riverpod_providers.dart';

class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with TickerProviderStateMixin {
  AnimationController? _animationController;
  Animation<double>? _fadeAnimation;
  late List<AnimationController> _cardAnimationControllers;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController!,
      curve: Curves.easeInOut,
    ));

    // Initialize card animation controllers
    _cardAnimationControllers = List.generate(
      6,
          (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      ),
    );

    // Start animations
    _animationController!.forward();
    for (int i = 0; i < _cardAnimationControllers.length; i++) {
      Future.delayed(Duration(milliseconds: i * 150), () {
        if (mounted) _cardAnimationControllers[i].forward();
      });
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    for (final controller in _cardAnimationControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers for reactive updates
    final profileService = ref.watch(playerProfileServiceProvider);
    final quizService = ref.watch(quizProgressServiceProvider);
    final coinBalance = ref.watch(coinBalanceProvider);
    final diamondBalance = ref.watch(diamondBalanceProvider);
    final ageGroup = ref.watch(userAgeGroupProvider);

    // User Details
    final userProfile = profileService.getProfile();
    final String userName = userProfile['name'] ?? 'Player';
    final String rank = userProfile['rank'] ?? 'Apprentice 1';
    final int level = userProfile['level'] ?? 0;
    final int currentXP = userProfile['currentXP'] ?? 340;
    final int maxXP = userProfile['maxXP'] ?? 1000;

    // Get recent quizzes from quiz service (using new synchronous method)
    final List<Map<String, String>> recentlyPlayedQuizzes = quizService.getRecentQuizzes();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      drawer: const AppDrawer(),
      appBar: UserGreetingAppBar(
        userName: userName,
        ageGroup: ageGroup,
      ),
      body: _fadeAnimation != null
          ? FadeTransition(
        opacity: _fadeAnimation!,
        child: _buildBody(
          userName,
          ageGroup,
          rank,
          level,
          currentXP,
          maxXP,
          recentlyPlayedQuizzes,
          coinBalance,
          diamondBalance,
        ),
      )
          : _buildBody(
        userName,
        ageGroup,
        rank,
        level,
        currentXP,
        maxXP,
        recentlyPlayedQuizzes,
        coinBalance,
        diamondBalance,
      ),
    );
  }

  Widget _buildBody(
      String userName,
      String ageGroup,
      String rank,
      int level,
      int currentXP,
      int maxXP,
      List<Map<String, String>> recentlyPlayedQuizzes,
      int coinBalance,
      int diamondBalance,
      ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Currency Display Widget (NEW)
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _cardAnimationControllers[0],
              curve: Curves.easeOutBack,
            )),
            child: Consumer(
              builder: (context, ref, child) {
                // Watch currency providers for real-time updates
                final coins = ref.watch(coinBalanceProvider);
                final diamonds = ref.watch(diamondBalanceProvider);

                // Watch energy and lives providers (add these to your providers file)
                final energyState = ref.watch(energyProvider);
                final livesState = ref.watch(livesProvider);

                return _CurrencyDisplay(
                  ageGroup: ageGroup,
                  coins: coins,
                  gems: diamonds,
                  currentEnergy: energyState.current,
                  maxEnergy: energyState.max,
                  currentLives: livesState.current,
                  maxLives: livesState.max,
                  ref: ref,
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Rank & Level Widget
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _cardAnimationControllers[0],
              curve: Curves.easeOutBack,
            )),
            child: RankLevelCard(
              rank: rank,
              level: level,
              currentXP: currentXP,
              maxXP: maxXP,
              ageGroup: ageGroup,
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons Row (now using index 2)
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _cardAnimationControllers[2], // Changed from index 1 to 2
              curve: Curves.easeOutBack,
            )),
            child: _ActionButtonsRow(ageGroup: ageGroup),
          ),

          const SizedBox(height: 24),

          // Trivia Progress Card (now using index 3)
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _cardAnimationControllers[3], // Changed from index 2 to 3
              curve: Curves.easeOutBack,
            )),
            child: _TriviaJourneyProgress(currentXP: currentXP, maxXP: maxXP),
          ),

          const SizedBox(height: 24),

          // Recently Played Quizzes Section (now using index 4)
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _cardAnimationControllers[4], // Changed from index 3 to 4
              curve: Curves.easeOutBack,
            )),
            child: RecentlyPlayedSection(
              quizzes: recentlyPlayedQuizzes,
              ageGroup: ageGroup,
            ),
          ),

          const SizedBox(height: 24),

          // User Matches Section (now using index 5)
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _cardAnimationControllers[5], // Now using index 5
              curve: Curves.easeOutBack,
            )),
            child: const _MatchesSection(),
          ),

          const SizedBox(height: 100), // Bottom padding
        ],
      ),
    );
  }
}

/// Enhanced Action Buttons Horizontal Scroll
class _ActionButtonsRow extends StatelessWidget {
  final String ageGroup;

  const _ActionButtonsRow({required this.ageGroup});

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'label': 'Invite',
        'icon': Icons.person_add,
        'gradient': _getGradient(0),
        'route': '/invite',
        'description': 'Invite friends to play'
      },
      {
        'label': 'Rewards',
        'icon': Icons.star,
        'gradient': _getGradient(1),
        'route': '/rewards',
        'description': 'Daily rewards & bonuses'
      },
      {
        'label': 'Leaderboard',
        'icon': Icons.trending_up,
        'gradient': _getGradient(3),
        'route': '/leaderboard',
        'description': 'Global leaderboard'
      },
      {
        'label': 'Challenges',
        'icon': Icons.emoji_events,
        'gradient': _getGradient(7),
        'route': '/challenges',
        'description': 'Weekly challenges'
      },
      {
        'label': 'Gifts',
        'icon': Icons.card_giftcard,
        'gradient': _getGradient(4),
        'route': '/gifts',
        'description': 'Send & receive gifts'
      },
      {
        'label': 'Offers',
        'icon': Icons.local_offer,
        'gradient': _getGradient(2),
        'route': '/offers',
        'description': 'Special deals & discounts'
      },
      {
        'label': 'Store',
        'icon': Icons.shopping_bag,
        'gradient': _getGradient(5),
        'route': '/store',
        'description': 'Power-ups & boosters'
      },
      {
        'label': 'Settings',
        'icon': Icons.settings,
        'gradient': _getGradient(6),
        'route': '/settings',
        'description': 'Game preferences'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header with scroll hint
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1E293B),
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      Icons.swipe_left,
                      size: 16,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Scroll',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Horizontal Scrollable Actions
          SizedBox(
            height: 100,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];

                return TweenAnimationBuilder<double>(
                  duration: Duration(milliseconds: 600 + (index * 80)),
                  tween: Tween(begin: 0.0, end: 1.0),
                  builder: (context, value, child) {
                    return Transform.translate(
                      offset: Offset(20 * (1 - value), 0),
                      child: Opacity(
                        opacity: value,
                        child: Container(
                          width: 80,
                          margin: const EdgeInsets.only(right: 12),
                          child: _ActionButton(
                            label: action['label'] as String,
                            icon: action['icon'] as IconData,
                            gradient: action['gradient'] as LinearGradient,
                            route: action['route'] as String,
                            description: action['description'] as String,
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 12),
        ],
      ),
    );
  }

  LinearGradient _getGradient(int index) {
    final gradients = [
      const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)]),
      const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
      const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
      const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
      const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
      const LinearGradient(colors: [Color(0xFF64748B), Color(0xFF475569)]),
      const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDB2777)]),
    ];
    return gradients[index % gradients.length];
  }
}

class _ActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final String route;
  final String description;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.route,
    required this.description,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  AnimationController? _hoverController;
  Animation<double>? _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _hoverController!,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _hoverController?.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    context.push(widget.route);
  }

  void _showTooltip() {
    final RenderBox renderBox = context.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (context) => Stack(
        children: [
          Positioned(
            left: position.dx - 40,
            top: position.dy - 60,
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  widget.description,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );

    // Auto dismiss after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: _showTooltip,
      onTapDown: (_) {
        setState(() => _isPressed = true);
        _hoverController!.forward();
      },
      onTapUp: (_) {
        setState(() => _isPressed = false);
        _hoverController!.reverse();
      },
      onTapCancel: () {
        setState(() => _isPressed = false);
        _hoverController!.reverse();
      },
      child: _scaleAnimation != null
          ? ScaleTransition(
        scale: _scaleAnimation!,
        child: _buildButton(),
      )
          : _buildButton(),
    );
  }

  Widget _buildButton() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            gradient: widget.gradient,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: widget.gradient.colors.first.withOpacity(_isPressed ? 0.4 : 0.3),
                blurRadius: _isPressed ? 12 : 8,
                offset: Offset(0, _isPressed ? 4 : 3),
              ),
            ],
          ),
          child: Icon(
            widget.icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          widget.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: _isPressed
                ? const Color(0xFF6366F1)
                : const Color(0xFF64748B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

/// Enhanced Trivia Journey Progress Card
class _TriviaJourneyProgress extends StatelessWidget {
  final int currentXP;
  final int maxXP;

  const _TriviaJourneyProgress({required this.currentXP, required this.maxXP});

  @override
  Widget build(BuildContext context) {
    final progressValue = currentXP / maxXP;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF6366F1),
            Color(0xFF8B5CF6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Trivia Journey',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Level up your knowledge!',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progressValue,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
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
                const SizedBox(height: 12),
                Text(
                  '$currentXP / $maxXP XP',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1,
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '50% OFF',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Premium',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Enhanced Matches Section
class _MatchesSection extends StatelessWidget {
  const _MatchesSection();

  final matches = const [
    {
      'name': 'mindpixell',
      'score': '0-0',
      'time': '1d left',
      'avatar': 'assets/images/avatars/avatar-1.png',
      'status': 'waiting',
    },
    {
      'name': 'giovanni.rasmussen',
      'score': '3-0',
      'time': '1d left',
      'avatar': 'assets/images/avatars/avatar-2.png',
      'status': 'winning',
    },
    {
      'name': 'dexter.henderson',
      'score': '0-1',
      'time': '1d left',
      'avatar': 'assets/images/avatars/avatar-3.png',
      'status': 'losing',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF64748B).withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF64748B).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Your Matches',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/matches'),
                child: const Text(
                  'View All',
                  style: TextStyle(
                    color: Color(0xFF6366F1),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...matches.asMap().entries.map((entry) {
            final index = entry.key;
            final match = entry.value;

            return TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 600 + (index * 150)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: Opacity(
                    opacity: value,
                    child: _buildMatchTile(context, match),
                  ),
                );
              },
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildMatchTile(BuildContext context, Map<String, String> match) {
    final status = match['status']!;
    Color statusColor = const Color(0xFF64748B);
    IconData statusIcon = Icons.schedule;

    switch (status) {
      case 'winning':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.trending_up;
        break;
      case 'losing':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.trending_down;
        break;
      case 'waiting':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.schedule;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: statusColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => context.push('/match-details', extra: match),
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            ShimmerAvatar(
              avatarPath: match['avatar']!,
              isOnline: true,
              isLoading: false,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    match['name']!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        statusIcon,
                        size: 16,
                        color: statusColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        match['score']!,
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    match['time']!,
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Enhanced Currency Display Widget with Riverpod Integration
class _CurrencyDisplay extends StatelessWidget {
  final String ageGroup;
  final int coins;
  final int gems;
  final int currentEnergy;
  final int maxEnergy;
  final int currentLives;
  final int maxLives;
  final WidgetRef ref;

  const _CurrencyDisplay({
    required this.ageGroup,
    required this.coins,
    required this.gems,
    required this.currentEnergy,
    required this.maxEnergy,
    required this.currentLives,
    required this.maxLives,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final currencies = [
      {
        'name': 'Coins',
        'value': _formatNumber(coins),
        'icon': Icons.monetization_on,
        'color': const Color(0xFFFFD700),
        'bgColor': const Color(0xFFFFF8DC),
        'onTap': () => _showCoinStore(context),
      },
      {
        'name': 'Gems',
        'value': _formatNumber(gems),
        'icon': Icons.diamond,
        'color': const Color(0xFF6366F1),
        'bgColor': const Color(0xFFF0F0FF),
        'onTap': () => _showGemStore(context),
      },
      {
        'name': 'Energy',
        'value': '$currentEnergy/$maxEnergy',
        'icon': Icons.flash_on,
        'color': const Color(0xFF10B981),
        'bgColor': const Color(0xFFF0FDF4),
        'onTap': () => _showEnergyInfo(context),
      },
      {
        'name': 'Lives',
        'value': '$currentLives/$maxLives',
        'icon': Icons.favorite,
        'color': const Color(0xFFEF4444),
        'bgColor': const Color(0xFFFEF2F2),
        'onTap': () => _showLivesInfo(context),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.08),
            blurRadius: 25,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: currencies.asMap().entries.map((entry) {
          final index = entry.key;
          final currency = entry.value;
          final isLast = index == currencies.length - 1;

          return Expanded(
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 600 + (index * 100)),
              tween: Tween(begin: 0.0, end: 1.0),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.8 + (0.2 * value),
                  child: Opacity(
                    opacity: value,
                    child: Row(
                      children: [
                        Expanded(
                          child: _CurrencyItem(
                            name: currency['name'] as String,
                            value: currency['value'] as String,
                            icon: currency['icon'] as IconData,
                            color: currency['color'] as Color,
                            bgColor: currency['bgColor'] as Color,
                            onTap: currency['onTap'] as VoidCallback,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 1,
                            height: 40,
                            margin: const EdgeInsets.symmetric(horizontal: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF64748B).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(0.5),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
    );
  }

  void _showCoinStore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {},
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Coin Store',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFD700).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _formatNumber(coins),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildStoreItem(context, '100 Coins', '\$0.99', Icons.monetization_on, 100, 'coins'),
                          _buildStoreItem(context, '500 Coins', '\$4.99', Icons.monetization_on, 500, 'coins'),
                          _buildStoreItem(context, '1,000 Coins', '\$9.99', Icons.monetization_on, 1000, 'coins'),
                          _buildStoreItem(context, '5,000 Coins', '\$19.99', Icons.monetization_on, 5000, 'coins'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showGemStore(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      enableDrag: true,
      builder: (context) => GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Container(
          color: Colors.transparent,
          child: GestureDetector(
            onTap: () {},
            child: DraggableScrollableSheet(
              initialChildSize: 0.7,
              maxChildSize: 0.9,
              minChildSize: 0.5,
              builder: (context, scrollController) => Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Gem Store',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFF6366F1).withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.diamond, color: Color(0xFF6366F1), size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  _formatNumber(gems),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: const EdgeInsets.all(20),
                        children: [
                          _buildStoreItem(context, '10 Gems', '\$1.99', Icons.diamond, 10, 'gems'),
                          _buildStoreItem(context, '50 Gems', '\$8.99', Icons.diamond, 50, 'gems'),
                          _buildStoreItem(context, '100 Gems', '\$15.99', Icons.diamond, 100, 'gems'),
                          _buildStoreItem(context, '500 Gems', '\$49.99', Icons.diamond, 500, 'gems'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showEnergyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.flash_on, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Energy System'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Energy: $currentEnergy/$maxEnergy'),
            const SizedBox(height: 8),
            const Text('• Energy refills automatically over time'),
            const Text('• 1 energy = 1 quiz attempt'),
            const Text('• Energy refills every 30 minutes'),
            const Text('• Watch ads for instant energy'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showEnergyOptions(context);
            },
            child: const Text('Get Energy'),
          ),
        ],
      ),
    );
  }

  void _showLivesInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Lives System'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Lives: $currentLives/$maxLives'),
            const SizedBox(height: 8),
            const Text('• Lives are lost when you fail a quiz'),
            const Text('• Lives regenerate every 2 hours'),
            const Text('• Ask friends for lives'),
            const Text('• Purchase lives with gems'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _showLivesOptions(context);
            },
            child: const Text('Get Lives'),
          ),
        ],
      ),
    );
  }

  void _showEnergyOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Get Energy',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildEnergyOption('Watch Ad', '+5 Energy', Icons.play_circle_fill, true, () {
              Navigator.pop(context);
            }),
            _buildEnergyOption('Buy with Gems', '10 Gems = +20 Energy', Icons.diamond, false, () {
              final gemNotifier = ref.read(diamondNotifierProvider);
              if (gems >= 10) {
                gemNotifier.deduct(10);
                Navigator.pop(context);
              }
            }),
            _buildEnergyOption('Wait', 'Next refill in 25 min', Icons.schedule, false, null),
          ],
        ),
      ),
    );
  }

  void _showLivesOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Get Lives',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            _buildEnergyOption('Ask Friends', 'Request from contacts', Icons.people, true, () {
              Navigator.pop(context);
            }),
            _buildEnergyOption('Buy with Gems', '5 Gems = +1 Life', Icons.diamond, false, () {
              final gemNotifier = ref.read(diamondNotifierProvider);
              if (gems >= 5) {
                gemNotifier.deduct(5);
                Navigator.pop(context);
              }
            }),
            _buildEnergyOption('Wait', 'Next life in 1h 30m', Icons.schedule, false, null),
          ],
        ),
      ),
    );
  }

  Widget _buildStoreItem(
      BuildContext context,
      String title,
      String price,
      IconData icon,
      int amount,
      String currencyType,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _handlePurchase(context, amount, currencyType),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                Icon(icon, color: const Color(0xFF6366F1), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _handlePurchase(BuildContext context, int amount, String currencyType) {
    if (currencyType == 'coins') {
      final coinNotifier = ref.read(coinBalanceProvider.notifier);
      coinNotifier.add(amount);
    } else if (currencyType == 'gems') {
      final gemNotifier = ref.read(diamondNotifierProvider);
      gemNotifier.addValue(amount);
    }

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Successfully purchased $amount $currencyType!'),
        backgroundColor: const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildEnergyOption(
      String title,
      String subtitle,
      IconData icon,
      bool isRecommended,
      VoidCallback? onTap,
      ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isRecommended ? const Color(0xFF10B981).withOpacity(0.1) : const Color(0xFFF8FAFF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isRecommended ? const Color(0xFF10B981) : Colors.grey.shade200,
                width: isRecommended ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isRecommended ? const Color(0xFF10B981) : const Color(0xFF6366F1),
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                if (isRecommended)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'FREE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CurrencyItem extends StatelessWidget {
  final String name;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _CurrencyItem({
    required this.name,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: color.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            name,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }
}
