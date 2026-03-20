import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../core/helpers/responsive_layout.dart';
import '../../core/services/theme/seasonal_theme_service.dart';
import '../../core/theme/themes.dart';
import '../../game/utils/gradient_themes.dart';
import '../../game/utils/greeting_utils.dart';
import '../../ui_components/tycoon_toast/tycoon_toast.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../core/animations/animation_manager.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

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
  AnimationController? _animationController;
  late List<AnimationController> _cardAnimationControllers;
  TycoonToast? _greetingToast;

  @override
  void initState() {
    super.initState();

    // Main fade animation
    _animationController = AnimationManager.createController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    // Card stagger animations
    _cardAnimationControllers = AnimationManager.createStaggeredControllers(
      vsync: this,
      count: 6,
      baseDurationMs: 600,
      durationIncrementMs: 100,
    );

    // Start animations
    _animationController!.forward();
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
      final completed = await serviceManager.onboardingSettingsService.hasCompletedOnboarding();
      if (!mounted || completed) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Complete onboarding to unlock your profile and avatar setup.'),
          duration: Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (_) {
      // Ignore reminder failures
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
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

    return Theme(
      data: appTheme.themeData,
      child: Scaffold(
        backgroundColor: appTheme.bg2,
        drawer: const AppDrawer(),
        appBar: _buildAppBar(),
        body: FadeTransition(
          opacity: AnimationManager.fadeIn(_animationController!),
          child: _buildResponsiveBody(),
        ),
      ),
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
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _buildAllComponents(),
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isExtraWide = constraints.maxWidth > 1200;
              return isExtraWide
                  ? _buildThreeColumnLayout()
                  : _buildTwoColumnLayout();
            },
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

        return CurrencyDisplay(
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
        final unreadNotifications = ref.watch(unreadNotificationsProvider);
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