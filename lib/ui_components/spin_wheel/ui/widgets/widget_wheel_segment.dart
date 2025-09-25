import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/physics/spin_velocity.dart';
import '../../models/spin_system_models.dart';
import 'segment_image.dart';
import 'segment_label.dart';
import 'reward_icon_overlay.dart';
import 'segment_unlock_overlay.dart';
import 'segment_animated_highlight.dart';

class WidgetWheelSegment extends ConsumerStatefulWidget {
  final WheelSegment segment;
  final double angle;
  final bool isLocked;
  final bool isActive;
  final VoidCallback? onTap;
  final void Function(double velocity)? onGestureSpin;

  const WidgetWheelSegment({
    super.key,
    required this.segment,
    required this.angle,
    this.isLocked = false,
    this.isActive = false,
    this.onTap,
    this.onGestureSpin,
  });

  @override
  ConsumerState<WidgetWheelSegment> createState() => _WidgetWheelSegmentState();
}

class _WidgetWheelSegmentState extends ConsumerState<WidgetWheelSegment>
    with SingleTickerProviderStateMixin {
  Offset? _dragStart;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  EnhancedSpinVelocity? _velocityHelper;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(WidgetWheelSegment oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _pulseController.repeat(reverse: true);
      } else {
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final spinSize = size.width * 0.8;

    // Cache velocity helper to avoid recreation
    _velocityHelper ??= EnhancedSpinVelocity(height: spinSize, width: spinSize);

    return Transform.rotate(
      angle: widget.angle,
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.isActive ? _pulseAnimation.value : 1.0,
            child: GestureDetector(
              onTap: widget.onTap,
              onPanStart: (details) {
                _dragStart = details.localPosition;
              },
              onPanEnd: (details) {
                if (_dragStart != null && widget.onGestureSpin != null) {
                  final velocity = _velocityHelper!.getVelocityFromGesture(
                    _dragStart!,
                    details.velocity.pixelsPerSecond,
                    const Duration(milliseconds: 300),
                  );
                  widget.onGestureSpin!(velocity);
                }
                _dragStart = null;
              },
              child: Tooltip(
                message: _buildTooltipMessage(),
                child: Semantics(
                  label: widget.segment.label,
                  hint: widget.isLocked
                      ? 'Locked segment. Unlock with streak & currency.'
                      : 'Spin to win this prize!',
                  button: true,
                  child: _buildSegmentContainer(theme),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String _buildTooltipMessage() {
    if (widget.segment.isExclusive) {
      return '🔒 Requires ${widget.segment.requiredStreak}+ streak & ${widget.segment.requiredCurrency}💎';
    }
    return '${widget.segment.label} (${widget.segment.rewardType})';
  }

  Widget _buildSegmentContainer(ThemeData theme) {
    return Container(
      decoration: _buildSegmentDecoration(theme),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          _buildMainContainer(theme),
          RewardIconOverlay(segment: widget.segment),
          if (widget.segment.isExclusive)
            SegmentUnlockOverlay(isUnlocked: !widget.isLocked),
          if (widget.isActive)
            const Positioned.fill(
              child: SegmentAnimatedHighlight(isActive: true),
            ),
          if (widget.isLocked) _buildLockedOverlay(theme),
        ],
      ),
    );
  }

  BoxDecoration _buildSegmentDecoration(ThemeData theme) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 8,
          offset: const Offset(0, 4),
        ),
        if (widget.isActive)
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 0),
          ),
      ],
    );
  }

  Widget _buildMainContainer(ThemeData theme) {
    return Container(
      width: 140,
      height: 90,
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        gradient: _buildSegmentGradient(),
        borderRadius: BorderRadius.circular(16),
        border: widget.isActive
            ? Border.all(
          color: theme.colorScheme.primary,
          width: 2,
        )
            : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            flex: 3,
            child: SegmentImage(
              segment: widget.segment,
              isLocked: widget.isLocked,
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            flex: 2,
            child: SegmentLabel(
              segment: widget.segment,
              isLocked: widget.isLocked,
            ),
          ),
        ],
      ),
    );
  }

  LinearGradient _buildSegmentGradient() {
    final baseColor = widget.segment.color;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        baseColor,
        baseColor.withOpacity(0.8),
        baseColor.withOpacity(0.9),
      ],
      stops: const [0.0, 0.5, 1.0],
    );
  }

  Widget _buildLockedOverlay(ThemeData theme) {
    return Positioned.fill(
      child: Container(
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.6),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.lock_outlined,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(height: 4),
              Text(
                'LOCKED',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}