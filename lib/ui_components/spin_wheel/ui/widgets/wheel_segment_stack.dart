import 'dart:math';
import 'package:flutter/material.dart';
import '../../models/spin_system_models.dart';
import 'widget_wheel_segment.dart';

class WheelSegmentStack extends StatefulWidget {
  final List<WheelSegment> segments;
  final double rotationAngle;
  final int? activeIndex;
  final void Function(int)? onSegmentTap;
  final void Function(double velocity)? onGestureSpin;
  final bool isSpinning;

  const WheelSegmentStack({
    super.key,
    required this.segments,
    required this.rotationAngle,
    this.activeIndex,
    this.onSegmentTap,
    this.onGestureSpin,
    this.isSpinning = false,
  });

  @override
  State<WheelSegmentStack> createState() => _WheelSegmentStackState();
}

class _WheelSegmentStackState extends State<WheelSegmentStack>
    with TickerProviderStateMixin {
  late AnimationController _rotationController;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _initAnimations();
  }

  void _initAnimations() {
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void didUpdateWidget(WheelSegmentStack oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Animate when spinning state changes
    if (widget.isSpinning != oldWidget.isSpinning) {
      if (widget.isSpinning) {
        _scaleController.forward();
      } else {
        _scaleController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.segments.isEmpty) {
      return const SizedBox.shrink();
    }

    final double sliceAngle = 2 * pi / widget.segments.length;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: widget.isSpinning
                  ? [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ]
                  : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: RepaintBoundary(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background circle for better visual hierarchy
                  Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          Colors.grey.shade50,
                        ],
                      ),
                    ),
                  ),
                  // Segments
                  ...List.generate(widget.segments.length, (index) {
                    return _buildSegmentWidget(index, sliceAngle);
                  }),
                  // Center decoration
                  _buildCenterDecoration(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSegmentWidget(int index, double sliceAngle) {
    final segment = widget.segments[index];
    final angle = sliceAngle * index;
    final isActive = widget.activeIndex == index;
    final isLocked = segment.isExclusive && !_isSegmentUnlocked(segment);

    return WidgetWheelSegment(
      key: ValueKey('segment_$index'),
      segment: segment,
      angle: widget.rotationAngle + angle,
      isActive: isActive,
      isLocked: isLocked,
      onTap: widget.isSpinning
          ? null
          : () => widget.onSegmentTap?.call(index),
      onGestureSpin: widget.isSpinning
          ? null
          : widget.onGestureSpin,
    );
  }

  Widget _buildCenterDecoration() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white,
            Colors.grey.shade100,
          ],
        ),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.isSpinning
                ? Colors.blue
                : Colors.grey.shade400,
          ),
        ),
      ),
    );
  }

  bool _isSegmentUnlocked(WheelSegment segment) {
    // This should be replaced with actual unlock logic
    // For now, assume all segments are unlocked for demo
    return true;
  }
}