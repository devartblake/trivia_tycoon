import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../../game/providers/riverpod_providers.dart';
import 'dart:math' as math;

/// Enhanced CoinBalanceDisplay with modern design and animations
class CoinBalanceDisplay extends ConsumerStatefulWidget {
  final bool animate;
  final bool showIcon;
  final bool enableTapToView;
  final Color? iconColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;
  final VoidCallback? onTap;

  const CoinBalanceDisplay({
    super.key,
    this.animate = true,
    this.showIcon = true,
    this.enableTapToView = false,
    this.iconColor,
    this.textColor,
    this.fontSize,
    this.padding,
    this.onTap,
  });

  @override
  ConsumerState<CoinBalanceDisplay> createState() => _CoinBalanceDisplayState();
}

class _CoinBalanceDisplayState extends ConsumerState<CoinBalanceDisplay>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  late AnimationController _incrementController;

  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<Color?> _glowAnimation;

  int _previousBalance = 0;
  bool _isIncreasing = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();

    // Initialize previous balance
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentBalance = ref.read(coinBalanceProvider);
      _previousBalance = currentBalance;
    });
  }

  void _initAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _incrementController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: -2.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _incrementController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = ColorTween(
      begin: widget.iconColor ?? Colors.amber,
      end: (widget.iconColor ?? Colors.amber).withOpacity(0.6),
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.animate) {
      _shimmerController.repeat();
    }
  }

  void _handleBalanceChange(int newBalance) {
    if (newBalance > _previousBalance) {
      setState(() => _isIncreasing = true);

      _incrementController.forward().then((_) {
        _incrementController.reverse();
        if (mounted) {
          setState(() => _isIncreasing = false);
        }
      });

      _pulseController.forward().then((_) {
        _pulseController.reverse();
      });

      // Haptic feedback for balance increase
      HapticFeedback.lightImpact();
    }

    _previousBalance = newBalance;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _shimmerController.dispose();
    _incrementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final coinBalance = ref.watch(coinBalanceProvider); // Use the StateNotifierProvider that returns int

    // Check for balance changes
    if (coinBalance != _previousBalance) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleBalanceChange(coinBalance);
      });
    }

    return GestureDetector(
      onTap: widget.enableTapToView ? _handleTap : widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _pulseAnimation,
          _shimmerAnimation,
          _scaleAnimation,
        ]),
        builder: (context, child) {
          return Transform.scale(
            scale: _isIncreasing ? _scaleAnimation.value : _pulseAnimation.value,
            child: Container(
              padding: widget.padding ?? const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.amber.withOpacity(0.1),
                    Colors.amber.withOpacity(0.05),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.amber.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: _isIncreasing
                    ? [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.4),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ]
                    : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Shimmer effect
                  if (widget.animate) _buildShimmerEffect(),

                  // Main content
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (widget.showIcon) _buildCoinIcon(),
                      if (widget.showIcon) const SizedBox(width: 6),
                      _buildBalanceText(coinBalance),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerEffect() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: CustomPaint(
          painter: ShimmerPainter(
            animation: _shimmerAnimation.value,
            color: Colors.white.withOpacity(0.3),
          ),
        ),
      ),
    );
  }

  Widget _buildCoinIcon() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          width: 24,
          height: 24,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                _glowAnimation.value ?? Colors.amber,
                (widget.iconColor ?? Colors.amber).withOpacity(0.8),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: (_glowAnimation.value ?? Colors.amber).withOpacity(0.3),
                blurRadius: 6,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Icon(
            Icons.monetization_on,
            color: Colors.white,
            size: 16,
          ),
        );
      },
    );
  }

  Widget _buildBalanceText(int balance) {
    return AnimatedSwitcher(
      duration: widget.animate ? const Duration(milliseconds: 500) : Duration.zero,
      transitionBuilder: (child, animation) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.5),
            end: Offset.zero,
          ).animate(animation),
          child: FadeTransition(
            opacity: animation,
            child: child,
          ),
        );
      },
      child: Text(
        _formatBalance(balance),
        key: ValueKey(balance),
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
          fontSize: widget.fontSize,
          color: widget.textColor ?? Colors.amber.shade700,
          shadows: [
            Shadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 1,
              offset: const Offset(0, 1),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBalance(int balance) {
    if (balance >= 1000000) {
      return '${(balance / 1000000).toStringAsFixed(1)}M';
    } else if (balance >= 1000) {
      return '${(balance / 1000).toStringAsFixed(1)}K';
    }
    return '$balance';
  }

  void _handleTap() {
    HapticFeedback.selectionClick();

    // Show detailed balance dialog
    showDialog(
      context: context,
      builder: (context) => CoinBalanceDialog(
        balance: ref.read(coinBalanceProvider),
      ),
    );
  }
}

class ShimmerPainter extends CustomPainter {
  final double animation;
  final Color color;

  ShimmerPainter({
    required this.animation,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.transparent,
          color,
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(
        animation * size.width - size.width * 0.5,
        0,
        size.width,
        size.height,
      ));

    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant ShimmerPainter oldDelegate) {
    return oldDelegate.animation != animation;
  }
}

/// Dialog showing detailed coin balance information
class CoinBalanceDialog extends ConsumerWidget {
  final int balance;

  const CoinBalanceDialog({
    super.key,
    required this.balance,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.amber.withOpacity(0.1),
              Colors.amber.withOpacity(0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [Colors.amber, Colors.amber.shade700],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monetization_on,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coin Balance',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Your current coins',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Balance display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber, Colors.amber.shade600],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.amber.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    '$balance',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Total Coins',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Close button
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  'Close',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.amber.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact version for tight spaces
class CompactCoinBalanceDisplay extends CoinBalanceDisplay {
  const CompactCoinBalanceDisplay({
    super.key,
    super.animate = true,
    super.showIcon = true,
    super.enableTapToView = false,
    super.iconColor,
    super.textColor,
    super.onTap,
  }) : super(
    fontSize: 14,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  );
}

/// Premium version with enhanced effects
class PremiumCoinBalanceDisplay extends CoinBalanceDisplay {
  const PremiumCoinBalanceDisplay({
    super.key,
    super.animate = true,
    super.showIcon = true,
    super.enableTapToView = true,
    super.iconColor = Colors.yellow,
    super.textColor,
    super.onTap,
  }) : super(
    fontSize: 18,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  );
}
