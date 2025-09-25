import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../game/providers/riverpod_providers.dart';

class RankLevelCard extends ConsumerStatefulWidget {
  final String? rank;
  final int? level;
  final int? currentXP;
  final int? maxXP;
  final String ageGroup;

  const RankLevelCard({
    super.key,
    this.rank,
    this.level,
    this.currentXP,
    this.maxXP,
    required this.ageGroup,
  });

  @override
  ConsumerState<RankLevelCard> createState() => _RankLevelCardState();
}

class _RankLevelCardState extends ConsumerState<RankLevelCard>
    with TickerProviderStateMixin {
  AnimationController? _progressController;
  Animation<double>? _progressAnimation;
  AnimationController? _pulseController;
  Animation<double>? _pulseAnimation;

  // Track previous values for animation updates
  double? _previousProgress;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // Progress bar animation
    _progressController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // Pulse animation for rank badge
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController!,
      curve: Curves.easeInOut,
    ));

    // Start pulse animation
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _pulseController!.repeat(reverse: true);
      }
    });
  }

  void _updateProgressAnimation(double newProgress) {
    if (_previousProgress != newProgress) {
      _progressAnimation = Tween<double>(
        begin: _previousProgress ?? 0.0,
        end: newProgress,
      ).animate(CurvedAnimation(
        parent: _progressController!,
        curve: Curves.easeOutCubic,
      ));

      _progressController!.reset();
      _progressController!.forward();
      _previousProgress = newProgress;
    }
  }

  @override
  void dispose() {
    _progressController?.dispose();
    _pulseController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch providers for real-time updates
    final profileService = ref.watch(playerProfileServiceProvider);
    final profile = profileService.getProfile();

    // Use provider data or fallback to widget parameters
    final rank = widget.rank ?? profile['rank'] ?? 'Apprentice 1';
    final level = widget.level ?? profile['level'] ?? 0;
    final currentXP = widget.currentXP ?? profile['currentXP'] ?? 0;
    final maxXP = widget.maxXP ?? profile['maxXP'] ?? 0;

    final theme = _getThemeData();
    final progressValue = maxXP > 0 ? currentXP / maxXP : 0.0;

    // Update progress animation when XP changes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _updateProgressAnimation(progressValue);
    });

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: theme['gradient'] as LinearGradient,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (theme['shadowColor'] as Color).withOpacity(0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _buildRankBadge(theme),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rank,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.trending_up,
                                color: Colors.white,
                                size: 16,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Level $level',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _buildXPDisplay(currentXP),
            ],
          ),
          const SizedBox(height: 24),
          _buildProgressSection(progressValue, currentXP, maxXP),
        ],
      ),
    );
  }

  Widget _buildRankBadge(Map<String, dynamic> theme) {
    return _pulseAnimation != null
        ? ScaleTransition(
      scale: _pulseAnimation!,
      child: _rankBadgeContent(theme),
    )
        : _rankBadgeContent(theme);
  }

  Widget _rankBadgeContent(Map<String, dynamic> theme) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        theme['icon'] as IconData,
        color: Colors.white,
        size: 28,
      ),
    );
  }

  Widget _buildXPDisplay(int currentXP) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Text(
            'TOTAL XP',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 4),
          TweenAnimationBuilder<int>(
            duration: const Duration(milliseconds: 800),
            tween: IntTween(begin: 0, end: currentXP),
            builder: (context, value, child) {
              return Text(
                '$value',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(double progressValue, int currentXP, int maxXP) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Progress to Next Level',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            TweenAnimationBuilder<int>(
              duration: const Duration(milliseconds: 800),
              tween: IntTween(begin: 0, end: (progressValue * 100).toInt()),
              builder: (context, value, child) {
                return Text(
                  '$value%',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
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
          child: _progressAnimation != null
              ? AnimatedBuilder(
            animation: _progressAnimation!,
            builder: (context, child) {
              return FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: _progressAnimation!.value,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.5),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                ),
              );
            },
          )
              : FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progressValue,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TweenAnimationBuilder<int>(
              duration: const Duration(milliseconds: 800),
              tween: IntTween(begin: 0, end: currentXP),
              builder: (context, value, child) {
                return Text(
                  '$value XP',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                );
              },
            ),
            Text(
              '$maxXP XP',
              style: TextStyle(
                fontSize: 14,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Map<String, dynamic> _getThemeData() {
    switch (widget.ageGroup) {
      case 'kids':
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFFFF6B6B), Color(0xFFFF8E53), Color(0xFFFF6B9D)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': const Color(0xFFFF6B6B),
          'icon': Icons.child_care,
        };
      case 'teens':
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFF4ECDC4), Color(0xFF44A08D), Color(0xFF093637)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': const Color(0xFF4ECDC4),
          'icon': Icons.school,
        };
      case 'adults':
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFF667eea), Color(0xFF764ba2), Color(0xFF6B73FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': const Color(0xFF667eea),
          'icon': Icons.business_center,
        };
      default:
        return {
          'gradient': const LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          'shadowColor': const Color(0xFF6366F1),
          'icon': Icons.star,
        };
    }
  }
}

// Helper method to add XP and trigger level up (call this from your game logic)
extension RankLevelCardHelpers on WidgetRef {
  Future<void> addXPAndCheckLevelUp(int xpToAdd) async {
    final profileService = read(playerProfileServiceProvider);
    final result = await profileService.addXP(xpToAdd);

    if (result['leveledUp'] == true) {
      // Show level up celebration
      // You can trigger confetti, sound effects, or show a dialog here
      final confettiController = read(confettiControllerProvider);
      confettiController.play();

      // Optional: Show level up dialog
      // showLevelUpDialog(result['newLevel'], result['xpGained']);
    }
  }
}
