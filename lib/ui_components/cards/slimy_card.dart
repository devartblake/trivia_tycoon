import 'dart:ui';
import 'package:flutter/material.dart';

class SlimyCard extends StatefulWidget {
  final Widget topChild;
  final Widget bottomChild;
  final bool initiallyExpanded;
  final Gradient? backgroundGradient;
  final double blurAmount;
  final String? badgeText;
  final Color badgeColor;
  final bool useColoredCard;
  final Color? badgeTextColor;

  const SlimyCard({
    super.key,
    required this.topChild,
    required this.bottomChild,
    this.initiallyExpanded = false,
    this.backgroundGradient,
    this.blurAmount = 0,
    this.badgeText,
    this.badgeColor = Colors.deepOrange,
    this.useColoredCard = false,
    this.badgeTextColor,
  });

  @override
  State<SlimyCard> createState() => _SlimyCardState();
}

class _SlimyCardState extends State<SlimyCard> with SingleTickerProviderStateMixin {
  late bool _expanded;
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    if (_expanded) {
      _controller.value = 1.0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Colored card mode (new design from screenshots)
    if (widget.useColoredCard) {
      return Container(
        decoration: BoxDecoration(
          gradient: widget.backgroundGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top content area
              Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: widget.topChild,
                  ),
                  if (widget.badgeText != null)
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.badgeColor,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: widget.badgeColor.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          widget.badgeText!,
                          style: TextStyle(
                            color: widget.badgeTextColor ?? Colors.black,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),

              // Animated expansion
              SizeTransition(
                sizeFactor: _animation,
                axisAlignment: 1,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.2),
                  ),
                  padding: const EdgeInsets.all(16.0),
                  child: widget.bottomChild,
                ),
              ),

              // Toggle button
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0, top: 8.0),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _toggle,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 300),
                        child: Icon(
                          Icons.keyboard_arrow_down,
                          color: widget.backgroundGradient?.colors.first ?? Colors.grey[600],
                          size: 24,
                        ),
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

    // Original card design (backward compatible)
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        children: [
          if (widget.backgroundGradient != null)
            Container(
              decoration: BoxDecoration(gradient: widget.backgroundGradient),
            ),
          if (widget.blurAmount > 0)
            BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: widget.blurAmount,
                sigmaY: widget.blurAmount,
              ),
              child: Container(color: Colors.black.withValues(alpha: 0.05)),
            ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(20),
              boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6)],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: widget.topChild,
                    ),
                    if (widget.badgeText != null)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: widget.badgeColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            widget.badgeText!,
                            style: const TextStyle(color: Colors.white24, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                SizeTransition(
                  sizeFactor: _animation,
                  axisAlignment: 1,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: widget.bottomChild,
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _toggle,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: AnimatedRotation(
                          turns: _expanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: const Icon(
                            Icons.keyboard_arrow_down,
                            color: Colors.black26,
                            size: 28,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
