import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/menu/widgets/app_drawer.dart';
import 'package:trivia_tycoon/screens/menu/widgets/standard_appbar.dart';
import '../../core/helpers/responsive_layout.dart';
import '../../screens/menu/widgets/rank_level_card.dart';
import '../../screens/menu/widgets/recently_played_section.dart';
import '../../ui_components/tycoon_toast/tycoon_toast.dart';
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
  TycoonToast? _greetingToast;

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

    // Show greeting toast after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _showGreetingToast();
    });
  }

  void _showGreetingToast() {
    final profileService = ref.read(playerProfileServiceProvider);
    final ageGroup = ref.read(userAgeGroupProvider);
    final userProfile = profileService.getProfile();
    final userName = userProfile['name'] ?? 'Player';
    final currentHour = DateTime.now().hour;
    final greeting = _getGreeting(currentHour);
    final greetingIcon = _getGreetingIcon(currentHour);

    _greetingToast = TycoonToast(
      title: greeting,
      message: 'Welcome back, $userName!',
      icon: Icon(greetingIcon, color: Colors.white, size: 32),
      titleSize: 18,
      messageSize: 15,
      duration: const Duration(seconds: 3),
      tycoonToastPosition: TycoonToastPosition.top,
      tycoonToastStyle: TycoonToastStyle.floating,
      backgroundGradient: _getGreetingGradient(ageGroup),
      shouldIconPulse: true,
      margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(20),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withOpacity(0.3),
          blurRadius: 25,
          offset: const Offset(0, 12),
        ),
      ],
    );

    _greetingToast!.show(context);
  }

  LinearGradient _getGreetingGradient(String ageGroup) {
    switch (ageGroup) {
      case 'kids':
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'teens':
        return const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'adults':
        return const LinearGradient(
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }

  String _getGreeting(int hour) {
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  IconData _getGreetingIcon(int hour) {
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_sunny_outlined;
    return Icons.nightlight_round;
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
        child: _buildResponsiveBody(),
      )
          : _buildResponsiveBody(),
    );
  }

  Widget _buildResponsiveBody() {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  // --- MOBILE LAYOUT ---
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildAllComponents(),
      ),
    );
  }

  // --- DESKTOP/WEB LAYOUT ---
  Widget _buildDesktopLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isExtraWide = constraints.maxWidth > 1200;

              if (isExtraWide) {
                // Three column layout for very wide screens
                return _buildThreeColumnLayout();
              } else {
                // Two column layout for desktop/tablet
                return _buildTwoColumnLayout();
              }
            },
          ),
        ),
      ),
    );
  }

  // Two column layout
  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _animatedComponent(0, _buildRewardsWidget()),
              const SizedBox(height: 20),
              _animatedComponent(1, _buildCurrencyWidget()),
              const SizedBox(height: 24),
              _animatedComponent(3, _buildActionButtons()),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Right Column
        Expanded(
          flex: 7,
          child: Column(
            children: [
              _animatedComponent(2, _buildRankCard()),
              const SizedBox(height: 24),
              _animatedComponent(4, _buildJourneyProgress()),
              const SizedBox(height: 24),
              _animatedComponent(5, _buildRecentlyPlayed()),
              const SizedBox(height: 24),
              _buildMatchesSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  // Three column layout for extra wide screens
  Widget _buildThreeColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column - Actions & Currency
        Expanded(
          flex: 3,
          child: Column(
            children: [
              _animatedComponent(1, _buildCurrencyWidget()),
              const SizedBox(height: 24),
              _animatedComponent(3, _buildActionButtons()),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Middle Column - Main Content
        Expanded(
          flex: 5,
          child: Column(
            children: [
              _animatedComponent(0, _buildRewardsWidget()),
              const SizedBox(height: 20),
              _animatedComponent(2, _buildRankCard()),
              const SizedBox(height: 24),
              _animatedComponent(4, _buildJourneyProgress()),
              const SizedBox(height: 24),
              _animatedComponent(5, _buildRecentlyPlayed()),
            ],
          ),
        ),
        const SizedBox(width: 24),
        // Right Column - Matches
        Expanded(
          flex: 4,
          child: Column(
            children: [
              _buildMatchesSection(),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final ageGroup = ref.watch(userAgeGroupProvider);

    return StandardAppBar(
      title: 'Trivia Tycoon',
      ageGroup: ageGroup,
      showSearch: true,
      showChat: true,
      showNotifications: true,
    );
  }

  // --- HELPER TO MAINTAIN ANIMATIONS ---
  Widget _animatedComponent(int index, Widget child) {
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.5),
        end: Offset.zero,
      ).animate(CurvedAnimation(
        parent: _cardAnimationControllers[index],
        curve: Curves.easeOutBack,
      )),
      child: child,
    );
  }

  // --- COMPONENT BUILDERS (Avoid Code Duplication) ---

  Widget _buildRewardsWidget() {
    return Consumer(
      builder: (context, ref, _) {
        final dailyRewardsAvailable = ref.watch(dailyRewardsAvailableProvider);
        final ageGroup = ref.watch(userAgeGroupProvider);
        return _RewardsAvailableWidget(
          dailyRewardsAvailable: dailyRewardsAvailable,
          ageGroup: ageGroup,
        );
      },
    );
  }

  Widget _buildCurrencyWidget() {
    return Consumer(
      builder: (context, ref, _) {
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
          showEnergyInfo: (cur, max) => _showEnergyInfo(context, cur, max),
          showLivesInfo: (cur, max) => _showLivesInfo(context, cur, max),
        );
      },
    );
  }

  Widget _buildRankCard() {
    return Consumer(
      builder: (context, ref, _) {
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
    );
  }

  Widget _buildActionButtons() {
    return Consumer(
      builder: (context, ref, _) {
        final ageGroup = ref.watch(userAgeGroupProvider);
        final unreadNotifications = ref.watch(unreadNotificationsProvider);
        final pendingInvites = ref.watch(pendingInvitesProvider);
        final dailyRewardsAvailable = ref.watch(dailyRewardsAvailableProvider);
        return _ActionButtonsRow(
          ageGroup: ageGroup,
          unreadNotifications: unreadNotifications,
          pendingInvites: pendingInvites,
          dailyRewardsAvailable: dailyRewardsAvailable,
          isDesktop: ResponsiveLayout.isDesktop(context),
        );
      },
    );
  }

  Widget _buildJourneyProgress() {
    return Consumer(
      builder: (context, ref, _) {
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
    );
  }

  Widget _buildRecentlyPlayed() {
    return Consumer(
      builder: (context, ref, _) {
        final quizService = ref.watch(quizProgressServiceProvider);
        final ageGroup = ref.watch(userAgeGroupProvider);
        final recentQuizzes = quizService.getRecentQuizzes();
        return RecentlyPlayedSection(
          quizzes: recentQuizzes,
          ageGroup: ageGroup,
        );
      },
    );
  }

  Widget _buildMatchesSection() {
    return Consumer(
      builder: (context, ref, _) {
        final matches = ref.watch(activeMatchesProvider);
        return _MatchesSection(matches: matches);
      },
    );
  }

  // Helper to build all components for mobile layout
  List<Widget> _buildAllComponents() {
    return [
      _animatedComponent(0, _buildRewardsWidget()),
      const SizedBox(height: 20),
      _animatedComponent(1, _buildCurrencyWidget()),
      const SizedBox(height: 24),
      _animatedComponent(2, _buildRankCard()),
      const SizedBox(height: 24),
      _animatedComponent(3, _buildActionButtons()),
      const SizedBox(height: 24),
      _animatedComponent(4, _buildJourneyProgress()),
      const SizedBox(height: 24),
      _animatedComponent(5, _buildRecentlyPlayed()),
      const SizedBox(height: 24),
      _buildMatchesSection(),
      const SizedBox(height: 100),
    ];
  }

  void _showEnergyInfo(BuildContext context, int currentEnergy, int maxEnergy) {
    final energyRefillTime = ref.read(energyRefillTimeProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

// Rewards Available Widget
class _RewardsAvailableWidget extends StatelessWidget {
  final bool dailyRewardsAvailable;
  final String ageGroup;

  const _RewardsAvailableWidget({
    required this.dailyRewardsAvailable,
    required this.ageGroup,
  });

  @override
  Widget build(BuildContext context) {
    if (!dailyRewardsAvailable) {
      return const SizedBox.shrink();
    }

    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        context.push('/rewards');
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: _getRewardGradient(ageGroup),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(
            color: Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.card_giftcard,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily Rewards Available!',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Tap to claim your rewards',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_forward_ios,
                color: Colors.white,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  LinearGradient _getRewardGradient(String ageGroup) {
    switch (ageGroup) {
      case 'kids':
        return const LinearGradient(
          colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'teens':
        return const LinearGradient(
          colors: [Color(0xFF4ECDC4), Color(0xFF44A08D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      case 'adults':
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
      default:
        return const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        );
    }
  }
}

// Currency Display Widget
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
            child: Row(
              children: [
                Expanded(child: _buildCurrencyItem(index, currency)),
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
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCurrencyItem(int index, Map<String, dynamic> currency) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
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
        );
      },
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
  }

  void _showCoinStore(BuildContext context) {
    // Implementation
  }

  void _showGemStore(BuildContext context) {
    // Implementation
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
                child: Icon(icon, color: color, size: 20),
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

// Action Buttons Widget
class _ActionButtonsRow extends StatelessWidget {
  final String ageGroup;
  final int unreadNotifications;
  final int pendingInvites;
  final bool dailyRewardsAvailable;
  final bool isDesktop;

  const _ActionButtonsRow({
    required this.ageGroup,
    required this.unreadNotifications,
    required this.pendingInvites,
    required this.dailyRewardsAvailable,
    this.isDesktop = false,
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
                if (!isDesktop)
                  Row(
                    children: [
                      Icon(Icons.swipe_left, size: 16, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text('Scroll', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
              ],
            ),
          ),

          // Desktop: Grid layout, Mobile: Horizontal scroll
          isDesktop
              ? Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) {
                final action = actions[index];
                return _buildActionCard(action, index);
              },
            ),
          )
              : SizedBox(
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

  Widget _buildActionCard(Map<String, dynamic> action, int index) {
    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 600 + (index * 80)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.scale(
          scale: 0.8 + (0.2 * value),
          child: Opacity(
            opacity: value,
            child: _ActionButton(
              label: action['label'] as String,
              icon: action['icon'] as IconData,
              gradient: action['gradient'] as LinearGradient,
              route: action['route'] as String,
              description: action['description'] as String,
              badge: action['badge'] as int?,
              isCard: true,
            ),
          ),
        );
      },
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
  final bool isCard;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.gradient,
    required this.route,
    required this.description,
    this.badge,
    this.isCard = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isCard) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push(route);
        },
        child: Container(
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
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icon, color: Colors.white, size: 32),
                    const SizedBox(height: 8),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (badge != null && badge! > 0)
                Positioned(
                  right: 8,
                  top: 8,
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
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      );
    }

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
                        fontWeight: FontWeight.bold,
                      ),
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
              color: Color(0xFF475569),
            ),
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
          const Text(
            'Trivia Journey',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
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
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (!isPremium)
            GestureDetector(
              onTap: () => context.push('/offers'),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Unlock Premium for $premiumDiscountPercent% OFF!',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFB45309),
                        ),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 14, color: Color(0xFFB45309)),
                  ],
                ),
              ),
            )
        ],
      ),
    );
  }
}

class _MatchesSection extends StatefulWidget {
  final List<Map<String, dynamic>> matches;

  const _MatchesSection({required this.matches});

  @override
  State<_MatchesSection> createState() => _MatchesSectionState();
}

class _MatchesSectionState extends State<_MatchesSection> {
  String _selectedTab = 'Classic';
  String _selectedFilter = 'All';

  @override
  Widget build(BuildContext context) {
    // If no matches, show sample matches for demo
    final displayMatches = widget.matches.isEmpty ? _getSampleMatches() : widget.matches;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tabs
          _buildTabs(),

          const SizedBox(height: 16),

          // Create Match Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildCreateMatchButton(),
          ),

          const SizedBox(height: 20),

          // Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: _buildFilterChips(),
          ),

          const SizedBox(height: 20),

          // Matches Horizontal Scroll
          SizedBox(
            height: 280, // Increased from 240 to 280
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              scrollDirection: Axis.horizontal,
              itemCount: displayMatches.length + 1, // +1 for invite card
              itemBuilder: (context, index) {
                if (index == 0) {
                  return _buildInviteCard();
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: _buildMatchCard(displayMatches[index - 1]),
                );
              },
            ),
          ),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF64748B).withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          _buildTab('Classic', 1),
          _buildTab('Live', 1),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int notificationCount) {
    final isSelected = _selectedTab == label;

    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? const Color(0xFF1E293B) : Colors.transparent,
                width: 3,
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                  color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
                ),
              ),
              if (notificationCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEF4444),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    notificationCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCreateMatchButton() {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [
            Color(0xFFFF6B6B),
            Color(0xFFFFD93D),
            Color(0xFF6BCB77),
            Color(0xFF4D96FF),
            Color(0xFF9D4EDD),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/create-match'),
            borderRadius: BorderRadius.circular(14),
            child: const Center(
              child: Text(
                'Create match',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = ['All', 'Your turn', 'Suggestions'];

    return Row(
      children: filters.map((filter) {
        final isSelected = _selectedFilter == filter;

        return Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FilterChip(
            selected: isSelected,
            label: Text(filter),
            onSelected: (selected) {
              setState(() => _selectedFilter = filter);
            },
            backgroundColor: Colors.white,
            selectedColor: const Color(0xFFE2E8F0),
            labelStyle: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            ),
            side: BorderSide(
              color: isSelected
                  ? const Color(0xFF94A3B8)
                  : const Color(0xFFE2E8F0),
              width: 1.5,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildInviteCard() {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3B82F6),
            Color(0xFF2563EB),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.push('/invite'),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.person_add_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Invite',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(Map<String, dynamic> match) {
    final status = match['status'] as String;
    String statusText = '';
    Color statusColor = const Color(0xFF64748B);
    String actionLabel = 'Start';

    switch (status) {
      case 'your_turn':
        statusText = 'Your turn';
        statusColor = const Color(0xFFEF4444);
        actionLabel = 'Play';
        break;
      case 'similar_stats':
        statusText = '#SimilarStats';
        statusColor = const Color(0xFF94A3B8);
        actionLabel = 'Start';
        break;
      case 'fast_player':
        statusText = '#FastPlayer';
        statusColor = const Color(0xFF94A3B8);
        actionLabel = 'Start';
        break;
      case 'waiting':
        statusText = 'Waiting...';
        statusColor = const Color(0xFF94A3B8);
        actionLabel = 'View';
        break;
    }

    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE2E8F0),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top content with flexible space
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Avatar
                  GestureDetector(
                    onTap: () => context.push('/profile/${match['name']}'),
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: _getAvatarColor(match['name'] as String),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _getAvatarColor(match['name'] as String).withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          (match['name'] as String).substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Name
                  Text(
                    match['name'] as String,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),

                  // Score
                  if (match['score'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        match['score'] as String,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ),
                  const SizedBox(height: 10),

                  // Status
                  Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),

          // Action Button - Fixed height at bottom
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFE0E7FF),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
              border: Border(
                top: BorderSide(
                  color: const Color(0xFFE2E8F0),
                  width: 2,
                ),
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  context.push('/match-details', extra: match);
                },
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(18),
                  bottomRight: Radius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    actionLabel,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getAvatarColor(String name) {
    final colors = [
      const Color(0xFFEC4899), // Pink
      const Color(0xFFF59E0B), // Yellow
      const Color(0xFF10B981), // Green
      const Color(0xFF3B82F6), // Blue
      const Color(0xFF8B5CF6), // Purple
    ];

    final index = name.hashCode % colors.length;
    return colors[index];
  }

  List<Map<String, dynamic>> _getSampleMatches() {
    return [
      {
        'name': 'techalien.9...',
        'score': '0-0',
        'status': 'your_turn',
      },
      {
        'name': 'todd.faugh...',
        'score': null,
        'status': 'similar_stats',
      },
      {
        'name': 'emelia.brin...',
        'score': null,
        'status': 'fast_player',
      },
      {
        'name': 'sarah.chen',
        'score': '850-720',
        'status': 'waiting',
      },
      {
        'name': 'mike.johnson',
        'score': '540-680',
        'status': 'your_turn',
      },
    ];
  }
}








