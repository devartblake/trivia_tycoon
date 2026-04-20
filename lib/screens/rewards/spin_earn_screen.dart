import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import 'package:trivia_tycoon/screens/rewards/widgets/reward_stepper_slider_widget.dart';
import '../../game/analytics/services/analytics_service.dart';
import '../../game/models/reward_step_models.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../ui_components/spin_wheel/ui/toasts/spin_ready_premium_toast.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class SpinEarnScreen extends ConsumerStatefulWidget {
  const SpinEarnScreen({super.key});

  @override
  ConsumerState<SpinEarnScreen> createState() => _SpinEarnScreenState();
}

class _SpinEarnScreenState extends ConsumerState<SpinEarnScreen>
    with TickerProviderStateMixin {
  late AnimationController _wheelController;
  late AnimationController _headerController;

  late Animation<double> _wheelAnimation;
  late Animation<double> _headerAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;

  // Spin statistics
  int _todaySpinCount = 0;
  int _weeklySpinCount = 0;
  int _totalSpins = 0;
  int _spinsRemaining = 0;
  int _dailyLimit = 5;

  // Reward progress
  double _currentSpinSliderValue = 20.0;

  // Analytics
  AnalyticsService? _analytics;
  DateTime? _screenEnteredTime;

  @override
  void initState() {
    super.initState();
    _screenEnteredTime = DateTime.now();
    _initAnimations();
    _loadSpinData().then((_) {
      // Show spin ready toast after data loads
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _checkAndShowSpinReadyToast();
        }
      });
    });
    _trackScreenView();
  }

  void _initAnimations() {
    _headerController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _wheelController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _headerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutBack,
    ));

    _wheelAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _wheelController,
      curve: Curves.elasticOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _headerController,
      curve: Curves.easeOutCubic,
    ));

    _headerController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _wheelController.forward();
    });
  }

  Future<void> _loadSpinData() async {
    try {
      // Check if we need to reset daily counts
      await _checkAndResetDailyCounts();

      // Load all spin data from AppSettings
      final results = await Future.wait([
        AppSettings.getTodaySpinCount(),
        AppSettings.getWeeklySpinCount(),
        AppSettings.getTotalLifetimeSpins(),
        AppSettings.getDailySpinLimit(),
        AppSettings.getRemainingSpinsToday(),
        AppSettings.getSpinRewardPoints(),
      ]);

      if (mounted) {
        setState(() {
          _todaySpinCount = results[0] as int;
          _weeklySpinCount = results[1] as int;
          _totalSpins = results[2] as int;
          _dailyLimit = results[3] as int;
          _spinsRemaining = results[4] as int;
          _currentSpinSliderValue = results[5] as double;
          _isLoading = false;
        });

        // Track analytics after loading
        await _trackDataLoaded();
      }
    } catch (e) {
      LogManager.debug('Failed to load spin data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
      await _trackError('load_spin_data_failed', e.toString());
    }
  }

  Future<void> _checkAndShowSpinReadyToast() async {
    final canSpin = await AppSettings.canSpinToday();
    final spinsRemaining = await AppSettings.getRemainingSpinsToday();
    final rewardPoints = await AppSettings.getSpinRewardPoints();

    if (canSpin && spinsRemaining > 0 && mounted) {
      // Show premium toast
      await PremiumSpinReadyToast.show(
        context: context,
        onSpinNow: _navigateToFullWheelScreen,
        spinsRemaining: spinsRemaining,
        rewardPoints: rewardPoints.toInt(),
        bonusMessage: spinsRemaining == 5 ? '🎉 All spins available!' : null,
      );
    }
  }

  /// Checks and resets daily/weekly counts if needed
  Future<void> _checkAndResetDailyCounts() async {
    final lastSpinDate = await AppSettings.getLastSpinDate();
    final now = DateTime.now();

    // Reset daily count if it's a new day
    if (lastSpinDate == null || !_isSameDay(lastSpinDate, now)) {
      await AppSettings.resetDailySpinCount();
      await _trackAnalyticsEvent('daily_spin_reset', {
        'last_spin_date': lastSpinDate?.toIso8601String(),
        'reset_date': now.toIso8601String(),
      });
    }

    // Reset weekly count if it's a new week
    final lastWeeklyReset = await AppSettings.getLastWeeklyResetDate();
    if (lastWeeklyReset == null || !_isSameWeek(lastWeeklyReset, now)) {
      await AppSettings.resetWeeklySpinCount();
      await AppSettings.setLastWeeklyResetDate(now);
      await _trackAnalyticsEvent('weekly_spin_reset', {
        'last_reset_date': lastWeeklyReset?.toIso8601String(),
        'reset_date': now.toIso8601String(),
      });
    }
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  bool _isSameWeek(DateTime date1, DateTime date2) {
    // Week starts on Monday
    final startOfWeek1 = date1.subtract(Duration(days: date1.weekday - 1));
    final startOfWeek2 = date2.subtract(Duration(days: date2.weekday - 1));
    return _isSameDay(startOfWeek1, startOfWeek2);
  }

  // ============ ANALYTICS METHODS ============

  /// Track screen view
  Future<void> _trackScreenView() async {
    await _trackAnalyticsEvent('screen_view', {
      'screen_name': 'SpinEarnScreen',
      'spins_remaining': _spinsRemaining,
      'daily_limit': _dailyLimit,
      'total_lifetime_spins': _totalSpins,
    });
  }

  /// Track when data is successfully loaded
  Future<void> _trackDataLoaded() async {
    await _trackAnalyticsEvent('spin_data_loaded', {
      'today_spin_count': _todaySpinCount,
      'weekly_spin_count': _weeklySpinCount,
      'total_spins': _totalSpins,
      'spins_remaining': _spinsRemaining,
      'reward_points': _currentSpinSliderValue,
    });
  }

  /// Track analytics event
  Future<void> _trackAnalyticsEvent(
      String eventName, Map<String, dynamic> data) async {
    try {
      _analytics ??= ref.read(analyticsServiceProvider);
      await _analytics?.trackEvent(eventName, data);
    } catch (e) {
      LogManager.debug('Analytics tracking failed: $e');
    }
  }

  /// Track engagement
  Future<void> _trackEngagement(String action,
      {Map<String, dynamic>? properties}) async {
    try {
      _analytics ??= ref.read(analyticsServiceProvider);
      await _analytics?.trackEngagement(
        action: action,
        screen: 'SpinEarnScreen',
        properties: properties,
      );
    } catch (e) {
      LogManager.debug('Engagement tracking failed: $e');
    }
  }

  /// Track error
  Future<void> _trackError(String errorType, String errorMessage) async {
    await _trackAnalyticsEvent('spin_screen_error', {
      'error_type': errorType,
      'error_message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  /// Track user interaction
  Future<void> _trackUserAction(String action,
      {Map<String, dynamic>? additionalData}) async {
    await _trackEngagement('user_action', properties: {
      'action': action,
      'spins_remaining': _spinsRemaining,
      'reward_points': _currentSpinSliderValue,
      ...?additionalData,
    });
  }

  @override
  void dispose() {
    _trackScreenExit();
    _headerController.dispose();
    _wheelController.dispose();
    super.dispose();
  }

  /// Track screen exit with duration
  Future<void> _trackScreenExit() async {
    if (_screenEnteredTime != null) {
      final duration = DateTime.now().difference(_screenEnteredTime!);
      await _trackAnalyticsEvent('screen_exit', {
        'screen_name': 'SpinEarnScreen',
        'duration_seconds': duration.inSeconds,
        'duration_minutes': duration.inMinutes,
        'spins_used': _todaySpinCount,
        'final_reward_points': _currentSpinSliderValue,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(theme),
          SliverFillRemaining(
            hasScrollBody: false,
            child: _isLoading ? _buildLoadingState() : _buildContent(theme),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(ThemeData theme) {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      elevation: 0,
      backgroundColor: theme.colorScheme.primary,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.8),
              ],
            ),
          ),
          child: SafeArea(
            child: AnimatedBuilder(
              animation: _headerAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: _headerAnimation.value,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.casino,
                          size: 32,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Spin & Earn',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '$_spinsRemaining spins remaining today',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withValues(alpha: 0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
      leading: IconButton(
        onPressed: () async {
          await _trackUserAction('back_button_pressed');
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/rewards');
          }
        },
        icon: const Icon(Icons.arrow_back, color: Colors.white),
      ),
      actions: [
        IconButton(
          onPressed: () async {
            await _trackUserAction('settings_button_pressed');
            _showSettingsDialog(theme);
          },
          icon: const Icon(Icons.settings, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildShowSpinToastButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ElevatedButton.icon(
        onPressed: _checkAndShowSpinReadyToast,
        icon: const Icon(Icons.casino),
        label: const Text('Check Spin Status'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 400,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading spin wheel...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildStatsSection(theme),
          const SizedBox(height: 24),
          _buildSpinPointsSlider(theme),
          const SizedBox(height: 24),
          Flexible(
            child: _buildWheelSection(theme),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Your Spin Stats',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () async {
                  await _trackUserAction('history_button_pressed');
                  _showHistoryDialog(theme);
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.history,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.today,
                  label: 'Today',
                  value: '$_todaySpinCount/$_dailyLimit',
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.date_range,
                  label: 'This Week',
                  value: '$_weeklySpinCount',
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timeline,
                  label: 'Total',
                  value: '$_totalSpins',
                  color: Colors.purple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  Widget _buildSpinPointsSlider(ThemeData theme) {
    final List<RewardStep> rewardSteps = [
      RewardStep(
        pointValue: 5,
        icon: Icons.inventory_2,
        backgroundColor: Colors.brown,
        quantity: 1,
        description: 'Mystery Box',
      ),
      RewardStep(
        pointValue: 20,
        icon: Icons.card_giftcard,
        backgroundColor: Colors.orange,
        quantity: 1,
        description: 'Gift Card',
      ),
      RewardStep(
        pointValue: 50,
        icon: Icons.monetization_on,
        backgroundColor: Colors.amber,
        quantity: 300,
        description: 'Coins',
      ),
      RewardStep(
        pointValue: 100,
        icon: Icons.card_giftcard,
        backgroundColor: Colors.orange,
        quantity: 2,
        description: 'Premium Gift',
      ),
      RewardStep(
        pointValue: 200,
        icon: Icons.monetization_on,
        backgroundColor: Colors.amber,
        quantity: 500,
        description: 'Bonus Coins',
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Reward Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.cyan.withValues(alpha: 0.1),
                  Colors.blue.withValues(alpha: 0.1)
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyan.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Text(
                  'Points',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.cyan[700],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${_currentSpinSliderValue.toInt()}/200',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          RewardStepperSlider(
            value: _currentSpinSliderValue,
            onChanged: (value) async {
              final oldValue = _currentSpinSliderValue;
              setState(() {
                _currentSpinSliderValue = value;
              });

              // Save to AppSettings
              await AppSettings.setSpinRewardPoints(value);

              // Track slider interaction
              await _trackUserAction('reward_slider_changed', additionalData: {
                'old_value': oldValue,
                'new_value': value,
                'difference': value - oldValue,
              });
            },
            rewardSteps: rewardSteps,
            progressColor: Colors.orange,
            height: 120,
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[200]!),
            ),
            child: Text(
              _getCurrentRewardDescription(rewardSteps),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[700],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  String _getCurrentRewardDescription(List<RewardStep> rewardSteps) {
    for (int i = 0; i < rewardSteps.length; i++) {
      if (_currentSpinSliderValue < rewardSteps[i].pointValue) {
        final pointsNeeded =
            rewardSteps[i].pointValue - _currentSpinSliderValue;
        return 'Next: ${rewardSteps[i].description} (${pointsNeeded.toInt()} points needed)';
      }
    }
    return 'All rewards unlocked!';
  }

  Widget _buildWheelSection(ThemeData theme) {
    return AnimatedBuilder(
      animation: _wheelAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _wheelAnimation.value,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.casino,
                      color: theme.colorScheme.primary,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Try Your Luck!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.purple.shade200,
                        Colors.blue.shade200,
                        Colors.pink.shade200,
                        Colors.orange.shade200,
                      ],
                      stops: const [0.0, 0.33, 0.66, 1.0],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: _spinsRemaining > 0
                          ? _navigateToFullWheelScreen
                          : _handleNoSpinsRemaining,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 4,
                          ),
                        ),
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _spinsRemaining > 0 ? Icons.casino : Icons.lock,
                                size: 48,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _spinsRemaining > 0
                                    ? 'TAP TO SPIN'
                                    : 'NO SPINS',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              Text(
                                '$_spinsRemaining left',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  _spinsRemaining > 0
                      ? 'Tap the wheel to open the full spin experience!'
                      : 'Come back tomorrow for more spins!',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleNoSpinsRemaining() async {
    await _trackUserAction('no_spins_tap', additionalData: {
      'spins_remaining': _spinsRemaining,
      'daily_limit': _dailyLimit,
      'today_count': _todaySpinCount,
    });

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('No spins remaining today! Come back tomorrow.'),
        backgroundColor: Colors.orange,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _navigateToFullWheelScreen() async {
    await _trackUserAction('spin_wheel_opened', additionalData: {
      'spins_remaining_before': _spinsRemaining,
      'reward_points': _currentSpinSliderValue,
    });

    final result = await context.push('/spin-earn/wheel');

    // Track return from wheel
    await _trackUserAction('returned_from_wheel', additionalData: {
      'result': result?.toString(),
    });

    // Refresh data after spinning
    if (mounted) {
      await _loadSpinData();
    }
  }

  void _showHistoryDialog(ThemeData theme) async {
    final history = await AppSettings.getSpinHistory();

    await _trackEngagement('spin_history_viewed', properties: {
      'history_count': history.length,
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            constraints: const BoxConstraints(maxHeight: 500),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(Icons.history, size: 24),
                    const SizedBox(width: 12),
                    Text(
                      'Spin History',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (history.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text('No spin history yet'),
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: history.length,
                      itemBuilder: (context, index) {
                        final spin = history[index];
                        return ListTile(
                          leading: Icon(
                            Icons.card_giftcard,
                            color: theme.colorScheme.primary,
                          ),
                          title: Text(spin['rewardType'] ?? 'Unknown'),
                          subtitle: Text(
                            'Value: ${spin['rewardValue']} • ${_formatDate(spin['timestamp'])}',
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showSettingsDialog(ThemeData theme) async {
    bool animationEnabled = await AppSettings.getSpinAnimationEnabled();
    bool soundEnabled = await AppSettings.getSpinSoundEnabled();
    bool hapticEnabled = await AppSettings.getSpinHapticEnabled();

    await _trackEngagement('settings_opened', properties: {
      'animation_enabled': animationEnabled,
      'sound_enabled': soundEnabled,
      'haptic_enabled': hapticEnabled,
    });

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.settings, size: 24),
                        const SizedBox(width: 12),
                        Text(
                          'Spin Settings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SwitchListTile(
                      title: const Text('Animations'),
                      subtitle: const Text('Enable spin animations'),
                      value: animationEnabled,
                      onChanged: (value) async {
                        await AppSettings.setSpinAnimationEnabled(value);
                        await _trackUserAction('setting_changed',
                            additionalData: {
                              'setting': 'animations',
                              'new_value': value,
                            });
                        setDialogState(() {
                          animationEnabled = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Sound Effects'),
                      subtitle: const Text('Play sounds when spinning'),
                      value: soundEnabled,
                      onChanged: (value) async {
                        await AppSettings.setSpinSoundEnabled(value);
                        await _trackUserAction('setting_changed',
                            additionalData: {
                              'setting': 'sound_effects',
                              'new_value': value,
                            });
                        setDialogState(() {
                          soundEnabled = value;
                        });
                      },
                    ),
                    SwitchListTile(
                      title: const Text('Haptic Feedback'),
                      subtitle: const Text('Vibrate when spinning'),
                      value: hapticEnabled,
                      onChanged: (value) async {
                        await AppSettings.setSpinHapticEnabled(value);
                        await _trackUserAction('setting_changed',
                            additionalData: {
                              'setting': 'haptic_feedback',
                              'new_value': value,
                            });
                        setDialogState(() {
                          hapticEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    _buildShowSpinToastButton(),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';
    try {
      final date = timestamp is DateTime
          ? timestamp
          : DateTime.parse(timestamp.toString());
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}

final analyticsServiceProvider = Provider<AnalyticsService>((ref) {
  return ref.watch(serviceManagerProvider).analyticsService;
});
