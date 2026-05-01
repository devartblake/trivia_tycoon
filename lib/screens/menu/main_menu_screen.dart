import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/screens/menu/sections/matches_section.dart';
import 'package:trivia_tycoon/screens/menu/widgets/action_buttons.dart';
import 'package:trivia_tycoon/screens/menu/widgets/app_drawer.dart';
import 'package:trivia_tycoon/screens/menu/widgets/curency_display.dart';
import 'package:trivia_tycoon/screens/menu/widgets/journey_progress.dart';
import 'package:trivia_tycoon/screens/menu/widgets/rank_card_widget.dart';
import 'package:trivia_tycoon/screens/menu/widgets/recently_played_widget.dart';
import 'package:trivia_tycoon/screens/menu/widgets/rewards_banner.dart';
import 'package:trivia_tycoon/screens/menu/widgets/standard_appbar.dart';
import '../../core/animations/animation_manager.dart';
import '../../core/constants/app_constants.dart';
import '../../core/helpers/responsive_layout.dart';
import '../../core/services/theme/seasonal_theme_service.dart';
import '../../core/theme/themes.dart';
import '../../game/providers/economy_providers.dart';
import '../../game/providers/core_providers.dart';
import '../../game/utils/gradient_themes.dart';
import '../../game/utils/greeting_utils.dart';
import '../../ui_components/tycoon_toast/tycoon_toast.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../game/providers/wallet_providers.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';
import '../../game/providers/personalization_providers.dart';
import 'widgets/coach_brief_banner.dart';
import '../../personalization/widgets/recommended_for_you_section.dart';

/// Modern, modular main menu screen
///
/// This screen has been completely refactored into modular components:
/// - RewardsBanner - Daily rewards notification
/// - CurrencyDisplay - Coins, gems, energy, lives
/// - ActionButtons - Quick action buttons
/// - JourneyProgress - XP progress tracker
/// - MatchesSection - Match tabs and cards
/// - RankCardWidget - Rank/level display
/// - RecentlyPlayedWidget - Recent games
class MainMenuScreen extends ConsumerStatefulWidget {
  const MainMenuScreen({super.key});

  @override
  ConsumerState<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends ConsumerState<MainMenuScreen>
    with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final AnimationController _pulseController;
  late List<AnimationController> _cardAnimationControllers;
  TycoonToast? _greetingToast;
  AppLifecycleListener? _lifecycleListener;

