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

    _cardAnimationControllers = List.generate(
      6,
          (index) => AnimationController(
        duration: Duration(milliseconds: 600 + (index * 100)),
        vsync: this,
      ),
    );

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      drawer: const AppDrawer(),
      appBar: _buildAppBar(),
      body: _fadeAnimation != null
          ? FadeTransition(
        opacity: _fadeAnimation!,
        child: _buildBody(),
      )
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final profileService = ref.watch(playerProfileServiceProvider);
    final ageGroup = ref.watch(userAgeGroupProvider);
    final userProfile = profileService.getProfile();
    final userName = userProfile['name'] ?? 'Player';

    return UserGreetingAppBar(
      userName: userName,
      ageGroup: ageGroup,
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Currency Display
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
                final coins = ref.watch(coinBalanceProvider);
                final diamonds = ref.watch(diamondBalanceProvider);
                final energyState = ref.watch(energyProvider);
                final livesState = ref.watch(livesProvider);
                final ageGroup = ref.watch(userAgeGroupProvider);

                return _CurrencyDisplay(
                  ageGroup: ageGroup,
                  coins: coins,
                  gems: diamonds,
                  currentEnergy: energyState.current,
                  maxEnergy: energyState.max,
                  currentLives: livesState.current,
                  maxLives: livesState.max,
                  ref: ref,
                  showEnergyInfo: (cur, max) =>
                      _showEnergyInfo(context, cur, max),
                  showLivesInfo: (cur, max) =>
                      _showLivesInfo(context, cur, max),
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Rank & Level
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _cardAnimationControllers[1],
              curve: Curves.easeOutBack,
            )),
            child: Consumer(
              builder: (context, ref, child) {
                final profileService = ref.watch(playerProfileServiceProvider);
                final ageGroup = ref.watch(userAgeGroupProvider);
                final userProfile = profileService.getProfile();

                return RankLevelCard(
                  rank: userProfile['rank'] ?? 'Apprentice 1',
                  level: userProfile['level'] ?? 0,
                  currentXP: userProfile['currentXP'] ?? 340,
                  maxXP: userProfile['maxXP'] ?? 1000,
                  ageGroup: ageGroup,
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _cardAnimationControllers[2],
              curve: Curves.easeOutBack,
            )),
            child: Consumer(
              builder: (context, ref, child) {
                final ageGroup = ref.watch(userAgeGroupProvider);
                final unreadNotifications =
                ref.watch(unreadNotificationsProvider);
                final pendingInvites = ref.watch(pendingInvitesProvider);
                final dailyRewardsAvailable =
                ref.watch(dailyRewardsAvailableProvider);

                return _ActionButtonsRow(
                  ageGroup: ageGroup,
                  unreadNotifications: unreadNotifications,
                  pendingInvites: pendingInvites,
                  dailyRewardsAvailable: dailyRewardsAvailable,
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Trivia Progress
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _cardAnimationControllers[3],
              curve: Curves.easeOutBack,
            )),
            child: Consumer(
              builder: (context, ref, child) {
                final profileService = ref.watch(playerProfileServiceProvider);
                final premiumStatus = ref.watch(premiumStatusProvider);
                final userProfile = profileService.getProfile();

                return _TriviaJourneyProgress(
                  currentXP: userProfile['currentXP'] ?? 340,
                  maxXP: userProfile['maxXP'] ?? 1000,
                  isPremium: premiumStatus.isPremium,
                  premiumDiscountPercent: premiumStatus.discountPercent,
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // Recently Played
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _cardAnimationControllers[4],
              curve: Curves.easeOutBack,
            )),
            child: Consumer(
              builder: (context, ref, child) {
                final quizService = ref.watch(quizProgressServiceProvider);
                final ageGroup = ref.watch(userAgeGroupProvider);
                final recentQuizzes = quizService.getRecentQuizzes();

                return RecentlyPlayedSection(
                  quizzes: recentQuizzes,
                  ageGroup: ageGroup,
                );
              },
            ),
          ),
          const SizedBox(height: 24),

          // User Matches
          SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.5),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: _cardAnimationControllers[5],
              curve: Curves.easeOutBack,
            )),
            child: Consumer(
              builder: (context, ref, child) {
                final matches = ref.watch(activeMatchesProvider);
                return _MatchesSection(matches: matches);
              },
            ),
          ),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  void _showEnergyInfo(
      BuildContext context, int currentEnergy, int maxEnergy) {
    final energyRefillTime = ref.read(energyRefillTimeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Energy System'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Energy: $currentEnergy/$maxEnergy'),
            const SizedBox(height: 8),
            if (currentEnergy < maxEnergy)
              Text('Next refill in: ${_formatDuration(energyRefillTime)}'),
            const SizedBox(height: 16),
            const Text(
              'Energy is used to play quizzes. It refills automatically over time or you can purchase refills in the store.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (currentEnergy < maxEnergy)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/store?section=energy');
              },
              child: const Text('Buy Energy'),
            ),
        ],
      ),
    );
  }

  void _showLivesInfo(BuildContext context, int currentLives, int maxLives) {
    final livesRefillTime = ref.read(livesRefillTimeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lives System'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Lives: $currentLives/$maxLives'),
            const SizedBox(height: 8),
            if (currentLives < maxLives)
              Text('Next life in: ${_formatDuration(livesRefillTime)}'),
            const SizedBox(height: 16),
            const Text(
              'Lives are lost when you fail a quiz. They refill automatically or you can ask friends for help.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
          if (currentLives < maxLives)
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.push('/ask-friends-lives');
              },
              child: const Text('Ask Friends'),
            ),
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }
}

