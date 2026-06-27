import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/navigation_extensions.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import 'package:trivia_tycoon/ui_components/synaptix_toast/synaptix_toast_service.dart';

import '../../game/analytics/services/analytics_service.dart';
import '../../game/models/reward_step_models.dart';
import '../../game/providers/riverpod_providers.dart';
import '../../game/providers/spin_providers.dart';
import '../../ui_components/spin_wheel/models/spin_system_models.dart';
import '../../ui_components/spin_wheel/services/spin_tracker.dart'
    show SpinStatistics, SpinTracker;
import '../../ui_components/spin_wheel/ui/toasts/spin_ready_premium_toast.dart';
import '../../ui_components/spin_wheel/ui/widgets/wheel_widget.dart';
import 'package:trivia_tycoon/core/manager/log_manager.dart';

class SpinEarnScreen extends ConsumerStatefulWidget {
  const SpinEarnScreen({super.key});

  @override
  ConsumerState<SpinEarnScreen> createState() => _SpinEarnScreenState();
}

class _SpinEarnScreenState extends ConsumerState<SpinEarnScreen>
    with TickerProviderStateMixin {
  late final AnimationController _wheelController;
  late final AnimationController _headerController;

  late final Animation<double> _wheelAnimation;
  late final Animation<double> _headerAnimation;
  late final Animation<Offset> _slideAnimation;

  Timer? _clockTimer;
  bool _isLoading = true;
  bool _segmentsLoading = true;

  int _todaySpinCount = 0;
  int _weeklySpinCount = 0;
  int _totalSpins = 0;
  int _spinsRemaining = 0;
  int _dailyLimit = 5;

  double _currentSpinSliderValue = 0.0;
  Duration _dailyResetRemaining = Duration.zero;
  Duration _cooldownRemaining = Duration.zero;
  List<WheelSegment> _segments = const [];

  AnalyticsService? _analytics;
  DateTime? _screenEnteredTime;

  @override
  void initState() {
    super.initState();
    _screenEnteredTime = DateTime.now();
    _initAnimations();
    _startClock();
    unawaited(_loadInitialData());
    unawaited(_trackScreenView());
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _loadSpinData(),
      _loadSegments(),
    ]);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        unawaited(_checkAndShowSpinReadyToast());
      }
    });
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
      begin: const Offset(0, 0.25),
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

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      unawaited(_refreshTimers());
    });
    unawaited(_refreshTimers());
  }

  Future<void> _refreshTimers() async {
    final cooldown = await SpinTracker.timeLeft();
    if (!mounted) return;
    setState(() {
      _dailyResetRemaining = _timeUntilTomorrow();
      _cooldownRemaining = cooldown;
    });
  }

  Future<void> _loadSpinData() async {
    try {
      await _checkAndResetDailyCounts();
      final results = await Future.wait([
        ref.read(spinStatisticsProvider.future),
        AppSettings.getSpinRewardPoints(),
      ]);

      final stats = results[0] as SpinStatistics;

      if (mounted) {
        setState(() {
          _todaySpinCount = stats.dailyCount;
          _weeklySpinCount = stats.weeklyCount;
          _totalSpins = stats.totalSpins;
          _dailyLimit = stats.maxSpinsPerDay;
          _spinsRemaining = stats.spinsRemainingToday;
          _currentSpinSliderValue = results[1] as double;
          _cooldownRemaining = stats.timeUntilNextSpin;
          _isLoading = false;
        });

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

  Future<void> _loadSegments() async {
    try {
      final segments = await ref.read(segmentLoaderProvider).loadSegments();
      if (!mounted) return;
      setState(() {
        _segments = segments;
        _segmentsLoading = false;
      });
    } catch (e) {
      LogManager.debug('Failed to load spin segments: $e');
      if (!mounted) return;
      setState(() {
        _segmentsLoading = false;
      });
      await _trackError('load_spin_segments_failed', e.toString());
    }
  }

  Future<void> _checkAndShowSpinReadyToast() async {
    if (_spinsRemaining > 0 && mounted) {
      await PremiumSpinReadyToast.show(
        context: context,
        onSpinNow: _navigateToFullWheelScreen,
        spinsRemaining: _spinsRemaining,
        rewardPoints: _currentSpinSliderValue.toInt(),
        bonusMessage:
            _spinsRemaining >= _dailyLimit ? 'All free spins available!' : null,
      );
    }
  }

  Future<void> _checkAndResetDailyCounts() async {
    final lastSpinDate = await AppSettings.getLastSpinDate();
    final now = DateTime.now();

    if (lastSpinDate == null || !_isSameDay(lastSpinDate, now)) {
      await AppSettings.resetDailySpinCount();
      await _trackAnalyticsEvent('daily_spin_reset', {
        'last_spin_date': lastSpinDate?.toIso8601String(),
        'reset_date': now.toIso8601String(),
      });
    }

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
    final startOfWeek1 = date1.subtract(Duration(days: date1.weekday - 1));
    final startOfWeek2 = date2.subtract(Duration(days: date2.weekday - 1));
    return _isSameDay(startOfWeek1, startOfWeek2);
  }

  Future<void> _trackScreenView() async {
    await _trackAnalyticsEvent('screen_view', {
      'screen_name': 'SpinEarnScreen',
      'spins_remaining': _spinsRemaining,
      'daily_limit': _dailyLimit,
      'total_lifetime_spins': _totalSpins,
    });
  }

  Future<void> _trackDataLoaded() async {
    await _trackAnalyticsEvent('spin_data_loaded', {
      'today_spin_count': _todaySpinCount,
      'weekly_spin_count': _weeklySpinCount,
      'total_spins': _totalSpins,
      'spins_remaining': _spinsRemaining,
      'reward_points': _currentSpinSliderValue,
    });
  }

  Future<void> _trackAnalyticsEvent(
    String eventName,
    Map<String, dynamic> data,
  ) async {
    try {
      _analytics ??= ref.read(analyticsServiceProvider);
      await _analytics?.trackEvent(eventName, data);
    } catch (e) {
      LogManager.debug('Analytics tracking failed: $e');
    }
  }

  Future<void> _trackEngagement(
    String action, {
    Map<String, dynamic>? properties,
  }) async {
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

  Future<void> _trackError(String errorType, String errorMessage) async {
    await _trackAnalyticsEvent('spin_screen_error', {
      'error_type': errorType,
      'error_message': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _trackUserAction(
    String action, {
    Map<String, dynamic>? additionalData,
  }) async {
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
    _clockTimer?.cancel();
    _headerController.dispose();
    _wheelController.dispose();
    super.dispose();
  }

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
    return Scaffold(
      backgroundColor: const Color(0xFF070725),
      body: Stack(
        children: [
          const Positioned.fill(child: _ArcadeBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth >= 900 ? 28 : 16,
                    vertical: 16,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - 32,
                    ),
                    child: _isLoading
                        ? _buildLoadingState()
                        : _buildResponsiveContent(constraints.maxWidth),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return SizedBox(
      height: 520,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFFFD95A), width: 4),
              ),
              child: const Padding(
                padding: EdgeInsets.all(18),
                child: CircularProgressIndicator(
                  color: Color(0xFFFFD95A),
                  strokeWidth: 4,
                ),
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Loading spin rewards',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResponsiveContent(double maxWidth) {
    final isWide = maxWidth >= 1060;
    final rewardSteps = ref.watch(spinRewardStepsProvider).maybeWhen(
          data: (steps) => steps,
          orElse: () => const <RewardStep>[],
        );
    final nextReward = _nextRewardStep(rewardSteps);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildTopBar(),
        const SizedBox(height: 18),
        _buildScoreStrip(isWide: isWide),
        const SizedBox(height: 20),
        if (isWide)
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  width: 286,
                  child: Column(
                    children: [
                      _buildCountdownPanel(),
                      const SizedBox(height: 16),
                      _buildStatusPanel(),
                      const SizedBox(height: 16),
                      _buildProgressPanel(nextReward),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildWheelStage(maxWidth: 560),
                ),
                const SizedBox(width: 24),
                SizedBox(
                  width: 322,
                  child: Column(
                    children: [
                      _buildGiveawayPanel(nextReward),
                      const SizedBox(height: 16),
                      _buildSpinControls(),
                      const SizedBox(height: 16),
                      _buildTargetPanel(nextReward),
                    ],
                  ),
                ),
              ],
            ),
          )
        else ...[
          _buildWheelStage(maxWidth: maxWidth),
          const SizedBox(height: 18),
          _buildSpinControls(),
          const SizedBox(height: 16),
          _buildCountdownPanel(),
          const SizedBox(height: 16),
          _buildGiveawayPanel(nextReward),
          const SizedBox(height: 16),
          _buildTargetPanel(nextReward),
          const SizedBox(height: 16),
          _buildStatusPanel(),
          const SizedBox(height: 16),
          _buildProgressPanel(nextReward),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTopBar() {
    return AnimatedBuilder(
      animation: _headerAnimation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _headerAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: child,
          ),
        );
      },
      child: Row(
        children: [
          _buildIconButton(
            icon: Icons.arrow_back_rounded,
            onPressed: () async {
              await _trackUserAction('back_button_pressed');
              if (!mounted) return;
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/rewards');
              }
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Spin & Earn',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFFFD95A),
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Free cooldown spins with guaranteed virtual rewards',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Color(0xFFD8DBFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _buildIconButton(
            icon: Icons.history_rounded,
            onPressed: () async {
              await _trackUserAction('history_button_pressed');
              if (!mounted) return;
              _showHistoryDialog(Theme.of(context));
            },
          ),
          const SizedBox(width: 8),
          _buildIconButton(
            icon: Icons.settings_rounded,
            onPressed: () async {
              await _trackUserAction('settings_button_pressed');
              if (!mounted) return;
              _showSettingsDialog(Theme.of(context));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 44,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF15104B).withValues(alpha: 0.92),
          border: Border.all(color: const Color(0xFFFFD95A), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: IconButton(
          tooltip: MaterialLocalizations.of(context).backButtonTooltip,
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }

  Widget _buildScoreStrip({required bool isWide}) {
    final items = [
      _ScoreItem(
        label: 'Free Spins Left',
        value: '$_spinsRemaining',
        icon: Icons.casino_rounded,
      ),
      _ScoreItem(
        label: 'Points Won',
        value: _formatNumber(_currentSpinSliderValue.round()),
        icon: Icons.stars_rounded,
      ),
      _ScoreItem(
        label: 'Total Spins',
        value: _formatNumber(_totalSpins),
        icon: Icons.emoji_events_rounded,
      ),
    ];

    if (!isWide) {
      return Column(
        children: [
          for (int i = 0; i < items.length; i++) ...[
            _buildScorePill(items[i]),
            if (i != items.length - 1) const SizedBox(height: 10),
          ],
        ],
      );
    }

    return Row(
      children: [
        for (int i = 0; i < items.length; i++) ...[
          Expanded(child: _buildScorePill(items[i])),
          if (i != items.length - 1) const SizedBox(width: 16),
        ],
      ],
    );
  }

  Widget _buildScorePill(_ScoreItem item) {
    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: const LinearGradient(
          colors: [Color(0xFFC50820), Color(0xFFFF3849), Color(0xFF8A0419)],
        ),
        border: Border.all(color: const Color(0xFFFFC83D), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(item.icon, color: const Color(0xFFFFE781), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFFFE781),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWheelStage({required double maxWidth}) {
    final wheelSize = maxWidth.clamp(320.0, 560.0);

    return AnimatedBuilder(
      animation: _wheelAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _wheelAnimation.value.clamp(0.0, 1.0),
          child: child,
        );
      },
      child: Container(
        constraints: BoxConstraints(maxWidth: wheelSize + 72),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                gradient: const LinearGradient(
                  colors: [Color(0xFF7B310A), Color(0xFFFFC94E)],
                ),
                border: Border.all(color: const Color(0xFFFFF0A3), width: 2),
              ),
              child: const Text(
                'SPIN TIL YOU WIN',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF401000),
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Center(
              child: Container(
                width: wheelSize,
                height: wheelSize,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const SweepGradient(
                    colors: [
                      Color(0xFFFFE98A),
                      Color(0xFF9A550B),
                      Color(0xFFFFC93D),
                      Color(0xFFFFF1A8),
                      Color(0xFFFFE98A),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFFD84D).withValues(alpha: 0.45),
                      blurRadius: 28,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 24,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF1A0944),
                    border: Border.all(
                      color: const Color(0xFFFFF3A6),
                      width: 3,
                    ),
                  ),
                  child: _segmentsLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFFFFD95A),
                          ),
                        )
                      : GestureDetector(
                          onTap: _spinsRemaining > 0
                              ? _navigateToFullWheelScreen
                              : _handleNoSpinsRemaining,
                          child: WheelWidget(
                            segments: _segments,
                            size: wheelSize - 44,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpinControls() {
    final isReady = _spinsRemaining > 0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildBalanceBadge(),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 72,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(36),
              gradient: LinearGradient(
                colors: isReady
                    ? const [Color(0xFFFF5967), Color(0xFFC9001A)]
                    : const [Color(0xFF7D7896), Color(0xFF4A4663)],
              ),
              border: Border.all(color: const Color(0xFFFFF2A0), width: 4),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.36),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: TextButton.icon(
              onPressed: isReady
                  ? _navigateToFullWheelScreen
                  : _handleNoSpinsRemaining,
              icon: const Icon(Icons.casino_rounded, size: 30),
              label: Text(isReady ? 'SPIN' : 'COOLDOWN'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                textStyle: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(36),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBalanceBadge() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [Color(0xFFFFEB67), Color(0xFFFFAF11)],
            ),
          ),
          child: const Icon(
            Icons.bolt_rounded,
            color: Color(0xFF7A1A00),
            size: 28,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'FREE SPINS',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 90,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF491075),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFFFD95A), width: 2),
          ),
          child: Text(
            '$_spinsRemaining / $_dailyLimit',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCountdownPanel() {
    final parts = _durationParts(_dailyResetRemaining);
    return _ArcadePanel(
      title: 'Daily Reset In',
      icon: Icons.timer_rounded,
      accent: const Color(0xFFFFD95A),
      child: Row(
        children: [
          Expanded(child: _buildTimeBox(parts.days.toString(), 'Days')),
          const SizedBox(width: 8),
          Expanded(child: _buildTimeBox(parts.hours.toString(), 'Hrs')),
          const SizedBox(width: 8),
          Expanded(child: _buildTimeBox(parts.minutes.toString(), 'Mins')),
          const SizedBox(width: 8),
          Expanded(child: _buildTimeBox(parts.seconds.toString(), 'Sec')),
        ],
      ),
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Column(
      children: [
        Container(
          height: 50,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            gradient: const LinearGradient(
              colors: [Color(0xFFB91727), Color(0xFF620721)],
            ),
            border: Border.all(color: const Color(0xFFFFD95A), width: 2.5),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value.padLeft(2, '0'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPanel() {
    return _ArcadePanel(
      title: 'Spin Status',
      icon: Icons.leaderboard_rounded,
      accent: const Color(0xFF58E0FF),
      child: Column(
        children: [
          _buildMeterRow('Today', '$_todaySpinCount / $_dailyLimit'),
          const SizedBox(height: 10),
          _buildMeterRow('This Week', _formatNumber(_weeklySpinCount)),
          const SizedBox(height: 10),
          _buildMeterRow('Lifetime', _formatNumber(_totalSpins)),
        ],
      ),
    );
  }

  Widget _buildMeterRow(String label, String value) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFEFEFFF),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 88),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            color: const Color(0xFFFFB917),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.16),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFF4D1600),
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGiveawayPanel(RewardStep? nextReward) {
    return _ArcadePanel(
      title: 'Giveaway',
      icon: Icons.card_giftcard_rounded,
      accent: const Color(0xFFFFC83D),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 158,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFF06C), Color(0xFFFFB012)],
              ),
              border: Border.all(color: const Color(0xFFFFF6A7), width: 2),
            ),
            child: Icon(
              nextReward?.icon ?? Icons.card_giftcard_rounded,
              size: 66,
              color: const Color(0xFF7B2500),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            nextReward?.description ?? 'Loading next reward',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTargetPanel(RewardStep? nextReward) {
    final target = _targetPoints(nextReward);
    final progress =
        target <= 0 ? 1.0 : (_currentSpinSliderValue / target).clamp(0.0, 1.0);

    return _ArcadePanel(
      title: 'Target Score',
      icon: Icons.flag_rounded,
      accent: const Color(0xFFFF9E25),
      warm: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            nextReward == null
                ? 'All reward targets cleared'
                : 'Reach ${_formatNumber(target.round())} points to unlock',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF1B103B),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 18,
              value: progress,
              backgroundColor: const Color(0xFF6D1430),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFF06C),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat(
                  label: 'Current',
                  value: _formatNumber(_currentSpinSliderValue.round()),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMiniStat(
                  label: 'Timer',
                  value: _cooldownRemaining > Duration.zero
                      ? _formatClock(_cooldownRemaining)
                      : 'Ready',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressPanel(RewardStep? nextReward) {
    final target = _targetPoints(nextReward);
    final progress =
        target <= 0 ? 1.0 : (_currentSpinSliderValue / target).clamp(0.0, 1.0);

    return _ArcadePanel(
      title: 'Reward Progress',
      icon: Icons.stars_rounded,
      accent: const Color(0xFFB25CFF),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            nextReward?.description ?? 'All rewards unlocked',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 16,
              value: progress,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFFFFD95A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '${_formatNumber(_currentSpinSliderValue.round())} / ${_formatNumber(target.round())}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFFFE781),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat({required String label, required String value}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF991525),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFD95A), width: 1.5),
      ),
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFFE781),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  RewardStep? _nextRewardStep(List<RewardStep> rewardSteps) {
    if (rewardSteps.isEmpty) return null;
    final sorted = [...rewardSteps]
      ..sort((a, b) => a.pointValue.compareTo(b.pointValue));
    for (final step in sorted) {
      if (_currentSpinSliderValue < step.pointValue) return step;
    }
    return null;
  }

  double _targetPoints(RewardStep? nextReward) {
    if (nextReward != null) return nextReward.pointValue;
    return math.max(_currentSpinSliderValue, 1);
  }

  Duration _timeUntilTomorrow() {
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    return tomorrow.difference(now);
  }

  _DurationParts _durationParts(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    return _DurationParts(
      days: safe.inDays,
      hours: safe.inHours.remainder(24),
      minutes: safe.inMinutes.remainder(60),
      seconds: safe.inSeconds.remainder(60),
    );
  }

  String _formatClock(Duration duration) {
    final safe = duration.isNegative ? Duration.zero : duration;
    final hours = safe.inHours;
    final minutes = safe.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = safe.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  String _formatNumber(int value) {
    final text = value.toString();
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      final fromEnd = text.length - i;
      buffer.write(text[i]);
      if (fromEnd > 1 && fromEnd % 3 == 1) {
        buffer.write(',');
      }
    }
    return buffer.toString();
  }

  void _handleNoSpinsRemaining() async {
    await _trackUserAction('no_spins_tap', additionalData: {
      'spins_remaining': _spinsRemaining,
      'daily_limit': _dailyLimit,
      'today_count': _todaySpinCount,
    });

    if (!mounted) return;

    await SynaptixToastService.info(
      context: context,
      title: 'Cooldown Active',
      message: 'Your next free spin unlocks soon.',
      duration: const Duration(seconds: 3),
    );
  }

  void _navigateToFullWheelScreen() async {
    await _trackUserAction('spin_wheel_opened', additionalData: {
      'spins_remaining_before': _spinsRemaining,
      'reward_points': _currentSpinSliderValue,
    });

    if (!mounted) return;
    final result = await context.push('/spin-earn/wheel');

    await _trackUserAction('returned_from_wheel', additionalData: {
      'result': result?.toString(),
    });

    if (mounted) {
      ref.invalidate(spinStatisticsProvider);
      await _loadSpinData();
      unawaited(_refreshTimers());
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
                            'Value: ${spin['rewardValue']} - ${_formatDate(spin['timestamp'])}',
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
                        await _trackUserAction(
                          'setting_changed',
                          additionalData: {
                            'setting': 'animations',
                            'new_value': value,
                          },
                        );
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
                        await _trackUserAction(
                          'setting_changed',
                          additionalData: {
                            'setting': 'sound_effects',
                            'new_value': value,
                          },
                        );
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
                        await _trackUserAction(
                          'setting_changed',
                          additionalData: {
                            'setting': 'haptic_feedback',
                            'new_value': value,
                          },
                        );
                        setDialogState(() {
                          hapticEnabled = value;
                        });
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _checkAndShowSpinReadyToast,
                        icon: const Icon(Icons.casino),
                        label: const Text('Check Spin Status'),
                      ),
                    ),
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

class _ScoreItem {
  const _ScoreItem({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;
}

class _DurationParts {
  const _DurationParts({
    required this.days,
    required this.hours,
    required this.minutes,
    required this.seconds,
  });

  final int days;
  final int hours;
  final int minutes;
  final int seconds;
}

class _ArcadePanel extends StatelessWidget {
  const _ArcadePanel({
    required this.title,
    required this.icon,
    required this.accent,
    required this.child,
    this.warm = false,
  });

  final String title;
  final IconData icon;
  final Color accent;
  final Widget child;
  final bool warm;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: warm
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFFD24C), Color(0xFFE48908)],
              )
            : const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF24105C), Color(0xFF5A1278)],
              ),
        border: Border.all(color: accent, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.26),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: warm ? const Color(0xFF4D1600) : accent,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ArcadeBackdrop extends StatelessWidget {
  const _ArcadeBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF12145A),
            Color(0xFF2C126B),
            Color(0xFF10012B),
          ],
        ),
      ),
      child: Stack(
        children: const [
          Positioned.fill(child: CustomPaint(painter: _StarfieldPainter())),
          Positioned.fill(child: CustomPaint(painter: _ArcadeGridPainter())),
        ],
      ),
    );
  }
}

class _StarfieldPainter extends CustomPainter {
  const _StarfieldPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final random = math.Random(11);
    final paint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 120; i++) {
      final dx = random.nextDouble() * size.width;
      final dy = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 1.7 + 0.4;
      final colors = [
        const Color(0xFF78E8FF),
        const Color(0xFFFFF0A3),
        const Color(0xFFD6B2FF),
      ];
      paint.color = colors[i % colors.length].withValues(alpha: 0.75);
      canvas.drawCircle(Offset(dx, dy), radius, paint);
    }

    final streakPaint = Paint()
      ..color = const Color(0xFFFF4BE1).withValues(alpha: 0.28)
      ..strokeWidth = 2;
    for (int i = 0; i < 10; i++) {
      final y = size.height * (0.18 + i * 0.065);
      canvas.drawLine(
        Offset(size.width * 0.15, y),
        Offset(size.width * 0.85, y + size.height * 0.24),
        streakPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ArcadeGridPainter extends CustomPainter {
  const _ArcadeGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final horizon = size.height * 0.58;
    final bottom = size.height;
    final centerX = size.width / 2;
    final paint = Paint()
      ..color = const Color(0xFF5DE2FF).withValues(alpha: 0.16)
      ..strokeWidth = 1;

    for (int i = -9; i <= 9; i++) {
      final x = centerX + i * size.width * 0.08;
      canvas.drawLine(
        Offset(centerX, horizon),
        Offset(x, bottom),
        paint,
      );
    }

    for (int i = 0; i < 13; i++) {
      final t = i / 12;
      final y = horizon + math.pow(t, 1.8) * (bottom - horizon);
      canvas.drawLine(
          Offset(0, y.toDouble()), Offset(size.width, y.toDouble()), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
