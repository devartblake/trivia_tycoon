import 'package:flutter/material.dart';

import '../../models/spin_system_models.dart';

// Enhanced Segment Image Component
class SegmentImage extends StatefulWidget {
  final WheelSegment segment;
  final bool isLocked;

  const SegmentImage({
    super.key,
    required this.segment,
    this.isLocked = false,
  });

  @override
  State<SegmentImage> createState() => _SegmentImageState();
}

class _SegmentImageState extends State<SegmentImage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: widget.segment.label,
      enabled: !widget.isLocked,
      button: true,
      child: MouseRegion(
        cursor: widget.isLocked
            ? SystemMouseCursors.forbidden
            : SystemMouseCursors.click,
        onEnter: (_) {
          if (!widget.isLocked) {
            setState(() => _isHovered = true);
            _controller.forward();
          }
        },
        onExit: (_) {
          setState(() => _isHovered = false);
          _controller.reverse();
        },
        child: AnimatedBuilder(
          animation: _scaleAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: _isHovered && !widget.isLocked
                      ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildImageContent(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildImageContent() {
    if (widget.segment.imagePath != null) {
      return Image.asset(
        widget.segment.imagePath!,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        color: widget.isLocked ? Colors.grey.withOpacity(0.6) : null,
        colorBlendMode: widget.isLocked ? BlendMode.saturation : null,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackIcon();
        },
      );
    }
    return _buildFallbackIcon();
  }

  Widget _buildFallbackIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: widget.isLocked
            ? Colors.grey.withOpacity(0.3)
            : widget.segment.color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.card_giftcard,
        size: 24,
        color: widget.isLocked
            ? Colors.grey
            : widget.segment.color,
      ),
    );
  }
}