// All the helper widgets that were missing or incomplete are defined below.

class _CurrencyDisplay extends StatelessWidget {
  final String ageGroup;
  final int coins;
  final int gems;
  final int currentEnergy;
  final int maxEnergy;
  final int currentLives;
  final int maxLives;
  final WidgetRef ref;
  final Function(int, int) showEnergyInfo;
  final Function(int, int) showLivesInfo;

  const _CurrencyDisplay({
    required this.ageGroup,
    required this.coins,
    required this.gems,
    required this.currentEnergy,
    required this.maxEnergy,
    required this.currentLives,
    required this.maxLives,
    required this.ref,
    required this.showEnergyInfo,
    required this.showLivesInfo,
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
        'isLow': coins < 100,
      },
      {
        'name': 'Gems',
        'value': _formatNumber(gems),
        'icon': Icons.diamond,
        'color': const Color(0xFF6366F1),
        'bgColor': const Color(0xFFF0F0FF),
        'onTap': () => _showGemStore(context),
        'isLow': gems < 10,
      },
      {
        'name': 'Energy',
        'value': '$currentEnergy/$maxEnergy',
        'icon': Icons.flash_on,
        'color': const Color(0xFF10B981),
        'bgColor': const Color(0xFFF0FDF4),
        'onTap': () => showEnergyInfo(currentEnergy, maxEnergy),
        'isLow': currentEnergy < maxEnergy * 0.3,
      },
      {
        'name': 'Lives',
        'value': '$currentLives/$maxLives',
        'icon': Icons.favorite,
        'color': const Color(0xFFEF4444),
        'bgColor': const Color(0xFFFEF2F2),
        'onTap': () => showLivesInfo(currentLives, maxLives),
        'isLow': currentLives < maxLives * 0.5,
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
                            isLow: currency['isLow'] as bool,
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
    return number
        .toString()
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  void _showCoinStore(BuildContext context) {
    // Implementation for showing coin store
  }

  void _showGemStore(BuildContext context) {
    // Implementation for showing gem store
  }
}

class _CurrencyItem extends StatelessWidget {
  final String name;
  final String value;
  final IconData icon;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;
  final bool isLow;

  const _CurrencyItem({
    required this.name,
    required this.value,
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.onTap,
    required this.isLow,
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
          Stack(
            clipBehavior: Clip.none,
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
              if (isLow)
                Positioned(
                  right: -2,
                  top: -2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: const Icon(
                      Icons.warning,
                      color: Colors.white,
                      size: 8,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isLow ? const Color(0xFFEF4444) : const Color(0xFF1E293B),
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

class _ActionButtonsRow extends StatelessWidget {
  final String ageGroup;
  final int unreadNotifications;
  final int pendingInvites;
  final bool dailyRewardsAvailable;

  const _ActionButtonsRow({
    required this.ageGroup,
    required this.unreadNotifications,
    required this.pendingInvites,
    required this.dailyRewardsAvailable,
  });

  @override
  Widget build(BuildContext context) {
    final actions = [
      {
        'label': 'Invite',
        'icon': Icons.person_add,
        'gradient': _getGradient(0),
        'route': '/invite',
        'description': 'Invite friends to play',
        'badge': pendingInvites > 0 ? pendingInvites : null,
      },
      {
        'label': 'Rewards',
        'icon': Icons.star,
        'gradient': _getGradient(1),
        'route': '/rewards',
        'description': 'Daily rewards & bonuses',
        'badge': dailyRewardsAvailable ? 1 : null,
      },
      {
        'label': 'Leaderboard',
        'icon': Icons.trending_up,
        'gradient': _getGradient(3),
        'route': '/leaderboard',
        'description': 'Global leaderboard',
        'badge': null,
      },
      {
        'label': 'Challenges',
        'icon': Icons.emoji_events,
        'gradient': _getGradient(7),
        'route': '/challenges',
        'description': 'Weekly challenges',
        'badge': null,
      },
      {
        'label': 'Store',
        'icon': Icons.shopping_bag,
        'gradient': _getGradient(5),
        'route': '/store-hub',
        'description': 'Power-ups & boosters',
        'badge': null,
      },
      {
        'label': 'Settings',
        'icon': Icons.settings,
        'gradient': _getGradient(6),
        'route': '/settings',
        'description': 'Game preferences',
        'badge': unreadNotifications > 0 ? unreadNotifications : null,
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
                            badge: action['badge'] as int?,
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
      const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
      const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
      const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDB2777)]),
      const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
      const LinearGradient(colors: [Color(0xFF64748B), Color(0xFF475569)]),
      const LinearGradient(colors: [Color(0xFF84CC16), Color(0xFF65A30D)]),
    ];
    return gradients[index % gradients.length];
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final LinearGradient gradient;
  final String route;
  final String description;
  final int? badge;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.route,
    required this.description,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push(route);
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: gradient,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: gradient.colors.first.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              if (badge != null && badge! > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                    child: Text(
                      badge.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF475569)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _TriviaJourneyProgress extends StatelessWidget {
  final int currentXP;
  final int maxXP;
  final bool isPremium;
  final int premiumDiscountPercent;

  const _TriviaJourneyProgress({
    required this.currentXP,
    required this.maxXP,
    required this.isPremium,
    required this.premiumDiscountPercent,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (currentXP / maxXP).clamp(0.0, 1.0);

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Trivia Journey',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 12,
                    backgroundColor: const Color(0xFFF1F5F9),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                        Color(0xFF6366F1)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Color(0xFF6366F1)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isPremium)
            GestureDetector(
              onTap: () => context.push('/offers'),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star,
                        color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unlock Premium for $premiumDiscountPercent% OFF!',
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFB45309)),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios,
                        size: 14, color: Color(0xFFB45309)),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}

class _MatchesSection extends StatelessWidget {
  final List<Map<String, dynamic>> matches;

  const _MatchesSection({required this.matches});

  @override
  Widget build(BuildContext context) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your Matches',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B))),
          const SizedBox(height: 16),
          if (matches.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24.0),
                child: Text('No active matches. Start a new game!',
                    style: TextStyle(color: Colors.grey)),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: matches.length,
              itemBuilder: (context, index) {
                return _buildMatchTile(context, matches[index]);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildMatchTile(BuildContext context, Map<String, dynamic> match) {
    final status = match['status'] as String;
    Color statusColor = const Color(0xFF64748B);
    IconData statusIcon = Icons.schedule;
    AvatarStatus avatarStatus = AvatarStatus.online;

    switch (status) {
      case 'winning':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.trending_up;
        avatarStatus = AvatarStatus.online;
        break;
      case 'losing':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.trending_down;
        avatarStatus = AvatarStatus.busy;
        break;
      case 'waiting':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.schedule;
        avatarStatus = AvatarStatus.away;
        break;
      case 'tied':
        statusColor = const Color(0xFF8B5CF6);
        statusIcon = Icons.drag_handle;
        avatarStatus = AvatarStatus.online;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/match-details', extra: match),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusColor.withOpacity(0.2),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              ShimmerAvatar(
                avatarPath: match['avatar'] as String,
                status: avatarStatus,
                isLoading: false,
                radius: 20,
                showStatusIndicator: true,
                borderColor: statusColor.withOpacity(0.3),
                borderWidth: 2,
                onTap: () => context.push('/profile/${match['name']}'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      match['name'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: Color(0xFF1E293B)),
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
                          match['score'] as String,
                          style: TextStyle(
                              color: statusColor,
                              fontSize: 14,
                              fontWeight: FontWeight.w500),
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
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      match['time'] as String,
                      style: TextStyle(
                          color: statusColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500),
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
      ),
    );
  }
}