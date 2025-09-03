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

  const SlimyCard({
    super.key,
    required this.topChild,
    required this.bottomChild,
    this.initiallyExpanded = false,
    this.backgroundGradient,
    this.blurAmount = 0,
    this.badgeText,
    this.badgeColor = Colors.deepOrange,
  });

  @override
  State<SlimyCard> createState() => _SlimyCardState();
}

class _SlimyCardState extends State<SlimyCard> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
  }

  void _toggle() => setState(() => _expanded = !_expanded);

  @override
  Widget build(BuildContext context) {
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
              child: Container(color: Colors.black.withOpacity(0.05)),
            ),
          Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.75),
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
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_expanded)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: widget.bottomChild,
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
                        child: Icon(
                          _expanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                          color: Colors.black54,
                          size: 28,
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