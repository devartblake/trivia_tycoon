import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trivia_tycoon/ui_components/spin_wheel/physics/spin_velocity.dart';
import '../../models/wheel_segment.dart';
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

class _WidgetWheelSegmentState extends ConsumerState<WidgetWheelSegment> {
  Offset? _dragStart;

  @override
  Widget build(BuildContext context) {
    final spinSize = MediaQuery.of(context).size.width * 0.8;
    final velocityHelper = SpinVelocity(height: spinSize, width: spinSize);

    return Transform.rotate(
      angle: widget.angle,
      child: GestureDetector(
        onTap: widget.onTap,
        onPanStart: (details) {
          _dragStart = details.localPosition;
        },
        onPanEnd: (details) {
          if (_dragStart != null && widget.onGestureSpin != null) {
            final velocity = velocityHelper.getVelocity(
              _dragStart!,
              details.velocity.pixelsPerSecond,
            );
            widget.onGestureSpin!(velocity);
          }
          _dragStart = null;
        },
        child: Tooltip(
          message: widget.segment.isExclusive
              ? '🔒 Requires ${widget.segment.requiredStreak}+ streak & ${widget.segment.requiredCurrency}💎'
              : '${widget.segment.label} (${widget.segment.rewardType})',
          child: Semantics(
            label: widget.segment.label,
            hint: widget.isLocked
                ? 'Locked segment. Unlock with streak & currency.'
                : 'Spin to win this prize!',
            button: true,
            child: Stack(
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: 140,
                  height: 90,
                  margin: const EdgeInsets.only(top: 16),
                  decoration: BoxDecoration(
                    color: widget.segment.color,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SegmentImage(
                        segment: widget.segment,
                        isLocked: widget.isLocked,
                      ),
                      const SizedBox(height: 4),
                      SegmentLabel(
                        segment: widget.segment,
                        isLocked: widget.isLocked,
                      ),
                    ],
                  ),
                ),
                RewardIconOverlay(segment: widget.segment),
                if (widget.segment.isExclusive)
                  SegmentUnlockOverlay(isUnlocked: !widget.isLocked),
                if (widget.isActive)
                  const Positioned.fill(
                    child: SegmentAnimatedHighlight(isActive: true),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
