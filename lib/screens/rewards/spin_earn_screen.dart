import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trivia_tycoon/core/services/settings/app_settings.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/ui/screen/wheel_screen.dart';
import '../../ui_components/spin_wheel/services/rewards/reward_probability.dart';
import '../../ui_components/spin_wheel/services/spin_tracker.dart';

class RewardStep {
  final double pointValue;
  final IconData icon;
  final Color backgroundColor;
  final int quantity;
  final String description;

  const RewardStep({
    required this.pointValue,
    required this.icon,
    required this.backgroundColor,
    this.quantity = 1,
    this.description = '',
  });
}

class RewardStepperSlider extends StatefulWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final List<RewardStep> rewardSteps;
  final Color progressColor;
  final double height;

  const RewardStepperSlider({
    super.key,
    required this.value,
    required this.onChanged,
    required this.rewardSteps,
    this.progressColor = Colors.orange,
    this.height = 100,
  });

  @override
  State<RewardStepperSlider> createState() => _RewardStepperSliderState();
}

class _RewardStepperSliderState extends State<RewardStepperSlider> {
  final List<GlobalKey<TooltipState>> _tooltipKeys = [];

  @override
  void initState() {
    super.initState();
    // Initialize tooltip keys for each reward step
    for (int i = 0; i < widget.rewardSteps.length; i++) {
      _tooltipKeys.add(GlobalKey<TooltipState>());
    }
  }
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      child: Column(
        children: [
          _buildRewardIconsRow(),
          const SizedBox(height: 8),
          _buildProgressSlider(),
          const SizedBox(height: 8),
          _buildPointLabels(),
        ],
      ),
    );
  }

  Widget _buildRewardIconsRow() {
    return SizedBox(
      height: 60,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: widget.rewardSteps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isUnlocked = widget.value >= step.pointValue;
          return _buildRewardIcon(step, isUnlocked, index);
        }).toList(),
      ),
    );
  }

  Widget _buildRewardIcon(RewardStep step, bool isUnlocked, int index) {
    return Tooltip(
      key: _tooltipKeys[index],
      message: '${step.description}\n${step.quantity > 1 ? '${step.quantity} ' : ''}Unlocked at ${step.pointValue.toInt()} points',
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      textStyle: TextStyle(
        color: Colors.white,
        fontSize: 12,
      ),
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      waitDuration: Duration(milliseconds: 300),
      triggerMode: TooltipTriggerMode.tap,
      enableFeedback: true,
      child: GestureDetector(
        onTap: () {
          // Force tooltip to show on tap for mobile devices
          _tooltipKeys[index].currentState?.ensureTooltipVisible();
        },
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: isUnlocked ? step.backgroundColor : Colors.grey[400],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isUnlocked ? Colors.orange[300]! : Colors.grey[500]!,
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    step.icon,
                    color: isUnlocked ? Colors.white : Colors.grey[600],
                    size: 24,
                  ),
                ),
              ),
              if (step.quantity > 1)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.orange, width: 1),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 2,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Text(
                      '${step.quantity}',
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                  ),
                ),
              if (isUnlocked && widget.value > step.pointValue)
                Positioned(
                  right: -5,
                  bottom: -5,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressSlider() {
    final maxValue = widget.rewardSteps.last.pointValue.toDouble();

    return Container(
      height: 20,
      child: SliderTheme(
        data: SliderTheme.of(context).copyWith(
          trackHeight: 8,
          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 12),
          thumbColor: widget.progressColor,
          activeTrackColor: widget.progressColor,
          inactiveTrackColor: Colors.grey[300],
          overlayShape: SliderComponentShape.noOverlay,
          tickMarkShape: SliderTickMarkShape.noTickMark,
        ),
        child: Slider(
          value: widget.value.clamp(0, maxValue),
          min: 0,
          max: maxValue,
          onChanged: widget.onChanged,
        ),
      ),
    );
  }

  Widget _buildPointLabels() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: widget.rewardSteps.map((step) {
        final isActive = widget.value >= step.pointValue;
        return Text(
          '${step.pointValue.toInt()}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isActive ? widget.progressColor : Colors.grey[600],
          ),
        );
      }).toList(),
    );
  }
}

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
  SpinStatistics? _spinStats;
  RewardProbabilities? _currentProbabilities;
  double _currentSpinSliderValue = 20.0;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _loadSpinData();
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
      final results = await Future.wait([
        EnhancedSpinTracker.getStatistics(),
        EnhancedRewardService().getCurrentProbabilities(),
      ]);

      if (mounted) {
        setState(() {
          _spinStats = results[0] as SpinStatistics;
          _currentProbabilities = results[1] as RewardProbabilities;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Failed to load spin data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    _wheelController.dispose();
    super.dispose();
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
            child: _isLoading
                ? _buildLoadingState()
                : _buildContent(theme),
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
                theme.colorScheme.primary.withOpacity(0.8),
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
                        Icon(
                          Icons.casino,
                          size: 32,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Spin & Earn',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_spinStats != null)
                          Text(
                            '${_spinStats!.spinsRemainingToday} spins remaining today',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withOpacity(0.9),
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
        onPressed: () {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          } else {
            context.go('/rewards');
          }
        },
        icon: Icon(Icons.arrow_back, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: 400,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text(
              'Loading spin wheel...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade600,
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
          SizedBox(height: 24),
          _buildSpinPointsSlider(theme),
          SizedBox(height: 24),
          Flexible(
            child: _buildWheelSection(theme),
          ),
          SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatsSection(ThemeData theme) {
    if (_spinStats == null) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
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
              Spacer(),
              GestureDetector(
                onTap: () => _showProbabilityDialog(theme),
                child: Container(
                  padding: EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline,
                    size: 18,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  icon: Icons.today,
                  label: 'Today',
                  value: '${_spinStats!.dailyCount}/${_spinStats!.maxSpinsPerDay}',
                  color: Colors.blue,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.date_range,
                  label: 'This Week',
                  value: '${_spinStats!.weeklyCount}',
                  color: Colors.green,
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  icon: Icons.timeline,
                  label: 'Total',
                  value: '${_spinStats!.totalSpins}',
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
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        SizedBox(height: 8),
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.emoji_events,
                color: Colors.amber,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Reward Progress',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.cyan.withOpacity(0.1), Colors.blue.withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.cyan.withOpacity(0.3)),
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
                SizedBox(width: 12),
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

          SizedBox(height: 20),

          RewardStepperSlider(
            value: _currentSpinSliderValue,
            onChanged: (value) {
              setState(() {
                _currentSpinSliderValue = value;
              });
            },
            rewardSteps: rewardSteps,
            progressColor: Colors.orange,
            height: 120,
          ),

          SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: EdgeInsets.all(12),
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
        final pointsNeeded = rewardSteps[i].pointValue - _currentSpinSliderValue;
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
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 12,
                  offset: Offset(0, 4),
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
                    SizedBox(width: 8),
                    Text(
                      'Try Your Luck!',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
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
                      stops: [0.0, 0.33, 0.66, 1.0],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(100),
                      onTap: _navigateToFullWheelScreen,
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
                                Icons.casino,
                                size: 48,
                                color: Colors.white,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'TAP TO SPIN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              if (_spinStats != null)
                                Text(
                                  '${_spinStats!.spinsRemainingToday} left',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
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
                SizedBox(height: 20),
                Text(
                  'Tap the wheel to open the full spin experience!',
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

  void _navigateToFullWheelScreen() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const WheelScreen(),
        fullscreenDialog: true,
      ),
    );
  }

  void _showProbabilityDialog(ThemeData theme) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Container(
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.pie_chart,
                      color: theme.colorScheme.secondary,
                      size: 24,
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Your Current Chances',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                if (_currentProbabilities != null) ...[
                  _buildProbabilityBar('Jackpot', _currentProbabilities!.jackpot, Colors.amber),
                  SizedBox(height: 12),
                  _buildProbabilityBar('Rare', _currentProbabilities!.rare, Colors.purple),
                  SizedBox(height: 12),
                  _buildProbabilityBar('Uncommon', _currentProbabilities!.uncommon, Colors.blue),
                  SizedBox(height: 12),
                  _buildProbabilityBar('Common', _currentProbabilities!.common, Colors.green),
                ] else
                  Container(
                    padding: EdgeInsets.all(20),
                    child: Column(
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Probability data not available',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue[200]!),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.info,
                        color: Colors.blue[600],
                        size: 20,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Probabilities are dynamic and may change based on your activity and progress.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue[700],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildProbabilityBar(String label, double probability, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(4),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: probability,
                child: Container(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: 8),
          Text(
            '${(probability * 100).toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}