import 'package:flutter/material.dart';
import '../../models/spin_system_models.dart';

class SegmentLabel extends StatefulWidget {
  final WheelSegment segment;
  final bool isLocked;
  final bool isActive;
  final TextStyle? customTextStyle;

  const SegmentLabel({
    super.key,
    required this.segment,
    this.isLocked = false,
    this.isActive = false,
    this.customTextStyle,
  });

  @override
  State<SegmentLabel> createState() => _SegmentLabelState();
}

class _SegmentLabelState extends State<SegmentLabel>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<Color?> _colorAnimation;

  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    _colorAnimation = ColorTween(
      begin: _getBaseTextColor(),
      end: _getActiveTextColor(),
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(SegmentLabel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Color _getBaseTextColor() {
    if (widget.isLocked) {
      return Colors.grey.shade400;
    }

    // Calculate contrast color based on segment background
    final luminance = widget.segment.color.computeLuminance();
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }

  Color _getActiveTextColor() {
    return widget.isLocked ? Colors.grey.shade300 : Colors.amber.shade100;
  }

  Color _getContainerColor() {
    if (widget.isLocked) {
      return Colors.black.withOpacity(0.6);
    }

    if (widget.isActive) {
      return Colors.black.withOpacity(0.4);
    }

    return Colors.black.withOpacity(0.25);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      label: widget.segment.label,
      enabled: !widget.isLocked,
      readOnly: true,
      child: MouseRegion(
        cursor: widget.isLocked
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) {
          if (!widget.isLocked) {
            setState(() => _isHovered = true);
          }
        },
        onExit: (_) {
          setState(() => _isHovered = false);
        },
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                constraints: const BoxConstraints(
                  minWidth: 60,
                  maxWidth: 80,
                  minHeight: 20,
                  maxHeight: 32,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getContainerColor(),
                  borderRadius: BorderRadius.circular(8),
                  border: widget.isActive
                      ? Border.all(
                    color: Colors.amber.withOpacity(0.6),
                    width: 1,
                  )
                      : null,
                  boxShadow: widget.isActive
                      ? [
                    BoxShadow(
                      color: Colors.amber.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ]
                      : _isHovered && !widget.isLocked
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                      : null,
                  gradient: widget.isActive
                      ? LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.amber.withOpacity(0.2),
                      Colors.amber.withOpacity(0.1),
                    ],
                  )
                      : null,
                ),
                child: Stack(
                  children: [
                    // Glow effect for active state
                    if (widget.isActive)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.amber.withOpacity(_glowAnimation.value * 0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                        ),
                      ),

                    // Main text content
                    Center(
                      child: _buildLabelText(theme),
                    ),

                    // Shimmer effect for premium segments
                    if (_isPremiumSegment() && !widget.isLocked)
                      _buildShimmerEffect(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildLabelText(ThemeData theme) {
    final textColor = _colorAnimation.value ?? _getBaseTextColor();

    return Text(
      widget.segment.label,
      style: widget.customTextStyle ?? theme.textTheme.bodySmall?.copyWith(
        color: textColor,
        fontWeight: widget.isActive ? FontWeight.bold : FontWeight.w600,
        fontSize: 10,
        letterSpacing: 0.5,
        shadows: widget.isActive
            ? [
          Shadow(
            color: Colors.amber.withOpacity(0.8),
            blurRadius: 4,
          ),
        ]
            : _isHovered && !widget.isLocked
            ? [
          Shadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ]
            : null,
      ),
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _buildShimmerEffect() {
    return Positioned.fill(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: LinearGradient(
                begin: Alignment(-1.0 + (_controller.value * 2), 0),
                end: Alignment(1.0 + (_controller.value * 2), 0),
                colors: [
                  Colors.transparent,
                  Colors.white.withOpacity(0.2),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isPremiumSegment() {
    final premiumTypes = ['premium', 'gems', 'rare', 'legendary', 'jackpot'];
    return premiumTypes.contains(widget.segment.rewardType.toLowerCase()) ||
        widget.segment.isExclusive;
  }
}

// Enhanced version with additional features for special segment types
class PremiumSegmentLabel extends StatefulWidget {
  final WheelSegment segment;
  final bool isLocked;
  final bool isActive;
  final TextStyle? customTextStyle;
  final bool showRarity;
  final String? rarityIndicator;

  const PremiumSegmentLabel({
    super.key,
    required this.segment,
    this.isLocked = false,
    this.isActive = false,
    this.customTextStyle,
    this.showRarity = true,
    this.rarityIndicator,
  });

  @override
  State<PremiumSegmentLabel> createState() => _PremiumSegmentLabelState();
}

class _PremiumSegmentLabelState extends State<PremiumSegmentLabel>
    with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late Animation<double> _sparkleAnimation;

  @override
  void initState() {
    super.initState();
    _initSparkleAnimation();

    if (!widget.isLocked && _isPremiumSegment()) {
      _sparkleController.repeat();
    }
  }

  void _initSparkleAnimation() {
    _sparkleController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _sparkleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _sparkleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(PremiumSegmentLabel oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isLocked != oldWidget.isLocked) {
      if (!widget.isLocked && _isPremiumSegment()) {
        _sparkleController.repeat();
      } else {
        _sparkleController.stop();
      }
    }
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    super.dispose();
  }

  bool _isPremiumSegment() {
    final premiumTypes = ['premium', 'gems', 'rare', 'legendary', 'jackpot'];
    return premiumTypes.contains(widget.segment.rewardType.toLowerCase()) ||
        widget.segment.isExclusive;
  }

  String _getRarityIndicator() {
    if (widget.rarityIndicator != null) return widget.rarityIndicator!;

    switch (widget.segment.rewardType.toLowerCase()) {
      case 'rare':
        return '★';
      case 'legendary':
        return '★★';
      case 'jackpot':
        return '★★★';
      case 'premium':
      case 'gems':
        return '💎';
      default:
        return '✨';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base label using SegmentLabel
        SegmentLabel(
          segment: widget.segment,
          isLocked: widget.isLocked,
          isActive: widget.isActive,
          customTextStyle: widget.customTextStyle,
        ),

        // Rarity indicator
        if (widget.showRarity && _isPremiumSegment() && !widget.isLocked)
          Positioned(
            top: -2,
            right: -2,
            child: AnimatedBuilder(
              animation: _sparkleAnimation,
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + (0.2 * _sparkleAnimation.value),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.9),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.amber.withOpacity(0.6),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Text(
                      _getRarityIndicator(),
                      style: const TextStyle(
                        fontSize: 8,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}