  @override
  void initState() {
    super.initState();

    // Main fade animation
    _animationController = AnimationManager.createController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _pulseController = AnimationManager.createController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    // Card stagger animations
    _cardAnimationControllers = AnimationManager.createStaggeredControllers(
      vsync: this,
      count: 6,
      baseDurationMs: 600,
      durationIncrementMs: 100,
    );

    // Start animations
    _animationController.forward();
    AnimationManager.startStaggered(
      controllers: _cardAnimationControllers,
      baseDelayMs: 0,
      delayIncrementMs: 150,
      mounted: mounted,
    );

    // Show greeting toast after delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) _showGreetingToast();
    });

    // Fetch economy state on first load and on app resume
    _fetchEconomy();
    _lifecycleListener = AppLifecycleListener(
      onResume: _fetchEconomy,
    );

    // Remind users to complete onboarding when needed.
    Future.delayed(const Duration(milliseconds: 1100), () {
      if (mounted) _showOnboardingReminderIfNeeded();
    });
  }

  void _showGreetingToast() {
    final profileService = ref.read(playerProfileServiceProvider);
    final ageGroup = ref.read(userAgeGroupProvider);
    final userProfile = profileService.getProfile();
    final userName = userProfile['name'] ?? 'Player';

    final currentHour = DateTime.now().hour;
    final greeting = GreetingUtils.getGreeting(currentHour);
    final greetingIcon = GreetingUtils.getGreetingIcon(currentHour);

    _greetingToast = TycoonToast(
      title: greeting,
      message: 'Welcome back, $userName!',
      icon: Icon(greetingIcon, color: Colors.white, size: 32),
      titleSize: 18,
      messageSize: 15,
      duration: const Duration(seconds: 3),
      tycoonToastPosition: TycoonToastPosition.top,
      tycoonToastStyle: TycoonToastStyle.floating,
      backgroundGradient: GradientThemes.getGreetingGradient(ageGroup),
      shouldIconPulse: true,
      margin: const EdgeInsets.only(top: 60, left: 16, right: 16),
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(20),
      boxShadows: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.3),
          blurRadius: 25,
          offset: const Offset(0, 12),
        ),
      ],
    );

    _greetingToast!.show(context);
  }

  Future<void> _showOnboardingReminderIfNeeded() async {
    try {
      final serviceManager = ref.read(serviceManagerProvider);
      final completed = await serviceManager.onboardingSettingsService
          .hasCompletedOnboarding();
      if (!mounted || completed) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Complete onboarding to unlock your profile and avatar setup.'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // Ignore reminder failures
    }
  }

  Future<void> _fetchEconomy() async {
    if (!mounted) return;
    try {
      final playerId = await ref.read(currentUserIdProvider.future);
      if (!mounted) return;
      await Future.wait([
        ref.read(economyProvider.notifier).fetchState(playerId),
        _syncWalletBalances(playerId),
      ]);
    } catch (_) {
      // Economy state is non-blocking — the HUD will show cached values.
    }
  }

  Future<void> _syncWalletBalances(String playerId) async {
    if (playerId.isEmpty || playerId == 'guest') {
      return;
    }

    try {
      final player =
          await ref.read(synaptixApiClientProvider).getPlayer(playerId);
      final coins = player.wallet.coins;
      final gems = player.wallet.gems;

      await Future.wait([
        ref.read(coinBalanceProvider.notifier).set(coins),
        ref.read(diamondNotifierProvider).set(gems),
        ref.read(walletServiceProvider).setBalances(coins: coins, gems: gems),
      ]);

      ref.read(playerCoinsProvider.notifier).state = coins;
      ref.read(playerGemsProvider.notifier).state = gems;
    } catch (e) {
      LogManager.debug('[MainMenu] Wallet sync skipped: $e');
    }
  }

  @override
  void dispose() {
    _lifecycleListener?.dispose();
    _animationController.dispose();
    _pulseController.dispose();
    AnimationManager.disposeControllers(_cardAnimationControllers);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeAsync = ref.watch(activeThemeTypeProvider);

    return themeAsync.when(
      data: (themeType) => _buildScaffold(themeType),
      loading: () => _buildScaffold(AppTheme.defaultTheme),
      error: (error, stack) {
        LogManager.debug('[Theme] Error loading theme: $error');
        return _buildScaffold(AppTheme.defaultTheme);
      },
    );
  }

  Widget _buildScaffold(ThemeType themeType) {
    final appTheme = AppTheme.fromType(themeType, ThemeMode.light);
    final isDesktop = ResponsiveLayout.isDesktop(context);

    return Theme(
      data: appTheme.themeData,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: appTheme.bg2,
        drawer: const AppDrawer(),
        appBar: _buildModernAppBar(),
        body: Stack(
          children: [
            const Positioned.fill(child: _AnimatedMeshBackdrop()),
            SafeArea(
              child: FadeTransition(
                opacity: AnimationManager.fadeIn(
                  animation: _animationController,
                ),
                child: _buildResponsiveBody(),
              ),
            ),
            if (!isDesktop)
              const Positioned(
                left: 16,
                right: 16,
                bottom: 14,
                child: _FloatingBottomNav(),
              ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildModernAppBar() {
    final ageGroup = ref.watch(userAgeGroupProvider);

    return StandardAppBar(
      title: appTitle,
      ageGroup: ageGroup,
      showSearch: true,
      showChat: true,
      showNotifications: true,
    );
  }

  Widget _buildResponsiveBody() {
    return ResponsiveLayout(
      mobile: _buildMobileLayout(),
      tablet: _buildMobileLayout(),
      desktop: _buildDesktopLayout(),
    );
  }

  // MOBILE LAYOUT - Single column
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 10),
          _buildLiveTickerBar(),
          const SizedBox(height: 8),
          _buildCoachBriefBanner(),
          _buildRecommendedForYou(),
          const SizedBox(height: 6),
          _animatedComponent(0, _buildFeaturedModeCard()),
          const SizedBox(height: 20),
          _animatedComponent(1, _buildCurrencyWidget()),
          const SizedBox(height: 16),
          _animatedComponent(2, _buildRewardsWidget()),
          const SizedBox(height: 16),
          _animatedComponent(3, _buildActionButtons()),
          const SizedBox(height: 20),
          _animatedComponent(4, _buildRankCard()),
          const SizedBox(height: 16),
          _animatedComponent(5, _buildJourneyProgress()),
          const SizedBox(height: 20),
          _buildRecentlyPlayed(),
          const SizedBox(height: 20),
          _buildMatchesSection(),
          const SizedBox(height: 120),
        ],
      ),
    );
  }

  // DESKTOP LAYOUT - Multi-column
  Widget _buildDesktopLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1400),
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildLiveTickerBar(),
              const SizedBox(height: 16),
              _buildFeaturedModeCard(),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isExtraWide = constraints.maxWidth > 1200;
                  return isExtraWide
                      ? _buildThreeColumnLayout()
                      : _buildTwoColumnLayout();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTwoColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column (40%)
        Expanded(
          flex: 4,
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
        // Right column (60%)
        Expanded(
          flex: 6,
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

  Widget _buildThreeColumnLayout() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column (30%)
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
        // Center column (40%)
        Expanded(
          flex: 4,
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
        // Right column (30%)
        Expanded(
          flex: 3,
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

  // ✅ Still using controllers for more control over timing
  // But AnimationManager handles creation/disposal
  Widget _animatedComponent(int index, Widget child) {
    return AnimationManager.fadeSlideIn(
      animation: _cardAnimationControllers[index],
      begin: const Offset(0, 0.5),
      child: child,
    );
  }

  Widget _buildCoachBriefBanner() {
    final asyncId = ref.watch(currentPlayerIdProvider);
    return asyncId.when(
      data: (id) {
        if (id == null || id.isEmpty) return const SizedBox.shrink();
        return CoachBriefBannerLoader(playerId: id);
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRecommendedForYou() {
    final asyncId = ref.watch(currentPlayerIdProvider);
    return asyncId.when(
      data: (id) {
        if (id == null || id.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 6),
          child: RecommendedForYouSection(playerId: id),
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildLiveTickerBar() {
    final ageGroup = ref.watch(userAgeGroupProvider);
    final primaryAccent = GradientThemes.getAgeGroupColors(ageGroup).first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          colors: [
            primaryAccent.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.72),
          ],
        ),
        border: Border.all(color: primaryAccent.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(Icons.show_chart_rounded, color: primaryAccent, size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'LIVE: Weekend Trivia Rush is active • 2x XP for party matches',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3D63),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedModeCard() {
    final ageGroup = ref.watch(userAgeGroupProvider);
    final primaryAccent = GradientThemes.getAgeGroupColors(ageGroup).first;
    final pulse = Tween<double>(begin: 1, end: 1.06).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                primaryAccent.withValues(alpha: 0.16),
                Colors.white.withValues(alpha: 0.78),
              ],
            ),
            border: Border.all(color: primaryAccent.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF5470C1).withValues(alpha: 0.12),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'FEATURED MODE',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF3D4A69),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Gemini Clash Arena',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1D2A49),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Fast 60-second rounds with reactive bonuses and global leaderboard spikes.',
                style: TextStyle(
                  color: const Color(0xFF2B3A5C),
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 16),
              AnimatedBuilder(
                animation: pulse,
                builder: (context, child) => Transform.scale(
                  scale: pulse.value,
                  alignment: Alignment.centerLeft,
                  child: child,
                ),
                child: ElevatedButton.icon(
                  onPressed: () => context.push('/play'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: primaryAccent,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: const Icon(Icons.flash_on_rounded),
                  label: const Text('Play Featured'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // COMPONENT BUILDERS
  // All components now use the modular widgets

  Widget _buildRewardsWidget() {
    return Consumer(
      builder: (context, ref, _) {
        final dailyRewardsAvailable = ref.watch(dailyRewardsAvailableProvider);
        final ageGroup = ref.watch(userAgeGroupProvider);

        return RewardsBanner(
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

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CurrencyDisplay(
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
            ),
          ],
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

        return RankCardWidget(
          level: userProfile['level'] ?? 0,
          rank: userProfile['rank'] ?? 1,
          ageGroup: ageGroup,
        );
      },
    );
  }

  Widget _buildActionButtons() {
    return Consumer(
      builder: (context, ref, _) {
        final ageGroup = ref.watch(userAgeGroupProvider);
        ref.watch(notificationRealtimeSyncProvider);
        final unreadNotifications = ref
            .watch(playerNotificationUnreadCountProvider)
            .maybeWhen(data: (value) => value, orElse: () => 0);
        final pendingInvites = ref.watch(pendingInvitesProvider);
        final dailyRewardsAvailable = ref.watch(dailyRewardsAvailableProvider);

        return ActionButtons(
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

        return JourneyProgress(
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

        // Convert to the expected format
        final quizzesList = recentQuizzes.map((quiz) {
          return {
            'id': quiz['id']?.toString() ?? '',
            'title': quiz['title']?.toString() ?? '',
            'category': quiz['category']?.toString() ?? '',
            'score': quiz['score']?.toString() ?? '',
            'date': quiz['date']?.toString() ?? '',
          };
        }).toList();

        return RecentlyPlayedWidget(
          quizzes: quizzesList,
          ageGroup: ageGroup,
        );
      },
    );
  }

  Widget _buildMatchesSection() {
    return Consumer(
      builder: (context, ref, _) {
        final matches = ref.watch(activeMatchesProvider);
        return MatchesSection(matches: matches);
      },
    );
  }

  // INFO DIALOGS

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
    final livesState = ref.read(livesProvider);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Challenge Lives'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Lives per run: $maxLives'),
            const SizedBox(height: 8),
            if (livesState.isRunActive) ...[
              Text('Current run lives: $currentLives/$maxLives'),
              const SizedBox(height: 4),
              Text(
                livesState.canRevive
                    ? 'Premium revive available (1 per run)'
                    : 'No revives remaining for this run',
              ),
            ],
            const SizedBox(height: 16),
            const Text(
              'Lives are used only in Challenge mode — 3 lives per run. '
              'They do not refill over time. Start a new run to restore lives. '
              'One premium revive is available per run.',
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
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

class _WorldGridBackdrop extends StatelessWidget {
  const _WorldGridBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: 0.12,
        child: CustomPaint(
          painter: _SubtleGridPainter(),
        ),
      ),
    );
  }
}

class _SubtleGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const spacing = 28.0;
    final paint = Paint()
      ..color = const Color(0xFF5B6B8A)
      ..strokeWidth = 1;

    for (double x = 0; x <= size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _AnimatedMeshBackdrop extends StatelessWidget {
  const _AnimatedMeshBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF8FBFF),
                  Color(0xFFF3F7FF),
                  Color(0xFFEEF4FF)
                ],
              ),
            ),
          ),
          Positioned(
            top: -160,
            left: -70,
            child: _MeshSphere(
              color: const Color(0xFF8EC5FF).withValues(alpha: 0.25),
              size: 360,
            ),
          ),
          Positioned(
            bottom: -130,
            right: -70,
            child: _MeshSphere(
              color: const Color(0xFFCDC1FF).withValues(alpha: 0.22),
              size: 340,
            ),
          ),
          const Positioned.fill(child: _WorldGridBackdrop()),
        ],
      ),
    );
  }
}

class _MeshSphere extends StatelessWidget {
  final Color color;
  final double size;

  const _MeshSphere({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [color, Colors.transparent],
        ),
      ),
    );
  }
}

class _FloatingBottomNav extends StatelessWidget {
  const _FloatingBottomNav();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(36),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          height: 66,
          padding: const EdgeInsets.symmetric(horizontal: 18),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(36),
            border: Border.all(color: const Color(0xFFD6E3FF)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const _NavIcon(icon: Icons.home_filled, isSelected: true),
              const _NavIcon(icon: Icons.emoji_events_outlined),
              GestureDetector(
                onTap: () => context.push('/play'),
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFF5AA9FF), Color(0xFF6C8DFF)],
                    ),
                  ),
                  child: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 30),
                ),
              ),
              const _NavIcon(icon: Icons.leaderboard_outlined),
              const _NavIcon(icon: Icons.settings_outlined),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavIcon extends StatelessWidget {
  final IconData icon;
  final bool isSelected;

  const _NavIcon({
    required this.icon,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFE8F1FF) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: isSelected ? const Color(0xFF3766D6) : const Color(0xFF7382A3),
        size: isSelected ? 25 : 23,
      ),
    );
  }
}
